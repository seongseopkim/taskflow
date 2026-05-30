from app.database import Base
from sqlalchemy import Column, String, Integer, Boolean, DateTime, func, ForeignKey, Float, VARCHAR, Text, UniqueConstraint, JSON

class Activity(Base):
    __tablename__ = "activities"

    id = Column(Integer, primary_key=True)
    board_id = Column(Integer, ForeignKey("boards.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    action = Column(String(50))
    detail = Column(JSON)
    created_at = Column(DateTime, default=func.now())

    