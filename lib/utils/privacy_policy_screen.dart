import 'package:flutter/material.dart';


class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});


  @override
  Widget build(BuildContext context) {
     Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'assets/images/logo.png',
            height: 75,
            fit: BoxFit.fitHeight,
          ),
        ),
        title: const Text('Home Story'),

        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0),
        body: const Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            '''
Privacy Policy
Effective Date: February 2026

Home Story ("we", "our", or "us") respects your privacy.

Information We Collect
We collect account information such as name and email when you create an account. We store home details and asset information that you voluntarily enter into the app.

Payments
All payments are securely processed by Apple App Store or Google Play. We do not store credit card information.

Data Storage
Home and asset data is stored locally on your device.

Contact
For questions, contact: cdeste1@gmail.com
            ''',
          ),
        ),
      ),
    );
  }
}
      