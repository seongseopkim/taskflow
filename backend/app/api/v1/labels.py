from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.label import Label, CardLabel
from app.models.card import Card
from app.schemas.label import LabelCreate, LabelResponse
from app.dependencies import get_current_user
from app.core.permissions import check_permission, Role

router = APIRouter(tags=["labels"])

# 1. 보드의 라벨 목록 조회
@router.get("/boards/{board_id}/labels")
async def get_labels(
    board_id: int,
    member=Depends(check_permission(Role.VIEWER)),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Label).where(Label.board_id == board_id)
    )

    labels = result.scalars().all()

    return [LabelResponse.model_validate(lb) for lb in labels]

# 2. 라벨 생성 (editor 이상)
@router.post("/boards/{board_id}/labels", status_code=201)
async def create_label(
    board_id: int,
    data: LabelCreate,
    member=Depends(check_permission(Role.EDITOR)),
    db: AsyncSession = Depends(get_db),
):
    label = Label(
        board_id = board_id,
        name = data.name,
        color = data.color,
    )

    db.add(label)
    await db.flush()

    return LabelResponse.model_validate(label)

# 3. 카드에 라벨 붙이기 (editor 이상)
@router.post("/cards/{card_id}/labels/{label_id}", status_code=201)
async def attach_label(
    card_id: int,
    label_id: int,
    member=Depends(check_permission(Role.EDITOR)),
    db: AsyncSession = Depends(get_db),
):
    # CardLabel 중간 테이블에 추가
    # 이미 붙어있으면 409

    result = await db.execute(
        select(CardLabel).where(
            CardLabel.card_id == card_id,
            CardLabel.label_id == label_id,
        )
    )

    check = result.scalar() or 0

    if check != 0:
        raise HTTPException(409, "이미 라벨링을 완료했습니다.")
    
    cardlabel = CardLabel(
        card_id = card_id,
        label_id = label_id,
    )
    db.add(cardlabel)

    await db.flush()

    return {"card_id" : card_id, "label_id" : label_id}




# 4. 카드에서 라벨 떼기 (editor 이상)
@router.delete("/cards/{card_id}/labels/{label_id}", status_code=204)
async def detach_label(
    card_id: int,
    label_id: int,
    member=Depends(check_permission(Role.EDITOR)),
    db: AsyncSession = Depends(get_db),
):
    # CardLabel 중간 테이블에서 삭제
    result = await db.execute(
        select(CardLabel).where(
            CardLabel.card_id == card_id,
            CardLabel.label_id == label_id,
        )
    )
    check = result.scalar_one_or_none()

    if not check:
        raise HTTPException(404, "해당 라벨은 존재하지 않습니다.")
    
    await db.delete(check)
    await db.flush()

    