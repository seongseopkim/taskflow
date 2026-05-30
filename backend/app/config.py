from pydantic_settings import BaseSettings


# 데이터베이스 연결되는 url, algorithm?뭔지모름 알아봐야함. 
# 엑세스 토큰은 30초, 리프레시토큰은 7일에 만료.  -> 이거 괜찮은가? 그건모르겠음. 리프레시가 7일만이면 7일마다 재로그인인건가?
class Settings(BaseSettings) :
    DATABASE_URL : str = "mysql+aiomysql://root:password@localhost:3306/taskflow"
    SECRET_KEY : str = "secret_key"
    ALGORITHM : str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES : int = 30
    REFRESH_TOKEN_EXPIRE_DAYS : int = 7
    REDIS_URL : str = "redis://localhost:6379"
    class Config:
        env_file = ".env"

settings = Settings()

