# 회원가입/로그인 할 때의 주고받는 데이터의 형태를 정의.
# 필요한 것들
# UserCreate : 회원가입 시 프론트에서 백으로 보내는 데이터 (이름, 이메일, 패스워드 등...)
#  UserLogin : 로그인 시 보내는 데이터 (이메일, 패스워드)
# TokenResponse : 로그인 성공 시 서버가 보내는 응답 (access_token, refresh_token)
# RefreshRequest : 토큰 재발급 시 보내는 데이터 (refresh_token)


from pydantic import BaseModel

class UserCreate(BaseModel):
    #회원가입에 필요한 필드들 (이름, 이메일, 패스워드)
    email : str
    password: str #password는 서버에서 해싱함. 그래서 보낼때는 password그대로 보냄...?
    name: str

class UserLogin(BaseModel):
    #로그인에 필요한 필드들
    email: str
    password: str

class TokenResponse(BaseModel):
    #서버에서 보내는 응답, 토큰들/토큰의 종류 표시
    access_token: str
    refresh_token: str
    token_type: str

class RefreshRequest(BaseModel):
    refresh_token: str

    