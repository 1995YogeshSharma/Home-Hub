import 'package:flutter/foundation.dart';

import '../core/models/session.dart';
import '../features/feature_module.dart';
import '../features/feature_registry.dart';
import 'dashboard_repository.dart';

/// State and actions for the dashboard page: which tiles are pinned, which
/// can still be added, and pinning a new one.
class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({
    required this._session,
    required this._features,
    required this._repository,
  });

  final Session _session;
  final FeatureRegistry _features;
  final DashboardRepository _repository;

  bool _isLoading = true;
  List<FeatureModule> _pinned = const [];
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String get groupName => _session.group.name;
  String get userLabel =>
      '${_session.user.displayName} · ${_session.role.label}';

  /// Tiles on the dashboard, in the user's order.
  List<FeatureModule> get pinned => _pinned;

  /// Modules the '+' tile can still add.
  List<FeatureModule> get addable => [
    for (final module in _features.all)
      if (!_isPinned(module.id)) module,
  ];

  /// Loads this user's layout for the active group, or the defaults.
  Future<void> load() async {
    final saved = await _repository.loadPinned(
      userId: _session.user.id,
      groupCode: _session.group.code,
    );
    final modules = <FeatureModule>[];
    for (final id in saved ?? _features.defaultPinnedIds) {
      // Skip ids the app no longer has (e.g. a removed module).
      final module = _features.byId(id);
      if (module != null) modules.add(module);
    }
    _pinned = modules;
    _isLoading = false;
    _notify();
  }

  /// Adds [featureId] to the end of the dashboard and saves the layout.
  Future<void> pin(String featureId) async {
    final module = _features.byId(featureId);
    if (module == null || _isPinned(featureId)) return;
    _pinned = [..._pinned, module];
    _notify(); // update the screen first, then save
    await _repository.savePinned(
      userId: _session.user.id,
      groupCode: _session.group.code,
      featureIds: [for (final m in _pinned) m.id],
    );
  }

  bool _isPinned(String id) => _pinned.any((m) => m.id == id);

  // load() is async: if the page closes before it finishes, notifying a
  // disposed ChangeNotifier would throw.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
