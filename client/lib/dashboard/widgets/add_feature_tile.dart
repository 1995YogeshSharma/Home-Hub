import 'package:flutter/material.dart';

/// The '+' tile that lets the user add a module to their dashboard.
class AddFeatureTile extends StatelessWidget {
  const AddFeatureTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 40),
            SizedBox(height: 8),
            Text('Add widget'),
          ],
        ),
      ),
    );
  }
}
