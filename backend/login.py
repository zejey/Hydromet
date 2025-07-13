From fastapi import FastAPI, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from datetime import datetime, timedelta
from typing import Optional
import firebase_admin
from firebase_admin import credentials, firestorem, auth
import os
from dotenv import load_dotenv
import secrets
import string
from twilio.rest import Client
import jwt
import json

# Load environment variables
load_dotenv()

app = FastAPI(title="HydroMet API", version="1.0.0")

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Firebase initialization
firebase_cred = credentials.Certificate({
    "type": "service_account",
    "project_id": os.getenv("FIREBASE_PROJECT_ID"),
    "private_key_id": os.getenv("FIREBASE_PRIVATE_KEY_ID"),
    "private_key": os.getenv("FIREBASE_PRIVATE_KEY").replace('\\n', '\n'),
    "client_email": os.getenv("FIREBASE_CLIENT_EMAIL"),
    "client_id": os.getenv("FIREBASE_CLIENT_ID"),
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
})

firebase_admin.initialize_app(firebase_cred)
db = firestore.client()

# Twilio client
twilio_client = Client(os.getenv("TWILIO_ACCOUNT_SID"), os.getenv("TWILIO_AUTH_TOKEN"))

# JWT settings
SECRET_KEY = os.getenv("JWT_SECRET", "your-secret-key-here")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7  # 7 days

# Security
security = HTTPBearer()

# Pydantic models
class SendSMSRequest(BaseModel):
    phone_number: str = Field(..., min_length=11, max_length=11)

class VerifySMSRequest(BaseModel):
    phone_number: str = Field(..., min_length=11, max_length=11)
    code: str = Field(..., min_length=6, max_length=6)

class UserProfile(BaseModel):
    first_name: Optional[str] = None
    middle_name: Optional[str] = None
    last_name: Optional[str] = None
    address: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    phone_number: str
    first_name: Optional[str] = None
    middle_name: Optional[str] = None
    last_name: Optional[str] = None
    address: Optional[str] = None
    is_verified: bool
    created_at: datetime
    updated_at: datetime

class AuthResponse(BaseModel):
    success: bool
    token: str
    user: UserResponse

