import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../state/export_access_state.dart';
import '../services/purchase_manager.dart';

import '../state/agent_state.dart';
import '../utils/privacy_policy_screen.dart';
import '../utils/terms_screen.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final exportAccess = context.watch<ExportAccessState>();
    final purchaseManager = PurchaseManager();
    final agent = context.watch<AgentState>().agent;
    final accent = agent?.accentColor != null
    ? Color(agent!.accentColor!)
    : Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Image.asset(
            'assets/images/logo.png',
            color: accent,
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
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      
          ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          const SizedBox(height: 12),

          // Account Status
          Card(
            child: ListTile(
              title: const Text("Access Status"),
              subtitle: Text(
                exportAccess.hasUnlimitedAccess()
                    ? "Unlimited Plan Active"
                    : "Pay Per Home",
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Restore Purchases (Required)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
            onPressed: () async {
              await purchaseManager.initialize(context);
              await InAppPurchase.instance.restorePurchases();
            },
            child: const Text("Restore Purchases"),
          ),

          const SizedBox(height: 16),

          // Optional: Manage Subscription (Apple auto handles)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
              ),
            onPressed: () async {
              Uri url;

              if (Platform.isIOS) {
                url = Uri.parse('https://apps.apple.com/account/subscriptions');
              } else {
                url = Uri.parse(
                  'https://play.google.com/store/account/subscriptions',
                );
              }

              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text("Manage Subscription"),
          ),

          const SizedBox(height: 32),

          TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  },
  child: const Text("Privacy Policy"),
),

TextButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TermsScreen()),
    );
  },
  child: const Text("Terms of Service"),
),
          if (kDebugMode)
            const SizedBox(height: 32),

          if (kDebugMode)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                context.read<ExportAccessState>().toggleDevForceUnlock();
              },
              child: const Text("DEV: Toggle Unlimited Access"),
            ),
        ],
      ),
    );
    
  }

}
