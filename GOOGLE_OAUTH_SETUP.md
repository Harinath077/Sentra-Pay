# Google OAuth Setup Guide for Sentra-Pay

## 🎯 Where to Paste Your Google Client ID

You have copied your **Google OAuth Client ID** from Google Cloud Console. Now you need to paste it in **2 locations**:

---

## 📍 Location 1: Backend Configuration

**File:** `Backend/.env`  
**Line:** 10

```env
# Google OAuth Configuration (Replace with your Client ID from Google Cloud Console)
GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com
```

**What to do:**
- Replace `YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com` with your actual Client ID
- Example: `GOOGLE_CLIENT_ID=123456789-abc123def456.apps.googleusercontent.com`

---

## 📍 Location 2: Flutter Frontend Configuration

**File:** `Sentra Pay/lib/services/google_auth_service.dart`  
**Line:** 9

```dart
// TODO: Replace with your Google Client ID from Google Cloud Console
static const String _clientId = 'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com';
```

**What to do:**
- Replace `YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com` with your actual Client ID
- Example: `static const String _clientId = '123456789-abc123def456.apps.googleusercontent.com';`

---

## ✅ After Pasting Client ID

### 1. Restart the Backend Server

```bash
cd Backend
# Kill the existing server (Ctrl+C in the terminal)
# Then restart:
python -m uvicorn app.main:app --host 127.0.0.1 --port 8000
```

### 2. Restart the Flutter App

```bash
cd "Sentra Pay"
# Press 'r' in the terminal where Flutter is running for hot reload
# OR stop and restart:
flutter run -d chrome
```

---

## 🧪 Testing Google Sign-In

1. Open the app in Chrome
2. Click the **"Continue with Google"** button on the login screen
3. Select your Google account
4. Grant permissions
5. You should be automatically signed in and redirected to the home screen

---

## 🔍 Troubleshooting

### Error: "Invalid Client ID"
- Double-check that you copied the **Client ID** (not the Client Secret)
- Ensure the Client ID matches exactly in both files

### Error: "Redirect URI Mismatch"
- Go back to Google Cloud Console
- Add `http://localhost:52808` to **Authorized JavaScript origins**

### Backend shows "GOOGLE_CLIENT_ID not set"
- Make sure you restarted the backend server after updating `.env`
- Check that there are no spaces around the `=` sign in the `.env` file

### Google Sign-In popup doesn't appear
- Check browser console for errors
- Ensure you're using Chrome (web target)
- Try clearing browser cache

---

## 📝 Quick Summary

**2 Files to Update:**
1. ✅ `Backend/.env` (Line 10)
2. ✅ `Sentra Pay/lib/services/google_auth_service.dart` (Line 9)

**Then:**
- Restart backend server
- Hot reload or restart Flutter app
- Test sign-in!

---

## 🎉 You're All Set!

Once you've pasted your Client ID in both locations and restarted the services, Google Sign-In will be fully functional.
