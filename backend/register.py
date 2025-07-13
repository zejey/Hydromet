from flask import Flask, request, jsonify
from flask_cors import CORS
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

# Initialize Firebase Admin SDK
try:
    # Get the current directory where register.py is located
    current_dir = os.path.dirname(os.path.abspath(__file__))
    service_account_path = os.path.join(current_dir, "json", "weather-app-e40b4-firebase-adminsdk-fbsvc-324f46bbf7.json")
    
    # Check if file exists
    if not os.path.exists(service_account_path):
        raise FileNotFoundError(f"Service account key not found at: {service_account_path}")
    
    cred = credentials.Certificate(service_account_path)
    firebase_admin.initialize_app(cred)
    db = firestore.client()
    print("Firebase initialized successfully")
except Exception as e:
    print(f"Firebase initialization error: {e}")
    db = None

@app.route('/register', methods=['POST'])
def register():
    try:
        # Check if Firebase is initialized
        if db is None:
            return jsonify({"error": "Database connection failed"}), 500
        
        # Get JSON data from the request
        data = request.get_json()
        
        # Check if data is received
        if not data:
            return jsonify({"error": "No data received"}), 400
        
        # Extract fields from the Flutter app
        first_name = data.get('first_name', '').strip()
        last_name = data.get('last_name', '').strip()
        address = data.get('address', '').strip()
        barangay = data.get('barangay', '').strip()
        phone = data.get('phone', '').strip()
        
        # Validate required fields
        if not all([first_name, last_name, address, barangay, phone]):
            return jsonify({"error": "Missing required fields"}), 400
        
        # Validate phone number format (basic validation)
        if not phone.startswith('09') or len(phone) != 11:
            return jsonify({"error": "Invalid phone number format"}), 400
        
        # Check if user already exists (by phone number)
        users_ref = db.collection('users')
        existing_user = users_ref.where('phone', '==', phone).limit(1).get()
        
        if existing_user:
            return jsonify({"error": "User with this phone number already exists"}), 409
        
        # Create user document
        user_data = {
            'first_name': first_name,
            'last_name': last_name,
            'full_name': f"{first_name} {last_name}",
            'address': address,
            'barangay': barangay,
            'phone': phone,
            'created_at': datetime.utcnow(),
            'updated_at': datetime.utcnow(),
            'is_active': True
        }
        
        # Add user to Firestore
        doc_ref = users_ref.add(user_data)
        user_id = doc_ref[1].id
        
        print(f"User registered with ID: {user_id}")
        
        # Return success response
        return jsonify({
            "message": "User registered successfully",
            "user_id": user_id
        }), 200
        
    except Exception as e:
        print(f"Error during registration: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/users', methods=['GET'])
def get_users():
    """Get all registered users (for testing purposes)"""
    try:
        if db is None:
            return jsonify({"error": "Database connection failed"}), 500
        
        users_ref = db.collection('users')
        users = []
        
        # Get all users
        docs = users_ref.stream()
        
        for doc in docs:
            user_data = doc.to_dict()
            user_data['id'] = doc.id
            # Convert datetime to string for JSON serialization
            if 'created_at' in user_data:
                user_data['created_at'] = user_data['created_at'].isoformat()
            if 'updated_at' in user_data:
                user_data['updated_at'] = user_data['updated_at'].isoformat()
            users.append(user_data)
        
        return jsonify({"users": users, "count": len(users)}), 200
        
    except Exception as e:
        print(f"Error fetching users: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500
    
@app.route('/users/<user_id>', methods=['PUT'])
def update_user(user_id):
    """Update a specific user"""
    try:
        if db is None:
            return jsonify({"error": "Database connection failed"}), 500
        
        data = request.get_json()
        if not data:
            return jsonify({"error": "No data received"}), 400
        
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            return jsonify({"error": "User not found"}), 404
        
        # Update allowed fields
        update_data = {}
        allowed_fields = ['first_name', 'last_name', 'address', 'barangay', 'phone']
        
        for field in allowed_fields:
            if field in data:
                update_data[field] = data[field].strip()
        
        if update_data:
            update_data['updated_at'] = datetime.utcnow()
            
            if 'first_name' in update_data or 'last_name' in update_data:
                current_data = user_doc.to_dict()
                
                # Check if current_data is None (safety check)
                if current_data is None:
                    return jsonify({"error": "User data is corrupted"}), 500
                
                first_name = update_data.get('first_name', current_data.get('first_name', ''))
                last_name = update_data.get('last_name', current_data.get('last_name', ''))
                update_data['full_name'] = f"{first_name} {last_name}"
            
            user_ref.update(update_data)
            
            return jsonify({"message": "User updated successfully"}), 200
        else:
            return jsonify({"error": "No valid fields to update"}), 400
        
    except Exception as e:
        print(f"Error updating user: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/users/<user_id>', methods=['DELETE'])
def delete_user(user_id):
    """Delete a specific user (soft delete)"""
    try:
        if db is None:
            return jsonify({"error": "Database connection failed"}), 500
        
        user_ref = db.collection('users').document(user_id)
        user_doc = user_ref.get()
        
        if not user_doc.exists:
            return jsonify({"error": "User not found"}), 404
        
        # Soft delete - mark as inactive
        user_ref.update({
            'is_active': False,
            'updated_at': datetime.utcnow()
        })
        
        return jsonify({"message": "User deleted successfully"}), 200
        
    except Exception as e:
        print(f"Error deleting user: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    firebase_status = "connected" if db is not None else "disconnected"
    return jsonify({
        "status": "OK",
        "firebase": firebase_status,
        "timestamp": datetime.utcnow().isoformat()
    }), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)