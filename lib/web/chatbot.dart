import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatBot extends StatefulWidget {
  final BuildContext context;
  const ChatBot({Key? key, required this.context}) : super(key: key);

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isMinimized = false;
  bool _showQuickQuestions = true;
  bool _isLoading = false;
  bool _isTyping = false;
  late AnimationController _animationController;
  late AnimationController _typingAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Initialize Gemini AI
  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGeminiAI();
    _addWelcomeMessage();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  void _initializeGeminiAI() {
    const apiKey = 'AIzaSyCr_7b0ouVns2_KYDndPigjH74I9Sv98x0';
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: apiKey,
    );
    _chat = _model.startChat();
  }

  final List<String> _quickQuestions = [
    'Tell me about SnapWise features',
    'How do I add expenses?',
    'How do I create a budget?',
    'What are the AI features?',
    'How does receipt scanning work?',
    'Tell me about budget notifications',
    'What reports are available?',
    'How do I track income?',
  ];

  void _addWelcomeMessage() {
    _messages.add(
      ChatMessage(
        text:
            "Hello! I'm your SnapWise AI Assistant. I can help you with any questions about SnapWise features, financial management, or general assistance. What would you like to know?",
        isUser: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 600;
    final isTablet =
        mediaQuery.size.width >= 600 && mediaQuery.size.width < 1024;
    final double chatWidth = isMobile
        ? mediaQuery.size.width * 0.98
        : isTablet
            ? 400
            : 380;
    final double chatHeight = isMobile
        ? mediaQuery.size.height * 0.85
        : isTablet
            ? 600
            : 550;
    final double chatRight =
        isMobile ? (mediaQuery.size.width - chatWidth) / 2 : 20;
    final double chatBottom = isMobile ? 80 : 80;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Positioned(
          right: chatRight,
          bottom: chatBottom,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isMinimized ? 70 : chatWidth,
                height: _isMinimized ? 70 : chatHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFF2E2E4F).withOpacity(0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: _isMinimized
                    ? _buildMinimizedChat()
                    : Column(
                        children: [
                          _buildChatHeader(isMobile: isMobile),
                          Expanded(child: _buildChatMessages()),
                          if (_showQuickQuestions)
                            _buildQuickQuestions(isMobile: isMobile),
                          _buildMessageInput(isMobile: isMobile),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMinimizedChat() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E2E4F),
            const Color(0xFF4A4A6A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E2E4F).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              _isMinimized = false;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildChatHeader({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E2E4F),
            const Color(0xFF4A4A6A),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E2E4F).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 6 : 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: isMobile ? 18 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SnapWise AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: isMobile ? 10 : 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.minimize,
                      color: Colors.white, size: isMobile ? 18 : 20),
                  onPressed: () {
                    setState(() {
                      _isMinimized = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(0),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length + (_isTyping ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _messages.length && _isTyping) {
            return _buildTypingIndicator();
          }
          return _messages[index];
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2E2E4F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'SnapWise AI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E4F),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypingDot(0),
                  const SizedBox(width: 4),
                  _buildTypingDot(1),
                  const SizedBox(width: 4),
                  _buildTypingDot(2),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getTimeString(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final delay = index * 0.2;
        final animationValue = (_typingAnimationController.value + delay) % 1.0;
        final opacity = (animationValue * 2).clamp(0.0, 1.0);

        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF2E2E4F).withOpacity(opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _getTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildQuickQuestions({bool isMobile = false}) {
    return Container(
      height: isMobile ? 100 : 130,
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: isMobile ? 14 : 16,
                color: const Color(0xFF2E2E4F),
              ),
              SizedBox(width: isMobile ? 4 : 6),
              Text(
                'Quick Questions',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E2E4F),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _quickQuestions.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: EdgeInsets.only(right: isMobile ? 6 : 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _handleQuickQuestion(_quickQuestions[index]),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 10 : 16,
                            vertical: isMobile ? 7 : 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2E2E4F),
                              const Color(0xFF4A4A6A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2E2E4F).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _quickQuestions[index],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isMobile ? 10 : 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                enabled: !_isLoading,
                style: TextStyle(fontSize: isMobile ? 13 : 14),
                decoration: InputDecoration(
                  hintText: _isLoading
                      ? 'AI is thinking...'
                      : 'Ask me anything about SnapWise...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: isMobile ? 13 : 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 20,
                    vertical: isMobile ? 10 : 12,
                  ),
                  suffixIcon: _isLoading
                      ? Container(
                          padding: EdgeInsets.all(isMobile ? 8 : 12),
                          child: SizedBox(
                            width: isMobile ? 14 : 16,
                            height: isMobile ? 14 : 16,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2E2E4F)),
                            ),
                          ),
                        )
                      : null,
                ),
                onSubmitted: (value) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: isMobile ? 8 : 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isLoading
                    ? [Colors.grey.shade400, Colors.grey.shade500]
                    : [
                        const Color(0xFF2E2E4F),
                        const Color(0xFF4A4A6A),
                      ],
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E2E4F).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(25),
                onTap: _isLoading ? null : _sendMessage,
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 8 : 12),
                  child: Icon(
                    _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                    color: Colors.white,
                    size: isMobile ? 18 : 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleQuickQuestion(String question) {
    setState(() {
      _messages.add(ChatMessage(text: question, isUser: true));
      _showQuickQuestions = false;
      _isTyping = true;
    });

    _typingAnimationController.repeat();

    Future.delayed(const Duration(milliseconds: 500), () {
      _processUserMessage(question);
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _showQuickQuestions = false;
      _isLoading = true;
      _isTyping = true;
    });

    _messageController.clear();
    _typingAnimationController.repeat();
    _processUserMessage(userMessage);
  }

  Future<void> _processUserMessage(String message) async {
    try {
      // Simulate typing delay for more natural feel
      await Future.delayed(const Duration(milliseconds: 800));

      final prompt = '''
You are SnapWise AI Assistant, a helpful and friendly financial management app assistant. 
The user is asking: "$message"

Please provide a helpful, informative, and conversational response. You can help with:

**SnapWise Features:**
- Expense tracking and management
- Budget planning and monitoring  
- Income tracking
- AI-powered receipt scanning
- Financial reports and analytics
- Budget notifications
- User profile and settings

**Financial Management Tips:**
- Budgeting advice
- Saving strategies
- Expense reduction tips
- Financial planning
- Money management best practices

**General Assistance:**
- Answer questions about SnapWise
- Provide financial guidance
- Help with app usage
- Explain features and benefits

Keep your response concise, friendly, and helpful. Use emojis occasionally to make it more engaging.
If the question is not related to SnapWise or financial management, politely redirect to how you can help with their financial needs.
''';

      final response = await _chat.sendMessage(Content.text(prompt));
      final aiResponse = response.text ??
          'I apologize, but I\'m having trouble processing your request right now. Please try again in a moment.';

      // Remove asterisks from the response
      final cleanResponse = aiResponse.replaceAll('*', '');

      setState(() {
        _messages.add(ChatMessage(text: cleanResponse, isUser: false));
        _isLoading = false;
        _isTyping = false;
      });

      _typingAnimationController.stop();
    } catch (e) {
      // Fallback response if AI fails
      setState(() {
        _messages.add(ChatMessage(
          text: '''
I apologize, but I'm experiencing some technical difficulties right now. 

I'm your SnapWise AI Assistant and I can help you with:
📱 SnapWise features and usage
💰 Financial management advice  
📊 Budgeting and expense tracking
🤖 AI-powered features
💡 Money-saving tips

Please try asking your question again, or feel free to ask about any SnapWise features!
''',
          isUser: false,
        ));
        _isLoading = false;
        _isTyping = false;
      });

      _typingAnimationController.stop();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _animationController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({Key? key, required this.text, required this.isUser})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E2E4F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'SnapWise AI',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E2E4F),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF2E2E4F),
                          const Color(0xFF4A4A6A),
                        ],
                      )
                    : null,
                color: isUser ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isUser
                    ? null
                    : Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getTimeString(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeString() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }
}
