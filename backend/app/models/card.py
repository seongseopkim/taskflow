from app.database import Base
from sqlalchemy import Column, String, Integer, Boolean, DateTime, func, ForeignKey, Float, VARCHAR, Text


class Card(Base):
    __tablename__ = "cards"

    id = Column(Integer, primary_key=True)
    list_id = Column(Integer, ForeignKey("lists.id"))
    title = Column(String(200), nullable=False)
    description = Column(Text, nullable=True)
    position = Column(Float, nullable=False)
    assignee_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    due_date = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
