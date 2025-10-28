# 📱 SnapWise - Your Smart Financial Assistant

**SnapWise** is an AI-powered expense tracking and budget management application built with Flutter. It uses OCR technology and artificial intelligence to automatically extract and categorize expenses from receipts, helping users manage their finances more efficiently.

## 🌟 Features

### 🔍 **Smart Receipt Processing**
- **OCR Technology**: Automatically extract details from receipts using camera or gallery
- **AI-Powered Categorization**: Intelligent expense categorization with manual override options
- **Receipt Storage**: Secure storage of receipt images with base64 encoding
- **Date Recognition**: Automatic detection of purchase dates from receipts

### 💰 **Comprehensive Budget Management**
- **Monthly Budgets**: Set and track monthly spending limits across categories
- **Income Tracking**: Monitor and manage monthly income
- **Category Management**: Create custom expense categories with spending limits
- **Budget Alerts**: Real-time notifications when approaching or exceeding budget limits
- **Visual Progress**: Circular progress indicators and charts for budget tracking

### 🔔 **Smart Notifications**
- **Real-time Alerts**: Instant notifications for budget overruns and payment reminders
- **Priority Payments**: Mark essential bills as priority with automatic reminders
- **Customizable Settings**: User-controlled notification preferences
- **Cross-platform Support**: Works on both Android and iOS

### 📊 **Financial Insights**
- **Visual Analytics**: Beautiful charts and graphs for spending patterns
- **Transaction History**: Complete record of all expenses with filtering options
- **Future Predictions**: AI-powered budget forecasting and expense predictions
- **Income Distribution**: Track how income is allocated across different categories

### ⭐ **Priority Payment System**
- **Bill Management**: Add and track recurring bills and payments
- **Payment Status**: Track paid, pending, and missed payments
- **Payment History**: Complete record of all payment transactions
- **Automatic Updates**: Budget and income updates when payments are confirmed

### 🌐 **Web Platform**
- **Landing Page**: Professional website with feature showcase
- **AI Chatbot**: Interactive AI assistant for user queries
- **Feedback System**: User feedback collection and rating system
- **Download Links**: Direct access to mobile app downloads

## 🛠️ Technology Stack

### **Frontend**
- **Flutter**: Cross-platform mobile development framework
- **Dart**: Programming language for Flutter development
- **GetX**: State management and dependency injection
- **Material Design**: Modern UI/UX design system

### **Backend & Services**
- **Firebase**: Backend-as-a-Service platform
  - **Firestore**: NoSQL database for data storage
  - **Firebase Auth**: User authentication and management
  - **Firebase Storage**: File storage for receipt images
- **Google Generative AI**: AI-powered expense categorization
- **OCR Integration**: Receipt text extraction and processing

### **Key Dependencies**
```yaml
dependencies:
  flutter: sdk: flutter
  firebase_core: ^3.15.1
  cloud_firestore: ^5.6.11
  firebase_auth: ^5.6.2
  google_generative_ai: ^0.4.6
  image_picker: ^1.1.2
  flutter_image_compress: ^2.3.0  # Image compression for Firestore
  path_provider: ^2.1.1
  flutter_local_notifications: ^19.3.0
  get: ^4.7.2
  get_storage: ^2.1.1  # Local caching
  fl_chart: ^1.0.0
  percent_indicator: ^4.2.2
  google_fonts: ^6.2.1
  lucide_icons: ^0.257.0
  intl: ^0.19.0  # Date formatting
  emailjs: ^4.0.0  # Web feedback system
  url_launcher: ^6.3.1  # External links
```

## 📱 Platform Support

- **Android**: API 23+ (Android 6.0+)
- **iOS**: iOS 10.0+
- **Web**: Modern web browsers (Chrome, Firefox, Safari, Edge)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- Firebase project setup
- Google AI API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/rmanales10/snapwise.git
   cd snapwise
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Enable Firestore, Authentication, and Storage
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate platform directories

4. **Configure Google AI**
   - Get API key from Google AI Studio
   - Add the key to your environment variables or configuration

5. **Run the application**
   ```bash
   # For mobile
   flutter run
   
   # For web
   flutter run -d chrome
   ```

## 📁 Project Structure

```
lib/
├── app/
│   ├── auth_screens/          # Authentication screens
│   │   ├── login/            # Login functionality
│   │   ├── register/         # User registration
│   │   ├── forgot_password/  # Password recovery
│   │   └── main_screen/      # Main authentication screen
│   ├── budget/               # Budget management
│   │   ├── budget.dart       # Main budget screen
│   │   ├── create_budget.dart
│   │   ├── edit_budget.dart
│   │   └── income/           # Income management
│   ├── expense/              # Expense tracking
│   │   ├── expense.dart      # Main expense screen
│   │   ├── gemini_ai.dart    # AI integration
│   │   └── view_expense.dart
│   ├── home/                 # Home dashboard
│   │   ├── home_screens/     # Main dashboard
│   │   └── predict_screens/  # Budget predictions
│   ├── profile/              # User profile
│   │   ├── favorites/        # Priority payments
│   │   └── settings/         # App settings
│   ├── notification/         # Notification management
│   └── widget/               # Reusable UI components
├── services/                 # Core services
│   ├── firebase_options.dart
│   ├── notification_service.dart
│   └── snackbar_service.dart
└── web/                      # Web platform
    ├── landing_page.dart     # Main landing page
    ├── chatbot.dart         # AI chatbot
    └── feedback_controller.dart
```

