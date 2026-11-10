import 'package:flutter/material.dart';

import '../../core/ui/coming_soon_page.dart';
import '../feature_module.dart';

final notesModule = FeatureModule(
  id: 'notes',
  title: 'Notes',
  icon: Icons.sticky_note_2_outlined,
  pinnedByDefault: true,
  pageBuilder: (context, state) => const ComingSoonPage(title: 'Notes'),
);
