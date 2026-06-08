import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'cart.dart';

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

  // M-Pesa Credentials (Sandbox)
  final String consumerKey = "z7SnqTDlDCFt3PgTpJ22NIQSo7v5vzmIla38X02lPxFldr4r";
  final String consumerSecret = "Th1VcqVPra8wzUOfNBXK5vAHuaRHl92GMNpabkUEsxZYe310n0Vv2ENNtLzbqpGu";
  final String businessShortCode = "174379"; 
  final String passkey = "bfb277292146065a6f2ea11362d41e58e3beba91d953151d80c60ad0ad0801a"; 

  Future<String> _getAccessToken() async {
    String credentials = base64Encode(utf8.encode("$consumerKey:$consumerSecret"));
    var url = Uri.parse("https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials");
    
    var response = await http.get(url, headers: {
      "Authorization": "Basic $credentials",
    });

    if (response.statusCode == 200) {
      return json.decode(response.body)["access_token"];
    } else {
      debugPrint("M-Pesa Auth Error: ${response.body}");
      throw Exception("Failed to get access token. Check credentials.");
    }
  }

  Future<void> _submitOrder(CartProvider cart) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String mpesaStatus = "N/A";
      String mpesaResponseBody = "";

      if (_selectedPaymentMethod == PaymentMethod.mpesa) {
        String token = await _getAccessToken();
        String timestamp = DateFormat("yyyyMMddHHmmss").format(DateTime.now());
        String password = base64Encode(utf8.encode("$businessShortCode$passkey$timestamp"));
        
        String rawPhone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
        String formattedPhone = "";
        
        if (rawPhone.startsWith('0')) {
          formattedPhone = '254${rawPhone.substring(1)}';
        } else if (rawPhone.startsWith('254') && rawPhone.length == 12) {
          formattedPhone = rawPhone;
        } else if (rawPhone.length == 9 && (rawPhone.startsWith('7') || rawPhone.startsWith('1'))) {
          formattedPhone = '254$rawPhone';
        }

        if (formattedPhone.length != 12) {
          throw Exception("Invalid phone format. Please enter a valid number (e.g., 07xxxxxxxx).");
        }

        var mpesaUrl = Uri.parse("https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest");
        
        var mpesaResponse = await http.post(
          mpesaUrl,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: json.encode({
            "BusinessShortCode": businessShortCode,
            "Password": password,
            "Timestamp": timestamp,
            "TransactionType": "CustomerPayBillOnline",
            "Amount": cart.totalAmount, 
            "PartyA": formattedPhone,
            "PartyB": businessShortCode,
            "PhoneNumber": formattedPhone,
            "CallBackURL": "https://mydomain.com/path", 
            "AccountReference": "Pure Scents",
            "TransactionDesc": "Perfume Payment"
          }),
        );

        mpesaResponseBody = mpesaResponse.body;
        debugPrint("M-Pesa STK Response: $mpesaResponseBody");

        if (mpesaResponse.statusCode == 200) {
          var responseData = json.decode(mpesaResponseBody);
          if (responseData["ResponseCode"] == "0") {
            mpesaStatus = "STK Push Initiated";
          } else {
            throw Exception(responseData["ResponseDescription"] ?? "STK Push failed.");
          }
        } else {
          throw Exception("M-Pesa request failed with status ${mpesaResponse.statusCode}");
        }
      } else {
        mpesaStatus = "Pay on Delivery";
      }

      // Send to Formspree
      String orderDetails = "";
      cart.items.forEach((key, item) {
        orderDetails += "${item.name} (${item.quantity}x) - KSh ${item.priceValue * item.quantity}\n";
      });

      final formspreeUrl = Uri.parse('https://formspree.io/f/mbdeoybd');
      await http.post(
        formspreeUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': _nameController.text,
          'reg_no': _regNoController.text,
          'phone': _phoneController.text,
          'location': _locationController.text,
          'items': orderDetails,
          'total': "KSh ${cart.totalAmount}",
          'payment_method': _selectedPaymentMethod == PaymentMethod.mpesa ? "M-Pesa" : "Pay on Delivery",
          'mpesa_status': mpesaStatus,
          'mpesa_raw_response': mpesaResponseBody,
        }),
      );

      if (!mounted) return;
      cart.clear();
      _showSuccessDialog();

    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error.toString().replaceAll("Exception: ", "")}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    String message = _selectedPaymentMethod == PaymentMethod.mpesa
        ? 'STK Push initiated! Please enter your PIN on your phone to complete the payment.'
        : 'Your order has been placed successfully. You will pay upon delivery.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Order Placed!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CHECKOUT', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF004D40)),
                SizedBox(height: 20),
                Text("Processing Order..."),
              ],
            ))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DELIVERY & CONTACT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
                  const SizedBox(height: 25),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(_nameController, 'Full Name', Icons.person, 'Enter your name'),
                        const SizedBox(height: 20),
                        _buildTextField(_regNoController, 'Registration Number', Icons.app_registration, 'Enter Reg No'),
                        const SizedBox(height: 20),
                        _buildTextField(
                          _phoneController, 
                          'Phone Number (e.g., 07xx...)', 
                          Icons.phone_android, 
                          'Enter valid Kenyan phone number', 
                          isPhone: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter phone number';
                            String cleaned = value.replaceAll(RegExp(r'\D'), '');
                            if (cleaned.length < 9) return 'Invalid phone number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(_locationController, 'Delivery Location', Icons.location_on, 'Enter location'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('SELECT PAYMENT METHOD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  RadioListTile<PaymentMethod>(
                    title: const Text('M-Pesa (STK Push)'),
                    value: PaymentMethod.mpesa,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (PaymentMethod? value) {
                      setState(() => _selectedPaymentMethod = value!);
                    },
                  ),
                  RadioListTile<PaymentMethod>(
                    title: const Text('Pay on Delivery'),
                    value: PaymentMethod.payOnDelivery,
                    groupValue: _selectedPaymentMethod,
                    onChanged: (PaymentMethod? value) {
                      setState(() => _selectedPaymentMethod = value!);
                    },
                  ),
                  const SizedBox(height: 30),
                  const Text('ORDER SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
                  const SizedBox(height: 20),
                  ...cart.items.values.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item.name} x ${item.quantity}'),
                            Text('KSh ${item.priceValue * item.quantity}'),
                          ],
                        ),
                      )),
                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL AMOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('KSh ${cart.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF004D40))),
                    ],
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _submitOrder(cart),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: Text(
                        _selectedPaymentMethod == PaymentMethod.mpesa
                            ? 'PAY VIA M-PESA & PLACE ORDER'
                            : 'PLACE ORDER (PAY ON DELIVERY)',
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String errorMsg, {bool isPhone = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF004D40)),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF004D40), width: 2)),
      ),
      validator: validator ?? (value) => value == null || value.isEmpty ? errorMsg : null,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regNoController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
