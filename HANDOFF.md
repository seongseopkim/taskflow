# TaskFlow 백엔드 → Flutter 프론트엔드 인수인계 문서

> 이 문서는 완성된 FastAPI 백엔드를 기반으로 Flutter 프론트엔드를 만들기 위한 명세서입니다.
> 초기 설계와 달라진 부분, 실제 구현 방식, 남은 제약사항을 전부 포함합니다.

---

## 0. 프로젝트 개요

**TaskFlow**는 Trello 스타일의 칸반 보드 협업 툴입니다.
계층 구조: `Workspace → Board → List → Card`

- **백엔드**: FastAPI + MySQL + Redis + Celery, Docker로 컨테이너화, AWS EC2에 배포됨
- **인증**: JWT (Access Token + Refresh Token, Refresh Token Rotation 적용)
- **API 문서**: 서버 실행 후 `/docs` 에서 Swagger UI로 전체 API 확인 가능 (가장 정확한 최신 스펙)
- **Base URL**: 로컬 개발 시 `http://localhost:8000/api/v1`, 배포 서버는 별도 안내

---

## 1. 디자인 & 요구사항 (중요)

### 1-1. UI/UX
- **Trello와 최대한 유사한 디자인**을 목표로 함 (칸반 보드, 드래그 앞 드롭, 카드형 UI)
- 컬럼(List)이 가로로 나열되고, 그 안에 카드가 세로로 쌓이는 전형적인 칸반 레이아웃
- 카드 드래그 시 리스트 간 이동 + 같은 리스트 내 순서 변경 모두 지원해야 함 (백엔드가 `position`으로 순서를 관리하므로, 프론트에서 드롭 위치에 맞는 `position` 값을 계산해서 API에 보내야 함 — 아래 6번 섹션 참고)

### 1-2. 다국어 지원 (i18n)
- **한국어 + 일본어 지원 필요** (사용자가 일본 거주, 한국어/일본어 병행 사용)
- Flutter의 `flutter_localizations` 또는 `easy_localization` 패키지 사용 권장
- UI 텍스트(버튼, 라벨, 안내 문구 등)는 다국어 키로 분리
- 서버에서 내려주는 데이터(카드 제목, 알림 메시지 등)는 사용자가 입력한 그대로이므로 번역 대상이 아님 (UI 자체의 정적 텍스트만 다국어 처리)

### 1-3. 플랫폼
- 웹을 메인으로, Flutter 특성상 모바일 대응도 자연스럽게 가능하면 좋음 (필수는 아님)

---

## 2. 인증 (Auth)

### 2-1. 플로우

```
POST /api/v1/auth/signup   { email, password, name } → TokenResponse
POST /api/v1/auth/login    { email, password }        → TokenResponse
POST /api/v1/auth/refresh  { refresh_token }           → TokenResponse
```

