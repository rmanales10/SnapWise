import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Default settings - all enabled by default
  static const bool _defaultExpenseAlerts = true;
  static const bool _defaultBudgetAlerts = true;
  static const bool _defaultIncomeAlerts = true;
  static const bool _defaultFavoritesAlerts = true;

  // Reactive variables
  final RxBool expenseAlertsEnabled = _defaultExpenseAlerts.obs;
  final RxBool budgetAlertsEnabled = _defaultBudgetAlerts.obs;
  final RxBool incomeAlertsEnabled = _defaultIncomeAlerts.obs;
  final RxBool favoritesAlertsEnabled = _defaultFavoritesAlerts.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  /// Load settings from Firestore
  Future<void> _loadSettings() async {
    try {
      isLoading.value = true;
      final user = _auth.currentUser;
      if (user == null) {
        // If no user, use default values
        _setDefaultValues();
        return;
      }

      final doc = await _firestore
          .collection('notificationSettings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        expenseAlertsEnabled.value =
            data['expenseAlerts'] ?? _defaultExpenseAlerts;
        budgetAlertsEnabled.value =
            data['budgetAlerts'] ?? _defaultBudgetAlerts;
        incomeAlertsEnabled.value =
            data['incomeAlerts'] ?? _defaultIncomeAlerts;
        favoritesAlertsEnabled.value =
            data['favoritesAlerts'] ?? _defaultFavoritesAlerts;
      } else {
        // If no document exists, create one with default values
        _setDefaultValues();
        await _saveSettingsToFirestore();
      }
    } catch (e) {
      print('Error loading notification settings: $e');
      _setDefaultValues();
    } finally {
      isLoading.value = false;
    }
  }

  /// Set default values
  void _setDefaultValues() {
    expenseAlertsEnabled.value = _defaultExpenseAlerts;
    budgetAlertsEnabled.value = _defaultBudgetAlerts;
    incomeAlertsEnabled.value = _defaultIncomeAlerts;
    favoritesAlertsEnabled.value = _defaultFavoritesAlerts;
  }

  /// Update expense alerts setting
  Future<void> updateExpenseAlerts(bool enabled) async {
    expenseAlertsEnabled.value = enabled;
    await _saveSettingsToFirestore();
  }

  /// Update budget alerts setting
  Future<void> updateBudgetAlerts(bool enabled) async {
    budgetAlertsEnabled.value = enabled;
    await _saveSettingsToFirestore();
  }

  /// Update income alerts setting
  Future<void> updateIncomeAlerts(bool enabled) async {
    incomeAlertsEnabled.value = enabled;
    await _saveSettingsToFirestore();
  }

  /// Update favorites alerts setting
  Future<void> updateFavoritesAlerts(bool enabled) async {
    favoritesAlertsEnabled.value = enabled;
    await _saveSettingsToFirestore();
  }

  /// Check if expense alerts are enabled
  bool get isExpenseAlertsEnabled => expenseAlertsEnabled.value;

  /// Check if budget alerts are enabled
  bool get isBudgetAlertsEnabled => budgetAlertsEnabled.value;

  /// Check if income alerts are enabled
  bool get isIncomeAlertsEnabled => incomeAlertsEnabled.value;

  /// Check if favorites alerts are enabled
  bool get isFavoritesAlertsEnabled => favoritesAlertsEnabled.value;

  /// Get all settings as a map
  Map<String, bool> getAllSettings() {
    return {
      'expenseAlerts': isExpenseAlertsEnabled,
      'budgetAlerts': isBudgetAlertsEnabled,
      'incomeAlerts': isIncomeAlertsEnabled,
      'favoritesAlerts': isFavoritesAlertsEnabled,
    };
  }

  /// Save settings to Firestore
  Future<void> _saveSettingsToFirestore() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('notificationSettings').doc(user.uid).set({
        'expenseAlerts': expenseAlertsEnabled.value,
        'budgetAlerts': budgetAlertsEnabled.value,
        'incomeAlerts': incomeAlertsEnabled.value,
        'favoritesAlerts': favoritesAlertsEnabled.value,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }

  /// Reset all settings to default
  Future<void> resetToDefaults() async {
    _setDefaultValues();
    await _saveSettingsToFirestore();
  }
}
