import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/home.dart';
import '../state/agent_state.dart';

class HomeFolderScreen extends StatelessWidget {
  final Home home;

  const HomeFolderScreen({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Home Folder'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Address
          Text(
            home.address,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          // Agent
          if (agent != null)
            Text(
              'Courtesy of ${agent.name}${agent.brokerage.isNotEmpty ? ' • ${agent.brokerage}' : ''}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[600]),
            ),

          const SizedBox(height: 24),

          _infoRow('Year Built', home.yearBuilt?.toString()),
          _infoRow('Square Feet', home.squareFeet?.toString()),
          _infoRow('Utilities', home.utilities),
          _infoRow('HOA Info', home.hoaInfo),

          const SizedBox(height: 32),

          // Export CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // You already handle export elsewhere
                Navigator.pop(context);
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Export Home Transfer Folder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
