"""###notifications
├── id            INTEGER, PK
├── user_id       INTEGER, FK → users.id
├── type          VARCHAR(50)
├── content       VARCHAR(500)
├── is_read       BOOLEAN, DEFAULT false
├── card_id       INTEGER, FK → cards.id, NULL 허용
└── created_at    DATETIME
###"""

from app.database import Base
from sqlalchemy import Column, String, Integer, Integer, Boolean, DateTime, func, ForeignKey, Index

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    type = Column(String(50), nullable=False)
    content = Column(String(500))
    is_read = Column(Boolean, default=False)
    card_id = Column(Integer, ForeignKey("cards.id"), nullable=True)
    created_at = Column(DateTime, default=func.now())

    __table_args__ = (
        Index("ix_notification_user_id_created_at", "user_id", "created_at"),
    )