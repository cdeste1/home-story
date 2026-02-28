import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/agent_profile.dart';
import '../state/agent_state.dart';

class EditAgentScreen extends StatefulWidget {
  const EditAgentScreen({super.key});

  @override
  State<EditAgentScreen> createState() => _EditAgentScreenState();
}

class _EditAgentScreenState extends State<EditAgentScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brokerageController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  int? _selectedAccentColor;
  String? _selectedLogoPath;

  @override
  void initState() {
    super.initState();
    final agent = context.read<AgentState>().agent;
    _nameController = TextEditingController(text: agent?.name ?? '');
    _brokerageController = TextEditingController(text: agent?.brokerage ?? '');
    _emailController = TextEditingController(text: agent?.email ?? '');
    _phoneController = TextEditingController(text: agent?.phone ?? '');
    _selectedAccentColor = agent?.accentColor;
    _selectedLogoPath = agent?.logoPath;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() {
        _selectedLogoPath = picked.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final agentState = context.read<AgentState>();
    final agent = agentState.agent;
    final accent = _selectedAccentColor != null
        ? Color(_selectedAccentColor!)
        : agent?.accentColor != null
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Name"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _brokerageController,
                decoration: const InputDecoration(labelText: "Brokerage"),
                validator: (value) =>
                    value == null || value.isEmpty ? "Required" : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: "Phone"),
              ),

              const SizedBox(height: 24),

              // Accent Color
              const Text("Accent Color"),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                children: [
                  Colors.blue,
                  Colors.red,
                  Colors.green,
                  Colors.orange,
                  Colors.purple,
                  Colors.black,
                ].map((color) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAccentColor = color.toARGB32()),
                    child: CircleAvatar(
                      backgroundColor: color,
                      radius: 20,
                      child: _selectedAccentColor == color.toARGB32()
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Logo
              const Text("Logo"),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: accent, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                    color: accent.withValues(alpha: .05),
                  ),
                  child: _selectedLogoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(_selectedLogoPath!),
                            fit: BoxFit.contain,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: accent, size: 32),
                            const SizedBox(height: 6),
                            Text('Tap to add logo',
                                style: TextStyle(color: accent, fontSize: 13)),
                          ],
                        ),
                ),
              ),

              if (_selectedLogoPath != null)
                TextButton(
                  onPressed: _pickLogo,
                  child: const Text("Change Logo"),
                ),

              const SizedBox(height: 32),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;

                  final updatedAgent = AgentProfile(
                    name: _nameController.text.trim(),
                    brokerage: _brokerageController.text.trim(),
                    email: _emailController.text.trim(),
                    phone: _phoneController.text.trim(),
                    accentColor: _selectedAccentColor ?? agent?.accentColor,
                    logoPath: _selectedLogoPath, // ← was always using agent?.logoPath before
                  );

                  await agentState.save(updatedAgent);

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}