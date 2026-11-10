import 'package:flutter/material.dart';

import '../core/ui/coming_soon_page.dart';
import 'feature_module.dart';
import 'feature_registry.dart';
import 'notes/notes_module.dart';

/// The single list of modules. Adding a module = one entry here.
FeatureRegistry buildFeatureRegistry() => FeatureRegistry([
  notesModule,
  _comingSoon(
    id: 'reminders',
    title: 'Reminders',
    icon: Icons.alarm,
    pinnedByDefault: true,
  ),
  _comingSoon(id: 'vault', title: 'Vault', icon: Icons.lock_outline),
  _comingSoon(
    id: 'pictures',
    title: 'Pictures',
    icon: Icons.photo_library_outlined,
  ),
  _comingSoon(id: 'files', title: 'Files', icon: Icons.folder_outlined),
]);

/// A module with no real page yet. Move it to `features/<id>/` when built.
FeatureModule _comingSoon({
  required String id,
  required String title,
  required IconData icon,
  bool pinnedByDefault = false,
}) => FeatureModule(
  id: id,
  title: title,
  icon: icon,
  pinnedByDefault: pinnedByDefault,
  pageBuilder: (_, _) => ComingSoonPage(title: title),
);
