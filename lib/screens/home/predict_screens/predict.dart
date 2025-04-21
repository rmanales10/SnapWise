import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:snapwise/screens/home/predict_screens/predict_controller.dart';

class PredictBudgetPage extends StatefulWidget {
  const PredictBudgetPage({super.key});

  @override
  State<PredictBudgetPage> createState() => _PredictBudgetPageState();
}

class _PredictBudgetPageState extends State<PredictBudgetPage> {
  final controller = Get.put(PredictController());

  double budgetAmount = 15000.0;
  bool isEditing = false;

  bool get isTablet => MediaQuery.of(context).size.shortestSide > 600;

  List<Map<String, dynamic>> budgetCategories = [
    {'name': 'Food', 'amount': 3500.0, 'icon': Icons.restaurant},
    {'name': 'Transport', 'amount': 2000.0, 'icon': Icons.directions_car},
    {'name': 'Shopping', 'amount': 2500.0, 'icon': Icons.shopping_bag},
    {'name': 'Utilities', 'amount': 1500.0, 'icon': Icons.bolt},
    {'name': 'Entertainment', 'amount': 1000.0, 'icon': Icons.movie},
    {'name': 'Others', 'amount': 1500.0, 'icon': Icons.more_horiz},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        title: Text(
          'Predict Budget',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 24 : 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: isTablet ? 28 : 24),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: Icon(
                isEditing ? LucideIcons.checkCheck : LucideIcons.edit2,
                color: Colors.black,
                size: isTablet ? 28 : 20,
              ),
              onPressed: () {
                if (isEditing) {
                  _showConfirmation(context);
                } else {
                  setState(() {
                    isEditing = true;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 30 : 20,
          vertical: isTablet ? 25 : 15,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Budget',
              style: TextStyle(
                fontSize: isTablet ? 22 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: isTablet ? 25 : 15),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isTablet ? 25 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isTablet ? 20 : 15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'For Next Month',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: isTablet ? 15 : 10),
                  Obx(
                    () =>
                        isEditing
                            ? Container(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: isTablet ? 250 : 200,
                                child: TextField(
                                  textAlign: TextAlign.right,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  style: TextStyle(
                                    fontSize: isTablet ? 32 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: const Color.fromARGB(255, 3, 30, 53),
                                  ),
                                  controller: TextEditingController(
                                    text: budgetAmount.toStringAsFixed(2),
                                  ),
                                  onChanged: (value) {
                                    double? newVal = double.tryParse(value);
                                    if (newVal != null) {
                                      setState(() {
                                        budgetAmount = newVal;
                                      });
                                    }
                                  },
                                ),
                              ),
                            )
                            : Text(
                              'PHP ${controller.totalBudget.value.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isTablet ? 32 : 28,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 3, 30, 53),
                              ),
                            ),
                  ),
                ],
              ),
            ),
            SizedBox(height: isTablet ? 30 : 20),
            Obx(
              () => GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.budgetCategories.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isTablet ? 3 : 2,
                  crossAxisSpacing: isTablet ? 20 : 15,
                  mainAxisSpacing: isTablet ? 20 : 15,
                  childAspectRatio: isTablet ? 1.5 : 1.8,
                ),
                itemBuilder: (context, index) {
                  final category = controller.budgetCategories[index];
                  return _buildCategoryCard(
                    category['name'],
                    category['amount'],
                    category['icon'],
                    (newAmount) {
                      controller.budgetCategories[index]['amount'] = newAmount;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    String category,
    double amount,
    IconData icon,
    Function(double) onAmountChanged,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          padding: EdgeInsets.all(isTablet ? 20 : 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 15 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: isTablet ? 28 : 24,
                    color: const Color.fromARGB(255, 3, 30, 53),
                  ),
                  SizedBox(width: isTablet ? 10 : 8),
                  Flexible(
                    child: Text(
                      category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              isEditing
                  ? SizedBox(
                    height: isTablet ? 30 : 28,
                    child: TextField(
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 8,
                        ),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                      controller: TextEditingController(
                        text: amount.toStringAsFixed(2),
                      ),
                      onChanged: (value) {
                        double? newVal = double.tryParse(value);
                        if (newVal != null) {
                          onAmountChanged(newVal);
                        }
                      },
                    ),
                  )
                  : Text(
                    'PHP ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: isTablet ? 20 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
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
                'Save Predicted Budget?',
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
                        Navigator.pop(context);
                        setState(() {
                          isEditing = false;
                        });
                        controller.predictBudget(controller.totalBudget.value);
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
}
