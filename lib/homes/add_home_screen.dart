import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/home.dart';
import '../state/agent_state.dart';

class AddHomeScreen extends StatefulWidget {
  const AddHomeScreen({super.key});

  @override
  State<AddHomeScreen> createState() => _AddHomeScreenState();
}

class _AddHomeScreenState extends State<AddHomeScreen> {
  final _addressController = TextEditingController();
  final _yearController = TextEditingController();
  final _sqftController = TextEditingController();
  final _utilitiesController = TextEditingController();
  final _hoaController = TextEditingController();

  String? _exteriorImagePath;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickExteriorPhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (photo != null) {
      setState(() {
        _exteriorImagePath = photo.path;
      });
    }
  }

  void _saveHome() {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    final home = Home(
      id: Random().nextInt(100000).toString(),
      address: address,
      createdAt: DateTime.now(),
      yearBuilt: int.tryParse(_yearController.text),
      squareFeet: int.tryParse(_sqftController.text),
      utilities: _utilitiesController.text.isNotEmpty
          ? _utilitiesController.text
          : null,
      hoaInfo: _hoaController.text.isNotEmpty ? _hoaController.text : null,
      exteriorImagePath: _exteriorImagePath,
    );

    Navigator.pop(context, home);
  }

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<AgentState>().agent;
    final accent = agent?.accentColor != null
        ? Color(agent!.accentColor!)
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Home'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Home Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Year Built & Square Feet
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Year Built',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _sqftController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Square Footage',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Utilities
            TextField(
              controller: _utilitiesController,
              decoration: const InputDecoration(
                labelText: 'Utilities (Gas, Electric, Water)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // HOA Info
            TextField(
              controller: _hoaController,
              decoration: const InputDecoration(
                labelText: 'HOA Info (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Exterior Photo
            Text(
              'Exterior Photo',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickExteriorPhoto,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                ),
                child: _exteriorImagePath != null
                    ? Image.file(
                        File(_exteriorImagePath!),
                        fit: BoxFit.cover,
                      )
                    : const Center(
                        child: Icon(
                          Icons.camera_alt,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveHome,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
