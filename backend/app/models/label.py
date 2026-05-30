from app.database import Base
from sqlalchemy import Column, String, Integer, Boolean, DateTime, func, ForeignKey, Float, VARCHAR, Text, UniqueConstraint

class Label(Base):
    __tablename__ = "labels"

    id = Column(Integer, primary_key=True)
    board_id = Column(Integer, ForeignKey("boards.id"))
    name = Column(String(50), nullable=False)
    color = Column(String(7), nullable=False)

    __table_args__ = (
        UniqueConstraint(
        "board_id", "name"
    ),
)
    
class CardLabel(Base):
    __tablename__ = "card_labels"

    card_id = Column(Integer, ForeignKey("cards.id"), primary_key=True)
    label_id = Column(Integer, ForeignKey("labels.id"), primary_key=True)
