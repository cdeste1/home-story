import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/home.dart';
import '../state/home_state.dart';
import 'add_home_screen.dart';
import 'home_capture_screen.dart';
import 'home_transfer_screen.dart';
import '../state/agent_state.dart';
import '../auth/settings_screen.dart';
import '../homes/edit_home_screen.dart';

class HomeListScreen extends StatefulWidget {
  const HomeListScreen({super.key});

  @override
  State<HomeListScreen> createState() => _HomeListScreenState();
}

class _HomeListScreenState extends State<HomeListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final homeState = context.watch<HomeState>();
    final allHomes = homeState.homes;

    final homes = allHomes.where((home) {
      return home.address
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();
    final agent = context.watch<AgentState>().agent;
    // If agent accent color exists, use it; otherwise fallback to theme
    final accent = agent?.accentColor != null
    ? Color(agent!.accentColor!) // convert int to Color
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
        actions: [
          // ✅ Settings Button
            IconButton(
              icon: const Icon(Icons.settings),
              color: accent,
              tooltip: 'Settings',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            
          ],
      ),
 body: homes.isEmpty
    ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              height: 120, // adjust size as needed
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            
            // Message
            const Text(
              'No homes yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first home',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
      : Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search homes...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
      Expanded(
        child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: homes.length,
              itemBuilder: (context, index) {
                final home = homes[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: home.exteriorImagePath != null
                          ? Image.file(
                              File(home.exteriorImagePath!),
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.home_outlined, size: 48, color: Colors.grey[400]),
                    ),
                    title: Text(
                      home.address,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      'Added ${home.createdAt.toLocal().toString().split(' ').first}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: accent),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditHomeScreen(home: home),
                          ),
                        );
                      } else if (value == 'share') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeTransferScreen(home: home),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Text('Export'),
                      ),
                    ],
                  ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HomeCaptureScreen(home: home),
                        ),
                      );
                    },
                  ),
                );
              },
            
            ),
      ),
    ],
  ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Home? newHome = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddHomeScreen(),
            ),
          );

          if (newHome != null) {
            context.read<HomeState>().addHome(newHome);
          }
        },
        backgroundColor: accent,
        child: const Icon(Icons.add),
      ),
      
    );
    
  }
  
}


