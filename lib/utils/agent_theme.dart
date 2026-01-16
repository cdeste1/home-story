import 'package:flutter/material.dart';
import '../models/agent_profile.dart';

Color resolveAgentAccent(AgentProfile? agent) {
  if (agent?.accentColor != null) {
    return Color(agent!.accentColor!);
  }
  return const Color(0xFF4F6D7A); // default fallback
}
