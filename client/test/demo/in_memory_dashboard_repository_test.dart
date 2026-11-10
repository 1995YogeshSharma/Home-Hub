import 'package:flutter_test/flutter_test.dart';
import 'package:home_hub_client/demo/in_memory_dashboard_repository.dart';

void main() {
  test('nothing is saved at first', () async {
    final repo = InMemoryDashboardRepository();

    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'sharma-family'),
      isNull,
    );
  });

  test('save then load returns the same ids in order', () async {
    final repo = InMemoryDashboardRepository();

    await repo.savePinned(
      userId: 'u-asha',
      groupCode: 'sharma-family',
      featureIds: ['files', 'notes'],
    );

    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'sharma-family'),
      ['files', 'notes'],
    );
  });

  test('layouts are separate per user and per group', () async {
    final repo = InMemoryDashboardRepository();

    await repo.savePinned(
      userId: 'u-asha',
      groupCode: 'sharma-family',
      featureIds: ['vault'],
    );

    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'book-club'),
      isNull,
    );
    expect(
      await repo.loadPinned(userId: 'u-ravi', groupCode: 'sharma-family'),
      isNull,
    );
  });

  test('callers cannot change what is stored', () async {
    final repo = InMemoryDashboardRepository();
    final ids = ['notes'];
    await repo.savePinned(
      userId: 'u-asha',
      groupCode: 'sharma-family',
      featureIds: ids,
    );

    ids.add('changed-after-save');
    final loaded = await repo.loadPinned(
      userId: 'u-asha',
      groupCode: 'sharma-family',
    );
    loaded!.add('changed-after-load');

    expect(
      await repo.loadPinned(userId: 'u-asha', groupCode: 'sharma-family'),
      ['notes'],
    );
  });
}
