# SafariSalama - Quick Reference Guide

**Generated:** December 23, 2025  
**Version:** 1.0

---

## ✅ ALL CRITICAL ERRORS FIXED

### Summary
- **Flutter Errors:** 5/5 Fixed ✅
- **Route Model:** Now includes stops field ✅
- **Unused Code:** Cleaned up ✅
- **Tests:** Updated to match app ✅
- **Backend:** Needs Python dependencies (not code errors) ⚠️

---

## 📂 Project Structure

```
SafariSalama/
├── safari_salama/                 # Flutter Frontend
│   ├── lib/
│   │   ├── main.dart             # App entry point
│   │   ├── config/               # Configuration
│   │   │   └── api_config.dart   # API base URL
│   │   ├── screens/              # UI Screens (8 screens)
│   │   ├── models/               # Data models (4 models)
│   │   ├── services/             # API & Auth services
│   │   └── widgets/              # Shared widgets (empty)
│   ├── pubspec.yaml              # Dependencies
│   └── test/
│       └── widget_test.dart      # Tests
│
├── safari_salama_backend/         # FastAPI Backend
│   ├── app/
│   │   ├── main.py               # FastAPI app
│   │   ├── core/
│   │   │   └── config.py         # Settings & DB URL
│   │   ├── db/
│   │   │   └── database.py       # SQLAlchemy setup
│   │   ├── models/               # SQLAlchemy ORM models
│   │   ├── schemas/              # Pydantic schemas
│   │   └── api/                  # API endpoints (5 routers)
│   ├── create_tables.py          # Database initialization
│   └── requirements.txt          # Python dependencies
│
├── matatu_database_schema.sql    # Full DB schema
└── Documentation/
    ├── ERROR_AND_INCOMPLETENESS_SUMMARY.md
    └── WORK_IN_PROGRESS.md
```

---

## 🔑 Key Files Modified Today

| File | Change | Status |
|------|--------|--------|
| `lib/models/route_model.dart` | Added RouteStop class & stops field | ✅ Complete |
| `lib/screens/route_detail_screen.dart` | Fixed waypoints → stops | ✅ Complete |
| `lib/screens/home_screen.dart` | Removed unused fields | ✅ Complete |
| `lib/screens/register_screen.dart` | Removed unused import | ✅ Complete |
| `test/widget_test.dart` | Updated to match app structure | ✅ Complete |

---

## 🚀 Running the Project

### Frontend
```bash
cd safari_salama

# Install dependencies
flutter pub get

# Run app
flutter run

# Run tests
flutter test
```

### Backend
```bash
cd safari_salama_backend

# Create virtual environment
python -m venv venv
source venv/Scripts/activate  # Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
# OR manually:
pip install fastapi uvicorn sqlalchemy psycopg2-binary pydantic python-multipart python-dotenv

# Run server
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Create tables (first time only)
python create_tables.py
```

### Database
```bash
# Create database
createdb safari_salama

# Run schema
psql -U postgres -d safari_salama -f matatu_database_schema.sql

# Or use Python
python create_tables.py
```

---

## 🛠️ Common Tasks

### Add New Screen
1. Create `lib/screens/my_screen.dart`
2. Import in parent screen
3. Navigate: `Navigator.push(MaterialPageRoute(builder: (_) => MyScreen()))`
4. Add route to home if needed

### Add New API Endpoint
1. Create method in `app/api/my_endpoint.py`
2. Create schema in `app/schemas/my_schema.py`
3. Create model in `app/models/my_model.py` (if new table)
4. Include router in `app/main.py`
5. Call from Flutter: `ApiService.callEndpoint()`

### Update Database Schema
1. Modify `app/models/*.py`
2. Modify table in `matatu_database_schema.sql`
3. Run: `python create_tables.py` OR manually recreate table
4. Test API endpoints return correct data

### Fix API Connection Issues
1. Check backend is running: `http://localhost:8000/` should return status
2. Check API_BASE_URL in `lib/config/api_config.dart`
3. If using local network: `http://192.168.X.X:8000` (get IP with `ipconfig`)
4. Check firewall allows port 8000
5. Check CORS settings in backend if cross-origin issue

---

## 📊 API Routes Overview

### Authentication (`/api/auth`)
```
POST   /register  - Create new account
POST   /login     - Login & get JWT token
```

### Routes (`/api/routes`)
```
GET    /          - List all routes with stops
GET    /{id}      - Get route details with stops
```

### Vehicles (`/api/vehicles`)
```
GET    /location  - Get all vehicle GPS locations
GET    /{id}      - Get vehicle details
PATCH  /{id}/location - Update vehicle GPS
```

### Trips (`/api/trips`)
```
POST   /start     - Start new trip
PATCH  /{id}/end  - End trip
```

