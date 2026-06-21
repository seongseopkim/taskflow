from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.user import User
from app.core.security import decode_token


oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


async def get_current_user(
    token: str = Depends(oauth2_scheme),   # 토큰 자동 추출
    db: AsyncSession = Depends(get_db),     # DB 세션
) -> User:
    payload = decode_token(token)
    if not payload or payload["type"] != "access":
        raise HTTPException(401, "정상적인 토큰이 아닙니다")
    user_id = payload["sub"]
    user = await db.get(User, user_id) 

    if not user or not user.is_active:
        raise HTTPException(401, "유저를 찾을 수 없습니다")
    
    return user
    

    # 1. decode_token으로 토큰 검증
    # 2. 실패하거나 type이 "access"가 아니면 401
    # 3. payload에서 user_id 꺼내서 DB 조회
    # 4. 유저 없거나 비활성이면 401
    # 5. 유저 반환