from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.user import User
from app.models.board import Board
from app.models.workspace import WorkspaceMember
from app.schemas.board import BoardCreate, BoardUpdate, BoardResponse
from app.dependencies import get_current_user
from app.core.permissions import check_permission, Role

router = APIRouter(prefix="/workspaces/{workspace_id}/boards", tags=["boards"])

# 1. 보드 목록 조회 (멤버면 누구나)
@router.get("/")
async def get_boards(
    workspace_id: int,
    member=Depends(check_permission(Role.VIEWER)),
    db: AsyncSession = Depends(get_db),
):
    # 이 워크스페이스의 보드 목록 조회
    result = await db.execute(
        select(Board).where(Board.workspace_id == workspace_id)
    )

    boards = result.scalars().all()

    return [BoardResponse.model_validate(bd) for bd in boards]
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
