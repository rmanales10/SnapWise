import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:get/get.dart';
import 'chatbot.dart';
import 'feedback_controller.dart';
import 'package:url_launcher/url_launcher.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _purposeController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final FeedbackController _feedbackController = Get.put(FeedbackController());
  int _rating = 0;
  bool _showChatBot = false;
  bool _isSubmitting = false;

  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _servicesKey = GlobalKey();
  final GlobalKey _feedbackKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  // Animation controllers for different sections
  late AnimationController _heroAnimationController;
  late AnimationController _featuresAnimationController;
  late AnimationController _servicesAnimationController;
  late AnimationController _ctaAnimationController;
  late AnimationController _feedbackAnimationController;
  late AnimationController _faqAnimationController;
  late AnimationController _fabAnimationController;

  late Animation<double> _heroFadeAnimation;
  late Animation<Offset> _heroSlideAnimation;
  late Animation<double> _featuresFadeAnimation;
  late Animation<Offset> _featuresSlideAnimation;
  late Animation<double> _servicesFadeAnimation;
  late Animation<Offset> _servicesSlideAnimation;
  late Animation<double> _ctaFadeAnimation;
  late Animation<Offset> _ctaSlideAnimation;
  late Animation<double> _feedbackFadeAnimation;
  late Animation<Offset> _feedbackSlideAnimation;
  late Animation<double> _faqFadeAnimation;
  late Animation<Offset> _faqSlideAnimation;
  late Animation<double> _fabScaleAnimation;

  bool _showFAB = false;

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controllers
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _featuresAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _servicesAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _ctaAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _feedbackAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _faqAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Define Fade and Slide Animations for each section
    _heroFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroAnimationController, curve: Curves.easeIn),
    );
    _heroSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _heroAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _featuresFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _featuresAnimationController,
        curve: Curves.easeIn,
      ),
    );
    _featuresSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _featuresAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _servicesFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _servicesAnimationController,
        curve: Curves.easeIn,
      ),
    );
    _servicesSlideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _servicesAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _ctaFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctaAnimationController, curve: Curves.easeIn),
    );
    _ctaSlideAnimation = Tween<Offset>(
      begin: const Offset(-0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ctaAnimationController, curve: Curves.easeInOut),
    );

    _feedbackFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _feedbackAnimationController,
        curve: Curves.easeIn,
      ),
    );
    _feedbackSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _feedbackAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _faqFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _faqAnimationController, curve: Curves.easeIn),
    );
    _faqSlideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _faqAnimationController, curve: Curves.easeInOut),
    );

    // FAB Scale Animation
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showFAB) {
        setState(() {
          _showFAB = true;
          _fabAnimationController.forward();
        });
      } else if (_scrollController.offset <= 300 && _showFAB) {
        _fabAnimationController.reverse().then((_) {
          setState(() {
            _showFAB = false;
          });
        });
      }
    });

    // Start hero animation immediately
    _heroAnimationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          if (!isMobile) return const SizedBox.shrink();
          return Drawer(
            backgroundColor: const Color(
              0xFF1A1A2E,
            ), // Dark background for modern look
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Modern Drawer Header
                Container(
                  height: 120, // Reduced height for minimalism
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2E2E4F), Color(0xFF4A4A7C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                // Menu Items
                _drawerItem('Product', Icons.star_border, () {
                  _scrollToSection(_heroKey);
                  Navigator.pop(context);
                }),
                _drawerItem('Features & Download', Icons.download, () {
                  _scrollToSection(_featuresKey);
                  Navigator.pop(context);
                }),
                _drawerItem('Services', Icons.build, () {
                  _scrollToSection(_servicesKey);
                  Navigator.pop(context);
                }),
                _drawerItem('Feedback', Icons.feedback_outlined, () {
                  _scrollToSection(_feedbackKey);
                  Navigator.pop(context);
                }),
                _drawerItem('FAQs', Icons.question_answer_outlined, () {
                  _scrollToSection(_faqKey);
                  Navigator.pop(context);
                }),
              ],
            ),
          );
        },
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                _buildNavBar(),
                VisibilityDetector(
                  key: const Key('hero-section'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.1) {
                      _heroAnimationController.forward();
                    }
                  },
                  child: _buildHeroSection(),
                ),
                VisibilityDetector(
                  key: const Key('features-overview'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.1) {
                      _featuresAnimationController.forward();
                    }
                  },
                  child: _buildFeaturesOverview(),
                ),
                VisibilityDetector(
                  key: const Key('detailed-features'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.1) {
                      _featuresAnimationController.forward();
                    }
                  },
                  child: _buildDetailedFeatures(),
                ),
                VisibilityDetector(
                  key: const Key('services-section'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.1) {
                      _servicesAnimationController.forward();
                    }
                  },
                  child: _buildServicesSection(),
                ),
                VisibilityDetector(
                  key: const Key('cta-section'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.1) {
                      _ctaAnimationController.forward();
                    }
                  },
                  child: _buildCTASection(),
                ),
                VisibilityDetector(
                  key: const Key('feedback-section'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.1) {
                      _feedbackAnimationController.forward();
                    }
                  },
                  child: _buildFeedbackSection(),
                ),
                VisibilityDetector(
                  key: const Key('faq-section'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.1) {
                      _faqAnimationController.forward();
                    }
                  },
                  child: _buildFAQSection(),
                ),
                _buildFooter(),
              ],
            ),
          ),
          if (_showChatBot) ChatBot(context: context),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          bool isMobile = MediaQuery.of(context).size.width < 600;
          return isMobile
              ? FloatingActionButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  backgroundColor: const Color(0xFF2E2E4F),
                  child: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Colors.white,
                  ),
                )
              : ScaleTransition(
                  scale: _fabScaleAnimation,
                  child: _showFAB
                      ? FloatingActionButton.extended(
                          onPressed: () {
                            _scrollController.animateTo(
                              0,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          },
                          backgroundColor: const Color(0xFF2E2E4F),
                          icon: const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            "Back to top",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ), // Label on desktop
                        )
                      : const SizedBox.shrink(),
                );
        },
      ),
    );
  }

  Widget _drawerItem(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(width: 16),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!, width: 1.0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: isMobile ? 60 : 100,
                    fit: BoxFit.cover,
                  ),
                ],
              ),
              if (!isMobile)
                Row(
                  children: [
                    _navItem('Product', () => _scrollToSection(_heroKey)),
                    _navItem(
                      'Features & Download',
                      () => _scrollToSection(_featuresKey),
                    ),
                    _navItem('Services', () => _scrollToSection(_servicesKey)),
                    _navItem('Feedback', () => _scrollToSection(_feedbackKey)),
                    _navItem('FAQs', () => _scrollToSection(_faqKey)),
                  ],
                )
              else
                IconButton(
                  icon: const Icon(Icons.menu, size: 30),
                  onPressed: () {
                    Scaffold.of(context).openEndDrawer();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _navItem(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return FadeTransition(
          opacity: _heroFadeAnimation,
          child: SlideTransition(
            position: _heroSlideAnimation,
            child: Container(
              key: _heroKey,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 100,
                vertical: isMobile ? 40 : 0,
              ),
              height: isMobile ? null : 670,
              color: Colors.white,
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image Content
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/for landingpage/Group 36707 (1).png',
                              height: isMobile ? 300 : 600,
                              fit: BoxFit.contain,
                            ),
                            Positioned(
                              bottom: 10,
                              right: 10,
                              child: Image.asset(
                                'assets/for landingpage/Group 36705.png',
                                height: isMobile ? 40 : 70,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Text Content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Snap Receipts.\nTrack Smarter.',
                              style: TextStyle(
                                fontSize: isMobile ? 30 : 70,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 20 : 0,
                              ),
                              child: Text(
                                'Take the stress out of spending. Snapwise uses AI and OCR to turn your receipts into real-time insights, smarter budgets, and future-ready money moves. Do you have a question about Snapwise?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 16,
                                  color: Colors.black54,
                                  height: 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            AnimatedButton(
                              onPressed: () {
                                setState(() {
                                  _showChatBot = true;
                                });
                              },
                              backgroundColor: Color(0xFF2E2E4F),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 80 : 60,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Ask with AI',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        Positioned(
                          top: 170,
                          left: 50,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Snap Receipts.\nTrack Smarter.',
                                style: TextStyle(
                                  fontSize: 70,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Take the stress out of spending. Snapwise uses AI and OCR to turn\nyour receipts into real-time insights, smarter budgets, and future-\nready money moves. Do you have a question about Snapwise?',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                  height: 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 20),
                              AnimatedButton(
                                onPressed: () {
                                  setState(() {
                                    _showChatBot = true;
                                  });
                                },
                                backgroundColor: const Color(0xFF2E2E4F),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 60,
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Ask with AI',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          right: 150,
                          child: SizedBox(
                            height: 670,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset(
                                  'assets/for landingpage/Group 36707 (1).png',
                                  height: 600,
                                  fit: BoxFit.contain,
                                ),
                                Positioned(
                                  bottom: 30,
                                  right: 20,
                                  child: Image.asset(
                                    'assets/for landingpage/Group 36705.png',
                                    height: 70,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturesOverview() {
    return FadeTransition(
      opacity: _featuresFadeAnimation,
      child: SlideTransition(
        position: _featuresSlideAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 600;

            return Container(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 40 : 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey.shade100, Colors.white],
                ),
              ),
              child: isMobile
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _featureCard(
                          icon: Icons.notifications_active,
                          iconColor: Colors.red[400]!,
                          title: 'Real-time Alerts',
                          description:
                              'Get instant notifications when you\'re about to overspend, when bills are due, or when you\'re approaching your budget limit—so you\'re always ahead, not behind.',
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 24),
                        _featureCard(
                          icon: Icons.auto_awesome,
                          iconColor: Colors.amber[600]!,
                          title: 'AI That Gets You',
                          description:
                              'Snapwise uses AI to instantly sort your expenses into accurate categories. Prefer control? You can manually adjust anything, anytime.',
                          isMobile: isMobile,
                        ),
                        const SizedBox(height: 24),
                        _featureCard(
                          icon: Icons.trending_up,
                          iconColor: Colors.blue[600]!,
                          title: 'Budget Like a Pro',
                          description:
                              'Set monthly budgets, track income distribution, and plan ahead with accurate predictions of future expenses. Financial clarity, made simple.',
                          isMobile: isMobile,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _featureCard(
                          icon: Icons.notifications_active,
                          iconColor: Colors.red[400]!,
                          title: 'Real-time Alerts',
                          description:
                              'Get instant notifications when you\'re about to overspend, when bills are due, or when you\'re approaching your budget limit—so you\'re always ahead, not behind.',
                          isMobile: isMobile,
                        ),
                        _featureCard(
                          icon: Icons.auto_awesome,
                          iconColor: Colors.amber[600]!,
                          title: 'AI That Gets You',
                          description:
                              'Snapwise uses AI to instantly sort your expenses into accurate categories. Prefer control? You can manually adjust anything, anytime.',
                          isMobile: isMobile,
                        ),
                        _featureCard(
                          icon: Icons.trending_up,
                          iconColor: Colors.blue[600]!,
                          title: 'Budget Like a Pro',
                          description:
                              'Set monthly budgets, track income distribution, and plan ahead with accurate predictions of future expenses. Financial clarity, made simple.',
                          isMobile: isMobile,
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isMobile,
  }) {
    return Container(
      width: isMobile ? double.infinity : 400,
      margin: isMobile ? const EdgeInsets.symmetric(horizontal: 40) : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: isMobile ? 32 : 40, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 16 : 16,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedFeatures() {
    return FadeTransition(
      opacity: _featuresFadeAnimation,
      child: SlideTransition(
        position: _featuresSlideAnimation,
        child: Container(
          key: _featuresKey,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;

              return Column(
                children: [
                  // Responsive Introductory Section
                  Container(
                    width: isMobile ? double.infinity : 1180,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 0,
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Features',
                          style: TextStyle(
                            fontSize: isMobile ? 32 : 40,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Snapwise turns messy expenses into crystal-clear insights. Whether you\'re scanning a coffee receipt or planning next month\'s bills, it\'s built to make budgeting feel effortless.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isMobile ? 40 : 60),
                  // Responsive Image and Features List
                  isMobile
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/for landingpage/Col.png',
                              height: isMobile ? 300 : 600,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 40),
                            AnimatedButton(
                              onPressed: () => launchUrl(
                                  Uri.parse(
                                      'https://www.dropbox.com/scl/fi/19axu4vqvu5fccu2a7zxl/app-release.apk?rlkey=m7x0bv4wdfv1oedr9t37efdpw&e=2&st=v42je5jb&dl=1'),
                                  mode: LaunchMode.externalApplication),
                              backgroundColor: const Color(0xFF2E2E4F),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 60,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'Download Snapwise',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _featureItem(
                                  'OCR Receipt Extraction',
                                  'Quickly snap and extract details from your receipts with powerful OCR technology.',
                                  isMobile: isMobile,
                                ),
                                _featureItem(
                                  'AI-Powered Categorization + Manual Control',
                                  'Automatically sort your expenses with AI—and tweak categories manually anytime you want.',
                                  isMobile: isMobile,
                                ),
                                _featureItem(
                                  'Smart Budgeting',
                                  'Set budgets, track your spending, and manage your finances like a pro.',
                                  isMobile: isMobile,
                                ),
                                _featureItem(
                                  'Real-Time Alerts',
                                  'Get instant notifications on your spending, budget limits, and upcoming payments so you never miss a beat.',
                                  isMobile: isMobile,
                                ),
                                _featureItem(
                                  'Priority Payments',
                                  'Set bills and essentials as priority payments, get reminders, and confirm payments that automatically update your budget and income.',
                                  isMobile: isMobile,
                                ),
                                _featureItem(
                                  'Financial Visual Insights',
                                  'Understand your money better with clear, beautiful charts and summaries.',
                                  isMobile: isMobile,
                                ),
                                _featureItem(
                                  'Future Budget Predictions',
                                  'See what\'s ahead with predictive insights on expenses and budget trends.',
                                  isMobile: isMobile,
                                ),
                                _featureItem(
                                  'Income Distribution',
                                  'Manage how your income is allocated across your income.',
                                  isMobile: isMobile,
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/for landingpage/Col.png',
                                  height: 600,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(width: 100),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _featureItem(
                                      'OCR Receipt Extraction',
                                      'Quickly snap and extract details from your receipts with powerful OCR technology.',
                                      isMobile: isMobile,
                                    ),
                                    _featureItem(
                                      'AI-Powered Categorization + Manual Control',
                                      'Automatically sort your expenses with AI—and tweak categories manually anytime you want.',
                                      isMobile: isMobile,
                                    ),
                                    _featureItem(
                                      'Smart Budgeting',
                                      'Set budgets, track your spending, and manage your finances like a pro.',
                                      isMobile: isMobile,
                                    ),
                                    _featureItem(
                                      'Real-Time Alerts',
                                      'Get instant notifications on your spending, budget limits, and upcoming payments so you never miss a beat.',
                                      isMobile: isMobile,
                                    ),
                                    _featureItem(
                                      'Priority Payments',
                                      'Set bills and essentials as priority payments, get reminders, and confirm payments that automatically update your budget and income.',
                                      isMobile: isMobile,
                                    ),
                                    _featureItem(
                                      'Financial Visual Insights',
                                      'Understand your money better with clear, beautiful charts and summaries.',
                                      isMobile: isMobile,
                                    ),
                                    _featureItem(
                                      'Future Budget Predictions',
                                      'See what\'s ahead with predictive insights on expenses and budget trends.',
                                      isMobile: isMobile,
                                    ),
                                    _featureItem(
                                      'Income Distribution',
                                      'Manage how your income is allocated across your income.',
                                      isMobile: isMobile,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            AnimatedButton(
                              onPressed: () => launchUrl(
                                  Uri.parse(
                                      'https://www.dropbox.com/scl/fi/19axu4vqvu5fccu2a7zxl/app-release.apk?rlkey=m7x0bv4wdfv1oedr9t37efdpw&e=2&st=v42je5jb&dl=1'),
                                  mode: LaunchMode.externalApplication),
                              backgroundColor: const Color(0xFF2E2E4F),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 60,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'Download Snapwise',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _featureItem(
    String title,
    String description, {
    required bool isMobile,
  }) {
    return isMobile
        ? Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isMobile)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, right: 8),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: 24,
                      color:
                          Colors.green, // Matches button color for consistency
                    ),
                  ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color:
                              isMobile ? const Color(0xFF2E2E4F) : Colors.black,
                          width: isMobile ? 2 : 3,
                        ),
                      ),
                      boxShadow: isMobile
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 6,
                                offset: const Offset(2, 2),
                              ),
                            ],
                      borderRadius: isMobile ? null : BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: isMobile ? Colors.black87 : Colors.black,
                              letterSpacing: isMobile ? 0.5 : 0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: isMobile ? double.infinity : 400,
                            child: Text(
                              description,
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                fontWeight: FontWeight
                                    .w600, // Slightly lighter for modern look
                                color: Colors.black54,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Colors.black, width: 3)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: isMobile ? double.infinity : 400,
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildServicesSection() {
    return FadeTransition(
      opacity: _servicesFadeAnimation,
      child: SlideTransition(
        position: _servicesSlideAnimation,
        child: Container(
          key: _servicesKey,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          color: const Color(0xFFF7FAFC),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Responsive Title
                            SizedBox(
                              width: isMobile ? double.infinity : 200,
                              child: Text(
                                'Snapwise\nServices',
                                textAlign: isMobile
                                    ? TextAlign.center
                                    : TextAlign.left,
                                style: TextStyle(
                                  fontSize: isMobile ? 24 : 30,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            // Responsive Service Cards
                            _serviceCard(
                              iconPath: 'assets/for landingpage/icon-01.png',
                              title: 'Smart Expense\nManagement',
                              description:
                                  'Capture and categorize your receipts instantly using OCR and AI, with manual editing whenever you need full control.',
                              color: const Color(0xFFCEC6EB),
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 24),
                            _serviceCard(
                              iconPath: 'assets/for landingpage/icon-02.png',
                              title: 'Personalized\nBudgeting & Alerts',
                              description:
                                  'Create budgets tailored to your lifestyle and get real-time notifications to keep your spending and bills on track.',
                              color: Colors.white,
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 24),
                            _serviceCard(
                              iconPath: 'assets/for landingpage/icon-03.png',
                              title: 'Priority\nPayment',
                              description:
                                  'Mark essential bills as priority payments, receive timely reminders, and confirm payments that automatically update your budget.',
                              color: Colors.white,
                              isMobile: isMobile,
                            ),
                            const SizedBox(height: 24),
                            _serviceCard(
                              iconPath: 'assets/for landingpage/icon-04.png',
                              title: 'Financial Insights &\nPredictions',
                              description:
                                  'Visualize your spending with easy-to-understand charts, predict future expenses, and manage how your income is distributed.',
                              color: Colors.white,
                              isMobile: isMobile,
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            SizedBox(
                              width: 200,
                              child: const Text(
                                'Snapwise\nServices',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _serviceCard(
                                      iconPath:
                                          'assets/for landingpage/icon-01.png',
                                      title: 'Smart Expense\nManagement',
                                      description:
                                          'Capture and categorize your receipts instantly using OCR and AI, with manual editing whenever you need full control.',
                                      color: const Color(0xFFCEC6EB),
                                      isMobile: isMobile,
                                    ),
                                    const SizedBox(width: 40),
                                    _serviceCard(
                                      iconPath:
                                          'assets/for landingpage/icon-02.png',
                                      title: 'Personalized\nBudgeting & Alerts',
                                      description:
                                          'Create budgets tailored to your lifestyle and get real-time notifications to keep your spending and bills on track.',
                                      color: Colors.white,
                                      isMobile: isMobile,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                Row(
                                  children: [
                                    _serviceCard(
                                      iconPath:
                                          'assets/for landingpage/icon-03.png',
                                      title: 'Priority\nPayment',
                                      description:
                                          'Mark essential bills as priority payments, receive timely reminders, and confirm payments that automatically update your budget.',
                                      color: Colors.white,
                                      isMobile: isMobile,
                                    ),
                                    const SizedBox(width: 40),
                                    _serviceCard(
                                      iconPath:
                                          'assets/for landingpage/icon-04.png',
                                      title:
                                          'Financial Insights &\nPredictions',
                                      description:
                                          'Visualize your spending with easy-to-understand charts, predict future expenses, and manage how your income is distributed.',
                                      color: Colors.white,
                                      isMobile: isMobile,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _serviceCard({
    required String iconPath,
    required String title,
    required String description,
    required Color color,
    required bool isMobile,
  }) {
    return Container(
      width: isMobile ? double.infinity : 350,
      height: isMobile ? 240 : 280,
      margin: isMobile ? const EdgeInsets.symmetric(horizontal: 16) : null,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                iconPath,
                width: isMobile ? 40 : 50,
                height: isMobile ? 40 : 50,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontSize: isMobile ? 16 : 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return FadeTransition(
      opacity: _ctaFadeAnimation,
      child: SlideTransition(
        position: _ctaSlideAnimation,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          color: const Color(0xFF6565A5),
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;

              return isMobile
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Responsive Text Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Start now and get the\nbest services',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 28 : 40,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                color: Colors
                                    .white, // Adjusted for better contrast
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: Text(
                                'Simplify your financial life and stay in control of your money with Snapwise. Make smarter spending decisions, avoid surprises, and confidently plan for the future. Enjoy peace of mind knowing your essentials are covered and your budget works for you.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  color: Colors
                                      .white70, // Softer contrast for mobile
                                  fontWeight: FontWeight.bold,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        // Responsive Image Section
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/for landingpage/col1.png',
                              height: isMobile ? 300 : 570,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start now and get the\nbest services',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                                color: Colors.white, // Adjusted for contrast
                              ),
                            ),
                            const SizedBox(height: 16),
                            const SizedBox(
                              width: 580,
                              child: Text(
                                'Simplify your financial life and stay in control of your money with Snapwise. Make smarter spending decisions, avoid surprises, and confidently plan for the future. Enjoy peace of mind knowing your essentials are covered and your budget works for you.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70, // Softer contrast
                                  fontWeight: FontWeight.bold,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 150),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/for landingpage/col1.png',
                              height: 570,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return FadeTransition(
      opacity: _feedbackFadeAnimation,
      child: SlideTransition(
        position: _feedbackSlideAnimation,
        child: Container(
          key: _feedbackKey,
          padding: EdgeInsets.symmetric(vertical: 40, horizontal: 16),
          color: const Color(0xFF2D2D47),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 600;
                double formWidth = isMobile ? constraints.maxWidth * 0.85 : 500;

                return Container(
                  width: formWidth,
                  padding: EdgeInsets.all(isMobile ? 24 : 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          'SnapWise Feedback Form',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name *',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 16,
                            horizontal: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 16,
                            horizontal: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _purposeController,
                        decoration: InputDecoration(
                          labelText: 'Purpose *',
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 16,
                            horizontal: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Share your experience in scaling *',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: isMobile
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.start,
                        children: List.generate(5, (index) {
                          return IconButton(
                            onPressed: () {
                              setState(() {
                                _rating = index + 1;
                              });
                            },
                            icon: Icon(
                              Icons.star,
                              size: isMobile ? 28 : 32,
                              color: index < _rating
                                  ? Colors.amber
                                  : Colors.grey[300],
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _commentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Comment *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: isMobile ? 12 : 16,
                            horizontal: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _nameController.clear();
                              _emailController.clear();
                              _purposeController.clear();
                              _commentController.clear();
                              setState(() {
                                _rating = 0;
                              });
                            },
                            child: Text(
                              'Clear form',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          AnimatedButton(
                            onPressed: () => _submitFeedback(),
                            backgroundColor: const Color(0xFF007BFF),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 20 : 28,
                              vertical: isMobile ? 10 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'SUBMIT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: isMobile ? 14 : 16,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_emailController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _purposeController.text.isEmpty ||
        _rating == 0 ||
        _commentController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all required fields');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    await _feedbackController.sendFeedbackEmail(
      _nameController.text,
      _emailController.text,
      _purposeController.text,
      _rating,
      _commentController.text,
    );
    setState(() {
      _isSubmitting = false;
    });
  }

  Widget _buildFAQSection() {
    return FadeTransition(
      opacity: _faqFadeAnimation,
      child: SlideTransition(
        position: _faqSlideAnimation,
        child: Container(
          key: _faqKey,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
          child: Column(
            children: [
              const Text(
                'Answers to your questions (FAQs)',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              _faqItem('What is Snapwise?'),
              _faqItem('How does Snapwise work?'),
              _faqItem('How can I begin using Snapwise?'),
              _faqItem('Can Snapwise be used without an internet connection?'),
              _faqItem('Is Snapwise a free application?'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faqItem(String question) {
    String answer = '';

    switch (question) {
      case 'What is Snapwise?':
        answer =
            'Snapwise is an AI-powered expense tracking app that uses OCR technology to scan receipts and automatically categorize your expenses. It helps you manage budgets, track spending patterns, and make smarter financial decisions.';
        break;
      case 'How does Snapwise work?':
        answer =
            'Simply take a photo of your receipt, and Snapwise will extract all the important details using OCR technology. Our AI then categorizes the expense automatically, though you can always adjust categories manually. The app tracks your spending, sends alerts when you\'re near budget limits, and provides insights into your financial habits.';
        break;
      case 'How can I begin using Snapwise?':
        answer =
            'Getting started is easy! Download Snapwise from your app store, create an account, and set up your first budget. You can immediately start snapping photos of receipts, and the app will begin tracking your expenses and providing insights.';
        break;
      case 'Can Snapwise be used without an internet connection?':
        answer =
            'Yes! You can capture receipts offline, and they\'ll be stored locally on your device. Once you reconnect to the internet, Snapwise will sync your data and process any pending receipts with our AI categorization system.';
        break;
      case 'Is Snapwise a free application?':
        answer =
            'Snapwise offers a free tier with basic features including receipt scanning, expense tracking, and budget management. Premium features like advanced analytics, unlimited receipt storage, and priority support are available through our subscription plans.';
        break;
    }

    return FAQItem(question: question, answer: answer);
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          color: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 600;

              return Column(
                children: [
                  // Contact Us Section
                  Text(
                    'CONTACT US',
                    style: TextStyle(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Facebook : Snapwise',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gmail : snapwiseofficial25@gmail.com',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Footer Columns
                  isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Smarter Money Starts Here
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Smarter Money Starts Here',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.facebook,
                                        color: const Color(0xFFF4C430),
                                        size: isMobile ? 20 : 24,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.camera_alt,
                                        color: const Color(0xFFF4C430),
                                        size: isMobile ? 20 : 24,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {},
                                      icon: Icon(
                                        Icons.alternate_email,
                                        color: const Color(0xFFF4C430),
                                        size: isMobile ? 20 : 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Company Info
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Company Info',
                                      style: TextStyle(
                                        fontSize: isMobile ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Emperors Quartet',
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 100),
                                // Features
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Features',
                                      style: TextStyle(
                                        fontSize: isMobile ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Product',
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Features & Download',
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Services',
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'FAQs',
                                      style: TextStyle(
                                        fontSize: isMobile ? 14 : 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 350),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Smarter Money Starts Here',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.facebook,
                                          color: Color(0xFFF4C430),
                                          size: 24,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {},
                                        icon: Icon(
                                          Icons.camera_alt,
                                          color: const Color(0xFFF4C430),
                                          size: 24,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {},
                                        icon: Icon(
                                          Icons.alternate_email,
                                          color: const Color(0xFFF4C430),
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Company Info',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Emperors Quartet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 40),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Features',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Product',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Features & Download',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Services',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'FAQs',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ],
              );
            },
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 600;
            return Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 30),
              color: const Color(0xFFE6F0FA),
              child: Center(
                child: Text(
                  'Made With @Emperor\'s Quartet All Right Reserved',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _purposeController.dispose();
    _commentController.dispose();
    _heroAnimationController.dispose();
    _featuresAnimationController.dispose();
    _servicesAnimationController.dispose();
    _ctaAnimationController.dispose();
    _feedbackAnimationController.dispose();
    _faqAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }
}

// Custom Animated Button Widget
class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color backgroundColor;
  final EdgeInsets padding;
  final RoundedRectangleBorder shape;

  const AnimatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    required this.backgroundColor,
    required this.padding,
    required this.shape,
  }) : super(key: key);

  @override
  AnimatedButtonState createState() => AnimatedButtonState();
}

class AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton(
          onPressed:
              null, // Disable ElevatedButton's onPressed to rely on GestureDetector
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: widget.backgroundColor,
            padding: widget.padding,
            shape: widget.shape,
            elevation: 0,
          ),
          child: widget.child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const FAQItem({Key? key, required this.question, required this.answer})
      : super(key: key);

  @override
  FAQItemState createState() => FAQItemState();
}

class FAQItemState extends State<FAQItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize Animation Controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Define Fade and Slide Animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(
        0.5,
        0,
      ), // Slide from right, matching FAQ section in LandingPage
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('faq-item-${widget.question}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.1 && !_animationController.isAnimating) {
          _animationController.forward();
        }
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                onExpansionChanged: (expanded) {
                  setState(() {});
                },
                title: Text(
                  widget.question,
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                ),
                trailing: const Icon(Icons.expand_more),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        widget.answer,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