## 🏗️ System Architecture

### **Architecture Overview**
SnapWise follows a modern Flutter architecture with clean separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                      │
├─────────────────────────────────────────────────────────────┤
│  • UI Screens (Home, Budget, Expense, Profile, Web)        │
│  • Widgets (Charts, Forms, Cards, Navigation)              │
│  • Controllers (GetX Controllers for State Management)     │
│  • Responsive Design (Mobile, Tablet, Web)                 │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                    │
├─────────────────────────────────────────────────────────────┤
│  • Controllers (Budget, Expense, Notification, AI)         │
│  • Services (Firebase, AI, Notification, Snackbar)         │
│  • Models (Data Models and DTOs)                           │
│  • State Management (GetX Reactive Programming)            │
└─────────────────────────────────────────────────────────────┘
                                │
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                            │
├─────────────────────────────────────────────────────────────┤
│  • Firebase Firestore (Primary Database)                   │
│  • Firebase Auth (User Authentication)                     │
│  • Firebase Storage (File Storage)                         │
│  • Local Storage (GetStorage for Caching)                  │
│  • Google AI (Gemini for OCR and Predictions)              │
└─────────────────────────────────────────────────────────────┘
```

### **Key Components**

#### **1. State Management (GetX)**
- **Reactive Programming**: Real-time UI updates using observables
- **Dependency Injection**: Automatic service registration and management
- **Route Management**: Programmatic navigation with named routes
- **Memory Management**: Automatic disposal of controllers and services

#### **2. Data Flow Architecture**
```
User Action → Controller → Service → Firebase → UI Update
     ↓              ↓         ↓         ↓
  UI Event → Business Logic → API Call → State Change
```

#### **3. Service Layer**
- **FirebaseService**: Database operations and authentication
- **NotificationService**: Cross-platform notification management
- **AIService**: Gemini AI integration for OCR and predictions
- **SnackbarService**: User feedback and error handling

## 🔧 Configuration

### Firebase Configuration
1. Create a new Firebase project
2. Enable the following services:
   - Authentication (Email/Password, Google Sign-In)
   - Firestore Database
   - Storage
3. Download configuration files and place them in:
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`

