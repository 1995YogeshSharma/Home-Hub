import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/features/all_features.dart';
import 'package:home_hub_client/features/feature_module.dart';
import 'package:home_hub_client/features/feature_registry.dart';

FeatureModule _module(String id, {bool pinned = false}) => FeatureModule(
  id: id,
  title: id,
  icon: Icons.circle,
  pinnedByDefault: pinned,
  pageBuilder: (_, _) => const SizedBox(),
);

void main() {
  test('byId finds a module and returns null for unknown ids', () {
    final registry = FeatureRegistry([_module('notes'), _module('files')]);

    expect(registry.byId('files')?.id, 'files');
    expect(registry.byId('nope'), isNull);
  });

  test('rejects duplicate ids', () {
    expect(
      () => FeatureRegistry([_module('notes'), _module('notes')]),
      throwsArgumentError,
    );
  });

  test('rejects ids that are not lowercase url slugs', () {
    expect(() => FeatureRegistry([_module('Notes')]), throwsArgumentError);
    expect(() => FeatureRegistry([_module('my/notes')]), throwsArgumentError);
    expect(() => FeatureRegistry([_module('')]), throwsArgumentError);
  });

  test('defaultPinnedIds keeps registry order', () {
    final registry = FeatureRegistry([
      _module('b', pinned: true),
      _module('a'),
      _module('c', pinned: true),
    ]);

    expect(registry.defaultPinnedIds, ['b', 'c']);
  });

  test('the list of modules cannot be changed from outside', () {
    final registry = FeatureRegistry([_module('notes')]);

    expect(() => registry.all.add(_module('x')), throwsUnsupportedError);
  });

  test('the app ships notes, reminders, vault, pictures and files', () {
    final registry = buildFeatureRegistry();

    expect(registry.all.map((m) => m.id).toList(), [
      'notes',
      'reminders',
      'vault',
      'pictures',
      'files',
    ]);
    expect(registry.defaultPinnedIds, ['notes', 'reminders']);
  });
}
