import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:snapwise/app/budget/budget_controller.dart';
import 'package:snapwise/app/expense/expense_controller.dart';
import 'package:snapwise/app/profile/favorites/favorite_controller.dart';
import 'package:snapwise/app/widget/bottomnavbar.dart';
import '../../services/snackbar_service.dart';

// ignore: must_be_immutable
class EditBudgetCategoryPage extends StatefulWidget {
  final String budgetId;
  final String category;
  final double amount;
  bool receiveAlert;
  double alertPercentage;

  EditBudgetCategoryPage({
    super.key,
    this.budgetId = '',
    this.category = "Shopping",
    this.amount = 0.0,
    this.receiveAlert = false,
    this.alertPercentage = 80.0,
  });

  @override
  State<EditBudgetCategoryPage> createState() => _EditBudgetCategoryPageState();
}

class _EditBudgetCategoryPageState extends State<EditBudgetCategoryPage> {
  bool isOverall = true;
  bool isdelete = true;
  final _budgetController = Get.put(BudgetController());
  final _expensecontroller = Get.put(ExpenseController());
  final _favoriteController = Get.put(FavoriteController());
  final TextEditingController amountController = TextEditingController();
  final TextEditingController categoryController = TextEditingController(
    text: "Shopping",
  );
  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    setState(() {
      amountController.text = widget.amount.toString();
      categoryController.text = widget.category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // bottomNavigationBar: CustomBottomNavBar(
      //   currentIndex: _selectedIndex,
      //   onTap: _onNavItemTapped,
      // ),
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
                          "Edit Budget Category",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    "How much do you want to spend?",
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
                  border: Border.all(width: 1, color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    _buildCategorySelector(),
                    const SizedBox(height: 20),
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
                            value: widget.receiveAlert,
                            onChanged: (value) {
                              setState(() {
                                widget.receiveAlert = value;
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
                        value: widget.alertPercentage,
                        min: 0,
                        max: 100,
                        label: "${widget.alertPercentage.round()}%",
                        onChanged: (value) {
                          setState(() {
                            widget.alertPercentage = value;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: isTablet ? 200 : 120,
                          child: ElevatedButton(
                            onPressed: () {
                              _showConfirmation(context, isdelete: true);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                175,
                                43,
                                3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Delete",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: isTablet ? 200 : 120,
                          child: ElevatedButton(
                            onPressed: () {
                              _showConfirmation(context, isdelete: false);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                3,
                                30,
                                53,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              "Save",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildCategorySelector() {
    // Get all available categories (expense categories + favorites categories)
    List<String> allCategories = List.from(_expensecontroller.categories);

    // Add favorites categories that are not already in expense categories
    Set<String> existingCategories =
        _expensecontroller.categories.map((cat) => cat.toLowerCase()).toSet();

    for (var favorite in _favoriteController.favorites) {
      String title = favorite['title'] ?? '';
      if (title.isNotEmpty &&
          !existingCategories.contains(title.toLowerCase())) {
        allCategories.add(title);
      }
    }

    // Create dropdown items with duplicate prevention
    List<DropdownMenuItem<String>> dropdownItems = [];
    Set<String> usedValues = <String>{};

    // Add regular expense categories
    for (String category in _expensecontroller.categories) {
      if (!usedValues.contains(category)) {
        dropdownItems.add(DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(
                Icons.category,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ));
        usedValues.add(category);
      }
    }

    // Add favorites categories (only those not already in expense categories)
    for (String category in allCategories) {
      if (!_expensecontroller.categories.contains(category) &&
          !usedValues.contains(category)) {
        dropdownItems.add(DropdownMenuItem(
          value: category,
          child: Row(
            children: [
              Icon(
                Icons.favorite,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Text(
                category,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Favorites',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ));
        usedValues.add(category);
      }
    }

    // Add "Add New" option
    dropdownItems.add(
        const DropdownMenuItem(value: '__add_new__', child: Text("Add New")));

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
        value: categoryController.text.isNotEmpty &&
                usedValues.contains(categoryController.text)
            ? categoryController.text
            : null,
        icon: const Icon(Icons.keyboard_arrow_down),
        decoration: const InputDecoration(border: InputBorder.none),
        items: dropdownItems,
        onChanged: (value) async {
          if (value == '__add_new__') {
            String? newCategory = await _showAddCategoryBottomSheet(context);

            if (newCategory != null && newCategory.isNotEmpty) {
              setState(() {
                _expensecontroller.categories.add(newCategory);
                categoryController.text = newCategory;
              });
            }
          } else {
            setState(() {
              categoryController.text = value!;
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

  void _showConfirmation(BuildContext context, {required bool isdelete}) {
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
                isdelete
                    ? 'Are you sure you want to delete category?'
                    : 'Are you sure you want to save category?',
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
                        if (isdelete) {
                          Navigator.pop(context);
                          deleteBudget();
                          return;
                        }

                        // Validate overall budget exists before editing category
                        await _budgetController.fetchOverallBudget();
                        final double overallBudget =
                            (_budgetController.budgetData.value['amount'] ??
                                    0.0)
                                .toDouble();
                        if (overallBudget <= 0) {
                          SnackbarService.showValidationWarning(
                            'Please set your overall budget first before editing category budgets',
                          );
                          Navigator.pop(context);
                          return;
                        }

                        Navigator.pop(context);
                        setBudgetCategory();
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

  Future<void> deleteBudget() async {
    await _budgetController.deleteBudget(widget.budgetId);
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => BottomNavBar(initialIndex: 2)),
    );
  }

  Future<void> setBudgetCategory() async {
    await _budgetController.setBudget(
      categoryController.text,
      double.parse(amountController.text),
      widget.alertPercentage,
      widget.receiveAlert,
      widget.budgetId,
    );
    if (_budgetController.isSuccess.value == true) {
      categoryController.clear();
      amountController.clear();
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => BottomNavBar(initialIndex: 2)),
      );
      SnackbarService.showBudgetSuccess('Budget updated successfully');
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
    final fillPaint = Paint()
      ..color = const Color(0xFF7F3DFF)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
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
      // ignore: deprecated_member_use
      textScaleFactor: textScaleFactor,
    )..layout();

    // Center the text inside the thumb
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
}
