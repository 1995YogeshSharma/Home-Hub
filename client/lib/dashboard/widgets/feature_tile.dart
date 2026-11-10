import 'package:flutter/material.dart';

import '../../features/feature_module.dart';

/// A dashboard tile that opens one feature module.
class FeatureTile extends StatelessWidget {
  const FeatureTile({super.key, required this.module, required this.onTap});

  final FeatureModule module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(module.icon, size: 40),
            const SizedBox(height: 8),
            Text(module.title),
          ],
        ),
      ),
    );
  }
}
