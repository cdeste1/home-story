import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/home.dart';
import '../state/home_state.dart';
import 'add_home_screen.dart';
import 'home_capture_screen.dart';
import 'home_transfer_screen.dart';
import '../state/agent_state.dart';

class HomeListScreen extends StatelessWidget {
  const HomeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final homeState = context.watch<HomeState>();
    final homes = homeState.homes;
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
          IconButton(
            icon: const Icon(Icons.restart_alt),
            color: Color(0XFF099999),
            tooltip: 'Reset Agent (Dev)',
            onPressed: (){
              context.read<AgentState>().clear();
              // ALSO clear homes
              context.read<HomeState>().clear();
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
          : ListView.builder(
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
                    trailing: IconButton(
                      icon: Icon(Icons.ios_share, color: accent),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HomeTransferScreen(home: home),
                          ),
                        );
                      },
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


