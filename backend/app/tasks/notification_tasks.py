from app.tasks.celery_app import celery_app
from app.database import AsyncSessionLocal
from app.models.notification import Notification
# 1. 카드 배정 알림
@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def send_card_assigned_notification(self, assignee_id: int, card_id: int, assigner_name: str):
    import asyncio
    asyncio.run(_send_card_assigned_notification(assignee_id, card_id, assigner_name))
    
async def _send_card_assigned_notification(assignee_id: int, card_id: int, assigner_name: str):
    content = f"{assigner_name}님이 카드를 당신에게 배정했습니다"

    async with AsyncSessionLocal() as db:
        notification = Notification(
            user_id=assignee_id,
            type="card_assigned",
            content=content,
            card_id=card_id,
        )
        db.add(notification)
        await db.commit()

# 2. 댓글 알림
@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def send_comment_notification(self, card_owner_id: int, card_id: int, commenter_name: str):
    import asyncio
    asyncio.run(_send_comment_notification(card_owner_id, card_id, commenter_name))
    # "민수님이 카드에 댓글을 남겼습니다" 알림
async def _send_comment_notification(card_owner_id: int, card_id: int, commenter_name: str):
    content = f"{commenter_name}님이 카드에 댓글을 남겼습니다"
    
    async with AsyncSessionLocal() as db:
         notification = Notification(
             user_id = card_owner_id,
             type="comment",
             content=content,
             card_id = card_id,
         )
         db.add(notification)
         await db.commit()


# 3. 이메일 발송 (선택)
@celery_app.task(bind=True, max_retries=3, default_retry_delay=60)
def send_email_notification(self, to_email: str, subject: str, body: str):
    # 이메일 발송 시도
    # 실패하면 self.retry()로 재시도
    try:
        print("이메일 발송 - notification_tasks.py:49" )
    except Exception as e:
        raise self.retry(exc = e)
