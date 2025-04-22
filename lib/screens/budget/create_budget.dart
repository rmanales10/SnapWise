// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:snapwise/screens/budget/budget_controller.dart';
import 'package:snapwise/screens/expense/expense_controller.dart';
import 'package:snapwise/screens/widget/bottomnavbar.dart';

class CreateBudget extends StatefulWidget {
  const CreateBudget({super.key});

  @override
  State<CreateBudget> createState() => _CreateBudgetState();
}

class _CreateBudgetState extends State<CreateBudget> {
  bool isOverall = true;
  bool receiveAlert = false;
  double alertPercentage = 80.0;
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController(
    text: null,
  );
  final _budgetController = Get.put(BudgetController());
  final _expensecontroller = Get.put(ExpenseController());

  @override
  void initState() {
    super.initState();
    fetchOverallBudget();
  }

  Future<void> fetchOverallBudget() async {
    await _budgetController.fetchOverallBudget();
    setState(() {
      alertPercentage =
          _budgetController.budgetData.value['alertPercentage'] as double;
      receiveAlert = _budgetController.budgetData.value['receiveAlert'] as bool;
    });
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
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      ),

                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          "Create Budget",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 300),
                          top: 2.5,
                          right:
                              isOverall
                                  ? MediaQuery.of(context).size.width / 2 - 20
                                  : 3,
                          left:
                              isOverall
                                  ? 3
                                  : MediaQuery.of(context).size.width / 2 - 20,
                          child: Container(
                            width: MediaQuery.of(context).size.width / 2 - 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 3, 30, 53),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isOverall = true),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Overall',
                                    style: TextStyle(
                                      color:
                                          isOverall
                                              ? Colors.white
                                              : Colors.black.withOpacity(0.7),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isOverall = false),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Category',
                                    style: TextStyle(
                                      color:
                                          isOverall
                                              ? Colors.black.withOpacity(0.7)
                                              : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    isOverall
                        ? "Set your budget"
                        : "How much do you want to spend?",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Category selector (only visible when not overall)
                    if (!isOverall) ...[
                      _buildCategorySelector(),
                      const SizedBox(height: 20),
                    ],

                    _buildAmountInput(),

                    const SizedBox(height: 20),

                    // Receive alert toggle
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Receive Alert",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Receive alert when it reaches some point.",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 0.8, // Increase size (e.g. 0.8 for smaller)
                          child: Switch(
                            value: receiveAlert,
                            onChanged: (value) {
                              setState(() {
                                receiveAlert = value;
                              });
                            },
                            activeTrackColor: const Color.fromARGB(
                              255,
                              3,
                              30,
                              53,
                            ),
                            inactiveTrackColor: const Color.fromARGB(
                              255,
                              3,
                              30,
                              53,
                            ),
                            activeColor: Colors.white,
                            inactiveThumbColor: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape: _PercentageThumbShape(),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 0,
                        ),
                        activeTrackColor: const Color.fromARGB(255, 3, 30, 53),
                        inactiveTrackColor: Colors.grey.shade300,
                        trackHeight: 4,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: alertPercentage,
                        min: 0,
                        max: 100,
                        label: "${alertPercentage.round()}%",
                        onChanged: (value) {
                          setState(() {
                            alertPercentage = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Create Budget button
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
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          "Set Budget",
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
                'Are you sure you want to save budget?',
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
                      onPressed: () {
                        if (categoryController.text.isNotEmpty &&
                            amountController.text.isNotEmpty) {
                          setBudgetCategory();
                        }
                        if (amountController.text.isNotEmpty &&
                            categoryController.text.isEmpty) {
                          setOverallBudget();
                        }
                        Navigator.pop(context);
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

  Widget _buildCategorySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        focusColor: Colors.white,
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(20),
        value:
            categoryController.text.isNotEmpty ? categoryController.text : null,
        icon: const Icon(Icons.keyboard_arrow_down),
        decoration: const InputDecoration(border: InputBorder.none),
        items: [
          ..._expensecontroller.categories.map(
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
          const DropdownMenuItem(value: '__add_new__', child: Text("Add New")),
        ],
        onChanged: (value) async {
          if (value == '__add_new__') {
            String? newCategory = await _showAddCategoryBottomSheet(context);

            if (newCategory != null && newCategory.isNotEmpty) {
              setState(() {
                _expensecontroller.categories.add(newCategory);
                categoryController.text = newCategory;
              });
              // Force rebuild of dropdown
              setState(() {});
            }
          } else if (value != null) {
            setState(() {
              categoryController.text = value;
            });
          }
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

  Widget _buildAmountInput() {
    return TextField(
      cursorColor: const Color.fromARGB(255, 3, 30, 53),
      enabled: amountController.text.isNotEmpty ? false : true,
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
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
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

  Future<void> setBudgetCategory() async {
    await _budgetController.addBudget(
      categoryController.text,
      double.parse(amountController.text),
      alertPercentage,
      receiveAlert,
    );
    if (_budgetController.isSuccess.value == true) {
      categoryController.clear();
      amountController.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavBar(initialIndex: 2)),
      );
      Get.snackbar('Success', 'Budget added successfully');
    }
  }

  Future<void> setOverallBudget() async {
    await _budgetController.addOverallBudget(
      double.parse(amountController.text),
      alertPercentage,
      receiveAlert,
    );
    if (_budgetController.isSuccess.value == true) {
      amountController.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavBar(initialIndex: 2)),
      );
      Get.snackbar('Success', 'Overall Budget added successfully');
    }
  }
}

class _PercentageThumbShape extends SliderComponentShape {
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(40, 40);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    // Define the thumb circle
    final rect = Rect.fromCenter(center: center, width: 40, height: 20);
    final fillPaint =
        Paint()
          ..color = const Color(0xFF7F3DFF)
          ..style = PaintingStyle.fill;

    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;

    // Draw thumb
    canvas.drawOval(rect, fillPaint);
    canvas.drawOval(rect, borderPaint);

    // Draw dynamic percentage text
    final percentageText = '${(value * 100).round()}%';
    final textPainter = TextPainter(
      text: TextSpan(
        text: percentageText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
    )..layout();

    // Center the text inside the thumb
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
}
