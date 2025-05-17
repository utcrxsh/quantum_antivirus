import 'package:flutter/material.dart';

void showAboutDialogCustom(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'Quantum Antivirus',
    applicationVersion: '1.0.0',
    applicationIcon: Image.asset('assets/logo.png', height: 48),
    children: [
      const Text('A modern, production-ready antivirus app built with Flutter.\n\nDeveloped by Your Team.'),
    ],
  );
} 