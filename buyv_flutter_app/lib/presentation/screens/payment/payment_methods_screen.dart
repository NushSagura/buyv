import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': '1',
      'type': 'Credit Card',
      'name': 'Visa ending in 1234',
      'icon': Icons.credit_card,
      'isDefault': true,
      'expiryDate': '12/25',
    },
    {
      'id': '2',
      'type': 'Credit Card',
      'name': 'Mastercard ending in 5678',
      'icon': Icons.credit_card,
      'isDefault': false,
      'expiryDate': '08/26',
    },
    {
      'id': '3',
      'type': 'PayPal',
      'name': 'user@example.com',
      'icon': Icons.account_balance_wallet,
      'isDefault': false,
      'expiryDate': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF114B7F)),
            onPressed: () => context.go('/settings'),
          ),
          title: const Text(
            'Payment Methods',
            style: TextStyle(
              color: Color(0xFF114B7F),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFF6F00)),
            onPressed: _addPaymentMethod,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                return _buildPaymentMethodCard(method, index);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addPaymentMethod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6F00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Add New Payment Method',
                  style: TextStyle(
                    color: const Color(0xFF114B7F),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: method['isDefault'] ? Colors.blue : Colors.grey[200]!,
          width: method['isDefault'] ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    method['icon'],
                    color: const Color(0xFF114B7F),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            method['name'],
                            style: const TextStyle(
                              color: const Color(0xFF114B7F),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (method['isDefault']) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Default',
                                style: TextStyle(
                                  color: const Color(0xFF114B7F),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        method['type'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (method['expiryDate'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Expires ${method['expiryDate']}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  color: Colors.grey[200],
                  onSelected: (value) => _handleMenuAction(value, index),
                  itemBuilder: (context) => [
                    if (!method['isDefault'])
                      const PopupMenuItem(
                        value: 'set_default',
                        child: Text(
                          'Set as Default',
                          style: TextStyle(color: const Color(0xFF114B7F)),
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text(
                        'Edit',
                        style: TextStyle(color: const Color(0xFF114B7F)),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action, int index) {
    switch (action) {
      case 'set_default':
        _setAsDefault(index);
        break;
      case 'edit':
        _editPaymentMethod(index);
        break;
      case 'delete':
        _deletePaymentMethod(index);
        break;
    }
  }

  void _setAsDefault(int index) {
    setState(() {
      // Remove default from all methods
      for (var method in _paymentMethods) {
        method['isDefault'] = false;
      }
      // Set selected method as default
      _paymentMethods[index]['isDefault'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default payment method updated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _editPaymentMethod(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[100],
        title: const Text(
          'Edit Payment Method',
          style: TextStyle(color: const Color(0xFF114B7F)),
        ),
        content: const Text(
          'Payment method editing functionality will be implemented here.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deletePaymentMethod(int index) {
    final method = _paymentMethods[index];
    
    if (method['isDefault'] && _paymentMethods.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete default payment method. Set another as default first.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[100],
        title: const Text(
          'Delete Payment Method',
          style: TextStyle(color: const Color(0xFF114B7F)),
        ),
        content: Text(
          'Are you sure you want to delete ${method['name']}?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _paymentMethods.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment method deleted'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _addPaymentMethod() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[100],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Payment Method',
              style: TextStyle(
                color: const Color(0xFF114B7F),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildPaymentOption('Credit/Debit Card', Icons.credit_card),
            _buildPaymentOption('PayPal', Icons.account_balance_wallet),
            _buildPaymentOption('Apple Pay', Icons.phone_iphone),
            _buildPaymentOption('Google Pay', Icons.android),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF114B7F)),
      title: Text(
        title,
        style: const TextStyle(color: const Color(0xFF114B7F)),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title setup will be implemented'),
            backgroundColor: const Color(0xFFFF6F00),
          ),
        );
      },
    );
  }
}
