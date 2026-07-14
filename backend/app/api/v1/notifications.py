from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, update

from app.database import get_db
from app.models.user import User
from app.models.notification import Notification
from app.schemas.notification import NotificationResponse
from app.schemas.common import PaginatedResponse
from app.dependencies import get_current_user

router = APIRouter(prefix="/notifications", tags=["notifications"])

# 1. 내 알림 목록 조회
@router.get("/", response_model=PaginatedResponse[NotificationResponse])
async def get_notifications(
    page: int = 1,
    size: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # total_count 위한 db조회
    count_result = await db.execute(
        select(func.count()).select_from(Notification)
        .where(Notification.user_id == current_user.id)
    )

    total = count_result.scalar()

    #실제 조회
    result = await db.execute(
        select(Notification)
        .where(Notification.user_id == current_user.id)
        .order_by(Notification.created_at.desc())
        .offset((page - 1) * size)
        .limit(size)
    )

    noti = result.scalars().all()

    return PaginatedResponse[NotificationResponse](
        items = [NotificationResponse.model_validate(n) for n in noti],
        page = page,
        size = size,
        pages = (total + size -1) // size,
        total = total

    )   

    # 힌트: Notification.user_id == current_user.id 로 필터
    # 힌트: order_by는 최신순(created_at 내림차순)이 자연스러움
    #       → .order_by(Notification.created_at.desc())


# 2. 알림 하나 읽음 처리
@router.patch("/{notification_id}/read")
async def mark_as_read(
    notification_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        update(Notification)
        .where(notification_id == Notification.id, Notification.user_id == current_user.id)
        .values(is_read = True)
    )

    if result.rowcount == 0:
        raise HTTPException(404, "알림을 찾을 수 없습니다")
    db.flush()
    return {"message" : "읽음 처리되었습니다"}
    #힌트: 알림 조회 → 본인 것인지 확인 → is_read = True
    

# 3. 전체 읽음 처리
@router.patch("/read-all")
async def mark_all_as_read(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # 힌트: update(Notification).where(...).values(is_read=True)
    # 이건 조회 없이 바로 여러 행을 한 번에 업데이트하는 방식이야
    result = await db.execute(
        update(Notification)
        .where(Notification.user_id == current_user.id)
        .values(is_read = True)
    )

    if result.rowcount == 0:
        raise HTTPException(404, "알림이 없습니다")
    db.flush()
    return {"message" : "전체 읽음 처리되었습니다."}