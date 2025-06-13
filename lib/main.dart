import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PhonePe Payment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const PaymentPage(),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _amountController = TextEditingController();

  bool _isLoading = false;
  String? _paymentStatus;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> initiatePhonePePayment(Map<String, String> formData) async {
    const String backendUrl =
        'https://phonepev2-backend-sdk.vercel.app/api/standardPayment';

    try {
      setState(() {
        _isLoading = true;
        _paymentStatus = null;
      });

      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(formData),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        final String merchantId = responseData['merchantId'];
        final String flowId = responseData['flowId'];
        final String orderId = responseData['data']['orderId'];
        final String token = responseData['data']['token'];
        const String environment = 'SANDBOX';
        const String appSchema = ''; // iOS only

        PhonePePaymentSdk.init(environment, merchantId, flowId, true);

        final payload = {
          "orderId": orderId,
          "merchantId": merchantId,
          "token": token,
          "paymentMode": {"type": "PAY_PAGE"},
        };

        final request = jsonEncode(payload);
        await PhonePePaymentSdk.startTransaction(request, appSchema);

        setState(() {
          _paymentStatus = 'Payment initiated successfully.';
        });
      } else {
        setState(() {
          _paymentStatus = 'Failed to initiate payment. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _paymentStatus = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onPayNow() {
    if (_formKey.currentState!.validate()) {
      final formData = {
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "email": _emailController.text.trim(),
        "mobileNumber": _mobileController.text.trim(),
        "amount": _amountController.text.trim(),
      };
      initiatePhonePePayment(formData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("PhonePe Payment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildTextField(_firstNameController, 'First Name'),
                    _buildTextField(_lastNameController, 'Last Name'),
                    _buildTextField(_emailController, 'Email',
                        keyboardType: TextInputType.emailAddress),
                    _buildTextField(_mobileController, 'Mobile Number',
                        keyboardType: TextInputType.phone),
                    _buildTextField(_amountController, 'Amount',
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _onPayNow,
                      child: const Text("Pay Now"),
                    ),
                    if (_paymentStatus != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _paymentStatus!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: labelText),
        keyboardType: keyboardType,
        validator: (value) => (value == null || value.trim().isEmpty)
            ? 'This field is required'
            : null,
      ),
    );
  }
}