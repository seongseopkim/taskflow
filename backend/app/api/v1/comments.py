from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func ,select

from app.database import get_db
from app.models.comment import Comment
from app.models.user import User
from app.models.card import Card
from app.schemas.comment import CommentCreate, CommentResponse
from app.dependencies import get_current_user
from app.core.permissions import check_permission, Role, check_card_permission
from app.tasks.notification_tasks import send_comment_notification

from app.schemas.common import PaginatedResponse

router = APIRouter(tags=["comments"])

# 1. 댓글 목록 조회 (카드의 댓글들)
@router.get("/cards/{card_id}/comments", response_model = PaginatedResponse[CommentResponse])
async def get_comments(
    card_id: int,
    page : int = 1,
    size : int = 20,
    member=Depends(check_card_permission(Role.VIEWER)),
    db: AsyncSession = Depends(get_db),
):
    
    count_result = await db.execute(
        select(func.count()).select_from(Comment)
        .where(Comment.card_id == card_id))
    
    total = count_result.scalar()

    result = await db.execute(
        select(Comment).where(Comment.card_id == card_id)
        .offset((page - 1) * size)
        .limit(size)
    )

    comment = result.scalars().all()

    return PaginatedResponse(
        items = [CommentResponse.model_validate(cm) for cm in comment],
        page = page,
        size = size,
        total = total,
        pages = (total + size -1 ) // size
    )
# 2. 댓글 작성 (viewer도 가능!)
@router.post("/cards/{card_id}/comments", status_code=201)
async def create_comment(
    card_id: int,
    data: CommentCreate,
    current_user: User = Depends(get_current_user),
    member=Depends(check_card_permission(Role.VIEWER)),
    db: AsyncSession = Depends(get_db),
):
    card = await db.get(Card, card_id)
    if not card:
        raise HTTPException(404, "카드가 없습니다")
    
    comment = Comment(
        card_id = card_id,
        user_id = current_user.id,
        content = data.content,
    )
    
    db.add(comment)
    await db.flush()
    await db.refresh(comment)
    if card.assignee_id and card.assignee_id != current_user.id:
        send_comment_notification.delay(card.assignee_id, card_id, current_user.name)
    return CommentResponse.model_validate(comment)

# 3. 댓글 삭제 (본인 댓글만)
@router.delete("/comments/{comment_id}", status_code=204)
async def delete_comment(
    comment_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # 1. 댓글 조회
    comment = await db.get(Comment, comment_id)
    if not comment:
        raise HTTPException(404, "댓글이 조회되지 않습니다")
    # 2. 댓글 작성자가 본인인지 확인
    if comment.user_id != current_user.id:
        raise HTTPException(403, "내 댓글이 아닙니다")
    # 3. 삭제
    await db.delete(comment)
    await db.flush()
