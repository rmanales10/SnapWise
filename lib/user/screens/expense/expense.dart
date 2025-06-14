import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapwise/user/screens/expense/expense_controller.dart';
import 'package:snapwise/user/screens/expense/gemini_ai.dart';
import 'package:snapwise/user/screens/home/home_screens/home_controller.dart';
import 'package:snapwise/user/screens/widget/bottomnavbar.dart';

class ExpenseManualPage extends StatefulWidget {
  const ExpenseManualPage({super.key});

  @override
  State<ExpenseManualPage> createState() => _ExpenseManualPageState();
}

class _ExpenseManualPageState extends State<ExpenseManualPage> {
  String? base64Image;
  final ImagePicker picker = ImagePicker();
  final GeminiAi aiController = Get.put(GeminiAi());
  final controller = Get.put(ExpenseController());
  final homeController = Get.put(HomeController());
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  @override
  void initState() {
    super.initState();
    controller.fetchCategories();
    dateController.text = DateTime.now().toString().split(' ')[0];
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            // Header background
            Container(
              height: isTablet ? 400 : 250,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 3, 30, 53),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Expense",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Overlapping white container
            Positioned(
              top: isTablet ? 280 : 210,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(width: 1, color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    _buildCategorySelector(),
                    const SizedBox(height: 20),
                    _buildAmountInput(),
                    const SizedBox(height: 20),
                    _buildDateInput(),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade600,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "or",
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: Colors.grey.shade600,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        if (base64Image != null) {
                          _showImagePreview(context);
                        } else {
                          _showImageSourceBottomSheet(context);
                        }
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1,
                            color: Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (base64Image == null) ...[
                              Icon(
                                Icons.attachment_rounded,
                                color: Colors.grey.shade700,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Add attachment',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ] else ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  base64Decode(base64Image!),
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'View Image',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showConfirmation(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImageSourceBottomSheet(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    final bool isTablet =
        MediaQueryData.fromView(
          // ignore: deprecated_member_use
          WidgetsBinding.instance.window,
        ).size.shortestSide >
        600;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(isTablet ? 50 : 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Camera Option
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        await _processAndDisplayImage(image);
                      }
                    },
                    child: Container(
                      width: isTablet ? 150 : 120,
                      height: isTablet ? 120 : 100,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 30,
                            color: Color.fromARGB(255, 3, 30, 53),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Camera',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 3, 30, 53),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Gallery Option
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 85,
                      );
                      if (image != null) {
                        await _processAndDisplayImage(image);
                      }
                    },
                    child: Container(
                      width: isTablet ? 150 : 120,
                      height: isTablet ? 120 : 100,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_library,
                            size: 30,
                            color: Color.fromARGB(255, 3, 30, 53),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gallery',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 3, 30, 53),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _processAndDisplayImage(XFile image) async {
    try {
      // Read the file as bytes
      Uint8List imageBytes = await image.readAsBytes();

      // Convert to base64
      String base64String = base64Encode(imageBytes);

      // Update the base64Image first
      setState(() {
        base64Image = base64String;
      });

      // Process with AI
      Map<String, String>? expenseDetails = await aiController
          .extractExpenseDetails(base64String);

      await controller.fetchCategories();
      await controller.addCategory(expenseDetails['category'] ?? '');

      setState(() {
        categoryController.text = expenseDetails['category'] ?? '';
        amountController.text = expenseDetails['amount'] ?? '';
        dateController.text =
            expenseDetails['date'] ?? DateTime.now().toString().split(' ')[0];
      });

      if (expenseDetails['category']?.isEmpty == true ||
          expenseDetails['amount']?.isEmpty == true ||
          expenseDetails['date']?.isEmpty == true) {
        _showErrorSnackbar(
          'Failed to extract some expense details. Please check and enter manually if needed.',
        );
      }

      // Show image preview
      // ignore: use_build_context_synchronously
      _showImagePreview(context);
    } catch (e) {
      _showErrorSnackbar(
        'Error processing the image. Please try again or enter details manually.',
      );
    }
  }

  void _showImagePreview(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.7,
              maxWidth: isTablet ? 500 : double.infinity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 3, 30, 53),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Receipt Preview',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Image Preview
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: screenHeight * 0.4,
                          ),
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(base64Image!),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),

                        // Extracted Details
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Extracted Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 3, 30, 53),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Category',
                                categoryController.text,
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow('Amount', amountController.text),
                              const SizedBox(height: 8),
                              _buildDetailRow('Date', dateController.text),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              3,
                              30,
                              53,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Done',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(':', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not detected' : value,
            style: TextStyle(
              fontSize: 14,
              color: value.isEmpty ? Colors.grey : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar('Error', message, colorText: Colors.white);
  }

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(
        () => DropdownButtonFormField<String>(
          focusColor: Colors.white,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(20),
          value:
              controller.categories.contains(categoryController.text)
                  ? categoryController.text
                  : (controller.categories.isNotEmpty
                      ? controller.categories.first
                      : null),
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: const InputDecoration(border: InputBorder.none),
          items: [
            ...controller.categories.map(
              (value) => DropdownMenuItem(
                value: value,
                child: Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
            const DropdownMenuItem(
              value: '__add_new__',
              child: Text("Add New"),
            ),
          ],
          onChanged: (value) async {
            if (value == '__add_new__') {
              String? newCategory = await _showAddCategoryBottomSheet(context);

              if (newCategory != null && newCategory.isNotEmpty) {
                await controller.addCategory(newCategory);
                setState(() {
                  categoryController.text = newCategory;
                });
              }
            } else if (value != null) {
              setState(() {
                categoryController.text = value;
              });
            }
          },
        ),
      ),
    );
  }

  Future<String?> _showAddCategoryBottomSheet(BuildContext context) async {
    final TextEditingController newCategoryController = TextEditingController();
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: isTablet ? 40 : 25,
            right: isTablet ? 40 : 25,
            top: isTablet ? 30 : 20,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + (isTablet ? 30 : 20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top handle
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Text(
                'Add New Category',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                cursorColor: const Color.fromARGB(255, 3, 30, 53),
                controller: newCategoryController,
                decoration: InputDecoration(
                  hintText: 'Enter category name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 12,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: isTablet ? 18 : 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final newCategory = newCategoryController.text.trim();
                        if (newCategory.isNotEmpty) {
                          Navigator.pop(context, newCategory);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 12,
                        ),
                      ),
                      child: Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showConfirmation(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isTablet = screenWidth >= 600;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 40 : 25,
            vertical: isTablet ? 30 : 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 40,
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Text(
                'Confirmation',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to save expense?',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 12,
                        ),
                      ),
                      child: Text(
                        'No',
                        style: TextStyle(fontSize: isTablet ? 18 : 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _addExpense(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 3, 30, 53),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: isTablet ? 16 : 12,
                        ),
                      ),
                      child: Text(
                        'Yes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 18 : 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAmountInput() {
    return TextField(
      cursorColor: const Color.fromARGB(255, 3, 30, 53),
      controller: amountController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],

      decoration: InputDecoration(
        hintText: "Amount",
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Widget _buildDateInput() {
    return TextField(
      cursorColor: const Color.fromARGB(255, 3, 30, 53),
      controller: dateController,
      readOnly: true,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            dateController.text = picked.toString().split(' ')[0];
          });
        }
      },
      decoration: InputDecoration(
        hintText: "Date",
        suffixIcon: Icon(Icons.calendar_today, color: Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  Future<void> _addExpense() async {
    await controller.addExpense(
      categoryController.text,
      double.parse(amountController.text),
      base64Image ?? 'No Image',
      dateController.text,
    );
    if (controller.isSuccess.value == true) {
      homeController.fetchTransactions();
      homeController.fetchTransactionsHistory();
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => BottomNavBar()),
      );
      categoryController.clear();
      amountController.clear();
    }
  }
}
