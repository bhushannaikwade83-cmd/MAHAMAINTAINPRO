import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_footer.dart';

class Message {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  Message({required this.text, required this.isUser, required this.timestamp});
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({Key? key}) : super(key: key);

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  bool _isMarathi = false;
  int _footerSelectedIndex = 2;
  late ScrollController _scrollController;

  final Map<String, Map<String, String>> _responses = {
    'booking': {
      'en': '📋 How can I help you book a service?\n\n• Search services\n• View available time slots\n• Confirm your address\n• Make payment\n\nWhich service would you like?',
      'mr': '📋 मी आपल्याला service बुक करण्यात कसे मदत करू शकतो?\n\n• Services शोधा\n• Available time slots पहा\n• आपले address confirm करा\n• Payment करा\n\nआपणास कोणती service बुक करायची आहे?',
    },
    'status': {
      'en': '📍 Real-time Booking Status\n\nYour active bookings:\n• Cleaning Service - 2:00 PM\n• Professional: Ramesh Kumar\n• Distance: 1.5 km away\n• ETA: 15 minutes\n\nNeed live updates?',
      'mr': '📍 तुमची booking स्थिती\n\nआपली सक्रिय bookings:\n• Cleaning Service - 2:00 PM\n• Professional: राम कुमार\n• अंतर: 1.5 km\n• ETA: 15 मिनिट\n\nलाइव अपडेट्स हवेत?',
    },
    'faq': {
      'en': '❓ Frequently Asked Questions\n\n• How do I book a service?\n• What\'s your cancellation policy?\n• How do I make payment?\n• What if I\'m not satisfied?\n• How do I rate a service?\n\nWhich question?',
      'mr': '❓ सामान्य प्रश्न\n\n• मी service कसे बुक करू?\n• Cancellation policy काय आहे?\n• मी payment कसे करू?\n• मी असंतुष्ट असल्यास?\n• मी rating कसे दू?\n\nकोणता प्रश्न?',
    },
    'service_info': {
      'en': '🔍 Service Information\n\nPopular Services:\n1️⃣ Women\'s Salon - ₹399-799\n2️⃣ Cleaning - ₹999-1999\n3️⃣ AC Service - ₹499-1299\n4️⃣ Electrician - ₹199-399\n\nWhich interests you?',
      'mr': '🔍 Service माहिती\n\nलोकप्रिय Services:\n1️⃣ Women\'s Salon - ₹399-799\n2️⃣ Cleaning - ₹999-1999\n3️⃣ AC Service - ₹499-1299\n4️⃣ Electrician - ₹199-399\n\nकोणती रुचते?',
    },
    'recommendation': {
      'en': '💡 Service Recommendations\n\nBased on your history:\n✓ Deep Cleaning (You liked before)\n✓ AC Maintenance (Available nearby)\n✓ Plumbing (Highly rated)\n✓ Repair Service (New offer)\n\nBook now?',
      'mr': '💡 Service शिफारसी\n\nआपल्या history:\n✓ Deep Cleaning (आवडले)\n✓ AC Maintenance (उपलब्ध)\n✓ Plumbing (उच्च रेटिंग)\n✓ Repair (नई ऑफर)\n\nआता बुक करा?',
    },
    'complaint': {
      'en': '📝 Report Issue or Feedback\n\nSorry to hear you\'re having trouble!\n\nPlease tell us:\n• What\'s the problem?\n• When did it happen?\n• Which service?\n\nResolved within 24 hours.',
      'mr': '📝 समस्या किंवा Feedback\n\nखेद आहे समस्या आहे!\n\nकृपया सांगा:\n• समस्या काय?\n• कधी झाले?\n• कोणती service?\n\n24 तासांत निवारण.',
    },
    'payment': {
      'en': '💳 Payment & Offers\n\nPayment Methods:\n✓ UPI (Google Pay, PhonePe)\n✓ Credit/Debit Card\n✓ Wallets\n\n🎁 Current Offers:\n• 20% off first booking\n• Free cancellation (2hrs)\n• Loyalty rewards',
      'mr': '💳 Payment & Offers\n\nPayment Methods:\n✓ UPI (Google Pay, PhonePe)\n✓ Card\n✓ Wallets\n\n🎁 Offers:\n• 20% सूट पहिल्या booking\n• Free cancellation\n• Loyalty rewards',
    },
    'profile': {
      'en': '👤 Manage Your Profile\n\nYou can update:\n• Home address\n• Phone number\n• Payment methods\n• Emergency contact\n• Service preferences\n\nWhat to change?',
      'mr': '👤 Profile व्यवस्थापित करा\n\nअपडेट करा:\n• घर पता\n• फोन नंबर\n• Payment methods\n• Emergency contact\n• Preferences\n\nकय बदलायचे?',
    },
    'greeting': {
      'en': '👋 Welcome to MahaMaintain Pro AI Assistant!\n\nI can help with:\n📋 Book Services\n📍 Track Bookings\n❓ FAQs\n🔍 Service Info\n💡 Recommendations\n📝 Complaints\n💳 Payment & Offers\n👤 Profile\n\nWhat can I do?',
      'mr': '👋 MahaMaintain Pro AI मध्ये स्वागत!\n\nमी मदत करू शकतो:\n📋 Services बुक करा\n📍 Bookings Track करा\n❓ FAQs\n🔍 Service Info\n💡 शिफारसी\n📝 समस्या\n💳 Payment & Offers\n👤 Profile\n\nकय करायचे?',
    },
  };

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _addMessage(_responses['greeting']![_isMarathi ? 'mr' : 'en']!, false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(Message(text: text, isUser: isUser, timestamp: DateTime.now()));
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleUserMessage(String message) {
    if (message.trim().isEmpty) return;

    _addMessage(message, true);
    _messageController.clear();

    String response = _getAIResponse(message);
    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(response, false);
    });
  }

  String _getAIResponse(String userMessage) {
    final msg = userMessage.toLowerCase();

    if (msg.contains('book') || msg.contains('service') || msg.contains('बुक') || msg.contains('सेवा')) {
      return _responses['booking']![_isMarathi ? 'mr' : 'en']!;
    } else if (msg.contains('status') || msg.contains('track') || msg.contains('where') || msg.contains('कहा') || msg.contains('कुठे')) {
      return _responses['status']![_isMarathi ? 'mr' : 'en']!;
    } else if (msg.contains('faq') || msg.contains('question') || msg.contains('help') || msg.contains('कसे') || msg.contains('असे')) {
      return _responses['faq']![_isMarathi ? 'mr' : 'en']!;
    } else if (msg.contains('price') || msg.contains('cost') || msg.contains('info') || msg.contains('किंमत') || msg.contains('माहिती')) {
      return _responses['service_info']![_isMarathi ? 'mr' : 'en']!;
    } else if (msg.contains('recommend') || msg.contains('suggest') || msg.contains('like') || msg.contains('सुचवा')) {
      return _responses['recommendation']![_isMarathi ? 'mr' : 'en']!;
    } else if (msg.contains('problem') || msg.contains('issue') || msg.contains('complaint') || msg.contains('समस्या')) {
      return _responses['complaint']![_isMarathi ? 'mr' : 'en']!;
    } else if (msg.contains('payment') || msg.contains('offer') || msg.contains('discount') || msg.contains('पेमेंट')) {
      return _responses['payment']![_isMarathi ? 'mr' : 'en']!;
    } else if (msg.contains('profile') || msg.contains('account') || msg.contains('update') || msg.contains('पत्ता')) {
      return _responses['profile']![_isMarathi ? 'mr' : 'en']!;
    } else {
      return _isMarathi
          ? '😊 मी समजला! आपल्याला कोणत्या बाबतीत मदत हवी?\n\n📋 Book | 📍 Track | ❓ FAQ\n🔍 Info | 💡 Suggest | 📝 Problem\n💳 Payment | 👤 Profile\n\nएक निवडा!'
          : '😊 I got it! What do you need help with?\n\n📋 Book | 📍 Track | ❓ FAQ\n🔍 Info | 💡 Suggest | 📝 Problem\n💳 Payment | 👤 Profile\n\nChoose one!';
    }
  }

  void _handleQuickReply(String category) {
    _addMessage(
      _isMarathi
          ? _getCategoryLabel(category, 'mr')
          : _getCategoryLabel(category, 'en'),
      true,
    );
    String response = _responses[category]![_isMarathi ? 'mr' : 'en']!;
    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(response, false);
    });
  }

  String _getCategoryLabel(String category, String lang) {
    const labels = {
      'booking': {'en': 'Book a service', 'mr': 'Service बुक करा'},
      'status': {'en': 'Track my booking', 'mr': 'मेरी booking track करा'},
      'faq': {'en': 'Help & FAQs', 'mr': 'मदत & FAQs'},
      'service_info': {'en': 'Service info', 'mr': 'Service माहिती'},
      'recommendation': {'en': 'Recommendations', 'mr': 'शिफारसी'},
      'complaint': {'en': 'Report issue', 'mr': 'समस्या रिपोर्ट'},
      'payment': {'en': 'Payment & offers', 'mr': 'Payment & ऑफर'},
      'profile': {'en': 'Manage profile', 'mr': 'Profile व्यवस्थापित करा'},
    };
    return labels[category]?[lang] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 380;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: screenWidth * 0.75,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: message.isUser
                            ? LinearGradient(
                                colors: [AppTheme.saffron, AppTheme.saffronDark],
                              )
                            : LinearGradient(
                                colors: [Colors.grey.shade100, Colors.grey.shade50],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        message.text,
                        style: TextStyle(
                          fontSize: isSmall ? 12 : 13,
                          color: message.isUser ? Colors.white : Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickButton('📋', 'booking'),
                  _buildQuickButton('📍', 'status'),
                  _buildQuickButton('❓', 'faq'),
                  _buildQuickButton('🔍', 'service_info'),
                  _buildQuickButton('💡', 'recommendation'),
                  _buildQuickButton('📝', 'complaint'),
                  _buildQuickButton('💳', 'payment'),
                  _buildQuickButton('👤', 'profile'),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isMarathi = !_isMarathi),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.saffron.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.saffron.withOpacity(0.3)),
                    ),
                    child: Text(
                      _isMarathi ? 'EN' : 'मराठी',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.saffron,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: _isMarathi ? 'संदेश लिहा...' : 'Type here...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (value) => _handleUserMessage(value),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _handleUserMessage(_messageController.text),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.saffron, AppTheme.saffronDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomFooter(
        selectedIndex: _footerSelectedIndex,
        onNavItemTap: (index) {
          setState(() {
            _footerSelectedIndex = index;
          });

          switch (index) {
            case 0:
              // TODO: Navigate to Home
              break;
            case 1:
              // TODO: Navigate to Bookings
              break;
            case 2:
              // Already on AI Chat
              break;
            case 3:
              // TODO: Navigate to History
              break;
            case 4:
              // TODO: Navigate to Profile
              break;
            case 5:
              // TODO: Navigate to Settings
              break;
          }
        },
      ),
    );
  }

  Widget _buildQuickButton(String emoji, String category) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _handleQuickReply(category),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.saffron.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.saffron.withOpacity(0.3),
            ),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
