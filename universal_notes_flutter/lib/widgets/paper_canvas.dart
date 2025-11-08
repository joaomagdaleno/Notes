import 'package:flutter/material.dart';

class PaperCanvas extends StatelessWidget {
  final Size paperSize;
  final EdgeInsets margins;
  final Widget child;

  const PaperCanvas({
    super.key,
    required this.paperSize,
    required this.margins,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade300,
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            width: paperSize.width,
            height: paperSize.height,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: margins,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
