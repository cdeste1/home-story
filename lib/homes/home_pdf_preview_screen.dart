import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/home.dart';

import '../state/agent_state.dart';
import '../state/asset_state.dart';
import '../utils/home_transfer_pdf.dart';

class HomeTransferPdfScreen extends StatelessWidget {
  final Home home;

  const HomeTransferPdfScreen({required this.home, super.key});

  @override
  Widget build(BuildContext context) {
    final assets = context.read<AssetState>().assetsForHome(home.id);
    final agent = context.read<AgentState>().agent;
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
            icon: const Icon(Icons.arrow_back),
            onPressed: (){Navigator.pop(context);},
              ),
               
          ],
      ),
      body: FutureBuilder(
        future: buildHomeTransferPdf(home: home, assets: assets, agent: agent),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final pdf = snapshot.data!;
            return PdfPreview(
              build: (format) => pdf.save(),
              canChangeOrientation: false,
              canChangePageFormat: false,
              allowPrinting: true,
              allowSharing: true,
            );
          }
        },
      ),
    );
  }
}