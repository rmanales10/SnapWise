import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:snapwise/user/screens/profile/favorites/favorite_controller.dart';
import 'package:snapwise/user/screens/widget/bottomnavbar.dart';

class AddFavoritesScreen extends StatefulWidget {
  const AddFavoritesScreen({super.key});

  @override
  State<AddFavoritesScreen> createState() => _AddFavoritesScreenState();
}

class _AddFavoritesScreenState extends State<AddFavoritesScreen> {
  final TextEditingController totalAmountController = TextEditingController();
  final TextEditingController frequencyController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController startDateController = TextEditingController();
  final TextEditingController endDateController = TextEditingController();
  final TextEditingController amountToPayController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  bool receiveAlert = false;
  final controller = Get.put(FavoriteController());
  final frequency = ['Monthly', 'Weekly', 'Daily', 'Yearly'];
  RxDouble amountToPay = 0.0.obs;

  @override
  void initState() {
    super.initState();
    totalAmountController.addListener(_updateAmountToPay);
    startDateController.addListener(_updateAmountToPay);
    endDateController.addListener(_updateAmountToPay);
    frequencyController.addListener(_updateAmountToPay);
  }

  @override
  void dispose() {
    totalAmountController.removeListener(_updateAmountToPay);
    startDateController.removeListener(_updateAmountToPay);
    endDateController.removeListener(_updateAmountToPay);
    frequencyController.removeListener(_updateAmountToPay);
    totalAmountController.dispose();
    frequencyController.dispose();
    dateController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    amountToPayController.dispose();
    super.dispose();
  }

  void _updateAmountToPay() {
    if (totalAmountController.text.isEmpty ||
        startDateController.text.isEmpty ||
        endDateController.text.isEmpty) {
      setState(() {
        amountToPay.value = 0.0;
      });
      return;
    }

    try {
      DateTime startDate = DateTime.parse(startDateController.text);
      DateTime endDate = DateTime.parse(endDateController.text);

      if (endDate.isBefore(startDate)) {
        setState(() {
          amountToPay.value = 0.0;
        });
        return;
      }

      // Calculate total days between dates
      int totalDays = endDate.difference(startDate).inDays + 1;

      if (totalDays <= 0) {
        setState(() {
          amountToPay.value = 0.0;
        });
        return;
      }

      double totalAmount = double.parse(totalAmountController.text);

      if (frequencyController.text == 'Monthly') {
        // Calculate number of months between dates
        int months =
            (endDate.year - startDate.year) * 12 +
            endDate.month -
            startDate.month +
            1;
        setState(() {
          amountToPay.value = totalAmount / months;
        });
      } else if (frequencyController.text == 'Weekly') {
        // Calculate number of weeks between dates
        int weeks = (totalDays / 7).ceil();
        setState(() {
          amountToPay.value = totalAmount / weeks;
        });
      } else if (frequencyController.text == 'Daily') {
        setState(() {
          amountToPay.value = totalAmount / totalDays;
        });
      } else if (frequencyController.text == 'Yearly') {
        // Calculate number of years between dates
        int years = endDate.year - startDate.year + 1;
        setState(() {
          amountToPay.value = totalAmount / years;
        });
      }
    } catch (e) {
      setState(() {
        amountToPay.value = 0.0;
      });
    }
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
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,

                    children: [
                      IconButton(
                        onPressed:
                            () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => BottomNavBar(initialIndex: 14),
                              ),
                            ),
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                      ),

                      Text(
                        "Favorite",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          totalAmountController.clear();
                          frequencyController.text = '';
                          startDateController.text = '';
                          endDateController.text = '';
                          amountToPay.value = 0.0;
                        },
                        tooltip: 'Clear All',
                      ),
                    ],
                  ),
                  Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'How much is your payment?',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                    _buildTitleInput(),
                    const SizedBox(height: 20),
                    _buildAmountInput(
                      'Total amount to pay',
                      totalAmountController.text,
                      true,
                    ),
                    const SizedBox(height: 20),
                    _buildCategorySelector(),
                    const SizedBox(height: 20),
                    Obx(() {
                      return _buildAmountInput(
                        "Amount to pay",
                        amountToPay.value.toStringAsFixed(2),
                        false,
                      );
                    }),
                    const SizedBox(height: 20),
                    _buildDateRangeAndAlert(),
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
                            borderRadius: BorderRadius.circular(12),
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

  Widget _buildCategorySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(width: 1, color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: DropdownButtonFormField<String>(
          focusColor: Colors.white,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(20),
          value: frequency.first,
          icon: const Icon(Icons.keyboard_arrow_down),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Select Frequency',
          ),
          items:
              frequency
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              frequencyController.text = value ?? '';
            });
            _updateAmountToPay(); // Update amount immediately when frequency changes
          },
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
                      onPressed: () => _addFavorite(),
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

  Widget _buildTitleInput() {
    return TextField(
      controller: titleController,
      decoration: InputDecoration(
        hintText: 'Title',
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

  Widget _buildAmountInput(String text, String controller, bool enable) {
    return TextField(
      enabled: enable,
      cursorColor: const Color.fromARGB(255, 3, 30, 53),
      controller:
          text == 'Total amount to pay'
              ? totalAmountController
              : TextEditingController(
                text:
                    amountToPay.value == 0.0
                        ? ''
                        : amountToPay.value.toStringAsFixed(2),
              ),
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        hintText: text,
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

  Widget _buildDateRangeAndAlert() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date Range Picker
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: _buildDateField(
                  controller: startDateController,
                  hint: "Start Date :",
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: _buildDateField(
                  controller: endDateController,
                  hint: "End Date :",
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Receive Alert Switch
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Receive Alert",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Receive a prompt alert for\napproaching payment.",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            Switch(
              value: receiveAlert,
              onChanged: (val) {
                setState(() {
                  receiveAlert = val;
                });
              },

              activeColor: Color(0xFF7F3DFF), // Purple
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Save Button
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() {
            controller.text = picked.toString().split(' ')[0];
          });
        }
      },
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: hint,
        prefixIcon: Icon(Icons.calendar_today, color: Colors.grey.shade400),
      ),
      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
    );
  }

  void _addFavorite() {
    if (totalAmountController.text.isEmpty ||
        amountToPay.value == 0.0 ||
        frequencyController.text.isEmpty ||
        startDateController.text.isEmpty ||
        endDateController.text.isEmpty ||
        titleController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill all fields');
      return;
    }
    controller.addFavorite(
      title: titleController.text,
      totalAmount: double.parse(totalAmountController.text),
      amountToPay: amountToPay.value,
      frequency: frequencyController.text,
      startDate: startDateController.text,
      endDate: endDateController.text,
      receiveAlert: receiveAlert,
    );
    if (controller.isLoading.value == true) {
      Get.snackbar('Success', 'Favorite added successfully');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavBar(initialIndex: 14)),
      );
    }
  }
}
