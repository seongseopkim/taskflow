from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.database import get_db
from app.models.card import Card
from app.models.list import List
from app.schemas.card import CardCreate, CardUpdate, CardMove, CardResponse
from app.dependencies import get_current_user
from app.core.permissions import check_permission, check_card_permission, Role, check_board_permission, check_list_permission

from app.schemas.common import PaginatedResponse
from app.tasks.notification_tasks import send_card_assigned_notification

from app.core.activity_logger import log_activity
router = APIRouter(tags=["cards"])

# 1. 카드 목록 조회 (리스트의 카드들, position 순서대로)
@router.get("/lists/{list_id}/cards", response_model = PaginatedResponse[CardResponse])
async def get_cards(
    list_id: int,
    page : int = 1,
    size : int = 20,
    member=Depends(check_list_permission(Role.VIEWER)),
    db: AsyncSession = Depends(get_db),
):
    count_result = await db.execute(
        select(func.count()).select_from(Card)
        .where(Card.list_id == list_id)
    )

    total = count_result.scalar()

    result = await db.execute(
        select(Card).where(
            Card.list_id == list_id
        ).order_by(Card.position)
        .offset((page - 1) * size)
        .limit(size)
    )

    card_list = result.scalars().all()

    return PaginatedResponse(
        items = [CardResponse.model_validate(cl) for cl in card_list],
        page = page,
        size = size,
        pages = (total + size -1) // size,
        total = total,
    
    )
# 2. 카드 생성 (editor 이상)
@router.post("/lists/{list_id}/cards", status_code=201)
async def create_card(
    list_id: int,
    data: CardCreate,
    member=Depends(check_list_permission(Role.EDITOR)),
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
    await db.refresh(new_card)

    lst = await db.get(List, list_id)

    await log_activity(
        db = db,
        board_id = lst.board_id,
        user_id = current_user.id,
        action = "card_created",
        detail = {"card_id": new_card.id, "title" : new_card.title},
    )

    return CardResponse.model_validate(new_card)

# 3. 카드 수정 (editor 이상)
@router.patch("/cards/{card_id}")
async def update_card(
    card_id: int,
    data: CardUpdate,
    member=Depends(check_card_permission(Role.EDITOR)),
    current_user = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):  
    assigneer_modified = False
    # 카드 조회 → 보낸 필드만 수정
    card = await db.get(Card, card_id)

    if not card :
        raise HTTPException(404, "카드가 없습니다")
    old_assignee_id = card.assignee_id
    if data.title is not None:
        card.title = data.title
    if data.description is not None:
        card.description = data.description
    if data.assignee_id is not None:
        if old_assignee_id != data.assignee_id:
             assigneer_modified = True
        card.assignee_id = data.assignee_id
    if data.due_date is not None:
        card.due_date = data.due_date

    await db.flush()
    await db.refresh(card)

    if assigneer_modified:
        send_card_assigned_notification.delay(data.assignee_id, card_id, current_user.name)
    return CardResponse.model_validate(card)

# 4. 카드 이동 (editor 이상)
@router.patch("/cards/{card_id}/move")
async def move_card(
    card_id: int,
    data: CardMove,
    member=Depends(check_card_permission(Role.EDITOR)),
    current_user = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # 카드 조회 → list_id + position 변경
    card = await db.get(Card, card_id)

    if not card :
        raise HTTPException(404, "카드가 없습니다")

##### 이동 시 acitivity 기록을 위해서 남겨두어야 함.
    card_list_id = card.list_id

    card.list_id = data.target_list_id
    card.position = data.position

    new_list = await db.get(List, data.target_list_id)
    await db.flush()


    await log_activity(
        db = db,
       board_id = new_list.board_id,
        user_id = current_user.id,
        action = "card_moved",
        detail = {"card_id": card.id, "from_list": card_list_id, "to_list": data.target_list_id}
    )

    return CardResponse.model_validate(card)
# 5. 카드 삭제 (editor 이상)
@router.delete("/cards/{card_id}", status_code=204)
async def delete_card(
    card_id: int,
    member=Depends(check_card_permission(Role.EDITOR)),
    db: AsyncSession = Depends(get_db),
):
    card = await db.get(Card, card_id)
    if not card :
        raise HTTPException(404, "카드가 없습니다")

    await db.delete(card)
    await db.flush()

    