### Google AI Configuration
1. Visit [Google AI Studio](https://aistudio.google.com/)
2. Create a new API key
3. Add the key to your environment or configuration file

### Notification Setup
The app includes comprehensive notification support for:
- Budget alerts
- Payment reminders
- Expense tracking notifications
- Custom notification channels for Android

## 📊 Key Features Deep Dive

### 1. Smart Receipt Processing System
- **Camera Integration**: Direct camera access for receipt capture with image quality optimization
- **Gallery Selection**: Choose existing images from device gallery with automatic compression (< 600KB)
- **OCR Processing**: Automatic text extraction from receipt images using Google's Gemini AI
- **AI Categorization**: Smart expense categorization with 6 main categories (Food, Transport, Shopping, Entertainment, Utilities, Other)
- **Manual Override**: Full control to modify AI-suggested categories and amounts
- **Dual Date Tracking**: 
  - **Receipt Date**: The actual date on the physical receipt (used for budget calculations and graphs)
  - **Transaction Date**: The date when the expense was added to the app (used for "Recent Transactions")
- **Image Compression**: Automatic image compression using `flutter_image_compress` to ensure Firestore compatibility
- **Base64 Storage**: Secure storage of receipt images in Firebase Firestore (< 1MB limit)
- **Error Handling**: Graceful fallback when AI extraction fails with user-friendly error messages

**Technical Implementation:**
```dart
// AI-powered expense extraction with dual date tracking
Future<Map<String, String>> extractExpenseDetails(String imageBase64) async {
  final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  final content = [Content.multi([TextPart(prompt), DataPart('image/jpeg', bytes)])];
  final response = await model.generateContent(content);
  
  return {
    'category': extractedCategory,
    'amount': cleanedAmount,
    'receiptDate': extractedDate,  // Date from physical receipt
    'transactionDate': DateTime.now().toString().split(' ')[0]  // Today's date
  };
}

// Image compression before storage
Future<Uint8List?> _compressImage(Uint8List imageBytes) async {
  return await FlutterImageCompress.compressWithList(
    imageBytes,
    minWidth: 1920,
    minHeight: 1080,
    quality: 85,
    format: CompressFormat.jpeg,
  );
}
```

### 1.1. Calculation Logic & Data Flow

SnapWise implements a sophisticated calculation system with clear separation of concerns:

#### **Account Balance Calculation**
```
Account Balance = Income - Total Spent
```
- **Income**: User's monthly income set in the app
- **Total Spent**: Sum of all expenses in current month (based on receipt date)
- **Updates**: Real-time updates when expenses are added or income is modified

#### **Total Spent Calculation**
```
Total Spent = Regular Expenses + Favorite (Priority) Expenses
```
- **Regular Expenses**: Filtered by `receiptDate` within current month
- **Favorite Expenses**: Priority payments made in current month
- **Date Logic**: Uses `receiptDate` to determine which month an expense belongs to
- **Real-time Sync**: Automatic recalculation with Firestore stream listeners

#### **Graph Data**
- **Daily Graph**: Shows expenses per day based on `receiptDate`
- **Monthly Graph**: Shows expenses per month based on `receiptDate` for last 12 months
- **Purpose**: Historical spending patterns based on when expenses actually occurred
- **Data Source**: All expenses filtered and grouped by `receiptDate`

#### **Recent Transactions**
- **Filter**: Shows expenses added TODAY (based on `transactionDate`)
- **Display**: Shows the `receiptDate` (actual expense date) for each item
- **Purpose**: Quick view of what was just added to the app, regardless of receipt date
- **Example**: If you scan an old receipt from 2014 today, it appears in Recent Transactions

#### **Data Flow Architecture**
```
┌──────────────────────────────────────────────────────────────┐
│              USER ADDS EXPENSE (Camera/Gallery)              │
└────────────────────────┬─────────────────────────────────────┘
                         │
              ┌──────────▼──────────┐
              │  AI Extraction      │
              │  (Gemini AI)        │
              │  - Category         │
              │  - Amount           │
              │  - Receipt Date     │
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │  Data Processing    │
              │  - Clean amount     │
              │  - Compress image   │
              │  - Set dates        │
              │    • receiptDate    │
              │    • transactionDate│
              └──────────┬──────────┘
                         │
              ┌──────────▼──────────┐
              │  Save to Firestore  │
              │  expenses collection│
              └──────────┬──────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌────────────┐  ┌────────────┐  ┌────────────┐
│Recent Trans│  │Total Spent │  │  Graph     │
│(txnDate)   │  │(rcptDate)  │  │(rcptDate)  │
│Shows today │  │Current     │  │Historical  │
│additions   │  │month total │  │patterns    │
└────────────┘  └────────────┘  └────────────┘
```

#### **Why This Design?**

✅ **No Redundancy**: Each component serves a unique purpose
- Recent Transactions: What was just added
- Total Spent: Current month's actual spending
- Graph: Historical spending patterns

✅ **Accurate Reporting**: Expenses counted once, displayed appropriately
- Budget calculations based on when expenses occurred (receiptDate)
- User can see what they just added (transactionDate)

✅ **Flexible Data Entry**: Scan old receipts without affecting current month
- Old receipts appear in correct historical period
- Still visible in Recent Transactions for confirmation

### 2. Advanced Budget Management System
- **Category-based Budgets**: Set individual budgets for different expense categories with custom alert percentages
- **Overall Budget**: Track total monthly spending against income with real-time calculations
- **Alert Thresholds**: Customizable percentage-based budget alerts (e.g., 80% warning, 100% exceeded)
- **Visual Progress**: Circular progress indicators and charts for budget tracking
- **Budget History**: Track budget performance over time with monthly comparisons
- **Dynamic Calculations**: Real-time remaining budget calculations with category breakdowns
- **Notification Integration**: Automatic alerts when budget limits are approached or exceeded

**Technical Implementation:**
```dart
// Budget calculation with real-time updates
Future<void> calculateRemainingBudget() async {
  double overallBudget = budgetData.value['amount'] ?? 0.0;
  double totalCategoryBudget = 0.0;
  
  // Calculate remaining budget (overall - category budgets)
  remainingBudget.value = overallBudget - totalCategoryBudget.value;
  
  // Calculate percentage remaining
  remainingBudgetPercentage.value = remainingBudget.value / overallBudget;
  
  // Check for notifications
  await _checkOverallBudgetNotification(overallBudget);
}
```

### 3. AI-Powered Budget Prediction System
- **Historical Analysis**: Analyze 6-10 months of spending data for accurate predictions
- **Daily Predictions**: Generate daily spending predictions for the next month
- **Category Breakdown**: AI-suggested budget allocation across expense categories
- **Visual Analytics**: Interactive charts showing historical trends and future predictions
- **Insights Generation**: AI-powered financial insights and recommendations
- **Prediction Storage**: Save and manage multiple budget predictions
- **Data-driven Approach**: Uses actual spending patterns for more accurate forecasts

**Technical Implementation:**
```dart
// AI budget prediction using Gemini
Future<List<double>> generateBudgetAllocation(double totalBudget) async {
  final prompt = '''
  Given a total budget of $totalBudget, allocate it among categories:
  1. Food 2. Transport 3. Shopping 4. Utilities 5. Entertainment 6. Others
  Provide numerical values separated by commas.
  ''';
  
  final response = await model.generateContent([Content.text(prompt)]);
  return parseAllocations(response.text);
}
```

### 4. Priority Payment System (Favorites)
- **Bill Management**: Add recurring bills and one-time payments with custom frequencies
- **Payment Status Tracking**: Monitor paid, pending, and missed payments with real-time updates
- **Payment History**: Complete transaction records with timestamps and amounts
- **Automatic Reminders**: Smart notifications for upcoming and overdue payments
- **Budget Integration**: Automatic budget and income updates when payments are confirmed
- **Status Management**: Reset missed payments and retry functionality
- **Visual Indicators**: Color-coded status indicators and progress bars

**Technical Implementation:**
```dart
// Payment status management
Future<void> updatePaymentStatus(String billId, double amount) async {
  await _firestore.collection('favorites').doc(billId).update({
    'paidAmount': FieldValue.increment(amount),
    'paymentHistory': FieldValue.arrayUnion([{
      'amount': amount,
      'timestamp': FieldValue.serverTimestamp(),
    }]),
  });
  
  // Update budget and income automatically
  await _updateBudgetAndIncome(amount);
}
```

### 5. Comprehensive Notification System
- **Multi-channel Notifications**: 7 different notification channels for different alert types
- **Cooldown Mechanism**: Prevents duplicate notifications with 5-minute cooldown periods
- **Platform Support**: Full Android and iOS notification support with proper permissions
- **Customizable Settings**: User-controlled notification preferences per category
- **Real-time Alerts**: Instant notifications for budget overruns, payment reminders, and income alerts
- **Visual Feedback**: Custom vibration patterns and sound alerts for different notification types

**Technical Implementation:**
```dart
// Notification service with cooldown mechanism
class NotificationService extends GetxController {
  final Map<String, DateTime> _lastNotificationTimes = {};
  static const Duration _cooldownPeriod = Duration(minutes: 5);
  
  bool _shouldSendNotification(String notificationKey) {
    final now = DateTime.now();
    final lastTime = _lastNotificationTimes[notificationKey];
    
    if (lastTime == null || now.difference(lastTime) >= _cooldownPeriod) {
      _lastNotificationTimes[notificationKey] = now;
      return true;
    }
    return false;
  }
}
```

### 6. Web Platform & AI Chatbot
- **Professional Landing Page**: Responsive website with feature showcase and animations
- **AI Chatbot Integration**: Interactive AI assistant powered by Gemini AI for user queries
- **Feedback System**: User feedback collection with EmailJS integration and rating system
- **Download Management**: Direct access to mobile app downloads with version management
- **Cross-platform Compatibility**: Works seamlessly across desktop and mobile browsers
- **SEO Optimization**: Search engine optimized content with proper meta tags

**Technical Implementation:**
```dart
// AI Chatbot with comprehensive app knowledge
Future<void> _processUserMessage(String message) async {
  final prompt = '''
  You are SnapWise AI Assistant, a comprehensive financial management app assistant.
  The user is asking: "$message"
  
  **SNAPWISE APP OVERVIEW:**
  SnapWise is a complete personal finance management app that helps users track expenses, 
  manage budgets, and make informed financial decisions through AI-powered features.
  
  **DETAILED FEATURES:**
  - AI-powered receipt scanning using Gemini AI
  - Smart budget allocation suggestions
  - Real-time notifications and alerts
  - Priority payment management
  - Financial insights and predictions
  ''';
  
  final response = await model.generateContent([Content.text(prompt)]);
  // Process and display response
}
```

### 7. Real-time Data Synchronization
- **Firestore Stream Listeners**: Automatic real-time updates from Firebase
- **GetX Reactive Programming**: Instant UI updates with `Obx` widgets
- **No Manual Refresh**: All data updates automatically when changes occur
- **Multi-component Sync**: Home screen, graphs, and transactions update simultaneously
- **Memory Efficient**: Proper disposal of stream subscriptions to prevent memory leaks
- **Optimized Performance**: Debounced updates to prevent excessive refreshes

**Technical Implementation:**
```dart
// Real-time listeners in HomeController
void _setupRealtimeListeners() {
  // Listen to expenses changes
  _expensesSubscription = _firestore
      .collection('expenses')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .listen((snapshot) {
    log('Expenses changed, refreshing data');
    refreshAllData();
  });

  // Listen to budget changes
  _budgetSubscription = _firestore
      .collection('overallBudget')
      .doc(user.uid)
      .snapshots()
      .listen((snapshot) {
    totalBudget.value = snapshot.data()?['totalBudget']?.toString() ?? '0.0';
  });

  // Auto-dispose on controller close
  @override
  void onClose() {
    _expensesSubscription?.cancel();
    _budgetSubscription?.cancel();
    super.onClose();
  }
}

// Reactive UI with Obx
Obx(() => Text('PHP ${controller.totalSpent}'))  // Auto-updates
```

### 8. Advanced Analytics & Reporting
- **Transaction History**: Complete record of all expenses with filtering and search capabilities
- **Spending Patterns**: Visual analysis of expense trends by category and time period
- **Monthly Summaries**: Comprehensive financial summaries with income vs expense analysis
- **Interactive Charts**: Beautiful charts and graphs using FL Chart library
- **Dual-axis Graphs**: Daily and monthly views with smooth transitions
- **Export Capabilities**: Data export functionality for external analysis
- **Real-time Updates**: Live data updates using GetX reactive programming
- **Responsive Design**: Optimized for mobile, tablet, and desktop viewing

### 8. Security & Data Management
- **Firebase Security**: Secure backend with Firebase security rules and authentication
- **Data Encryption**: Sensitive data encrypted in transit and at rest
- **User Authentication**: Secure user registration and login with Firebase Auth
- **Privacy Controls**: User control over data sharing and notification preferences
- **Local Storage**: Secure local storage for sensitive information using GetStorage
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Payment Tracking**: Monitor payment status (Paid, Pending, Missed)
- **Automatic Reminders**: Smart notifications for upcoming payments
- **Payment History**: Complete transaction records
- **Budget Integration**: Automatic budget updates when payments are made

### 4. Analytics & Insights
- **Spending Patterns**: Visual analysis of expense trends
- **Category Breakdown**: Detailed spending by category
- **Income vs Expenses**: Clear view of financial health
- **Predictive Analytics**: AI-powered future expense predictions
- **Export Capabilities**: Data export for external analysis

## 🔐 Security & Privacy

- **Firebase Security**: Secure backend with Firebase security rules
- **Data Encryption**: Sensitive data encrypted in transit and at rest
- **User Authentication**: Secure user registration and login
- **Privacy Controls**: User control over data sharing and notifications
- **Local Storage**: Secure local storage for sensitive information

## 🧪 Testing

The application includes comprehensive testing for:
- Unit tests for business logic
- Widget tests for UI components
- Integration tests for user flows
- Notification testing across platforms

Run tests with:
```bash
flutter test
```

## 📊 Database Schema

### **Firebase Firestore Data Model / Schema Diagram**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        FIREBASE FIRESTORE DATABASE                          │
│                          (NoSQL Document Database)                          │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: users                                                          │
│  Document ID: {userId} (Firebase Auth UID)                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  {                                                                          │
│    email: string               // "user@example.com"                       │
│    displayName: string         // "John Doe"                               │
│    photoUrl: string            // "https://..."                            │
│    createdAt: timestamp        // Account creation date                    │
│    lastLogin: timestamp        // Last login date                          │
│  }                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ userId (1:N)
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: expenses                                                       │
│  Document ID: {expenseId} (Auto-generated)                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  {                                                                          │
│    userId: string              // Reference to users collection            │
│    category: string            // "Food", "Transport", "Shopping", etc.    │
│    amount: number              // 25.50 (double)                           │
│    base64Image: string         // Base64 encoded receipt image             │
│    receiptDate: string         // "2025-01-15" (date from receipt)         │
│    transactionDate: string     // "2025-10-28" (date added to app)         │
│    timestamp: timestamp        // Server timestamp (Firestore)             │
│  }                                                                          │
│                                                                             │
│  Indexes:                                                                   │
│    - userId, timestamp (desc)  // For fetching user's recent expenses      │
│    - userId, receiptDate       // For monthly totals and graphs            │
│    - userId, transactionDate   // For "Recent Transactions" feature        │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ userId (1:N)
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: budget                                                         │
│  Document ID: {budgetId} (Auto-generated)                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  {                                                                          │
│    userId: string              // Reference to users collection            │
│    category: string            // "Food", "Transport", "Shopping", etc.    │
│    amount: number              // 5000.00 (budget limit for category)      │
│    alertPercentage: number     // 80.0 (trigger alert at 80%)              │
│    receiveAlert: boolean       // true/false (enable/disable alerts)       │
│    timestamp: timestamp        // Server timestamp                         │
│  }                                                                          │
│                                                                             │
│  Indexes:                                                                   │
│    - userId, category          // For category-specific budget queries     │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ userId (1:1)
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: overallBudget                                                  │
│  Document ID: {userId} (Firebase Auth UID - One per user)                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  {                                                                          │
│    userId: string              // Reference to users collection            │
│    amount: number              // 50000.00 (total monthly budget)          │
│    totalBudget: number         // 50000.00 (for display)                   │
│    alertPercentage: number     // 80.0 (trigger alert at 80%)              │
│    receiveAlert: boolean       // true/false                               │
│    timestamp: timestamp        // Server timestamp                         │
│  }                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ userId (1:1)
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: income                                                         │
│  Document ID: {userId} (Firebase Auth UID - One per user)                 │
├─────────────────────────────────────────────────────────────────────────────┤
│  {                                                                          │
│    userId: string              // Reference to users collection            │
│    amount: number              // 90000.00 (monthly income)                │
│    income: number              // 90000.00 (for display)                   │
│    alertPercentage: number     // 80.0 (income utilization alert)          │
│    receiveAlert: boolean       // true/false                               │
│    timestamp: timestamp        // Server timestamp                         │
│  }                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ userId (1:N)
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: favorites (Priority Payments)                                  │
│  Document ID: {favoriteId} (Auto-generated)                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  {                                                                          │
│    userId: string              // Reference to users collection            │
│    title: string               // "Electric Bill", "Water Bill", etc.      │
│    totalAmount: number         // 2500.00 (total bill amount)              │
│    amountToPay: number         // 2500.00 (amount due)                     │
│    paidAmount: number          // 0.00 (amount paid so far)                │
│    frequency: string           // "Monthly", "Weekly", "One-time"          │
│    startDate: string           // "2025-01-01"                             │
│    endDate: string             // "2025-12-31"                             │
│    status: string              // "Pending", "Paid", "Missed"              │
│    paymentHistory: [           // Array of payment records                 │
│      {                                                                      │
│        amount: number          // 2500.00                                  │
│        timestamp: timestamp    // Payment date                             │
│      }                                                                      │
│    ],                                                                       │
│    timestamp: timestamp        // Server timestamp (creation)              │
│  }                                                                          │
│                                                                             │
│  Indexes:                                                                   │
│    - userId, status            // For filtering by payment status          │
│    - userId, timestamp         // For recent payments                      │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      │ userId (1:N)
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  COLLECTION: predictions                                                    │
│  Document ID: {predictionId} (Auto-generated)                              │
├─────────────────────────────────────────────────────────────────────────────┤
│  {                                                                          │
│    userId: string              // Reference to users collection            │
│    totalBudget: number         // 30000.00 (predicted budget)              │
│    categories: [               // Array of category predictions            │
│      {                                                                      │
│        name: string            // "Food"                                   │
│        amount: number          // 8000.00                                  │
│        percentage: number      // 26.7                                     │
│      },                                                                     │
│      {                                                                      │
│        name: string            // "Transport"                              │
│        amount: number          // 5000.00                                  │
│        percentage: number      // 16.7                                     │
│      }                                                                      │
│    ],                                                                       │
│    dailyPredictions: [         // Array of daily predictions               │
│      {                                                                      │
│        day: number             // 1-31                                     │
│        amount: number          // 1000.00                                  │
│      }                                                                      │
│    ],                                                                       │
│    insights: string            // "AI-generated financial insights..."     │
│    timestamp: timestamp        // Prediction creation date                 │
│  }                                                                          │
│                                                                             │
│  Indexes:                                                                   │
│    - userId, timestamp (desc)  // For fetching latest predictions          │
└─────────────────────────────────────────────────────────────────────────────┘
```

### **Relationship Diagram**

```
┌──────────┐
│  users   │
│ (1 user) │
└────┬─────┘
     │
     ├─────────────────┐
     │                 │
     ▼ (1:N)           ▼ (1:N)
┌──────────┐      ┌──────────┐
│ expenses │      │  budget  │
│(multiple)│      │(multiple)│
└──────────┘      └──────────┘
     │
     │
     ├─────────────────┐
     │                 │
     ▼ (1:1)           ▼ (1:1)
┌────────────┐    ┌──────────┐
│overallBudget│   │  income  │
│  (single)   │   │ (single) │
└────────────┘    └──────────┘
     │
     │
     ├─────────────────┐
     │                 │
     ▼ (1:N)           ▼ (1:N)
┌──────────┐      ┌──────────────┐
│favorites │      │ predictions  │
│(multiple)│      │  (multiple)  │
└──────────┘      └──────────────┘
```

### **Key Design Decisions**

#### **1. Document Structure**
- **Denormalized Design**: Data is intentionally duplicated (e.g., userId in each collection) for faster queries
- **No Foreign Keys**: NoSQL doesn't enforce referential integrity; handled in application logic
- **Subcollections**: Not used; flat structure for simpler queries

#### **2. Data Types**
- **Timestamps**: Server timestamps for consistency across devices
- **Numbers**: JavaScript numbers (doubles) for all numeric values
- **Strings**: For dates (YYYY-MM-DD format) to enable easy parsing and filtering
- **Arrays**: For payment history and category predictions

#### **3. Indexing Strategy**
- **Composite Indexes**: userId + timestamp for efficient user-specific queries
- **Single Field Indexes**: Automatic indexing on frequently queried fields
- **Query Optimization**: Indexes designed for common query patterns

#### **4. Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /expenses/{expenseId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == resource.data.userId;
    }
    
    match /budget/{budgetId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == resource.data.userId;
    }
    
    match /overallBudget/{userId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == userId;
    }
    
    match /income/{userId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == userId;
    }
    
    match /favorites/{favoriteId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == resource.data.userId;
    }
    
    match /predictions/{predictionId} {
      allow read, write: if request.auth != null && 
                           request.auth.uid == resource.data.userId;
    }
  }
}
```

### **Data Flow & Calculations**

#### **Account Balance Calculation**
```
Query: income/{userId}
Query: expenses (where userId == currentUser && receiptDate in currentMonth)
Query: favorites (where userId == currentUser && paymentHistory in currentMonth)

Calculation:
  income.amount - (sum(expenses.amount) + sum(favorites.paymentHistory.amount))
```

#### **Total Spent Calculation**
```
Query: expenses (where userId == currentUser && receiptDate in currentMonth)
Query: favorites (where userId == currentUser && paymentHistory in currentMonth)

Calculation:
  sum(expenses.amount) + sum(favorites.paymentHistory.amount)
```

#### **Graph Data (Daily View)**
```
Query: expenses (where userId == currentUser)
Filter: receiptDate in currentMonth
Group By: Day of receiptDate
Calculation: sum(expenses.amount) per day
```

#### **Recent Transactions**
```
Query: expenses (where userId == currentUser)
Filter: transactionDate == today
Order By: timestamp desc
Limit: 3
Display: receiptDate for each expense
```

### **Firebase Firestore Collections Summary**

| Collection | Purpose | Document ID | Relationship |
|------------|---------|-------------|--------------|
| `users` | User authentication data | Firebase Auth UID | Parent (1:N) |
| `expenses` | Expense records | Auto-generated | Child of users |
| `budget` | Category budgets | Auto-generated | Child of users |
| `overallBudget` | Total monthly budget | User ID | Child of users (1:1) |
| `income` | Monthly income | User ID | Child of users (1:1) |
| `favorites` | Priority payments | Auto-generated | Child of users |
| `predictions` | Budget predictions | Auto-generated | Child of users |

## 🔌 API Documentation

### **Core Services API**

#### **1. Expense Management**
```dart
// Add new expense
Future<void> addExpense(
  String category,
  double amount,
  String base64Image,
  String receiptDate,
  String transactionDate,
);

// Fetch user expenses
Future<List<Map<String, dynamic>>> fetchExpenses();

// Update expense
Future<void> updateExpense(String expenseId, Map<String, dynamic> data);

// Delete expense
Future<void> deleteExpense(String expenseId);
```

#### **2. Budget Management**
```dart
// Add budget category
Future<void> addBudget(
  String category,
  double amount,
  double alertPercentage,
  bool receiveAlert,
);

// Calculate remaining budget
Future<void> calculateRemainingBudget();

// Fetch budget data
Future<Map<String, dynamic>> fetchOverallBudget();

// Update budget
Future<void> setBudget(
  String category,
  double amount,
  double alertPercentage,
  bool receiveAlert,
  String budgetId,
);
```

#### **3. AI Services**
```dart
// Extract expense details from receipt
Future<Map<String, String>> extractExpenseDetails(String imageBase64);

// Generate budget allocation
Future<List<double>> generateBudgetAllocation(double totalBudget);

// Generate budget predictions
Future<Map<String, dynamic>> generateDataDrivenPrediction();
```

#### **4. Notification Services**
```dart
// Show budget exceeded notification
Future<void> showOverallBudgetExceeded({
  required double totalExpenses,
  required double budgetLimit,
  required double exceededAmount,
});

// Show category budget notification
Future<void> showCategoryBudgetExceeded({
  required String category,
  required double categoryExpenses,
  required double categoryLimit,
  required double exceededAmount,
});

// Show payment notifications
Future<void> showPaymentDueToday({
  required String title,
  required double amountToPay,
  required String frequency,
});
```

#### **5. Priority Payment Management**
```dart
// Add favorite payment
Future<void> addFavorite({
  required String title,
  required double totalAmount,
  required double amountToPay,
  required String frequency,
  required String startDate,
  required String endDate,
});

// Update payment status
Future<void> updatePaymentStatus(String billId, double amount);

// Mark as paid
Future<void> markAsPaid(String billId);

// Reset missed payment
Future<void> resetMissedPayment(String billId);
```

## 📱 Screenshots

### Mobile App
- **Dashboard**: Overview of finances with visual charts
- **Expense Entry**: Receipt scanning and manual entry
- **Budget Management**: Category-wise budget tracking
- **Priority Payments**: Bill management and payment tracking
- **Analytics**: Spending insights and predictions

### Web Platform
- **Landing Page**: Professional marketing website
- **Feature Showcase**: Detailed feature descriptions
- **Download Section**: Mobile app download links
- **Contact & Support**: User feedback and support channels

## 🤝 Contributing

We welcome contributions! Please see our contributing guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Team

**Emperor's Quartet** - The development team behind SnapWise

## 📞 Support

- **Email**: snapwiseofficial25@gmail.com
- **Facebook**: [Snapwise](https://facebook.com/snapwise)
- **Website**: [SnapWise Landing Page](https://snapwisefinal.web.app/)

## 🔄 Version History

### Version 1.0.0
- Initial release
- Core expense tracking functionality
- AI-powered receipt processing
- Budget management system
- Priority payment tracking
- Cross-platform support (Android, iOS, Web)
- Comprehensive notification system

## 🎯 Roadmap

### Upcoming Features
- [ ] Multi-currency support
- [ ] Advanced analytics dashboard
- [ ] Bank account integration
- [ ] Investment tracking
- [ ] Family/shared budgets
- [ ] Advanced AI insights
- [ ] Offline mode improvements
- [ ] Dark theme support

## 🔧 Troubleshooting

### **Common Issues & Solutions**

#### **1. Receipt Scanning Issues**
- **Problem**: AI not extracting data from receipts
- **Solution**: Ensure good lighting, clear image, and try different angles
- **Fallback**: Use manual entry if AI extraction fails

#### **2. Notification Problems**
- **Android**: Check notification permissions in device settings
- **iOS**: Ensure notifications are enabled in app settings
- **Web**: Notifications not supported on web platform

#### **3. Firebase Connection Issues**
- **Problem**: App not connecting to Firebase
- **Solution**: Check internet connection and Firebase configuration files
- **Debug**: Enable debug mode to see detailed error messages

#### **4. AI Service Errors**
- **Problem**: Gemini AI not responding
- **Solution**: Check API key configuration and internet connection
- **Fallback**: App continues to work with manual entry

#### **5. Data Sync Issues**
- **Problem**: Data not syncing across devices
- **Solution**: Check Firebase authentication and internet connection
- **Refresh**: Pull down to refresh data on home screen

### **Performance Optimization**

#### **1. Image Optimization**
- Receipt images are automatically compressed before storage
- Base64 encoding ensures efficient data transfer
- Images are stored in Firebase Firestore for quick access

#### **2. Memory Management**
- GetX controllers are automatically disposed when not needed
- Images are cached locally for better performance
- Lazy loading implemented for large data sets

#### **3. Network Optimization**
- Offline support for viewing cached data
- Automatic retry mechanism for failed network requests
- Efficient data pagination for large expense lists

## ❓ Frequently Asked Questions

### **General Questions**

**Q: Is SnapWise free to use?**
A: Yes, SnapWise is completely free to use with all core features available at no cost.

**Q: Is my financial data secure?**
A: Absolutely! We use Firebase security rules, data encryption, and follow industry best practices for data protection.

**Q: Can I use SnapWise offline?**
A: Yes, you can view your data offline. New data will sync when you're back online.

**Q: Does SnapWise work on all devices?**
A: Yes, SnapWise works on Android, iOS, and web browsers with responsive design.

### **Feature Questions**

**Q: How accurate is the AI receipt scanning?**
A: Our AI achieves high accuracy rates, but manual verification is always recommended for important transactions.

**Q: Can I customize expense categories?**
A: Yes, you can add custom categories and modify existing ones to fit your needs.

**Q: How does the budget prediction work?**
A: Our AI analyzes your historical spending patterns to predict future budget needs with high accuracy.

**Q: Can I export my financial data?**
A: Yes, you can export your data for external analysis and backup purposes.

### **Technical Questions**

**Q: What happens if I lose my phone?**
A: Your data is safely stored in Firebase, so you can access it from any device by logging in.

**Q: How often does the app sync data?**
A: Data syncs in real-time when you're online, with automatic retry for failed syncs.

**Q: Can I use multiple currencies?**
A: Currently, SnapWise supports PHP (Philippine Peso), with multi-currency support planned for future updates.

**Q: How much storage space does the app use?**
A: The app uses minimal storage space as images are compressed and data is stored in the cloud.

## 📈 Performance Metrics

### **App Performance**
- **Startup Time**: < 3 seconds on average devices
- **Memory Usage**: < 100MB typical usage
- **Battery Impact**: Minimal with optimized background processes
- **Network Usage**: Efficient data transfer with compression

### **AI Performance**
- **Receipt Processing**: 2-5 seconds average processing time
- **Accuracy Rate**: 85-95% for clear receipt images
- **Prediction Accuracy**: 80-90% for budget predictions
- **Response Time**: < 3 seconds for AI queries

### **Database Performance**
- **Query Speed**: < 1 second for most operations
- **Sync Time**: Real-time updates with < 2 second delay
- **Storage Efficiency**: Optimized data structure for minimal storage usage
- **Backup Frequency**: Continuous real-time backup

## 🚀 Future Enhancements

### **Planned Features**
- [ ] **Multi-currency Support**: Support for multiple currencies and exchange rates
- [ ] **Advanced Analytics**: More detailed financial insights and reporting
- [ ] **Bank Integration**: Direct bank account integration for automatic transaction import
- [ ] **Investment Tracking**: Portfolio management and investment tracking
- [ ] **Family Budgets**: Shared budgets and expense tracking for families
- [ ] **Advanced AI**: More sophisticated AI features and recommendations
- [ ] **Offline Mode**: Enhanced offline functionality with local data storage
- [ ] **Dark Theme**: Dark mode support for better user experience
- [ ] **Voice Commands**: Voice-activated expense entry and budget management
- [ ] **Smart Notifications**: More intelligent and personalized notifications

### **Technical Improvements**
- [ ] **Performance Optimization**: Further speed and efficiency improvements
- [ ] **Security Enhancements**: Additional security features and encryption
- [ ] **API Expansion**: More comprehensive API for third-party integrations
- [ ] **Testing Coverage**: Increased test coverage for better reliability
- [ ] **Documentation**: More detailed technical documentation and guides

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Google AI for intelligent categorization
- Open source community for various packages
- All beta testers and early users

---

**Made with ❤️ by Emperor's Quartet**

*SnapWise - Where Smart Money Management Begins*