import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/purchase_manager.dart';
import '../models/home.dart';
import '../models/agent_profile.dart';
import '../state/asset_state.dart';
import '../state/home_state.dart';
import '../state/agent_state.dart';
import '../state/export_access_state.dart';
import '../utils/summary_helpers.dart';
import 'home_pdf_preview_screen.dart';

class HomeTransferScreen extends StatelessWidget {
  final Home home;

  const HomeTransferScreen({required this.home, super.key});

  @override
  Widget build(BuildContext context) {
    final assets = context.read<AssetState>().assetsForHome(home.id);
    final summary = countAssetsByCategory(assets);
    final agent = context.read<AgentState>().agent;
    final exportAccess = context.watch<ExportAccessState>();

    final accent = agent?.accentColor != null
        ? Color(agent!.accentColor!)
        : Theme.of(context).colorScheme.primary;

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
            Text(
              home.address,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "This home's digital twin contains everything the next owner needs.",
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),

            if (agent != null) _agentBrandingCard(context, agent, accent),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: summary.entries.map((entry) {
                  return Card(
                    elevation: 1,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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

            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(
                exportAccess.isHomeUnlocked(home.id) ||
                        exportAccess.hasUnlimitedAccess()
                    ? 'Export Home Transfer'
                    : 'Unlock Home Transfer',
              ),
              style: ElevatedButton.styleFrom(
                elevation: 2,
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: () async {
                if (exportAccess.isHomeUnlocked(home.id) ||
                    exportAccess.hasUnlimitedAccess()) {
                  await _exportPdf(context, home);
                } else {
                  _showUnlockDialog(context, home);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _agentBrandingCard(
      BuildContext context, AgentProfile agent, Color accent) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: accent.withOpacity(0.1),
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
                  Text('Closing Gift',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(agent.name,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(agent.brokerage,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, Home home) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeTransferPdfScreen(home: home),
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, Home home) {
    final purchaseManager = context.read<PurchaseManager>();
    final homeState = context.read<HomeState>();
    final agent = context.read<AgentState>().agent;
    final accent = agent?.accentColor != null
        ? Color(agent!.accentColor!)
        : Theme.of(context).colorScheme.primary;

    // Set the callback BEFORE showing the dialog.
    // When the purchase succeeds, this will close the dialog and navigate to PDF.
    purchaseManager.setOnUnlockListener((unlockedIds) {
      // Pop the dialog if it's still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      // Navigate to PDF if this home was among the unlocked ones
      if (unlockedIds.contains(home.id) || unlockedIds.isNotEmpty) {
        _exportPdf(context, home);
      }
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _UnlockDialog(
          home: home,
          accent: accent,
          purchaseManager: purchaseManager,
          homeState: homeState,
          onCancel: () {
            // Clear the listener if the user cancels without purchasing
            purchaseManager.onUnlockListener = null;
            Navigator.pop(dialogContext);
          },
        );
      },
    );
  }
}

/// Stateful dialog that watches PurchaseManager for loading/error states.
class _UnlockDialog extends StatelessWidget {
  final Home home;
  final Color accent;
  final PurchaseManager purchaseManager;
  final HomeState homeState;
  final VoidCallback onCancel;

  const _UnlockDialog({
    required this.home,
    required this.accent,
    required this.purchaseManager,
    required this.homeState,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Watch PurchaseManager so loading/error states rebuild the dialog
    return ChangeNotifierProvider.value(
      value: purchaseManager,
      child: Consumer<PurchaseManager>(
        builder: (context, pm, _) {
          return AlertDialog(
            title: const Text('Unlock Home Transfer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Choose how you'd like to unlock this home:"),
                const SizedBox(height: 24),

                if (pm.status == PurchaseFlowStatus.error) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      pm.errorMessage ?? 'Purchase failed. Please try again.',
                      style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // $59 single home
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: pm.isLoading
                      ? null // disable while processing
                      : () async {
                          await pm.buyHomeUnlock(home.id);
                        },
                  child: pm.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          '\$59 – Unlock this home permanently',
                          textAlign: TextAlign.center,
                        ),
                ),

                const SizedBox(height: 14),

                // $399 annual
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: pm.isLoading
                      ? null
                      : () async {
                          final allHomeIds = homeState.allHomeIds();
                          await pm.buyUnlimitedYearly(allHomeIds);
                        },
                  child: pm.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Column(
                          children: [
                            Text(
                              '\$399/year – Unlimited Homes',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Best for active agents • Cancel anytime',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: 18),

                TextButton(
                  onPressed: pm.isLoading ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}