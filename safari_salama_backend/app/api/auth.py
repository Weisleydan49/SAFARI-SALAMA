from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
from app.schemas.user import UserRegister, UserLogin, Token, UserResponse
from app.core.security import get_password_hash, verify_password, create_access_token

router = APIRouter(prefix= "/api/auth", tags = ["Authentication"])

@router.post("/register", response_model = UserResponse, status_code = status.HTTP_201_CREATED)
def register(user_data: UserRegister, db: Session = Depends(get_db)):
    #Check if phone exists already
    existing_user = db.query(User).filter(User.phone == user_data.phone).first()
    if existing_user:
        raise HTTPException(
            status_code = status.HTTP_400_BAD_REQUEST,
            detail = "Phone number already registered."
            )
    
    #Check if email exists already
    existing_user = db.query(User).filter(User.email == user_data.email).first()
    if existing_user:
        raise HTTPException(
            status_code = status.HTTP_400_BAD_REQUEST,
            detail= "Email already registered."
        )
    
    #Create new user
    new_user = User(
        phone= user_data.phone,
        name= user_data.name,
        email = user_data.email,
        password_hash = get_password_hash(user_data.password),
        user_type = user_data.user_type
    )

    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return new_user

@router.post("/login", response_model = Token)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    #Find user by phone
    user = db.query(User).filter(User.phone == credentials.phone).first()

    if not user or not verify_password(credentials.password, user.password_hash):
        raise HTTPException(
            status_code = status.HTTP_401_UNAUTHORIZED,
            detail = "Invalid phone or password!"
        )
    
    if not user.is_active:
        raise HTTPException(
            status_code = status.HTTP_403_FORBIDDEN,
            detail = "User account is inactive."
        )
    
    #Create access token
    access_token = create_access_token(data = {"sub": str(user.id), "type": user.user_type.value})


    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": user
    }