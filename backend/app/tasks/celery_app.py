from celery import Celery
from celery.schedules import crontab
from app.config import settings

celery_app = Celery(
    "taskflow",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
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