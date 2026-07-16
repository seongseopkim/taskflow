# 서버 성능 테스트를 위한 디버그 파일

from fastapi import APIRouter
from app.database import engine   # 경로는 네 구조에 맞게

router = APIRouter(prefix="/debug", tags=["debug"])

@router.get("/pool")
async def get_pool_status():
    pool = engine.sync_engine.pool
    return {
        "size": pool.size(),          # 풀 설정 크기
        "checked_out": pool.checkedout(),   # 지금 쓰이는 중
        "checked_in": pool.checkedin(),    # 지금 노는 중
    }