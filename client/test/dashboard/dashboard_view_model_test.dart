import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/core/models/group.dart';
import 'package:home_hub_client/core/models/session.dart';
import 'package:home_hub_client/core/models/user.dart';
import 'package:home_hub_client/dashboard/dashboard_view_model.dart';
import 'package:home_hub_client/demo/demo_data.dart';
import 'package:home_hub_client/demo/in_memory_dashboard_repository.dart';
import 'package:home_hub_client/features/all_features.dart';
import 'package:home_hub_client/features/feature_module.dart';

Session _sessionFor(User user, Group group) {
  final memberships = DemoData.memberships
      .where((m) => m.userId == user.id)
      .toList();
  return Session(
    user: user,
    memberships: memberships,
    active: memberships.firstWhere((m) => m.group.code == group.code),
  );
}

DashboardViewModel _viewModel(
  InMemoryDashboardRepository repo, {
  Group group = DemoData.sharmaFamily,
}) => DashboardViewModel(
  session: _sessionFor(DemoData.asha, group),
  features: buildFeatureRegistry(),
  repository: repo,
);

List<String> _ids(List<FeatureModule> modules) => [
  for (final m in modules) m.id,
];

void main() {
  test('is loading until load completes', () async {
    final vm = _viewModel(InMemoryDashboardRepository());

    expect(vm.isLoading, isTrue);
    await vm.load();
    expect(vm.isLoading, isFalse);
  });

  test('uses the default tiles when nothing is saved', () async {
    final vm = _viewModel(InMemoryDashboardRepository());

    await vm.load();

    expect(_ids(vm.pinned), ['notes', 'reminders']);
    expect(_ids(vm.addable), ['vault', 'pictures', 'files']);
  });

  test('uses the saved order and drops unknown ids', () async {
    final repo = InMemoryDashboardRepository();
    await repo.savePinned(
      userId: 'u-asha',
      groupCode: 'sharma-family',
      featureIds: ['files', 'old-thing', 'notes'],
    );
    final vm = _viewModel(repo);

    await vm.load();

    expect(_ids(vm.pinned), ['files', 'notes']);
  });

  test('pin appends, notifies and saves', () async {
    final repo = InMemoryDashboardRepository();
    final vm = _viewModel(repo);
    await vm.load();
    var calls = 0;
    vm.addListener(() => calls++);

    await vm.pin('vault');

    expect(_ids(vm.pinned), ['notes', 'reminders', 'vault']);
    expect(_ids(vm.addable), ['pictures', 'files']);
    expect(calls, 1);
    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'sharma-family'),
      ['notes', 'reminders', 'vault'],
    );
  });

  test('pin ignores already-pinned and unknown ids', () async {
    final repo = InMemoryDashboardRepository();
    final vm = _viewModel(repo);
    await vm.load();
    var calls = 0;
    vm.addListener(() => calls++);

    await vm.pin('notes');
    await vm.pin('nope');

    expect(calls, 0);
    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'sharma-family'),
      isNull,
    );
  });

  test('pinning in one group does not change another group', () async {
    final repo = InMemoryDashboardRepository();
    final family = _viewModel(repo);
    await family.load();
    await family.pin('vault');

    final club = _viewModel(repo, group: DemoData.bookClub);
    await club.load();

    expect(_ids(club.pinned), ['notes', 'reminders']);
  });

  test('exposes group name and user label', () {
    final vm = _viewModel(InMemoryDashboardRepository());

    expect(vm.groupName, 'Sharma Family');
    expect(vm.userLabel, 'Asha · Admin');
  });
}
