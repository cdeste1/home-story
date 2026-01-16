import 'package:flutter/material.dart';
import 'package:home_story/homes/home_list_screen.dart';
import 'package:provider/provider.dart';
import '../state/agent_state.dart';
import 'agent_signup_screen.dart';

class AgentBootstrapScreen extends StatelessWidget {
  const AgentBootstrapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final agent = context.watch<AgentState>().agent;

    if (agent == null) {
      return const AgentSignupScreen();
    }

    // Agent already exists → sellers land directly in app
    return const HomeListScreen(); // or whatever your main app widget is
  }
}