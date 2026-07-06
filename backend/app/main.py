from fastapi import FastAPI
import uvicorn
from fastapi.middleware.cors import CORSMiddleware
#CORS 미들웨어 -> 뭐 없으면 api호출 시 브라우저가 차단된다함.

### api 추가

# main.py에 추가
from app.api.v1.auth import router as auth_router
from app.api.v1.workspaces import router as workspace_router
from app.api.v1.boards import router as board_router
from app.api.v1.lists import router as list_router
from app.api.v1.cards import router as card_router
from app.api.v1.comments import router as comment_router
from app.api.v1.labels import router as label_router
from app.api.v1.websocket import router as ws_router

# fastapi 객체 만들기, 앱, 버전 설정 가능함.
app = FastAPI(title = "Trello", version = "0.1")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(auth_router, prefix="/api/v1")
app.include_router(workspace_router, prefix="/api/v1")
app.include_router(board_router, prefix="/api/v1")
app.include_router(list_router, prefix="/api/v1")
app.include_router(card_router, prefix="/api/v1")
app.include_router(comment_router, prefix="/api/v1")
app.include_router(label_router, prefix="/api/v1")
app.include_router(ws_router)  # prefix 없이! /ws/로 시작하니까



#여기선 서버를 키는 작업을 할거임. 근데 아래 if문은, 혹시 다른 파일에서 main.py를 import했을 때 자동으로 서버가 실행되면 안되기 때문에, main.py를 직접 실행시켯을 때에만
# 서버가 돌아라! 라는 의미로 저 if문을 삽입하고, 조건에 충족했을 때에만 서버 가동을 넣어둠.
if __name__ == "__main__" :
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)