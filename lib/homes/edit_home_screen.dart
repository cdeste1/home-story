import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/home.dart';
import '../state/home_state.dart';
import '../state/agent_state.dart';

class EditHomeScreen extends StatefulWidget {
  final Home home;

  const EditHomeScreen({super.key, required this.home});

  @override
  State<EditHomeScreen> createState() => _EditHomeScreenState();
}

class _EditHomeScreenState extends State<EditHomeScreen> {
  late TextEditingController _addressController;
  late TextEditingController _yearController;
  late TextEditingController _sqftController;
  late TextEditingController _utilitiesController;
  late TextEditingController _hoaController;

  String? _exteriorImagePath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    _addressController =
        TextEditingController(text: widget.home.address);

    _yearController = TextEditingController(
        text: widget.home.yearBuilt?.toString() ?? '');

    _sqftController = TextEditingController(
        text: widget.home.squareFeet?.toString() ?? '');

    _utilitiesController =
        TextEditingController(text: widget.home.utilities ?? '');

    _hoaController =
        TextEditingController(text: widget.home.hoaInfo ?? '');

    _exteriorImagePath = widget.home.exteriorImagePath;
  }

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

  void _saveChanges() {
    final updatedHome = widget.home.copyWith(
      address: _addressController.text.trim(),
      yearBuilt: int.tryParse(_yearController.text),
      squareFeet: int.tryParse(_sqftController.text),
      utilities: _utilitiesController.text.isNotEmpty
          ? _utilitiesController.text
          : null,
      hoaInfo: _hoaController.text.isNotEmpty
          ? _hoaController.text
          : null,
      exteriorImagePath: _exteriorImagePath,
    );

    context.read<HomeState>().updateHome(updatedHome);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<AgentState>().agent;
    final accent = agent?.accentColor != null
        ? Color(agent!.accentColor!)
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Home'),
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
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Save Changes'),
              ),
            ),

            const SizedBox(height: 16),

            // Delete Button
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Home'),
                    content: const Text(
                        'Are you sure you want to delete this home? This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  context
                      .read<HomeState>()
                      .deleteHome(widget.home.id);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Delete Home',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}