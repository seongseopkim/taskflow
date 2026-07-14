from app.database import Base
from sqlalchemy import Column, String, Integer, Boolean, DateTime, func, ForeignKey, Float, VARCHAR, Index
from sqlalchemy.orm import relationship

class List(Base):
    __tablename__ = "lists"

    id = Column(Integer, primary_key=True)
    board_id = Column(Integer, ForeignKey("boards.id"))
    title = Column(String(255), nullable=False)
    position = Column(Float, nullable=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())
    
    cards = relationship("Card", back_populates = "list", order_by="Card.position")

    board = relationship("Board", back_populates = "lists")

    __table_args__ = (
        Index("ix_list_board_id_position", "board_id", "position"), 
    )