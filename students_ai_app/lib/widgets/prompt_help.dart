import 'package:flutter/material.dart';
import 'package:students_ai_app/themes.dart';

class HelpPrompt extends StatelessWidget {
  const HelpPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      child: Column(
        children: [
          Text(
            'How can I help you?',
            style: TextStyle(
              fontSize: 50,
              fontWeight: FontWeight.w500,
              color: primaryColorDark,
            ),
          ),
          Text(
            'Upload your PDF (or other format)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: primaryColorDark,
            ),
          ),
        ],
      )
    );
  }
}
