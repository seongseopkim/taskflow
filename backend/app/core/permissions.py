from fastapi import Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from enum import Enum

from app.database import get_db
from app.models.user import User
from app.models.workspace import WorkspaceMember
from app.models.board import Board
from app.models.list import List
from app.models.card import Card
from app.dependencies import get_current_user

class Role(str, Enum):
    OWNER = "owner"
    EDITOR = "editor"
    VIEWER = "viewer"

ROLE_HIERARCHY = {Role.OWNER: 3, Role.EDITOR: 2, Role.VIEWER: 1}


# ── 공통 로직: workspace_id로 실제 권한 확인 ──
async def _verify_role(db: AsyncSession, user_id: int, workspace_id: int, required: Role):
    result = await db.execute(
        select(WorkspaceMember).where(
            WorkspaceMember.workspace_id == workspace_id,
            WorkspaceMember.user_id == user_id,
        )
    )
    member = result.scalar_one_or_none()

    if not member:
        raise HTTPException(403, "워크스페이스 멤버가 아닙니다")

    if ROLE_HIERARCHY[member.role] < ROLE_HIERARCHY[required]:
        raise HTTPException(403, "권한이 부족합니다")

    return member


# ── 1. workspace_id로 직접 체크 (workspaces.py에서 사용) ──
def check_permission(required: Role):
    async def _check(
        workspace_id: int,
        current_user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ):
        return await _verify_role(db, current_user.id, workspace_id, required)
    return _check


# ── 2. board_id로 체크 (boards.py, lists.py에서 사용) ──
def check_board_permission(required: Role):
    async def _check(
        board_id: int,
        current_user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ):
        board = await db.get(Board, board_id)
        if not board:
            raise HTTPException(404, "보드를 찾을 수 없습니다")
        return await _verify_role(db, current_user.id, board.workspace_id, required)
    return _check


# ── 3. list_id로 체크 (카드 생성 등에서 사용) ──
def check_list_permission(required: Role):
    async def _check(
        list_id: int,
        current_user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ):
        lst = await db.get(List, list_id)
        if not lst:
            raise HTTPException(404, "리스트를 찾을 수 없습니다")
        board = await db.get(Board, lst.board_id)
        return await _verify_role(db, current_user.id, board.workspace_id, required)
    return _check


# ── 4. card_id로 체크 (카드 수정/이동/삭제, 댓글, 라벨에서 사용) ──
def check_card_permission(required: Role):
    async def _check(
        card_id: int,
        current_user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ):
        card = await db.get(Card, card_id)
        if not card:
            raise HTTPException(404, "카드를 찾을 수 없습니다")
        lst = await db.get(List, card.list_id)
        board = await db.get(Board, lst.board_id)
        return await _verify_role(db, current_user.id, board.workspace_id, required)
    return _check