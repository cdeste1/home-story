import 'package:flutter/material.dart';
//import 'package:home_story/utils/splash_screen.dart';
import 'package:provider/provider.dart';
import 'services/purchase_manager.dart';
import 'state/home_state.dart';
import 'state/asset_state.dart';
import 'state/agent_state.dart';
import 'state/export_access_state.dart';
import 'auth/login_screen.dart';
import 'homes/home_list_screen.dart';

void main() 
    async {
      WidgetsFlutterBinding.ensureInitialized();

      final exportAccessState = ExportAccessState();
      await exportAccessState.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeState()),
        ChangeNotifierProvider(create: (_) => AssetState()),
        ChangeNotifierProvider(create: (_) => AgentState()),
        ChangeNotifierProvider.value(value: exportAccessState), // ← use the loaded instance
        ChangeNotifierProvider(create: (_) => PurchaseManager()), // ← ChangeNotifier now
      ],
      child: const HomeStoryApp(),
    ),
  );
}

class HomeStoryApp extends StatelessWidget {
  const HomeStoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Story',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF5C6B73),
        scaffoldBackgroundColor: const Color(0xFFF7F7F6),
      ),
      home: const BootstrapScreen(),
    );
  }
}

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
  await context.read<HomeState>().load();
  await context.read<AssetState>().load();
  await context.read<AgentState>().load();

  await context.read<PurchaseManager>().initialize(context);

  if (mounted) {
    setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final agent = context.watch<AgentState>().agent;

    return agent == null
        ? const AgentBootstrapScreen()
        : const HomeListScreen();
  }
}