# Utility functions
def generate_sms_code() -> str:
    """Generate a 6-digit SMS verification code"""
    return ''.join(secrets.choice(string.digits) for _ in range(6))

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def validate_phone_number(phone_number: str) -> bool:
    """Validate Philippine phone number format"""
    return phone_number.isdigit() and len(phone_number) == 11 and phone_number.startswith('09')

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current user from JWT token"""
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        user_id: str = payload.get("user_id")
        if user_id is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Could not validate credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        # Get user from Firebase
        user_doc = db.collection('users').document(user_id).get()
        if not user_doc.exists:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found",
                headers={"WWW-Authenticate": "Bearer"},
            )
        
        user_data = user_doc.to_dict()
        user_data['id'] = user_doc.id
        return user_data
    except jwt.PyJWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


# API Routes
@app.get("/")
async def root():
    return {"message": "HydroMet API is running"}

@app.post("/api/auth/send-sms")
async def send_sms_code(request: SendSMSRequest):
    """Send SMS verification code"""
    try:
        # Validate phone number
        if not validate_phone_number(request.phone_number):
            raise HTTPException(
                status_code=400,
                detail="Invalid phone number format. Must be 11 digits starting with 09"
            )
        
        # Generate verification code
        code = generate_sms_code()
        expires_at = datetime.utcnow() + timedelta(minutes=10)  # 10 minutes expiry
        
        # Save to Firebase
        verification_data = {
            "phone_number": request.phone_number,
            "code": code,
            "expires_at": expires_at,
            "is_used": False,
            "created_at": datetime.utcnow()
        }
        
        db.collection('sms_verifications').add(verification_data)
        
        # Send SMS using Twilio
        try:
            message = twilio_client.messages.create(
                body=f"Your HydroMet verification code is: {code}",
                from_=os.getenv("TWILIO_PHONE_NUMBER"),
                to=f"+63{request.phone_number[1:]}"  # Convert to international format
            )
            
            return {
                "success": True,
                "message": "SMS code sent successfully",
                "message_sid": message.sid
            }
        except Exception as e:
            # For development, you might want to return the code
            # Remove this in production!
            if os.getenv("ENVIRONMENT") == "development":
                return {
                    "success": True,
                    "message": "SMS code sent successfully",
                    "dev_code": code  # Only for development
                }
            else:
                raise HTTPException(status_code=500, detail="Failed to send SMS")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/auth/verify-sms", response_model=AuthResponse)
async def verify_sms_code(request: VerifySMSRequest):
    """Verify SMS code and authenticate user"""
    try:
        # Validate phone number
        if not validate_phone_number(request.phone_number):
            raise HTTPException(
                status_code=400,
                detail="Invalid phone number format"
            )
        
        # Find valid verification code
        verifications = db.collection('sms_verifications')\
            .where('phone_number', '==', request.phone_number)\
            .where('code', '==', request.code)\
            .where('is_used', '==', False)\
            .order_by('created_at', direction=firestore.Query.DESCENDING)\
            .limit(1)\
            .get()
        
        if not verifications:
            raise HTTPException(
                status_code=400,
                detail="Invalid or expired verification code"
            )
        
        verification = verifications[0]
        verification_data = verification.to_dict()
        
        # Check if code is expired
        if datetime.utcnow() > verification_data['expires_at']:
            raise HTTPException(
                status_code=400,
                detail="Verification code has expired"
            )
        
        # Mark verification as used
        verification.reference.update({"is_used": True})
        
        # Find or create user
        users = db.collection('users')\
            .where('phone_number', '==', request.phone_number)\
            .limit(1)\
            .get()
        
        if users:
            # Update existing user
            user_doc = users[0]
            user_doc.reference.update({
                "is_verified": True,
                "updated_at": datetime.utcnow()
            })
            user_data = user_doc.to_dict()
            user_data['id'] = user_doc.id
        else:
            # Create new user
            user_data = {
                "phone_number": request.phone_number,
                "first_name": None,
                "middle_name": None,
                "last_name": None,
                "address": None,
                "is_verified": True,
                "created_at": datetime.utcnow(),
                "updated_at": datetime.utcnow()
            }
            user_ref = db.collection('users').add(user_data)
            user_data['id'] = user_ref[1].id
        
        # Create access token
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            data={"user_id": user_data['id'], "phone_number": request.phone_number},
            expires_delta=access_token_expires
        )
        
        return AuthResponse(
            success=True,
            token=access_token,
            user=UserResponse(**user_data)
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/user/profile", response_model=UserResponse)
async def get_user_profile(current_user: dict = Depends(get_current_user)):
    """Get user profile"""
    return UserResponse(**current_user)

@app.put("/api/user/profile", response_model=UserResponse)
async def update_user_profile(
    profile: UserProfile,
    current_user: dict = Depends(get_current_user)
):
    """Update user profile"""
    try:
        # Prepare update data
        update_data = {
            "updated_at": datetime.utcnow()
        }
        
        # Only update fields that are provided
        if profile.first_name is not None:
            update_data["first_name"] = profile.first_name
        if profile.middle_name is not None:
            update_data["middle_name"] = profile.middle_name
        if profile.last_name is not None:
            update_data["last_name"] = profile.last_name
        if profile.address is not None:
            update_data["address"] = profile.address
        
        # Update user in Firebase
        user_ref = db.collection('users').document(current_user['id'])
        user_ref.update(update_data)
        
        # Get updated user data
        updated_user = user_ref.get().to_dict()
        updated_user['id'] = current_user['id']
        
        return UserResponse(**updated_user)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/user/profile")
async def delete_user_account(current_user: dict = Depends(get_current_user)):
    """Delete user account"""
    try:
        # Delete user from Firebase
        db.collection('users').document(current_user['id']).delete()
        
        # Also delete any related SMS verifications
        verifications = db.collection('sms_verifications')\
            .where('phone_number', '==', current_user['phone_number'])\
            .get()
        
        for verification in verifications:
            verification.reference.delete()
        
        return {"success": True, "message": "Account deleted successfully"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Health check endpoint
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow(),
        "version": "1.0.0"
    }

# Error handlers
@app.exception_handler(404)
async def not_found_handler(request, exc):
    return {"error": "Not found", "status_code": 404}

@app.exception_handler(500)
async def internal_error_handler(request, exc):
    return {"error": "Internal server error", "status_code": 500}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
