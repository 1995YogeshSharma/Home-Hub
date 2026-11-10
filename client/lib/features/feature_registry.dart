import 'feature_module.dart';

/// The fixed set of modules the app ships with.
class FeatureRegistry {
  /// Throws [ArgumentError] if an id is duplicated or is not a lowercase slug.
  FeatureRegistry(List<FeatureModule> modules)
    : all = List.unmodifiable(modules) {
    final seen = <String>{};
    for (final module in modules) {
      if (!_idPattern.hasMatch(module.id)) {
        throw ArgumentError.value(module.id, 'id', 'must be a lowercase slug');
      }
      if (!seen.add(module.id)) {
        throw ArgumentError.value(module.id, 'id', 'is used more than once');
      }
    }
  }

  // URLs are case-sensitive, so ids are lowercase letters, digits and '-'.
  static final _idPattern = RegExp(r'^[a-z][a-z0-9-]*$');

  /// Every module, in display order.
  final List<FeatureModule> all;

  /// The module with [id], or null if there is none.
  FeatureModule? byId(String id) {
    for (final module in all) {
      if (module.id == id) return module;
    }
    return null;
  }

  /// Ids shown on a dashboard nobody has customised yet.
  List<String> get defaultPinnedIds => [
    for (final module in all)
      if (module.pinnedByDefault) module.id,
  ];
}
