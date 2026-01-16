import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/asset.dart';
import '../state/asset_state.dart';

class AssetDetailScreen extends StatefulWidget {
  final Asset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  State<AssetDetailScreen> createState() => _AssetDetailScreenState();
}

class _AssetDetailScreenState extends State<AssetDetailScreen> {
  late AssetCategory _category;
  final _roomController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _category = widget.asset.category;
    _roomController.text = widget.asset.room ?? '';
    _notesController.text = widget.asset.notes ?? '';
  }

  void _save() {
    final updated = Asset(
      id: widget.asset.id,
      homeId: widget.asset.homeId,
      imagePath: widget.asset.imagePath,
      category: _category,
      room: _roomController.text,
      notes: _notesController.text,
    );

    context.read<AssetState>().addAsset(updated);
    Navigator.pop(context);
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Asset?'),
        content: const Text(
            'Are you sure you want to delete this asset? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AssetState>().deleteAsset(widget.asset.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close asset detail screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tag Asset'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            color: Color(0XFF009A38),
            tooltip: 'Save Asset',
            onPressed: _save,
              ),
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            color: Color(0XFFE7001D),
            tooltip: 'Delete Asset',
            onPressed: _delete,
              ),
          ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.file(File(widget.asset.imagePath)),
            const SizedBox(height: 16),
            DropdownButtonFormField<AssetCategory>(
              initialValue: _category,
              items: AssetCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.name),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Room (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}