### Emergency (`/api/emergency`)
```
POST   /          - Create emergency alert
GET    /          - List all alerts
GET    /{id}      - Get alert details
PATCH  /{id}      - Update alert status
```

---

## 🔐 Authentication Flow

1. **Register:** POST `/api/auth/register` → Returns User + Token
2. **Login:** POST `/api/auth/login` → Returns User + Token
3. **Save:** Token saved to SharedPreferences
4. **Use:** Add `Authorization: Bearer <token>` header to requests
5. **Check:** `AuthService.isLoggedIn()` returns boolean
6. **Logout:** Clear SharedPreferences

---

## 💾 Data Models

### User
- id, phone, name, email, userType
- isVerified, isActive
- createdAt, lastLogin

### Route
- id, name, routeNumber
- origin, destination
- distance, duration, fare
- **stops** (List of RouteStop)

### RouteStop (NEW)
- sequence (order number)
- stopName (stop location)

### Vehicle
- id, registrationNumber
- currentLatitude, currentLongitude
- isOnline, vehicleType, capacity
- route assignment

### Trip
- id, userId, vehicleId
- startLocation, endLocation
- startTime, endTime
- distance, duration, fare
- status (ongoing/completed)

### EmergencyAlert
- id, userId, vehicleId
- alertType, location
- description, status
- createdAt

---

## ⚠️ Known Issues & Workarounds

| Issue | Impact | Workaround |
|-------|--------|-----------|
| API base URL hardcoded | Can't easily switch servers | Edit `api_config.dart` or use .env |
| No offline mode | App won't work without internet | Consider adding local caching |
| No retry logic | Failed requests just fail | Add retry with exponential backoff |
| SharedPreferences for tokens | Not secure for production | Use flutter_secure_storage |
| CORS allows all origins | Security risk | Lock down to specific domains |
| No input validation frontend | Could send bad data | Add validation before API calls |

---

## 🧪 Testing Checklist

### Smoke Test (5 minutes)
```
1. flutter run
2. See splash screen
3. Register with phone/password
4. See home with map
5. Tap route to see stops
```

### Full Integration Test (30 minutes)
```
1. Register new account
2. Login again with same credentials
3. View routes list, search, click one
4. Check stops display correctly
5. View map, see vehicles
6. Click vehicle, start trip
7. Wait 10 seconds, verify timer counts up
8. End trip, see completion screen
9. Logout, verify redirect to login
```

### Backend Test (10 minutes)
```bash
# Test API directly
curl http://localhost:8000/health
curl http://localhost:8000/api/routes
curl http://localhost:8000/api/vehicles/location
```

---

## 📚 Documentation Files

- **ERROR_AND_INCOMPLETENESS_SUMMARY.md** - Detailed error explanations and incomplete features
- **WORK_IN_PROGRESS.md** - Development status, testing checklist, known bugs
- **QUICK_REFERENCE_GUIDE.md** - This file

---

## 💡 Tips & Tricks

### Debug Print
```dart
print('Debug: $variable');  // Shows in console
debugPrint('Data: ${object.toString()}');
```

### Check Widget Errors
```dart
// In VS Code terminal:
flutter analyze
```

### Hot Reload vs Hot Restart
```bash
flutter run
# Then in console:
# r = Hot Reload (code changes only)
# R = Hot Restart (resets app state)
```

### Database Debugging
```bash
# Connect to PostgreSQL
psql -U postgres -d safari_salama

# Common queries
\dt                           # List tables
SELECT * FROM routes;         # View routes
SELECT * FROM users;          # View users
```

### API Debugging
```bash
# Add logging to see API requests
# In ApiService, add print(response.body) before returning
```

---

## 📞 Troubleshooting

### "Failed to load routes"
- Check backend is running: `python -m uvicorn app.main:app --reload`
- Check API URL in config matches backend address
- Check internet connection

### "Login failed"
- Check phone number format (use +254XXX for Kenya)
- Verify password is correct
- Check user exists in database

### "Splash screen stuck"
- Check AuthService.isLoggedIn() isn't blocked
- Verify SharedPreferences has read/write permission
- Check Android/iOS manifest for required permissions

### "Map won't load"
- Check Google Maps API key in AndroidManifest.xml
- Verify location permission granted on device
- Check device has GPS enabled

### "Emergency alert fails"
- Verify backend is running
- Check location permission granted
- Verify internet connection

---

## 📋 Next Steps (Recommended Priority)

1. ✅ **DONE** - Fix route stops display
2. ⏭️ **NEXT** - Test routes with real backend data
3. ⏭️ **THEN** - Implement trip offline sync
4. ⏭️ **THEN** - Add payment integration
5. ⏭️ **THEN** - Add emergency notifications
6. ⏭️ **THEN** - Create driver dashboard
7. ⏭️ **THEN** - Add user profile screen

---

**Last Updated:** December 23, 2025  
**Status:** 🟢 All critical errors fixed. Project ready for testing.
