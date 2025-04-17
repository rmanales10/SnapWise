import 'package:flutter/material.dart';

class IncomeEditPage extends StatefulWidget {
  const IncomeEditPage({super.key});

  @override
  State<IncomeEditPage> createState() => _IncomeEditPageState();
}

class _IncomeEditPageState extends State<IncomeEditPage> {
  bool receiveAlert = false;
  double alertPercentage = 80.0;


  final TextEditingController amountController = TextEditingController();

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
                          "Edit Income",
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
                    "How much is your income?",
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
                    _buildAmountInput(), const SizedBox(height: 20),

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
                'Are you sure you want to save income?',
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
      keyboardType: TextInputType.number,
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
