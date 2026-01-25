import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:home_story/state/home_state.dart';
import 'package:home_story/state/agent_state.dart';
import '../fakes/fake_home_state.dart';
import '../fakes/fake_agent_state.dart';

Widget testApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<HomeState>(
        create: (_) => FakeHomeState(),
      ),
      ChangeNotifierProvider<AgentState>(
        create: (_) => FakeAgentState(),
      ),
    ],
    child: MaterialApp(home: child),
  );
}
