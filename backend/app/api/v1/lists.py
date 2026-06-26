from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models.list import List
from app.models.board import Board
from app.schemas.list import ListCreate, ListUpdate, ListResponse
from app.dependencies import get_current_user
from app.core.permissions import check_permission, Role

router = APIRouter(tags=["lists"])

# 1. 리스트 목록 조회 (보드의 리스트들, position 순서대로)
@router.get("/boards/{board_id}/lists")
async def get_lists(
    board_id: int,
    member=Depends(check_permission(Role.VIEWER)),
    db: AsyncSession = Depends(get_db),
):
    # Board의 리스트를 position 순서로 조회
    # 힌트: .order_by(List.position)
    result = await db.execute(
        select(List).where(
            List.board_id == board_id
        ).order_by(List.position)
    )

    lists = result.scalars().all()


    return [ListResponse.model_validate(lst) for lst in lists]

# 2. 리스트 생성 (editor 이상)
@router.post("/boards/{board_id}/lists", status_code=201)
async def create_list(
    board_id: int,
    data: ListCreate,
    member=Depends(check_permission(Role.EDITOR)),
    db: AsyncSession = Depends(get_db),
):
    # 1. 현재 리스트들 중 가장 큰 position 조회
    result = await db.execute(
        select(func.max(List.position)).where(List.board_id == board_id)
    )
    max_position = result.scalar() or 0

    # 2. 새 리스트의 position = max_position + 65536.0
    
    new_position = max_position + 65536.0

    new_list = List(
        title = data.title,
        position = new_position,
        board_id = board_id,
    )

    db.add(new_list)
    await db.flush()

    return ListResponse.model_validate(new_list)

    # 힌트: select(func.max(List.position)).where(List.board_id == board_id)
    pass    

# 3. 리스트 삭제 (editor 이상)
@router.delete("/lists/{list_id}", status_code=204)
async def delete_list(
    list_id: int,
    member=Depends(check_permission(Role.EDITOR)),
    db: AsyncSession = Depends(get_db),
):
    lst = await db.get(List, list_id)

    if not lst :
        raise HTTPException(404, "리스트가 존재하지 않습니다")
    db.delete(lst)
    await db.flush()

