import 'package:flutter/material.dart';
import '../widgets/hud/floating_hud_card.dart';

/// Frameless transparent window shell hosting the Otto HUD popover.
class HudOverlayWindow extends StatelessWidget {
  const HudOverlayWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: FloatingHudCard(),
      ),
    );
  }
}
