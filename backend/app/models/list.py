from app.database import Base
from sqlalchemy import Column, String, Integer, Boolean, DateTime, func, ForeignKey, Float, VARCHAR

class List(Base):
    __tablename__ = "lists"

    id = Column(Integer, primary_key=True)
    board_id = Column(Integer, ForeignKey("boards.id"))
    title = Column(String(255), nullable=False)
    position = Column(Float, nullable=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    