**TokenResponse:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer"
}
```

### 2-2. 토큰 사용법
- 이후 모든 API 요청에 헤더 추가: `Authorization: Bearer {access_token}`
- Access Token 수명: 30분
- Refresh Token 수명: 7일

### 2-3. ⚠️ Refresh Token Rotation (초기 설계와 달라진 중요한 부분)
- Refresh Token은 **1회용**입니다. `/auth/refresh`를 호출하면 새로운 `refresh_token`이 발급되고, 이전 토큰은 즉시 무효화됩니다.
- **프론트엔드는 refresh 응답을 받을 때마다 반드시 새 `refresh_token`으로 저장된 값을 덮어써야 합니다.** 예전 토큰을 계속 쓰면 다음 refresh 시도에서 401이 납니다.
- Access Token이 만료되어 401을 받으면 → 자동으로 `/auth/refresh` 호출 → 성공하면 새 토큰 쌍으로 갱신 후 원래 요청 재시도 → 실패하면 로그인 화면으로 이동

---

## 3. 공통 응답 규칙

### 3-1. 페이지네이션
목록을 반환하는 대부분의 API(보드, 리스트, 카드, 댓글, 라벨, 알림)는 아래 형식으로 응답합니다:

```json
{
  "items": [ ... ],
  "total": 45,
  "page": 1,
  "size": 20,
  "pages": 3
}
```

쿼리 파라미터: `?page=1&size=20` (기본값 page=1, size=20)

> ⚠️ 워크스페이스 목록 조회(`GET /workspaces/`)는 페이지네이션 적용 여부가 불확실하니 실제 Swagger 응답을 먼저 확인하고 개발하세요.

### 3-2. 에러 응답
- 커스텀 에러 포맷은 적용하지 않았고, **FastAPI 기본 형식**을 그대로 사용합니다:
```json
{ "detail": "에러 메시지" }
```
- 상태 코드: 401(인증 실패/만료), 403(권한 없음), 404(리소스 없음), 409(중복), 422(입력값 검증 실패)

---

## 4. API 엔드포인트 전체 목록

### Workspaces
| Method | URL | 설명 | 권한 |
|---|---|---|---|
| GET | `/workspaces/` | 내 워크스페이스 목록 | 로그인 필요 |
| POST | `/workspaces/` | 워크스페이스 생성 `{name}` | 로그인 필요 |
| DELETE | `/workspaces/{workspace_id}` | 워크스페이스 삭제 | owner |
| POST | `/workspaces/{workspace_id}/members` | 멤버 초대 `{email, role}` | owner |

### Boards
| Method | URL | 설명 | 권한 |
|---|---|---|---|
| GET | `/workspaces/{workspace_id}/boards/` | 보드 목록 (페이지네이션) | viewer 이상 |
| POST | `/workspaces/{workspace_id}/boards/` | 보드 생성 `{name}` | editor 이상 |
| GET | `/workspaces/{workspace_id}/boards/{board_id}` | **보드 상세** — 리스트+카드까지 중첩으로 한 번에 반환 (N+1 최적화됨) | viewer 이상 |
| DELETE | `/workspaces/{workspace_id}/boards/{board_id}` | 보드 삭제 | owner |

**보드 상세 응답 형태** (칸반 보드 화면을 만들 때 이 API 하나로 전부 그릴 수 있음):
```json
{
  "id": 1, "workspace_id": 1, "name": "홈택스 자동화", "created_at": "...",
  "lists": [
    {
      "id": 1, "board_id": 1, "title": "할 일", "position": 65536.0,
      "cards": [ { "id": 1, "title": "...", "position": 65536.0, ... } ]
    }
  ]
}
```

### Lists
| Method | URL | 설명 | 권한 |
|---|---|---|---|
| GET | `/boards/{board_id}/lists` | 리스트 목록 (페이지네이션, position 순 정렬) | viewer 이상 |
| POST | `/boards/{board_id}/lists` | 리스트 생성 `{title}` | editor 이상 |
| DELETE | `/lists/{list_id}` | 리스트 삭제 | editor 이상 |

### Cards
| Method | URL | 설명 | 권한 |
|---|---|---|---|
| GET | `/lists/{list_id}/cards` | 카드 목록 (페이지네이션, position 순 정렬) | viewer 이상 |
| POST | `/lists/{list_id}/cards` | 카드 생성 `{title, description?, assignee_id?, due_date?}` | editor 이상 |
| PATCH | `/cards/{card_id}` | 카드 부분 수정 (title/description/assignee_id/due_date 중 보낸 필드만) | editor 이상 |
| PATCH | `/cards/{card_id}/move` | 카드 이동 `{target_list_id, position}` | editor 이상 |
| DELETE | `/cards/{card_id}` | 카드 삭제 | editor 이상 |

- 카드 담당자(assignee_id)가 변경되면 자동으로 알림이 생성됩니다 (본인에게 배정 시 제외).

### Comments
| Method | URL | 설명 | 권한 |
|---|---|---|---|
| GET | `/cards/{card_id}/comments` | 댓글 목록 (페이지네이션) | viewer 이상 |
| POST | `/cards/{card_id}/comments` | 댓글 작성 `{content}` | viewer 이상 (댓글은 뷰어도 가능) |
| DELETE | `/comments/{comment_id}` | 댓글 삭제 | 본인 댓글만 |

- 댓글이 달리면 카드 담당자에게 자동 알림 (본인이 자기 카드에 단 경우 제외).
- ✅ 권한 체크 방식이 `check_card_permission`으로 교체되어 정상 동작 확인됨 (2026-07-11, Swagger/curl로 검증 완료).

### Labels
| Method | URL | 설명 | 권한 |
|---|---|---|---|
| GET | `/boards/{board_id}/labels` | 라벨 목록 (페이지네이션) | viewer 이상 |
| POST | `/boards/{board_id}/labels` | 라벨 생성 `{name, color}` (color는 `#FF5733` 형식) | editor 이상 |
| POST | `/cards/{card_id}/labels/{label_id}` | 카드에 라벨 부착 | editor 이상 |
| DELETE | `/cards/{card_id}/labels/{label_id}` | 카드에서 라벨 제거 | editor 이상 |

