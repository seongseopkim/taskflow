from fastapi import FastAPI
import uvicorn
from fastapi.middleware.cors import CORSMiddleware
#CORS 미들웨어 -> 뭐 없으면 api호출 시 브라우저가 차단된다함.



# fastapi 객체 만들기, 앱, 버전 설정 가능함.
app = FastAPI(title = "Trello", version = "0.1")

#여기선 서버를 키는 작업을 할거임. 근데 아래 if문은, 혹시 다른 파일에서 main.py를 import했을 때 자동으로 서버가 실행되면 안되기 때문에, main.py를 직접 실행시켯을 때에만
# 서버가 돌아라! 라는 의미로 저 if문을 삽입하고, 조건에 충족했을 때에만 서버 가동을 넣어둠.
if __name__ == "__main__" :
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credencials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#app.include_router(api_router, prefix="/api/v1")
