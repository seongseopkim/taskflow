from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models.card import Card
from app.models.list import List
from app.schemas.card import CardCreate, CardUpdate, CardMove, CardResponse
from app.dependencies import get_current_user
from app.core.permissions import check_permission, Role

router = APIRouter(tags=["cards"])

# 1. 카드 목록 조회 (리스트의 카드들, position 순서대로)
@router.get("/lists/{list_id}/cards")
async def get_cards(
    list_id: int,
    member=Depends(check_permission(Role.VIEWER)),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Card).where(
            Card.list_id == list_id
        ).order_by(Card.position)
    )

    card_list = result.scalars().all()

    return [CardResponse.model_validate(cl) for cl in card_list]

# 2. 카드 생성 (editor 이상)
@router.post("/lists/{list_id}/cards", status_code=201)
async def create_card(
    list_id: int,
    data: CardCreate,
    member=Depends(check_permission(Role.EDITOR)),
    current_user=Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # position 계산 (lists에서 했던 거랑 같아)

    result = await db.execute(
        select(func.max(Card.position)).where(Card.list_id == list_id)
               )
    

    max_position = result.scalar() or 0

    new_position = max_position + 65536.0
    created_by = current_user.id

    new_card = Card(
        list_id = list_id,
        title = data.title,
        description = data.description,
        position = new_position,
        assignee_id = data.assignee_id,
        due_date = data.due_date,
        created_by = created_by,
    )
    # created_by = current_user.id
    
    db.add(new_card)
    await db.flush()

    return CardResponse.model_validate(new_card)

# 3. 카드 수정 (editor 이상)
@router.patch("/cards/{card_id}")
async def update_card(
    card_id: int,
    data: CardUpdate,
    member=Depends(check_permission(Role.EDITOR)),
    db: AsyncSession = Depends(get_db),
):
    # 카드 조회 → 보낸 필드만 수정
    card = await db.get(Card, card_id)

    if not card :
        raise HTTPException(404, "카드가 없습니다")

    if data.title is not None:
        card.title = data.title
    if data.description is not None:
        card.description = data.description
    if data.assignee_id is not None:
        card.assignee_id = data.assignee_id
    if data.due_date is not None:
        card.due_date = data.due_date

    await db.flush()

    return CardResponse.model_validate(card)

# 4. 카드 이동 (editor 이상)
@router.patch("/cards/{card_id}/move")
async def move_card(
    card_id: int,
    data: CardMove,
    member=Depends(check_permission(Role.EDITOR)),
    db: AsyncSession = Depends(get_db),
):
    # 카드 조회 → list_id + position 변경
    card = await db.get(Card, card_id)
    
    if not card :
        raise HTTPException(404, "카드가 없습니다")

    card.list_id = data.target_list_id
    card.position = data.position

    await db.flush()

    return CardResponse.model_validate(card)
# 5. 카드 삭제 (editor 이상)
@router.delete("/cards/{card_id}", status_code=204)
async def delete_card(
    card_id: int,
    member=Depends(check_permission(Role.EDITOR)),
    db: AsyncSession = Depends(get_db),
):
    card = await db.get(Card, card_id)
    if not card :
        raise HTTPException(404, "카드가 없습니다")

    await db.delete(card)
    await db.flush()

    