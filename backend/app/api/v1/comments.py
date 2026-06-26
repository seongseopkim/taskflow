from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.database import get_db
from app.models.comment import Comment
from app.models.user import User
from app.schemas.comment import CommentCreate, CommentResponse
from app.dependencies import get_current_user
from app.core.permissions import check_permission, Role

router = APIRouter(tags=["comments"])

# 1. 댓글 목록 조회 (카드의 댓글들)
@router.get("/cards/{card_id}/comments")
async def get_comments(
    card_id: int,
    member=Depends(check_permission(Role.VIEWER)),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Comment).where(Comment.card_id == card_id)
    )

    comment = result.scalars().all()

    return [CommentResponse.model_validate(cm) for cm in comment]

# 2. 댓글 작성 (viewer도 가능!)
@router.post("/cards/{card_id}/comments", status_code=201)
async def create_comment(
    card_id: int,
    data: CommentCreate,
    current_user: User = Depends(get_current_user),
    member=Depends(check_permission(Role.VIEWER)),
    db: AsyncSession = Depends(get_db),
):
    comment = Comment(
        card_id = card_id,
        user_id = current_user.id,
        content = data.content,
    )
    
    db.add(comment)
    await db.flush()

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
