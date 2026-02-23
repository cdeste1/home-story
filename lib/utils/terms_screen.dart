import 'package:flutter/material.dart';


class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});


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
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: (){Navigator.pop(context);},
              ),
               
          ],),
        body:  Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Text(
            '''
Terms of Service
Effective Date: February 2026

By using Home Story, you agree to the following:

Subscription Terms
Unlimited access is billed at \$399 per year and renews automatically unless canceled at least 24 hours before renewal through your Apple or Google account settings.

Payments are non-refundable except as required by Apple or Google policies.

Limitation of Liability
Home Dossier is not responsible for errors in documentation entered by users.

We may update these terms periodically.
            ''',
          ),
        ),
      ),
    );
  }
}
      