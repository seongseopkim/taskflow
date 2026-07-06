from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from typing import Dict, Set
import json

router = APIRouter()

# 보드별 연결 관리
board_connections: Dict[int, Set[WebSocket]] = {}

# 개인 알림 채널
user_connections: Dict[int, WebSocket] = {}

@router.websocket("/ws/boards/{board_id}")
async def board_websocket(websocket: WebSocket, board_id: int):
    # 1. 연결 수락
    await websocket.accept()
    # 2. board_connections[board_id]에 추가
    if board_id not in board_connections:
        board_connections[board_id] = set()
    board_connections[board_id].add(websocket)
    # 3. 메시지 수신 대기 (while True)
    try:    
        while True:
            data = await websocket.receive_text()# 메세지 수신하기
            data = json.loads(data)#수신한 메세지 json변환
            if data: #메세지 존재 시 전파
                
                #전파하는 부분. 자신 = websocket / 타인 = conn 
                # 이렇게 생각해도 좋음. 지금은 나 말고 다른 이들에게 전파.
                for conn in board_connections[board_id]:
                    if conn != websocket:
                        await conn.send_text(json.dumps(data))
    except WebSocketDisconnect:
        # 연결이 끊긴 경우 제외하기. discard를 사용함. set에서 사용하는거
        board_connections[board_id].discard(websocket)
        if not board_connections[board_id]: # 방이 비어있으면 방도 삭제
            del board_connections[board_id]
        print("웹소켓 연결이 끊겼습니다. - websocket.py:38")
    # 4. 받은 메시지를 같은 보드의 다른 사람에게 브로드캐스트
    # 5. 연결 해제 시 board_connections에서 제거
    

@router.websocket("/ws/notifications/{user_id}")
async def notification_websocket(websocket: WebSocket, user_id: int):
    # 1. 연결 수락
    await websocket.accept()

    # 2. user_connections[user_id]에 추가
    user_connections[user_id] = (websocket)
    # 3. 메시지 수신 대기
    try:
        while True:
            data = await websocket.receive_text()
            data = json.loads(data)
    except WebSocketDisconnect:
        del user_connections[user_id]

    # 4. 연결 해제 시 제거
    pass