# UPI Fraud Shield — Flutter Frontend

> AI-powered UPI fraud detection app with real-time risk scoring, animated result screens, transaction history, trust scores, and full dark mode support.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Tech Stack](#tech-stack)
3. [Project Structure](#project-structure)
4. [Screens & Features](#screens--features)
5. [Widgets Reference](#widgets-reference)
6. [Theme System](#theme-system)
7. [Backend Integration](#backend-integration)
8. [How Risk Score is Displayed](#how-risk-score-is-displayed)
9. [Demo Guide for Judges](#demo-guide-for-judges)
10. [Setup & Run](#setup--run)

---

## Project Overview

This Flutter app is the frontend of a **3-layer AI fraud detection system** for UPI payments. When a user enters a receiver UPI ID and amount, the app sends the request to a Flask backend, receives a fraud risk score (0–100), and displays the result through animated, colour-coded UI screens.

The app is designed to show judges:
- **Transparent AI** — each contributing factor is shown with a progress bar
- **Real-time animation** — risk gauge fills up live as the score loads
- **Community trust signals** — crowdsourced fraud alerts shown per receiver
- **Trend analysis** — line graph showing the user's risk exposure over time
- **Trust score** — a personalised safety rating for the logged-in user

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Provider (`theme_provider.dart`) |
| Charts | `fl_chart` (risk trend line graph) |
| HTTP | `http` package (REST calls to Flask backend) |
| Storage | `shared_preferences` (transaction history persistence) |
| Theme | Custom `AppTheme` with light + dark mode |

---

## Project Structure

```
lib/
│
├── main.dart                          ← App entry point, theme provider setup
│
├── screens/
│   ├── home_screen.dart               ← Login + Send Money input form
│   ├── enhanced_risk_result_screen.dart  ← Full result screen (animated)
│   └── history_screen.dart            ← Transaction history + trust score
│
├── widgets/
│   ├── risk_factor_breakdown.dart     ← Animated progress bars (3 factors)
│   ├── community_alert.dart           ← Crowdsourced fraud reports widget
│   └── risk_trend_graph.dart          ← Line chart: risk over last 10 txns
│
├── models/
│   └── transaction_history.dart       ← TransactionRecord data model
│
└── theme/
    ├── app_theme.dart                 ← Light + dark ThemeData definitions
    └── theme_provider.dart            ← ChangeNotifier for theme toggle
```

---

## Screens & Features

### 1. Home Screen — `home_screen.dart`

The entry point and transaction initiation screen.

**UI Elements:**
- **AppBar** with app title, dark mode toggle (moon/sun icon, top-right), and history button (top-right)
- **Sender UPI ID field** — pre-filled at login (e.g. `user1@upi`)
- **Receiver UPI ID field** — user enters the payee's UPI ID
- **Amount field** — numeric input in ₹
- **Analyse Button** — triggers API call to backend `/analyze` endpoint
- **Loading indicator** — shown while awaiting backend response

**Flow:**
```
User fills form → taps Analyse → POST /analyze →
Loading spinner → response received → navigate to EnhancedRiskResultScreen
```

**AppBar Actions (top-right):**
```
[History Icon]  [Dark Mode Toggle Icon]
```

---

### 2. Enhanced Risk Result Screen — `enhanced_risk_result_screen.dart`

The core screen. Displays the full fraud analysis result with animations.

**Sections (top to bottom):**

```
┌─────────────────────────────────┐
│        RISK GAUGE (animated)    │  ← Circular gauge, fills over 1.5s
│         Score: 84 / 100         │
│         Level: CRITICAL         │
├─────────────────────────────────┤
│      ACTION BANNER              │  ← ALLOW / WARN / OTP / BLOCK
│   🚫 Transaction Blocked        │     Colour-coded background
├─────────────────────────────────┤
│   COMMUNITY FRAUD ALERT         │  ← ⚠️ 12 users reported this account
│   Last reported: 2 hours ago    │     Red card, shown for risky receivers
├─────────────────────────────────┤
│   RISK FACTOR BREAKDOWN         │  ← 3 animated progress bars
│   Receiver Reputation  ████ 40% │
│   Behaviour Analysis   ███  30% │
│   Transaction Amount   ███  30% │
├─────────────────────────────────┤
│   ANALYSIS FACTORS LIST         │  ← Bullet points from backend explanation
│   • First-time receiver         │     e.g. "Never paid this receiver"
│   • Amount 50× your average     │     Mapped from layer explanation
│   • Impossible travel detected  │
├─────────────────────────────────┤
│   [Proceed Anyway] [Go Back]    │  ← Buttons shown only for WARN/OTP
└─────────────────────────────────┘
```

**Animations:**
- Risk gauge: `AnimationController` with 1.5s duration, `CurvedAnimation(Curves.easeOut)`
- Factor bars: staggered fade-in, each bar animates after the previous
- Entire screen: `FadeTransition` on entry

**Colour coding by action:**

| Action | Gauge Colour | Banner Colour | Icon |
|--------|-------------|---------------|------|
| ALLOW | `#10B981` Green | Green | ✅ |
| WARN | `#F59E0B` Amber | Amber | ⚠️ |
| OTP | `#F59E0B` Amber | Orange | 🔐 |
| BLOCK | `#EF4444` Red | Red | 🚫 |

---

### 3. History Screen — `history_screen.dart`

Shows the user's past transactions and their safety rating.

**Sections:**

```
┌─────────────────────────────────┐
│       TRUST SCORE CARD          │
│    🏆 Platinum   95%            │
│    Your safety rating           │
├─────────────────────────────────┤
│       RISK TREND GRAPH          │
│   ╭──╮     Risk over            │
│  ╯    ╰─╮  last 10 txns         │
│          ╰──                    │
│  ↓ -12.3% risk decreasing ✓    │
├─────────────────────────────────┤
│       RECENT TRANSACTIONS       │
│  recv1@upi   ₹3,000   ● LOW 6  │
│  recv6@upi   ₹25,000  ● HIGH 72│
│  recv9@upi   ₹1,50,000 ● CRIT 88│
└─────────────────────────────────┘
```

**Trust Score Tiers:**

| Score | Tier | Icon |
|-------|------|------|
| 95%+ | Platinum | 🏆 |
| 85–94% | Gold | ⭐ |
| 70–84% | Silver | ⭐ |
| < 70% | Bronze | 🛡️ |

Trust score is computed as:
```dart
trustScore = 100 - (average of all past final_risk_scores)
```

**Empty State:** Displays an illustrated placeholder card when no transactions exist yet.

---

## Widgets Reference

### `risk_factor_breakdown.dart`

Renders three animated horizontal progress bars showing each layer's contribution to the final risk score.

| Factor | Weight | Maps to Backend |
|--------|--------|----------------|
| Receiver Reputation | 40% | `layer3.receiver_risk_score` |
| Behaviour Analysis | 30% | `layer1.user_risk_score` |
| Transaction Amount | 30% | `layer2.amount_risk_score` |

Each bar animates from 0 → actual value over **1.5 seconds** using `Tween<double>`.

Colour thresholds:
```
0–30   →  #10B981  Green
31–65  →  #F59E0B  Amber
66–100 →  #EF4444  Red
```

---

### `community_alert.dart`

Displays a red alert card when the receiver has been flagged by other users.

**Logic:**
- Report count is derived from `receiver_upi` hash (deterministic, so same receiver always shows same count for demo)
- Only shown when `final_risk_score >= 45`
- Format: `"⚠️ {N} users reported this account"` + time since last report

---

### `risk_trend_graph.dart`

A line chart (using `fl_chart`) drawn over the last 10 transactions stored in history.

**Features:**
- Gradient fill under the curve (risk colour → transparent)
- Trend indicator: calculates slope of last 3 points
  - Decreasing → `"✓ Your risk exposure is decreasing -X.X%"` (green)
  - Increasing → `"⚠ Risk exposure is increasing +X.X%"` (red)
- Animated draw-on effect using `AnimationController`

---

### `transaction_history.dart` (Model)

```dart
class TransactionRecord {
  final String senderUpi;
  final String receiverUpi;
  final double amount;
  final int finalRiskScore;
  final String action;       // ALLOW / WARN / OTP / BLOCK
  final String riskLevel;    // LOW / MODERATE / HIGH / CRITICAL
  final DateTime timestamp;
}
```

Stored via `shared_preferences` as a JSON list. Max 50 records kept (oldest removed).

---

## Theme System

### `app_theme.dart`

Defines two complete `ThemeData` objects.

**Light Mode**

| Token | Value | Usage |
|-------|-------|-------|
| Background | `#F8FAFC` | Scaffold background |
| Primary | `#2563EB` | Buttons, AppBar |
| Success | `#10B981` | ALLOW, low risk |
| Warning | `#F59E0B` | WARN, medium risk |
| Error | `#EF4444` | BLOCK, high risk |
| Card | `#FFFFFF` | Widget cards |
| Text primary | `#0F172A` | Body text |

**Dark Mode**

| Token | Value | Usage |
|-------|-------|-------|
| Background | `#0F172A` | Scaffold background |
| Card | `#1E293B` | Widget cards |
| Text | `#F1F5F9` | All text |
| Border | `#334155` | Card borders, dividers |
| Primary | `#3B82F6` | Buttons (slightly lighter for dark) |

---

### `theme_provider.dart`

```dart
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
```

Wrapped at `main.dart` level with `ChangeNotifierProvider` so all screens rebuild on toggle.

---

## Backend Integration

The app communicates with the Flask backend over HTTP.

### Base URL

```dart
const String baseUrl = 'http://10.0.2.2:5000';  // Android emulator
// or
const String baseUrl = 'http://localhost:5000';   // iOS simulator
// or
const String baseUrl = 'http://<YOUR_LOCAL_IP>:5000';  // Physical device
```

### Analyze Transaction

```dart
// POST /analyze
final response = await http.post(
  Uri.parse('$baseUrl/analyze'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'sender_upi'   : senderUpi,
    'receiver_upi' : receiverUpi,
    'amount'       : amount,
  }),
);

final data = jsonDecode(response.body);

// Key fields used by frontend:
data['action']             // ALLOW | WARN | OTP | BLOCK
data['final_risk_score']   // 0–100
data['risk_level']         // LOW | MODERATE | HIGH | CRITICAL
data['explanation']['reasons']          // List<String> — bullet points
data['layer1_user']['user_risk_score']
data['layer2_amount']['amount_risk_score']
data['layer3_receiver']['receiver_risk_score']
data['layer3_receiver']['features_used']['location_mismatch']  // 0 or 1
```

### Error Handling

```dart
if (response.statusCode == 200) {
  // parse and navigate to result screen
} else {
  // show SnackBar: "Analysis failed. Please try again."
}
```

---

## How Risk Score is Displayed

The backend returns a single `final_risk_score` (0–100). Here is how every UI element maps to it:

```
final_risk_score   risk_level   action    gauge colour   banner
─────────────────────────────────────────────────────────────────
0  – 24           LOW          ALLOW     Green           ✅ Safe to Pay
25 – 44           MODERATE     WARN      Amber           ⚠️ Proceed with Caution
45 – 69           HIGH         OTP       Orange          🔐 Verify with OTP
70 – 100          CRITICAL     BLOCK     Red             🚫 Transaction Blocked
```

The **animated gauge** uses `AnimationController`:

```dart
_animation = Tween<double>(begin: 0, end: riskScore / 100)
  .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
_controller.forward();
```

The **3 factor bars** animate staggered using `Future.delayed`:

```dart
Future.delayed(Duration(milliseconds: 300), () => animateBehaviourBar());
Future.delayed(Duration(milliseconds: 600), () => animateAmountBar());
Future.delayed(Duration(milliseconds: 900), () => animateReceiverBar());
```

---

## Demo Guide for Judges

Use these input combinations to showcase all 3 fraud levels live:

### ✅ Safe Transaction (ALLOW)
```
Sender UPI  : user1@upi
Receiver UPI: recv1@upi
Amount      : ₹3,000

Expected → Score: ~6  |  Action: ALLOW  |  Gauge: Green
Shows    → 5 past transactions, trusted relationship, normal amount
```

### ⚠️ Moderate Risk (WARN / OTP)
```
Sender UPI  : user4@upi
Receiver UPI: recv6@upi
Amount      : ₹40,000

Expected → Score: ~52  |  Action: OTP  |  Gauge: Orange
Shows    → First-time sender, impossible travel detected (Pune→Chennai in 75min)
           Amount above average, community alert visible
```

### 🚨 High Fraud (BLOCK)
```
Sender UPI  : user1@upi
Receiver UPI: recv9@upi
Amount      : ₹1,50,000

Expected → Score: ~88  |  Action: BLOCK  |  Gauge: Red
Shows    → Never paid before, amount is 40× sender's average,
           impossible travel (Mumbai→Kolkata in 55min), night transactions,
           community alerts active
```

---

## Setup & Run

### Prerequisites

```bash
flutter --version   # Flutter 3.x or above
dart --version      # Dart 3.x
```

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
# Make sure the Flask backend is running first:
# cd fraud_backend && python app.py

# Then run Flutter:
flutter run
```

### Run on physical device

1. Find your machine's local IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
2. Update `baseUrl` in your API service file:
   ```dart
   const String baseUrl = 'http://192.168.x.x:5000';
   ```
3. Ensure your phone and laptop are on the **same Wi-Fi network**
4. Run `flutter run`

### Build APK for demo

```bash
flutter build apk --release
# APK location: build/app/outputs/flutter-apk/app-release.apk
```

---

## Key Design Decisions

**Why animated gauge instead of just showing the number?**
The animation makes the AI feel like it is "calculating" in real time. Judges respond better to motion — it communicates that the system did real work, not just a lookup.

**Why show 3 separate factor bars?**
Transparency is a key concern with fraud AI. Showing each factor (receiver reputation 40%, behaviour 30%, amount 30%) makes it clear the decision is not a black box. This directly addresses a common judge question: *"how does it decide?"*

**Why trust score in history?**
It personalises the app. A user who consistently pays known receivers will have a high trust score. This proves the system learns from behaviour over time, not just one-off transactions.

**Why impossible travel in the UI?**
It is the most visually compelling fraud signal. A judge immediately understands *"this person was in Chennai and Mumbai in the same hour — that's impossible"* without needing to understand ML at all.
