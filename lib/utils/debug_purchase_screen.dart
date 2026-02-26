import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/purchase_manager.dart';
import '../state/export_access_state.dart';

class DebugPurchaseScreen extends StatefulWidget {
  final List<String> unlockedIds; // passed from the onUnlockListener callback
  final String triggeredFromHomeId;

  const DebugPurchaseScreen({
    required this.unlockedIds,
    required this.triggeredFromHomeId,
    super.key,
  });

  @override
  State<DebugPurchaseScreen> createState() => _DebugPurchaseScreenState();
}

class _DebugPurchaseScreenState extends State<DebugPurchaseScreen> {
  final List<String> _log = [];

  @override
  void initState() {
    super.initState();
    _log.add('[${_ts()}] DebugPurchaseScreen opened');
    _log.add('[${_ts()}] triggeredFromHomeId: ${widget.triggeredFromHomeId}');
    _log.add('[${_ts()}] unlockedIds passed in: ${widget.unlockedIds}');
    _log.add('[${_ts()}] unlockedIds.contains(homeId): ${widget.unlockedIds.contains(widget.triggeredFromHomeId)}');

    // Also snapshot current state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final exportAccess = context.read<ExportAccessState>();
      final pm = context.read<PurchaseManager>();
      setState(() {
        _log.add('--- ExportAccessState snapshot ---');
        _log.add('hasUnlimitedAccess: ${exportAccess.hasUnlimitedAccess()}');
        _log.add('subscriptionExpiry: ${exportAccess.subscriptionExpiry}');
        _log.add('isHomeUnlocked(${widget.triggeredFromHomeId}): ${exportAccess.isHomeUnlocked(widget.triggeredFromHomeId)}');
        _log.add('--- PurchaseManager snapshot ---');
        _log.add('status: ${pm.status}');
        _log.add('pendingHomeIds: ${pm.pendingHomeIds}');
        _log.add('onUnlockListener set: ${pm.onUnlockListener != null}');
      });
    });
  }

  String _ts() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute}:${now.second}.${now.millisecond}';
  }

  @override
  Widget build(BuildContext context) {
    final exportAccess = context.watch<ExportAccessState>();
    final pm = context.watch<PurchaseManager>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Debug'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.greenAccent,
      ),
      backgroundColor: Colors.black,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _section('WHY THIS SCREEN OPENED', [
            _row('unlockedIds passed in', widget.unlockedIds.toString()),
            _row('triggeredFromHomeId', widget.triggeredFromHomeId),
            _row('contains homeId?', '${widget.unlockedIds.contains(widget.triggeredFromHomeId)}'),
          ]),

          _section('EXPORT ACCESS STATE (live)', [
            _row('hasUnlimitedAccess()', '${exportAccess.hasUnlimitedAccess()}'),
            _row('subscriptionExpiry', '${exportAccess.subscriptionExpiry}'),
            _row('isHomeUnlocked(homeId)', '${exportAccess.isHomeUnlocked(widget.triggeredFromHomeId)}'),
          ]),

          _section('PURCHASE MANAGER (live)', [
            _row('status', '${pm.status}'),
            _row('pendingHomeIds', '${pm.pendingHomeIds}'),
            _row('onUnlockListener set?', '${pm.onUnlockListener != null}'),
            _row('isLoading', '${pm.isLoading}'),
          ]),

          _section('INIT LOG', _log.map((l) => _logLine(l)).toList()),

          const SizedBox(height: 32),
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: Colors.greenAccent),
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            color: Colors.greenAccent,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const Divider(color: Colors.green),
        ...rows,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logLine(String line) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        line,
        style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
      ),
    );
  }
}