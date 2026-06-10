import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart.dart';
import 'auth.dart';

enum PaymentMethod { mpesa, payOnDelivery }

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regNoController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  PaymentMethod _selectedPaymentMethod = PaymentMethod.mpesa;
  bool _isLoading = false;
  String _loadingStatus = "Processing Order...";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user != null) {
        _nameController.text = userProvider.fullName;
        _regNoController.text = userProvider.regNo;
        _phoneController.text = userProvider.phone;
        _locationController.text = userProvider.location;
      }
    });
  }

  Future<void> _submitOrder(CartProvider cart, UserProvider userProvider) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: Colors.orange)
      );
      return;
    }
    
    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your bag is empty. Add items before checking out.'))
      );
      return;
    }

    // Capture values before processing/clearing
    final int finalTotal = cart.totalAmount;
    final String itemsSummary = cart.items.values.map((i) => "${i.name} (x${i.quantity})").join(", ");

    setState(() {
      _isLoading = true;
      _loadingStatus = "Saving your order...";
    });

    try {
      final orderData = {
        'userId': userProvider.user?.uid,
        'name': _nameController.text.trim(),
        'reg_no': _regNoController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'items': itemsSummary,
        'total': "KSh $finalTotal",
        'payment_method': _selectedPaymentMethod == PaymentMethod.mpesa ? "M-Pesa (Send Money)" : "Pay on Delivery",
        'status': "Pending",
        'timestamp': FieldValue.serverTimestamp(),
      };

      // 1. Save to Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .add(orderData)
          .timeout(const Duration(seconds: 15));

      // 2. Update user profile details
      if (userProvider.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userProvider.user!.uid)
            .set({
              'phone': _phoneController.text.trim(),
              'reg_no': _regNoController.text.trim(),
              'location': _locationController.text.trim(),
            }, SetOptions(merge: true))
            .timeout(const Duration(seconds: 10));
        await userProvider.fetchUserProfile();
      }

      // 3. Send to Formspree Backup (Fire and forget)
      final formspreeData = Map<String, dynamic>.from(orderData);
      formspreeData.remove('timestamp'); // FieldValue doesn't encode to JSON
      formspreeData['order_date'] = DateTime.now().toIso8601String();
      
      http.post(
        Uri.parse('https://formspree.io/f/mbdeoybd'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formspreeData),
      ).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('Error', 500));

      if (!mounted) return;
      cart.clear();
      
      _showSuccessDialog(finalTotal);

    } catch (error) {
      debugPrint("Order Error: $error");
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: ${error.toString()}'), 
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(int total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('ORDER PLACED!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              if (_selectedPaymentMethod == PaymentMethod.mpesa) ...[
                const Text('To complete your order, please send money to:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 15),
                const Text('M-Pesa Number: +254 116 145544', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('Name: Pure Scents Ltd'),
                Text('Amount: KSh $total', style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                const SizedBox(height: 10),
                const Text('After payment, your order will be processed. You can track it in your profile.'),
              ] else ...[
                const Text('Order confirmed! We will contact you shortly for delivery. Payment will be made on delivery.'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('CHECKOUT', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF004D40)),
                const SizedBox(height: 25),
                Text(_loadingStatus, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${userProvider.fullName.isNotEmpty ? userProvider.fullName.split(" ")[0] : "User"}!',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF004D40)),
                  ),
                  const Text(
                    'Confirm your delivery details below:',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildField(_nameController, 'Full Name', Icons.person),
                        const SizedBox(height: 15),
                        _buildField(_regNoController, 'Registration Number', Icons.badge),
                        const SizedBox(height: 15),
                        _buildField(_phoneController, 'Your Phone Number', Icons.phone, isPhone: true),
                        const SizedBox(height: 15),
                        _buildField(_locationController, 'Delivery Location', Icons.location_on),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  RadioListTile<PaymentMethod>(
                    title: const Text('M-Pesa (Send Money)'),
                    subtitle: const Text('Payment details shown after order'),
                    activeColor: const Color(0xFF004D40),
                    value: PaymentMethod.mpesa,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                  ),
                  RadioListTile<PaymentMethod>(
                    title: const Text('Pay on Delivery'),
                    activeColor: const Color(0xFF004D40),
                    value: PaymentMethod.payOnDelivery,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                  ),
                  const Divider(height: 50),
                  Center(child: Text('TOTAL: KSh ${cart.totalAmount}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF004D40)))),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submitOrder(cart, userProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('COMPLETE ORDER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label, 
        prefixIcon: Icon(icon, color: const Color(0xFF004D40)), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF004D40), width: 2),
        ),
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}
