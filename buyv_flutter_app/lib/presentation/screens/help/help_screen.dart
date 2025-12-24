import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _faqItems = [
    {
      'category': 'Account',
      'question': 'How do I create an account?',
      'answer': 'To create an account, tap on "Sign Up" on the login screen, fill in your details including email, password, and personal information, then verify your email address.',
    },
    {
      'category': 'Account',
      'question': 'How do I reset my password?',
      'answer': 'On the login screen, tap "Forgot Password", enter your email address, and follow the instructions sent to your email to reset your password.',
    },
    {
      'category': 'Orders',
      'question': 'How do I track my order?',
      'answer': 'Go to "My Orders" in your profile, find your order, and tap "Track Order" to see real-time tracking information and delivery status.',
    },
    {
      'category': 'Orders',
      'question': 'Can I cancel my order?',
      'answer': 'You can cancel your order within 24 hours of placing it if it hasn\'t been shipped yet. Go to "My Orders" and tap "Cancel Order".',
    },
    {
      'category': 'Payment',
      'question': 'What payment methods do you accept?',
      'answer': 'We accept credit cards (Visa, MasterCard, American Express), PayPal, Apple Pay, Google Pay, and bank transfers.',
    },
    {
      'category': 'Payment',
      'question': 'Is my payment information secure?',
      'answer': 'Yes, we use industry-standard SSL encryption and comply with PCI DSS standards to protect your payment information.',
    },
    {
      'category': 'Shipping',
      'question': 'How long does shipping take?',
      'answer': 'Standard shipping takes 3-7 business days, express shipping takes 1-3 business days, and overnight shipping delivers the next business day.',
    },
    {
      'category': 'Shipping',
      'question': 'Do you ship internationally?',
      'answer': 'Yes, we ship to over 100 countries worldwide. Shipping costs and delivery times vary by destination.',
    },
    {
      'category': 'Returns',
      'question': 'What is your return policy?',
      'answer': 'We offer a 30-day return policy for unused items in original packaging. Some restrictions apply to certain product categories.',
    },
    {
      'category': 'Returns',
      'question': 'How do I return an item?',
      'answer': 'Go to "My Orders", find the item you want to return, tap "Return Item", select a reason, and follow the instructions to print a return label.',
    },
  ];

  final List<Map<String, dynamic>> _contactOptions = [
    {
      'title': 'Live Chat',
      'subtitle': 'Chat with our support team',
      'icon': Icons.chat_bubble_outline,
      'color': Colors.blue,
      'available': true,
      'hours': '24/7',
    },
    {
      'title': 'Email Support',
      'subtitle': 'support@buyv.com',
      'icon': Icons.email_outlined,
      'color': Colors.green,
      'available': true,
      'hours': 'Response within 24 hours',
    },
    {
      'title': 'Phone Support',
      'subtitle': '+1 (555) 123-4567',
      'icon': Icons.phone_outlined,
      'color': Colors.orange,
      'available': true,
      'hours': 'Mon-Fri 9AM-6PM EST',
    },
    {
      'title': 'WhatsApp',
      'subtitle': 'Message us on WhatsApp',
      'icon': Icons.message_outlined,
      'color': Colors.green,
      'available': true,
      'hours': '24/7',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Contact'),
            Tab(text: 'Guides'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(),
          _buildContactTab(),
          _buildGuidesTab(),
        ],
      ),
    );
  }

  Widget _buildFAQTab() {
    final filteredFAQs = _faqItems.where((faq) {
      return faq['question'].toLowerCase().contains(_searchQuery) ||
             faq['answer'].toLowerCase().contains(_searchQuery) ||
             faq['category'].toLowerCase().contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search FAQ...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
        ),
        
        // FAQ Categories
        if (_searchQuery.isEmpty) ...[
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', 'Account', 'Orders', 'Payment', 'Shipping', 'Returns']
                  .map((category) => Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: false,
                          onSelected: (selected) {
                            // Filter by category
                          },
                          backgroundColor: Colors.grey[900],
                          selectedColor: Colors.blue.withValues(alpha: 0.3),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
        
        // FAQ List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredFAQs.length,
            itemBuilder: (context, index) {
              final faq = filteredFAQs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ExpansionTile(
                  title: Text(
                    faq['question'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      faq['category'],
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  iconColor: Colors.white,
                  collapsedIconColor: Colors.grey,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        faq['answer'],
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact Options
          const Text(
            'Get in Touch',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ..._contactOptions.map((option) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: option['color'].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  option['icon'],
                  color: option['color'],
                  size: 24,
                ),
              ),
              title: Text(
                option['title'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option['subtitle'],
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: option['available'] ? Colors.green : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        option['hours'],
                        style: TextStyle(
                          color: option['available'] ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Icon(Icons.arrow_forward_ios, color: option['color'] as Color, size: 16),
              onTap: () => _handleContactOption(option),
            ),
          )),
          
          const SizedBox(height: 24),
          
          // Quick Contact Form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Message',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Subject',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Your message...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Message sent successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Send Message',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuidesTab() {
    final guides = [
      {
        'title': 'Getting Started',
        'description': 'Learn the basics of using our app',
        'icon': Icons.play_circle_outline,
        'color': Colors.green,
        'steps': 5,
      },
      {
        'title': 'Making Your First Order',
        'description': 'Step-by-step guide to placing an order',
        'icon': Icons.shopping_cart_outlined,
        'color': Colors.blue,
        'steps': 7,
      },
      {
        'title': 'Managing Your Account',
        'description': 'Update profile, settings, and preferences',
        'icon': Icons.person_outline,
        'color': Colors.purple,
        'steps': 4,
      },
      {
        'title': 'Payment & Billing',
        'description': 'Add payment methods and manage billing',
        'icon': Icons.payment_outlined,
        'color': Colors.orange,
        'steps': 6,
      },
      {
        'title': 'Tracking & Returns',
        'description': 'Track orders and process returns',
        'icon': Icons.local_shipping_outlined,
        'color': Colors.red,
        'steps': 3,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: guides.length,
      itemBuilder: (context, index) {
        final guide = guides[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: (guide['color'] as Color).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                guide['icon'] as IconData,
                color: guide['color'] as Color,
                size: 24,
              ),
            ),
            title: Text(
              guide['title'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guide['description'] as String,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                    '${guide['steps']} steps',
                    style: TextStyle(
                      color: guide['color'] as Color,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            onTap: () => _openGuide(guide),
          ),
        );
      },
    );
  }

  void _handleContactOption(Map<String, dynamic> option) async {
    switch (option['title']) {
      case 'Live Chat':
        _showLiveChatDialog();
        break;
      case 'Email Support':
        try {
          // Launch email client with pre-filled support email
          final Uri emailUri = Uri(
            scheme: 'mailto',
            path: 'support@buyv.com',
            query: 'subject=Support Request&body=Hello, I need help with...',
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening email client...'),
              backgroundColor: Colors.blue,
            ),
          );
          
          // In a real app, you would use url_launcher package
          // await launchUrl(emailUri);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open email client'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case 'Phone Support':
        try {
          // Launch phone dialer with support number
          final Uri phoneUri = Uri(scheme: 'tel', path: '+1-800-BUYV-HELP');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Calling support...'),
              backgroundColor: Colors.orange,
            ),
          );
          
          // In a real app, you would use url_launcher package
          // await launchUrl(phoneUri);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not make phone call'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case 'WhatsApp':
        try {
          // Launch WhatsApp with support number
          final Uri whatsappUri = Uri.parse('https://wa.me/18005287835?text=Hello, I need help with...');
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening WhatsApp...'),
              backgroundColor: Colors.green,
            ),
          );
          
          // In a real app, you would use url_launcher package
          // await launchUrl(whatsappUri);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
    }
  }

  void _showLiveChatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Live Chat',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Would you like to start a live chat session with our support team?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Starting live chat...'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }

  void _openGuide(Map<String, dynamic> guide) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (guide['color'] as Color).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      guide['icon'] as IconData,
                      color: guide['color'] as Color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      guide['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                guide['description'] as String,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: guide['steps'],
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: guide['color'] as Color,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Step ${index + 1}: This is a sample step description for ${guide['title'] as String}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
        ),
      ),
    );
  }
}