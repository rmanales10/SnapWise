import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapwise/app/expense/expense_controller.dart';
import 'package:snapwise/app/widget/bottomnavbar.dart';
import '../../services/snackbar_service.dart';

class ViewExpense extends StatefulWidget {
  final String expenseId;
  const ViewExpense({super.key, required this.expenseId});

  @override
  State<ViewExpense> createState() => _ViewExpenseState();
}

class _ViewExpenseState extends State<ViewExpense> {
  String? base64Image;
  final ImagePicker picker = ImagePicker();
  final controller = Get.put(ExpenseController());
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController(
    text: "Shopping",
  );
  final TextEditingController dateController =
      TextEditingController(); // Transaction date
  final TextEditingController receiptDateController =
      TextEditingController(); // Receipt date
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await controller.fetchCategories();
    await controller.fetchExpense(widget.expenseId);
    setState(() {
      amountController.text = controller.expenses['amount'].toString();
      categoryController.text = controller.expenses['category'].toString();
      // Use receipt date if available, otherwise use transaction date, otherwise current date
      receiptDateController.text = controller.expenses['receiptDate'] ??
          controller.expenses['date'] ??
          DateTime.now().toString().split(' ')[0];
      dateController.text = controller.expenses['transactionDate'] ??
          controller.expenses['date'] ??
          DateTime.now().toString().split(' ')[0];
      base64Image = controller.expenses['base64Image'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      resizeToAvoidBottomInset: true,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
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
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: isTablet ? 28 : 24,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Expense",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isTablet ? 22 : 18,
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
              bottom: 0, // Extend to bottom for scrolling
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(width: 1, color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(isTablet ? 30 : 20),
                  child: Column(
                    children: [
                      _buildCategorySelectorWithLabel(),
                      SizedBox(height: isTablet ? 25 : 20),
                      _buildAmountInputWithLabel(),
                      SizedBox(height: isTablet ? 25 : 20),
                      _buildDateInputWithLabel(),
                      SizedBox(height: isTablet ? 25 : 20),
                      _buildReceiptDateInputWithLabel(),
                      SizedBox(height: isTablet ? 25 : 20),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade600,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: isTablet ? 20 : 16),
                            child: Text(
                              "or",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: isTablet ? 18 : 16,
                              ),
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
                      SizedBox(height: isTablet ? 25 : 20),
                      GestureDetector(
                        onTap: () {
                          if (base64Image != null &&
                              base64Image != 'No Image' &&
                              base64Image!.isNotEmpty) {
                            _showImagePreview(context);
                          } else {
                            _showImageSourceBottomSheet(context);
                          }
                        },
                        child: Container(
                          height: isTablet ? 60 : 50,
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
                              if (base64Image == null ||
                                  base64Image == 'No Image' ||
                                  base64Image!.isEmpty) ...[
                                Icon(
                                  Icons.attachment_rounded,
                                  color: Colors.grey.shade700,
                                  size: isTablet ? 24 : 20,
                                ),
                                SizedBox(width: isTablet ? 15 : 10),
                                Text(
                                  'Add attachment',
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 17,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ] else ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Builder(
                                    builder: (BuildContext context) {
                                      try {
                                        return Image.memory(
                                          base64Decode(base64Image!),
                                          width: isTablet ? 50 : 40,
                                          height: isTablet ? 50 : 40,
                                          fit: BoxFit.cover,
                                        );
                                      } catch (e) {
                                        // Handle the error (e.g., show a placeholder or error icon)
                                        return Container(
                                          width: isTablet ? 50 : 40,
                                          height: isTablet ? 50 : 40,
                                          color: Colors.grey.shade300,
                                          child: Icon(
                                            Icons.broken_image,
                                            color: Colors.grey.shade600,
                                            size: isTablet ? 24 : 20,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(width: isTablet ? 15 : 10),
                                Text(
                                  'View Image',
                                  style: TextStyle(
                                    fontSize: isTablet ? 20 : 17,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 30 : 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _showConfirmation(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 3, 30, 53),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 18 : 14,
                            ),
                          ),
                          child: Text(
                            "Save",
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isTablet ? 20 : 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _showConfirmationDelete(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: isTablet ? 18 : 14,
                            ),
                          ),
                          child: Text(
                            "Delete",
                            style: TextStyle(
                              fontSize: isTablet ? 20 : 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Add extra padding at bottom for better scrolling experience
                      SizedBox(height: isTablet ? 40 : 30),
                    ],
                  ),
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

    final bool isTablet = MediaQueryData.fromView(
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

      setState(() {
        base64Image = base64String;
      });

      // Show the image preview
      // ignore: use_build_context_synchronously
      _showImagePreview(context);
    } catch (e) {
      _showErrorSnackbar('Error processing the image. Please try again.');
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
                            child: Builder(
                              builder: (context) {
                                try {
                                  return Image.memory(
                                    base64Decode(base64Image!),
                                    fit: BoxFit.contain,
                                  );
                                } catch (e) {
                                  return Container(
                                    height: 200,
                                    color: Colors.grey.shade300,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          color: Colors.grey.shade600,
                                          size: 50,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Unable to display image',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
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
                                'Expense Details',
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

  Widget _buildConfirmationRow(String label, String value) {
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
            value,
            style: TextStyle(
              fontSize: 14,
              color: value.contains('Not') ? Colors.red : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showErrorSnackbar(String message) {
    SnackbarService.showExpenseError(message);
  }

  List<String> categories = [
    'Shopping',
    'Food',
    'Transport',
    'Rent',
    'Entertainment',
  ];
  Widget _buildCategorySelectorWithLabel() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        _buildCategorySelector(),
      ],
    );
  }

  Widget _buildCategorySelector() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 8 : 4,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Obx(
        () {
          // Ensure we have a valid selected value
          String? selectedValue;
          if (categoryController.text.isNotEmpty &&
              controller.categories.contains(categoryController.text)) {
            selectedValue = categoryController.text;
          } else if (controller.categories.isNotEmpty) {
            selectedValue = controller.categories.first;
            // Auto-set the first category if none is selected
            if (categoryController.text.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  categoryController.text = selectedValue!;
                });
              });
            }
          }

          return DropdownButtonFormField<String>(
            focusColor: Colors.white,
            dropdownColor: Colors.white,
            borderRadius: BorderRadius.circular(20),
            value: selectedValue,
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: isTablet ? 28 : 24,
            ),
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
                      fontSize: isTablet ? 18 : 16,
                    ),
                  ),
                ),
              ),
              DropdownMenuItem(
                value: '__add_new__',
                child: Text(
                  "Add New",
                  style: TextStyle(fontSize: isTablet ? 18 : 16),
                ),
              ),
            ],
            onChanged: (value) async {
              if (value == '__add_new__') {
                String? newCategory =
                    await _showAddCategoryBottomSheet(context);

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
          );
        },
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
                'Are you sure you want to save this expense?',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: isTablet ? 18 : 16,
                ),
              ),
              const SizedBox(height: 15),
              // Show expense details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expense Details:',
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 3, 30, 53),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildConfirmationRow(
                        'Category',
                        categoryController.text.isEmpty
                            ? 'Not selected'
                            : categoryController.text),
                    const SizedBox(height: 4),
                    _buildConfirmationRow(
                        'Amount',
                        amountController.text.isEmpty
                            ? 'Not entered'
                            : '₱${amountController.text}'),
                    const SizedBox(height: 4),
                    _buildConfirmationRow(
                        'Transaction Date',
                        dateController.text.isEmpty
                            ? 'Not selected'
                            : dateController.text),
                    const SizedBox(height: 4),
                    _buildConfirmationRow(
                        'Receipt Date',
                        receiptDateController.text.isEmpty
                            ? 'Not selected'
                            : receiptDateController.text),
                    const SizedBox(height: 4),
                    _buildConfirmationRow(
                        'Attachment',
                        base64Image == null || base64Image == 'No Image'
                            ? 'None'
                            : 'Image attached'),
                  ],
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

  void _showConfirmationDelete(BuildContext context) {
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
                'Are you sure you want to delete expense?',
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
                      onPressed: () async {
                        controller.deleteExpense(widget.expenseId);
                        await controller.fetchCategories();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => BottomNavBar(),
                          ),
                        );
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

  Widget _buildAmountInputWithLabel() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        _buildAmountInput(),
      ],
    );
  }

  Widget _buildAmountInput() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return TextField(
      cursorColor: const Color.fromARGB(255, 3, 30, 53),
      controller: amountController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: TextStyle(fontSize: isTablet ? 18 : 16),
      decoration: InputDecoration(
        hintText: "Amount",
        hintStyle: TextStyle(fontSize: isTablet ? 18 : 16),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 18 : 14,
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

  Widget _buildDateInputWithLabel() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Date (When Entered)',
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        _buildDateInput(),
      ],
    );
  }

  Widget _buildDateInput() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return TextField(
      cursorColor: const Color.fromARGB(255, 3, 30, 53),
      controller: dateController,
      readOnly: true,
      style: TextStyle(fontSize: isTablet ? 18 : 16),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.tryParse(dateController.text) ?? DateTime.now(),
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
        hintText: "Select transaction date",
        hintStyle: TextStyle(fontSize: isTablet ? 18 : 16),
        suffixIcon: Icon(
          Icons.calendar_today,
          color: Colors.grey.shade600,
          size: isTablet ? 24 : 20,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 18 : 14,
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

  Widget _buildReceiptDateInputWithLabel() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receipt Date (Purchase Date)',
          style: TextStyle(
            fontSize: isTablet ? 20 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: isTablet ? 12 : 8),
        _buildReceiptDateInput(),
      ],
    );
  }

  Widget _buildReceiptDateInput() {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    return TextField(
      cursorColor: const Color.fromARGB(255, 3, 30, 53),
      controller: receiptDateController,
      readOnly: true,
      style: TextStyle(fontSize: isTablet ? 18 : 16),
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate:
              DateTime.tryParse(receiptDateController.text) ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            receiptDateController.text = picked.toString().split(' ')[0];
          });
        }
      },
      decoration: InputDecoration(
        hintText: "Select receipt date",
        hintStyle: TextStyle(fontSize: isTablet ? 18 : 16),
        suffixIcon: Icon(
          Icons.receipt_long,
          color: Colors.grey.shade600,
          size: isTablet ? 24 : 20,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: isTablet ? 20 : 16,
          vertical: isTablet ? 18 : 14,
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
    // Validate inputs before saving
    if (categoryController.text.isEmpty) {
      _showErrorSnackbar('Please select a category');
      return;
    }

    if (amountController.text.isEmpty) {
      _showErrorSnackbar('Please enter an amount');
      return;
    }

    if (dateController.text.isEmpty) {
      _showErrorSnackbar('Please select a transaction date');
      return;
    }

    if (receiptDateController.text.isEmpty) {
      _showErrorSnackbar('Please select a receipt date');
      return;
    }

    try {
      await controller.addExpense(
        categoryController.text,
        double.parse(amountController.text),
        base64Image ?? 'No Image',
        receiptDateController.text, // Receipt date (for graph)
        dateController.text, // Transaction date (when input)
      );
      if (controller.isSuccess.value == true) {
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => BottomNavBar()),
        );
        categoryController.clear();
        amountController.clear();
      }
    } catch (e) {
      _showErrorSnackbar('Error saving expense: ${e.toString()}');
    }
  }
}
