import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/models/session.dart';
import '../features/feature_registry.dart';
import '../routing/app_routes.dart';
import 'dashboard_repository.dart';
import 'dashboard_view_model.dart';
import 'widgets/add_feature_tile.dart';
import 'widgets/feature_tile.dart';

/// The home dashboard at `/home`: the user's pinned feature tiles plus '+'.
class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.session,
    required this.features,
    required this.repository,
  });

  static const addTileKey = ValueKey('dashboard-add-tile');
  static ValueKey<String> tileKey(String featureId) =>
      ValueKey('dashboard-tile-$featureId');

  final Session session;
  final FeatureRegistry features;
  final DashboardRepository repository;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Created once in initState, not in build or in the route builder,
  // so navigating around does not replace it with a fresh, unloaded one.
  late final DashboardViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = DashboardViewModel(
      session: widget.session,
      features: widget.features,
      repository: widget.repository,
    )..load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openPicker() async {
    // A bottom sheet is a temporary overlay, not a page with a URL,
    // so closing it with Navigator.pop is correct alongside go_router.
    final featureId = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final module in _viewModel.addable)
              ListTile(
                leading: Icon(module.icon),
                title: Text(module.title),
                onTap: () => Navigator.of(sheetContext).pop(module.id),
              ),
          ],
        ),
      ),
    );
    if (featureId != null) await _viewModel.pin(featureId);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_viewModel.groupName),
              Text(
                _viewModel.userLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Server status',
              icon: const Icon(Icons.cloud_outlined),
              onPressed: () => context.go(AppRoutes.status),
            ),
          ],
        ),
        body: _viewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : GridView.extent(
                maxCrossAxisExtent: 220,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  for (final module in _viewModel.pinned)
                    FeatureTile(
                      key: DashboardPage.tileKey(module.id),
                      module: module,
                      onTap: () => context.go(AppRoutes.feature(module.id)),
                    ),
                  if (_viewModel.addable.isNotEmpty)
                    AddFeatureTile(
                      key: DashboardPage.addTileKey,
                      onTap: _openPicker,
                    ),
                ],
              ),
      ),
    );
  }
}
