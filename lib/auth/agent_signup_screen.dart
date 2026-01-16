import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/agent_profile.dart';
import '../state/agent_state.dart';

class AgentSignupScreen extends StatefulWidget {
  const AgentSignupScreen({super.key});

  @override
  State<AgentSignupScreen> createState() => _AgentSignupScreenState();
}

class _AgentSignupScreenState extends State<AgentSignupScreen> {
  final _nameCtrl = TextEditingController();
  final _brokerageCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  Color _accent = Colors.blueGrey;
  String? _logoPath;

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _logoPath = image.path;
    });
  }

  void _saveAgent() {
    if (_nameCtrl.text.trim().isEmpty ||
        _brokerageCtrl.text.trim().isEmpty) {
      return;
    }

    final agent = AgentProfile(
      name: _nameCtrl.text.trim(),
      brokerage: _brokerageCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      accentColor: _accent.value,
      logoPath: _logoPath,
    );

    context.read<AgentState>().save(agent);
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

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
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agent Setup',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Agent Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _brokerageCtrl,
              decoration: const InputDecoration(
                labelText: 'Brokerage',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Logo picker
            Row(
              children: [
                if (_logoPath != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_logoPath!),
                      height: 56,
                      width: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.image),
                  label: const Text('Add Logo (optional)'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Accent color picker (simple MVP version)
            Row(
              children: [
                const Text('Accent Color'),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    final color = await showDialog<Color>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Select Accent Color'),
                        content: Wrap(
                          spacing: 8,
                          children: [
                            Colors.blue,
                            Colors.red,
                            Colors.green,
                            Colors.orange,
                            Colors.purple,
                            Colors.teal,
                          ].map((c) {
                            return GestureDetector(
                              onTap: () => Navigator.pop(context, c),
                              child: CircleAvatar(backgroundColor: c),
                            );
                          }).toList(),
                        ),
                      ),
                    );

                    if (color != null) {
                      setState(() => _accent = color);
                    }
                  },
                  child: CircleAvatar(backgroundColor: _accent),
                ),
              ],
            ),

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveAgent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}