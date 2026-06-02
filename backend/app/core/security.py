# JWT 생성/검증, 비밀번호 해싱

from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError
from passlib.context import CryptContext
from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"]) # --> passlib중에서, Crypt의 여러 방식 중 bcrypt라는 방식을 사용하겠다?

# 비밀번호 해싱
def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def create_access_token(user_id: int) -> str:

    expire_time = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    payload = {"sub": str(user_id), "exp": expire_time, "type": "access"}

    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

#Refresh Token 생성
def create_refresh_token(user_id: int) -> str:

    expire_time = datetime.now(timezone.utc) + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    
    payload = {"sub": str(user_id), "exp": expire_time, "type": "refresh"}

    return jwt.encode(payload, settings.SECRET_KEY, algorithm=settings.ALGORITHM)

#토큰 디코드?(왜 필요한지 모르겠엉)
def decode_token(token: str):

    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])

        return payload
    except JWTError:
        return None