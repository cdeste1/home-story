//import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../services/purchase_manager.dart';
import '../models/home.dart';
//import '../models/asset.dart';
import '../models/agent_profile.dart';
import '../state/asset_state.dart';
import '../state/agent_state.dart';
import '../state/export_access_state.dart';
import '../utils/summary_helpers.dart';
import '../utils/home_transfer_pdf.dart';

class HomeTransferScreen extends StatelessWidget {
  final Home home;
  const HomeTransferScreen({required this.home, super.key});

  @override
  Widget build(BuildContext context) {
    final assets = context.read<AssetState>().assetsForHome(home.id);
    final summary = countAssetsByCategory(assets);
    final agent = context.read<AgentState>().agent;
    
    final exportAccess = context.watch<ExportAccessState>();
    // If agent accent color exists, use it; otherwise fallback to theme
    final accent = agent?.accentColor != null
    ? Color(agent!.accentColor!) // convert int to Color
    : Theme.of(context).colorScheme.primary;
    

    // Temporary agent info until form is ready
    /*context.read<AgentState>().save(
      /*AgentProfile(
        name: 'Jane Smith',
        brokerage: 'Smith Realty Group',
        email: 'jane@smithrealty.com',
        phone: '(555) 123-4567',
        accentColor: Color.fromARGB(255, 255, 0, 0).value,
      ),*/
    );*/

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Transfer'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Header
            Text(
              home.address,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "This home's digital twin contains everything the next owner needs.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            // Agent Branding Card
            if (agent != null) _agentBrandingCard(context, agent, accent),
            const SizedBox(height: 16),

            // Asset summary cards
            Expanded(
              child: ListView(
                children: summary.entries.map((entry) {
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline, color: accent),
                      title: Text(entry.key.name.toUpperCase()),
                      trailing: Text(
                        entry.value.toString(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Export Button
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(
                exportAccess.isHomeUnlocked(home.id)
                    ? 'Export Home Transfer'
                    : 'Unlock Home Transfer',
              ),
              style: ElevatedButton.styleFrom(
                elevation: 2,
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () async {
                if (!exportAccess.isHomeUnlocked(home.id)) {
                  _showUnlockDialog(context);
                  return;
                }
                await _exportPdf(context, home);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _agentBrandingCard(BuildContext context, AgentProfile agent, Color accent) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: accent.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.verified_outlined, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Closing Gift', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(agent.name, style: Theme.of(context).textTheme.titleMedium),
                  Text(agent.brokerage, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, Home home) async {
    final assets = context.read<AssetState>().assetsForHome(home.id);
    final agent = context.read<AgentState>().agent;

    final pdf = await buildHomeTransferPdf(
    home: home,
    assets: assets,
    agent: agent,
  );
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _showUnlockDialog(BuildContext context) {
  final purchaseManager = PurchaseManager();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Unlock Home Transfer'),
      content: const Text(
        'Choose how you’d like to unlock this home:',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        // Per Home Option
        ElevatedButton(
          onPressed: () async {
            await purchaseManager.initialize(context);
            await purchaseManager.buyHomeUnlock(home.id);
            Navigator.pop(context);
          },
          child: const Text('\$59 Unlock this home permanently'),
        ),

        // Unlimited Option
        ElevatedButton(
          onPressed: () async {
            await purchaseManager.initialize(context);
            await purchaseManager.buyUnlimitedYearly();
            Navigator.pop(context);
          },
          child: const Text(
            '\$399/year – Unlimited homes\n'
            'Best for active agents (8+ homes/year)\n'
            'Auto-renews annually. Cancel anytime in Settings.'
          ),
        ),
      ],
    ),
  );
}
}