- ✅ 권한 체크 방식이 `check_board_permission`/`check_card_permission`으로 교체되어 정상 동작 확인됨. `LabelResponse` 스키마에 `from_attributes = True`가 누락되어 라벨 생성 시 500 에러가 나던 버그도 함께 수정됨 (2026-07-11).

### Notifications
| Method | URL | 설명 |
|---|---|---|
| GET | `/notifications/` | 내 알림 목록 (페이지네이션, 최신순) |
| PATCH | `/notifications/{notification_id}/read` | 알림 하나 읽음 처리 |
| PATCH | `/notifications/read-all` | 전체 읽음 처리 |

**주의**: 알림은 카드 배정/댓글 작성 시 **비동기(Celery)로 DB에 저장**됩니다. 실시간으로 즉시 오는 게 아니라 약간의 지연(보통 1초 이내)이 있을 수 있고, 화면에 반영하려면 폴링하거나 아래 WebSocket 알림 채널을 연결해야 합니다.

> ⚠️ **알려진 미완성 부분**: 알림을 DB에 저장하는 Celery 태스크는 완성됐지만, 저장 후 WebSocket으로 실시간 push하는 연결은 아직 구현되지 않았습니다. 지금은 알림이 DB에는 쌓이지만, 실시간으로 화면에 뜨려면 프론트에서 주기적으로 `GET /notifications/`를 폴링하거나, 백엔드에 WebSocket push 로직을 추가로 구현해야 합니다.

---

## 5. WebSocket (실시간 기능)

두 개의 채널이 있습니다:

### 5-1. 보드 실시간 동기화
```
ws://{host}/ws/boards/{board_id}
```
- 보드 화면에 들어갈 때 연결, 나갈 때 연결 해제
- 같은 보드를 보고 있는 다른 사용자가 카드를 옮기면 브로드캐스트로 메시지 전달받음
- 메시지 형식은 자유 텍스트(JSON)를 그대로 relay하는 구조이므로, 프론트에서 카드 이동 시 `{"type": "card_moved", "card_id": ..., ...}` 같은 형태로 보내고 받는 쪽에서 파싱해서 화면 갱신하는 방식으로 설계하면 됨
- **현재는 REST API로 카드를 이동시켜도 WebSocket 브로드캐스트가 자동으로 연동되어 있지 않습니다.** 프론트에서 카드 이동 API 호출 성공 후, 직접 WebSocket으로 메시지를 보내 다른 사용자에게 알리는 방식으로 구현하거나, 백엔드에 자동 연동을 추가해야 합니다.

### 5-2. 개인 알림 채널
```
ws://{host}/ws/notifications/{user_id}
```
- 로그인 시 연결, 로그아웃/앱 종료 시 해제
- 위에서 언급했듯 현재 서버에서 이 채널로 실제 알림을 push하는 로직은 미구현 상태 — 연결만 유지되고 데이터는 안 옴 (추후 구현 필요)

---

## 6. 카드/리스트 순서(Position) 계산 방식 — 중요

드래그 앤 드롭 구현 시 반드시 이해해야 하는 부분입니다.

- `position`은 float 값이고, 정렬 기준입니다.
- 새 카드/리스트를 만들면 서버가 자동으로 `기존 최댓값 + 65536.0`을 부여합니다 (맨 뒤에 추가됨).
- **카드를 드래그해서 두 카드 사이로 옮길 때는 프론트에서 목표 position 값을 직접 계산해서 API에 보내야 합니다.**

