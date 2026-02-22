import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/home.dart';
import '../state/home_state.dart';

class EditHomeScreen extends StatefulWidget {
  final Home home;

  const EditHomeScreen({super.key, required this.home});

  @override
  State<EditHomeScreen> createState() => _EditHomeScreenState();
}

class _EditHomeScreenState extends State<EditHomeScreen> {
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.home.address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                final updatedHome = widget.home.copyWith(
                  address: _addressController.text,
                );

                context.read<HomeState>().updateHome(updatedHome);
                Navigator.pop(context);
              },
              child: const Text('Save Changes'),
            ),

            const Spacer(),

            // DELETE BUTTON
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
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  context.read<HomeState>().deleteHome(widget.home.id);
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