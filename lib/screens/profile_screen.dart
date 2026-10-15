import 'package:flutter/material.dart';
import '../services/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';

class ProfileScreen extends StatelessWidget {
  final AppStore store;
  const ProfileScreen({super.key, required this.store});

  Future<void> changeName(BuildContext context) async {
    final controller = TextEditingController(text: store.athleteName);
    final newName = await showDialog<String>(context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit athlete name'),
        content: TextField(controller: controller,
          maxLength: 28,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Your name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(onPressed: () {
            final text = controller.text.trim();
            if (text.isEmpty) return;
            Navigator.pop(dialogContext, text);
          }, child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (newName != null) {
      await store.updateName(newName);
      if (context.mounted) showMessage(context, 'Profile updated.');
    }
  }

  Future<void> resetData(BuildContext context) async {
    if (!await confirmDelete(context, 'all training history and custom drills')) return;
    await store.clearUserData();
    if (context.mounted) showMessage(context, 'Your local training data was cleared.');
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 15, 22, 24),
    children: [
      const Kicker('This is your court'),
      const SizedBox(height: 9),
      Text('ATHLETE PROFILE', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 21),
      SurfaceCard(child: Row(children: [
        Container(width: 70, height: 70,
          decoration: BoxDecoration(color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.person_rounded, size: 40, color: AppColors.orange)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(store.athleteName, style: Theme.of(context).textTheme.titleLarge,
            overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          const Text('Always working on the game'),
        ])),
        IconButton(tooltip: 'Edit name', onPressed: () => changeName(context),
          icon: const Icon(Icons.edit_outlined, color: AppColors.orange)),
      ])),
      const SizedBox(height: 20),
      const SectionHeader(title: 'Your numbers'),
      const SizedBox(height: 10),
      SurfaceCard(child: Column(children: [
        _InfoRow(icon: Icons.sports_basketball_outlined, label: 'Total workouts',
          value: '${store.totalSessions}'),
        const Divider(height: 24),
        _InfoRow(icon: Icons.schedule_outlined, label: 'Training minutes',
          value: '${store.totalMinutes}'),
        const Divider(height: 24),
        _InfoRow(icon: Icons.library_add_check_outlined, label: 'Custom drills',
          value: '${store.customDrills.length}'),
      ])),
      const SizedBox(height: 20),
      const SectionHeader(title: 'Weekly target'),
      const SizedBox(height: 10),
      SurfaceCard(child: Row(children: [
        const Icon(Icons.flag_outlined, color: AppColors.orange, size: 26),
        const SizedBox(width: 13),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Sessions per week', style: TextStyle(color: AppColors.text,
            fontWeight: FontWeight.w700)),
          Text('Set a goal that fits your schedule', style: TextStyle(fontSize: 11)),
        ])),
        IconButton(onPressed: store.weeklyGoal > 1
          ? () => store.updateWeeklyGoal(store.weeklyGoal - 1) : null,
          tooltip: 'Lower goal', icon: const Icon(Icons.remove_circle_outline)),
        Text('${store.weeklyGoal}', style: const TextStyle(color: AppColors.orange,
          fontWeight: FontWeight.w900, fontSize: 20)),
        IconButton(onPressed: store.weeklyGoal < 7
          ? () => store.updateWeeklyGoal(store.weeklyGoal + 1) : null,
          tooltip: 'Raise goal', icon: const Icon(Icons.add_circle_outline)),
      ])),
      const SizedBox(height: 20),
      const SectionHeader(title: 'App information'),
      const SizedBox(height: 10),
      SurfaceCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _InfoRow(icon: Icons.phone_iphone_rounded, label: 'App', value: 'Court IQ · v1.0'),
        const Divider(height: 24),
        const _InfoRow(icon: Icons.cloud_outlined, label: 'News feed', value: 'ESPN NBA API'),
        const Divider(height: 24),
        const Text('Your sessions, goals and custom drills are stored locally on this device. '
          'News requires an internet connection; offline examples are clearly labeled.',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
      ])),
      const SizedBox(height: 18),
      OutlinedButton.icon(
        onPressed: () => resetData(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.redAccent,
          side: const BorderSide(color: Color(0xFF6B3540)),
          padding: const EdgeInsets.symmetric(vertical: 15)),
        icon: const Icon(Icons.delete_forever_outlined),
        label: const Text('Clear training history & custom drills'),
      ),
      const SizedBox(height: 15),
      const Center(child: Text('MADE FOR THE LOVE OF THE GAME',
        style: TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 1.5))),
    ],
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: AppColors.orange, size: 20),
    const SizedBox(width: 11),
    Expanded(child: Text(label, style: const TextStyle(color: AppColors.text, fontSize: 13))),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800,
      color: AppColors.orangeSoft, fontSize: 12)),
  ]);
}
