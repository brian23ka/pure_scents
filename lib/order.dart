import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  // M-Pesa Credentials (Sandbox)
  final String consumerKey = "z7SnqTDlDCFt3PgTpJ22NIQSo7v5vzmIla38X02lPxFldr4r";
  final String consumerSecret = "Th1VcqVPra8wzUOfNBXK5vAHuaRHl92GMNpabkUEsxZYe310n0Vv2ENNtLzbqpGu";
  final String businessShortCode = "174379"; 
  final String passkey = "bfb277292146065a6f2ea11362d41e58e3beba91d953151d80c60ad0ad0801a"; 

  @override
  void initState() {
    super.initState();
    // Pre-fill fields with user data if available
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

  Future<String> _getAccessToken() async {
    String credentials = base64Encode(utf8.encode("$consumerKey:$consumerSecret"));
    var url = Uri.parse("https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials");
    
    var response = await http.get(url, headers: {
      "Authorization": "Basic $credentials",
    }).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return json.decode(response.body)["access_token"];
    } else {
      throw Exception("M-Pesa Auth Failed");
    }
  }

  Future<void> _submitOrder(CartProvider cart, UserProvider userProvider) async {
    if (!_formKey.currentState!.validate()) return;
    if (cart.items.isEmpty) return;

    setState(() {
      _isLoading = true;
      _loadingStatus = "Checking details...";
    });

    String mpesaStatus = "Pending";
    bool showManualInstructions = false;

    try {
      if (_selectedPaymentMethod == PaymentMethod.mpesa) {
        if (kIsWeb) {
          mpesaStatus = "Web: Manual Payment Expected";
          showManualInstructions = true;
        } else {
          setState(() => _loadingStatus = "Requesting M-Pesa Prompt...");
          try {
            String token = await _getAccessToken();
            String timestamp = DateFormat("yyyyMMddHHmmss").format(DateTime.now());
            String password = base64Encode(utf8.encode("$businessShortCode$passkey$timestamp"));
            
            String rawPhone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
            String formattedPhone = rawPhone.startsWith('0') 
                ? '254${rawPhone.substring(1)}' 
                : rawPhone.startsWith('254') ? rawPhone : '254$rawPhone';

            var mpesaResponse = await http.post(
              Uri.parse("https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest"),
              headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
              body: json.encode({
                "BusinessShortCode": businessShortCode,
                "Password": password,
                "Timestamp": timestamp,
                "TransactionType": "CustomerPayBillOnline",
                "Amount": cart.totalAmount, 
                "PartyA": formattedPhone,
                "PartyB": businessShortCode,
                "PhoneNumber": formattedPhone,
                "CallBackURL": "https://mydomain.com/callback", 
                "AccountReference": "PureScents",
                "TransactionDesc": "Perfume Order"
              }),
            ).timeout(const Duration(seconds: 12));

            if (mpesaResponse.statusCode == 200) {
              mpesaStatus = "Prompt Sent";
            } else {
              mpesaStatus = "Prompt Failed (Manual Payment)";
              showManualInstructions = true;
            }
          } catch (e) {
            debugPrint("STK Push Error: $e");
            mpesaStatus = "STK Error (Manual Payment)";
            showManualInstructions = true;
          }
        }
      } else {
        mpesaStatus = "Pay on Delivery";
      }

      setState(() => _loadingStatus = "Finalizing Order...");

      String orderItemsText = cart.items.values.map((i) => "${i.name} (x${i.quantity})").join(", ");

      final orderData = {
        'userId': userProvider.user?.uid,
        'name': _nameController.text.trim(),
        'reg_no': _regNoController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'items': orderItemsText,
        'total': "KSh ${cart.totalAmount}",
        'payment_method': _selectedPaymentMethod == PaymentMethod.mpesa ? "M-Pesa" : "Pay on Delivery",
        'mpesa_status': mpesaStatus,
      };

      // 1. Save to Firestore
      final firestoreData = Map<String, dynamic>.from(orderData);
      firestoreData['timestamp'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('orders').add(firestoreData);

      // 2. Update user details in their profile so they are remembered next time
      if (userProvider.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userProvider.user!.uid).update({
          'phone': _phoneController.text.trim(),
          'reg_no': _regNoController.text.trim(),
          'location': _locationController.text.trim(),
        });
        // Refresh local provider data
        await userProvider.fetchUserProfile();
      }

      // 3. Send to Formspree
      final formspreeData = Map<String, dynamic>.from(orderData);
      formspreeData['timestamp'] = DateTime.now().toIso8601String();
      http.post(
        Uri.parse('https://formspree.io/f/mbdeoybd'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formspreeData),
      ).timeout(const Duration(seconds: 5)).catchError((_) => http.Response('Error', 500));

      if (!mounted) return;
      cart.clear();
      _showSuccessDialog(showManualInstructions);

    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order failed: $error'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(bool manualMpesa) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('ORDER PLACED!', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              if (manualMpesa && _selectedPaymentMethod == PaymentMethod.mpesa) ...[
                const Text('Please pay manually to complete your order:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 15),
                const Text('M-Pesa Paybill: 174379'),
                const Text('Account: Pure Scents'),
                Text('Amount: KSh ${Provider.of<CartProvider>(context, listen: false).totalAmount}'),
                const Divider(),
                const SizedBox(height: 10),
                const Text('Your order has been saved permanently and can be tracked in your profile.'),
              ] else if (_selectedPaymentMethod == PaymentMethod.mpesa) ...[
                const Text('Success! Your order is saved. Please check your phone for the M-Pesa prompt.'),
              ] else ...[
                const Text('Order confirmed! It is now saved permanently in your profile history.'),
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
            child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold)),
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
                Text(_loadingStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildField(_nameController, 'Full Name', Icons.person),
                        const SizedBox(height: 15),
                        _buildField(_regNoController, 'Registration Number', Icons.badge),
                        const SizedBox(height: 15),
                        _buildField(_phoneController, 'M-Pesa Number', Icons.phone, isPhone: true),
                        const SizedBox(height: 15),
                        _buildField(_locationController, 'Delivery Location', Icons.location_on),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  RadioListTile<PaymentMethod>(
                    title: const Text('M-Pesa Payment'),
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
                  Text('TOTAL: KSh ${cart.totalAmount}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
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
      ),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }
}
