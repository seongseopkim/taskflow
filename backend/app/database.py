from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.config import settings
# db엔진을 만드는데 필요한 내용들을 작성함. 엔진은 create_async_engine을 사용해서 만든다.

#여기서 엔진을 만드는데, 필요한 파라미터는 DB의 URL, echo는 선택사항(개발시 sql로그 콘솔에 출력해준다. 좋겠죠 있으면)
engine = create_async_engine(settings.DATABASE_URL, echo=True)

# 세션메이커는 세션 공장( 작업 단위? 라고 생각해야 하나?)을 만든다. 어떤 엔진에서, 어떤 세션을 만들고, 커밋 후에도 객체 데이터 유지..?
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

# User, Board 같은 db 테이블 모델들이 이걸 상속받아서 만들어질거임
class Base(DeclarativeBase) :
    pass

async def get_db():
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise

