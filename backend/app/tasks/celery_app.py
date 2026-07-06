from backend.app.tasks.celery_app import Celery
from app.config import settings
from celery.schedules import crontab

celery_app = Celery(
    "taskflow",
    broker=settings.REDIS_URL,     # Redis가 메시지 큐 역할
    backend=settings.REDIS_URL,    # 결과 저장소
)

celery_app.conf.update(
    task_serializer="json",        # 태스크 데이터를 JSON으로 직렬화
    accept_content=["json"],       # JSON만 받음
    timezone="Asia/Tokyo",         # 시간대 설정
)


celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    timezone="Asia/Tokyo",
    beat_schedule={
        "check-due-dates": {
            "task": "app.tasks.scheduled_tasks.check_due_dates",
            "schedule": crontab(hour=9, minute=0),
        },
    },
)