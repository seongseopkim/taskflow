from sqlalchemy.ext.asyncio import AsyncSession
from app.models.activity import Activity


async def log_activity(
    db: AsyncSession,
    board_id: int,
    user_id: int,
    action: str,
    detail: dict,
):
    activity = Activity(
        board_id=board_id,
        user_id=user_id,
        action=action,
        detail=detail,
    )
    db.add(activity)
    await db.flush()