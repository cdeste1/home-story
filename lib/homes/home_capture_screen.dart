import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/home.dart';
import '../models/asset.dart';
import '../state/asset_state.dart';
import '../state/agent_state.dart';
import '../assets/asset_detail_screen.dart';

class HomeCaptureScreen extends StatelessWidget {
  final Home home;

  const HomeCaptureScreen({super.key, required this.home});

  Future<void> _capturePhoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (photo == null) return;

    final Asset asset = Asset(
      id: Random().nextInt(100000).toString(),
      homeId: home.id,
      imagePath: photo.path,
      category: AssetCategory.other,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssetDetailScreen(asset: asset),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assets = context.watch<AssetState>().assetsForHome(home.id);
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
            height: 75,
            color: accent,
            fit: BoxFit.fitHeight,
          ),
        ),
        title: const Text('Home Story'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: (){Navigator.pop(context);},
              ),
        ]
      ),
      body: assets.isEmpty
    ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              color: accent,
              height: 120, // adjust size as needed
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            
            // Message
            const Text(
              'No assets yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the camera to add your assets',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: assets.length,
              itemBuilder: (_, index) {
                final asset = assets[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssetDetailScreen(asset: asset),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image with floating card effect
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Image.file(
                            File(asset.imagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.broken_image, size: 40),
                            ),
                          ),
                        ),
                        // Gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 6),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black54,
                                ],
                              ),
                            ),
                            child: Text(
                              asset.category.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Delete button (smaller & subtle)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Delete Asset?'),
                                  content: const Text(
                                      'Are you sure you want to delete this asset?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('Cancel')),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent),
                                      onPressed: () {
                                        context
                                            .read<AssetState>()
                                            .deleteAsset(asset.id);
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Delete'),
                                    )
                                  ],
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _capturePhoto(context),
        backgroundColor: accent,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }
}