```
예: A(position=65536.0), B(position=131072.0) 사이로 C를 옮기고 싶다면
새 position = (65536.0 + 131072.0) / 2 = 98304.0

맨 앞으로 옮기고 싶다면: 맨 앞 카드 position / 2
맨 뒤로 옮기고 싶다면: 맨 뒤 카드 position + 65536.0
```

`PATCH /cards/{card_id}/move` 호출 시 `{target_list_id, position}`을 이 방식으로 계산해서 보내야 합니다.

---

## 7. 데이터 모델 요약 (프론트 상태 관리 설계용)

```
User: id, email, name, is_active, created_at
  (hashed_password, refresh_token은 API 응답에 노출되지 않음)

Workspace: id, name, owner_id, created_at
WorkspaceMember: user_id, workspace_id, role(owner/editor/viewer)

Board: id, workspace_id, name, created_at

List: id, board_id, title, position(float), created_at

Card: id, list_id, title, description, position(float),
      assignee_id(nullable), created_by, due_date(nullable), created_at

Comment: id, card_id, user_id, content, created_at

Label: id, board_id, name, color(#hex)
CardLabel: card_id + label_id (다대다 연결)

Notification: id, user_id, type, content, is_read, card_id(nullable), created_at
  type 값: "card_assigned", "comment"
```

### 권한(Role) 체계
```
owner(3) > editor(2) > viewer(1)
```
- owner: 워크스페이스 삭제, 멤버 관리, 모든 작업 가능
- editor: 보드/리스트/카드 생성·수정·삭제 가능
- viewer: 조회 + 댓글 작성만 가능

프론트에서 로그인한 유저의 role에 따라 UI 요소(수정/삭제 버튼 등)를 조건부로 숨기거나 비활성화하는 처리가 필요합니다. role 정보는 워크스페이스 멤버 목록 조회 시 확인 가능합니다 (또는 백엔드에 "내 role 조회" API가 없다면 추가 요청 필요할 수 있음 — 현재 없음, 필요시 백엔드 보강 필요).

---

## 8. 초기 설계 대비 변경/추가된 사항 정리

| 항목 | 초기 설계 | 실제 구현 |
|---|---|---|
| 목록 API 응답 | 배열 그대로 반환 | `{items, total, page, size, pages}` 페이지네이션 포맷 |
| 보드 상세 조회 | 없었음 | 리스트+카드까지 중첩 반환하는 전용 API 신설 (`GET /boards/{id}`) |
| Refresh Token | 만료 전까지 계속 재사용 가능 | 1회용, 재발급마다 교체(Rotation), DB에서 유효성 대조 |
| 알림 시스템 | 설계만 있고 미구현 | DB 저장까지는 구현됨. WebSocket 실시간 push는 미구현 |
| 활동 로그(Activity) | 설계만 있고 미구현 | 카드 생성/이동 2가지 액션만 기록됨 (수정/삭제는 미기록) |
| 인덱스 | 미설계 | cards, lists, comments, notifications에 복합 인덱스 적용 |
| 에러 응답 형식 | 통일된 커스텀 포맷 계획 | FastAPI 기본 `{"detail": "..."}` 형식 그대로 사용 |
| 이미지 업로드 | 계획에 있었음 | **미구현** (카드에 이미지 첨부 불가) |
| 워크스페이스 삭제 | - | 자식 데이터(workspace_members) 함께 삭제하도록 FK 이슈 수정됨 |

---

## 9. Flutter 개발 시 참고할 것

1. **Swagger UI(`/docs`)를 항상 최종 진실 소스로 삼으세요.** 이 문서와 실제 동작이 다르면 Swagger가 맞습니다.
2. comments, labels API는 권한 체크 관련 버그를 2026-07-11에 수정 완료 (위 4번 섹션 참고).
3. 알림/WebSocket 실시간 기능은 미완성 부분이 있으므로, 필수 기능이 아니라면 후순위로 두고 먼저 REST API 기반 화면(로그인, 보드 목록, 칸반 보드, 카드 상세)부터 완성하는 걸 권장합니다.
4. 다국어 처리와 Trello 스타일 UI를 최우선 요구사항으로 고려해주세요.
