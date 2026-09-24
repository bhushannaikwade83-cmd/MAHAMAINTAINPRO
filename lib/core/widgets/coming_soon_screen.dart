import 'package:flutter/material.dart';
import 'empty_state.dart';

/// Placeholder for routes owned by future sprints. Keeping these wired
/// into the router now means navigation/menus don't need rework later —
/// only this screen gets swapped for the real feature.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  const ComingSoonScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: '$title is coming soon',
        subtitle: 'This module is scheduled in a later sprint.',
      ),
    );
  }
}
