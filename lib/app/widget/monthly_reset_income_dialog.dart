import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../budget/budget_controller.dart';
import '../../services/snackbar_service.dart';

/// Blocking dialog that appears after monthly reset to require user to set income
class MonthlyResetIncomeDialog extends StatefulWidget {
  const MonthlyResetIncomeDialog({super.key});

  @override
  State<MonthlyResetIncomeDialog> createState() =>
      _MonthlyResetIncomeDialogState();

  /// Show the dialog (blocking - cannot be dismissed without setting income)
  static Future<void> show() async {
    return Get.dialog(
      const MonthlyResetIncomeDialog(),
      barrierDismissible: false, // Cannot dismiss by tapping outside
      barrierColor: Colors.black54,
    );
  }
}

class _MonthlyResetIncomeDialogState extends State<MonthlyResetIncomeDialog> {
  final _budgetController = Get.put(BudgetController());
  final _amountController = TextEditingController();
  bool _receiveAlert = false;
  double _alertPercentage = 80.0;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 500 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          const Color.fromARGB(255, 3, 30, 53).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Color.fromARGB(255, 3, 30, 53),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Monthly Income',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Please set your monthly income to continue using the app.',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Amount Input
              Text(
                'Monthly Income',
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter your monthly income',
                  prefixText: '₱ ',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color.fromARGB(255, 3, 30, 53),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Alert Settings
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Enable Spending Alert',
                            style: TextStyle(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Switch(
                          value: _receiveAlert,
                          onChanged: (value) {
                            setState(() {
                              _receiveAlert = value;
                            });
                          },
                          activeColor: const Color.fromARGB(255, 3, 30, 53),
                        ),
                      ],
                    ),
                    if (_receiveAlert) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Alert when ${_alertPercentage.toStringAsFixed(0)}% of income is spent',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _alertPercentage,
                        min: 50,
                        max: 100,
                        divisions: 10,
                        label: '${_alertPercentage.toStringAsFixed(0)}%',
                        activeColor: const Color.fromARGB(255, 3, 30, 53),
                        onChanged: (value) {
                          setState(() {
                            _alertPercentage = value;
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveIncome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Save Income & Continue',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveIncome() async {
    // Validate amount
    if (_amountController.text.trim().isEmpty) {
      SnackbarService.showIncomeError('Please enter your income amount');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      SnackbarService.showIncomeError('Please enter a valid income amount');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Add timeout to prevent infinite loading
      await _budgetController
          .addIncome(
        amount,
        _alertPercentage,
        _receiveAlert,
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Save operation timed out. Please check your internet connection.');
        },
      );

      // Check if save was successful immediately after addIncome completes
      if (_budgetController.isSuccess.value) {
        if (mounted) {
          Get.back(); // Close dialog immediately
          // Show snackbar AFTER closing dialog
          SnackbarService.showIncomeSuccess('Income set successfully!');
        }
      } else {
        // If isSuccess is still false, something went wrong
        SnackbarService.showIncomeError(
            'Failed to save income. Please try again.');
        setState(() {
          _isSaving = false;
        });
      }
    } catch (e) {
      // Handle any errors (including timeout)
      SnackbarService.showIncomeError('Error: ${e.toString()}');
      setState(() {
        _isSaving = false;
      });
    }
  }
}
