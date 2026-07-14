from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select
from app.database import get_db
from app.models.user import User
from app.models.board import Board
from app.models.workspace import WorkspaceMember
from app.schemas.board import BoardCreate, BoardUpdate, BoardResponse
from app.dependencies import get_current_user
from app.core.permissions import check_permission, Role, check_board_permission, check_list_permission

from app.schemas.common import PaginatedResponse

router = APIRouter(prefix="/workspaces/{workspace_id}/boards", tags=["boards"])

# 1. 보드 목록 조회 (멤버면 누구나)
@router.get("/", response_model = PaginatedResponse[BoardResponse])
async def get_boards(
    workspace_id: int,
    page: int = 1,
    size: int = 20,
    member=Depends(check_permission(Role.VIEWER)),
    db: AsyncSession = Depends(get_db),
):
    
    count_result = await db.execute(
        select(func.count()).select_from(Board)
        .where(Board.workspace_id == workspace_id))
    # 이 워크스페이스의 보드 목록 조회
    result = await db.execute(
        select(Board).where(Board.workspace_id == workspace_id)
        .offset((page - 1) * size)
        .limit(size)
    )
    total = count_result.scalar()

    boards = result.scalars().all()

    return PaginatedResponse(
        items = [BoardResponse.model_validate(bd) for bd in boards],
        total = total,
        page = page,
        size = size,
        pages = (total + size - 1) // size
        )
# 2. 보드 생성 (editor 이상)
@router.post("/", status_code=201)
async def create_board(
    workspace_id: int,
    data: BoardCreate,
    member=Depends(check_permission(Role.EDITOR)),
    db: AsyncSession = Depends(get_db),
):
    # Board 생성 (workspace_id 연결)
    board = Board(
        workspace_id = workspace_id,
        name = data.name,
    )

    db.add(board)
    await db.flush()
    await db.refresh(board)
    return BoardResponse.model_validate(board
                                        )

# 3. 보드 삭제 (owner만)
@router.delete("/{board_id}", status_code=204)
async def delete_board(
    board_id: int,
    member=Depends(check_permission(Role.OWNER)),
    db: AsyncSession = Depends(get_db),
):
    # 보드 조회 → 삭제
    board = await db.get(Board, board_id)

    if not board:
        raise HTTPException(404, "해당 보드가 없습니다")

    await db.delete(board)
    await db.flush()

####  보드 상세 조회 api


from sqlalchemy.orm import selectinload
from app.schemas.board import BoardDetailResponse
from app.models.list import List
from app.models.card import Card

@router.get("/{board_id}", response_model=BoardDetailResponse)
async def get_board_detail(
    board_id: int,
    member=Depends(check_board_permission(Role.VIEWER)),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Board)
        .where(Board.id == board_id)
        .options(
            selectinload(Board.lists).selectinload(List.cards)
        )
    )
    board = result.scalar_one_or_none()

    if not board:
        raise HTTPException(404, "보드를 찾을 수 없습니다")

    return BoardDetailResponse.model_validate(board)