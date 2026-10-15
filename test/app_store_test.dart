import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:court_iq/models/training.dart';
import 'package:court_iq/services/app_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('workout persists and can be deleted', () async {
    final store = AppStore();
    await store.load();
    expect(store.totalSessions, 0);
    await store.addSession(defaultDrills.first);
    expect(store.totalSessions, 1);
    expect(store.totalMinutes, defaultDrills.first.minutes);

    final reloaded = AppStore();
    await reloaded.load();
    expect(reloaded.totalSessions, 1);
    final id = reloaded.records.first.id;
    await reloaded.deleteSession(id);
    expect(reloaded.records, isEmpty);

    final check = AppStore();
    await check.load();
    expect(check.records, isEmpty);
  });

  test('custom drill persists and editing replaces its entry', () async {
    final store = AppStore();
    await store.load();
    const first = Drill(
      id: 'user-1', title: 'Layup ladder', category: 'Shooting',
      level: 'Custom', description: '10 layups each side',
      minutes: 12, steps: ['10 layups each side'], isCustom: true,
    );
    await store.saveCustomDrill(first);
    expect(store.customDrills.length, 1);
    final edited = Drill.fromJson({...first.toJson(), 'minutes': 17});
    await store.saveCustomDrill(edited);
    expect(store.customDrills.length, 1);
    expect(store.customDrills.first.minutes, 17);

    final reloaded = AppStore();
    await reloaded.load();
    expect(reloaded.customDrills.first.minutes, 17);
    await reloaded.deleteCustomDrill('user-1');
    final afterDelete = AppStore();
    await afterDelete.load();
    expect(afterDelete.customDrills, isEmpty);
  });

  test('weekly goal and athlete name persist', () async {
    final store = AppStore();
    await store.load();
    await store.updateName('Alex');
    await store.updateWeeklyGoal(4);

    final reloaded = AppStore();
    await reloaded.load();
    expect(reloaded.athleteName, 'Alex');
    expect(reloaded.weeklyGoal, 4);
  });
}
