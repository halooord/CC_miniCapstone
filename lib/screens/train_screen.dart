import 'package:flutter/material.dart';
import '../models/training.dart';
import '../services/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/ui.dart';
import 'workout_screen.dart';

const drillCategories = ['Handles', 'Shooting', 'Footwork', 'Conditioning'];

class TrainScreen extends StatefulWidget {
  final AppStore store;
  const TrainScreen({super.key, required this.store});
  @override
  State<TrainScreen> createState() => _TrainScreenState();
}

class _TrainScreenState extends State<TrainScreen> {
  String filter = 'All';
  String query = '';
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _openDrill(Drill drill) async {
    final saved = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => WorkoutScreen(drill: drill, store: widget.store)));
    if (saved == true && mounted) showMessage(context, 'Session added to your progress!');
  }

  Future<void> _editDrill([Drill? edit]) async {
    final title = TextEditingController(text: edit?.title ?? '');
    final description = TextEditingController(text: edit?.description ?? '');
    final minutes = TextEditingController(text: edit?.minutes.toString() ?? '15');
    final formKey = GlobalKey<FormState>();
    String category = edit?.category ?? 'Handles';
    final result = await showModalBottomSheet<Drill>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => StatefulBuilder(builder: (sheetContext, updateSheet) =>
        Padding(
          padding: EdgeInsets.fromLTRB(22, 18, 22,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 25),
          child: SingleChildScrollView(child: Form(key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(height: 4, width: 48,
                  decoration: BoxDecoration(color: AppColors.border,
                    borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 20),
                Text(edit == null ? 'Create your drill' : 'Edit your drill',
                  style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 19),
                TextFormField(controller: title, maxLength: 45,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Drill name',
                    hintText: 'e.g. Layup ladder'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a drill name' : null),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: drillCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) { if (v != null) updateSheet(() => category = v); },
                ),
                const SizedBox(height: 14),
                TextFormField(controller: minutes,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n < 1 || n > 180) return 'Enter 1 to 180 minutes';
                    return null;
                  }),
                const SizedBox(height: 14),
                TextFormField(controller: description, maxLines: 2, maxLength: 180,
                  decoration: const InputDecoration(labelText: 'Instructions / description'),
                  validator: (v) => (v ?? '').trim().isEmpty ? 'Enter instructions' : null),
                const SizedBox(height: 8),
                PrimaryAction(label: edit == null ? 'Create drill' : 'Save changes',
                  icon: Icons.check_rounded,
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final details = description.text.trim();
                    Navigator.pop(sheetContext, Drill(
                      id: edit?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                      title: title.text.trim(), category: category,
                      level: 'Custom', description: details,
                      minutes: int.parse(minutes.text.trim()),
                      steps: [details, 'Keep track of your effort and rest as needed.'],
                      isCustom: true,
                    ));
                  }),
              ]),
          )),
        ),
      ),
    );
    title.dispose();
    minutes.dispose();
    description.dispose();
    if (result != null) {
      await widget.store.saveCustomDrill(result);
      if (mounted) showMessage(context, edit == null ? 'Custom drill created.' : 'Drill updated.');
    }
  }

  Future<void> _deleteDrill(Drill drill) async {
    if (!await confirmDelete(context, '"${drill.title}"')) return;
    await widget.store.deleteCustomDrill(drill.id);
    if (mounted) showMessage(context, 'Custom drill deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final drills = widget.store.allDrills.where((d) =>
      (filter == 'All' || filter == d.category) &&
      ('${d.title} ${d.description} ${d.category}').toLowerCase()
          .contains(query.toLowerCase().trim())).toList();

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(22, 15, 22, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Kicker('Build your skills'),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Text('TRAINING LAB', style: Theme.of(context).textTheme.headlineMedium)),
            IconButton.filledTonal(
              key: const Key('add_drill'),
              onPressed: () => _editDrill(),
              tooltip: 'Add custom drill',
              icon: const Icon(Icons.add_rounded, color: AppColors.orange)),
          ]),
          const SizedBox(height: 6),
          const Text('Find your next rep. Or create your own.'),
          const SizedBox(height: 18),
          TextField(
            key: const Key('search_drills'),
            controller: searchController,
            onChanged: (text) => setState(() => query = text),
            decoration: const InputDecoration(hintText: 'Search drills...',
              prefixIcon: Icon(Icons.search_rounded, color: AppColors.muted)),
          ),
          const SizedBox(height: 13),
        ])),
      SizedBox(height: 46, child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        children: ['All', ...drillCategories].map((category) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(category),
            selected: filter == category,
            backgroundColor: AppColors.surface,
            selectedColor: AppColors.orange,
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
              color: filter == category ? AppColors.bg : AppColors.muted),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50),
              side: BorderSide(color: filter == category ? AppColors.orange : AppColors.border)),
            onSelected: (_) => setState(() => filter = category),
          ),
        )).toList(),
      )),
      const SizedBox(height: 11),
      Expanded(child: drills.isEmpty
        ? Padding(padding: const EdgeInsets.all(22), child: EmptyPanel(
            icon: Icons.search_off_rounded, title: 'No matching drills',
            details: 'Try a different search or category.'))
        : ListView.builder(
            key: const Key('drill_list'),
            padding: const EdgeInsets.fromLTRB(22, 3, 22, 20),
            itemCount: drills.length,
            itemBuilder: (context, index) {
              final drill = drills[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 11),
                child: _DrillCard(drill: drill,
                  onTap: () => _openDrill(drill),
                  onEdit: drill.isCustom ? () => _editDrill(drill) : null,
                  onDelete: drill.isCustom ? () => _deleteDrill(drill) : null),
              );
            },
          )),
    ]);
  }
}

class _DrillCard extends StatelessWidget {
  final Drill drill;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _DrillCard({required this.drill, required this.onTap, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) => SurfaceCard(
    padding: const EdgeInsets.all(15),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Row(children: [
          Container(width: 72, height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16)),
            child: Icon(drill.icon, color: AppColors.orange, size: 33)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Kicker(drill.category),
            const SizedBox(height: 5),
            Text(drill.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            Text('${drill.minutes} MIN  •  ${drill.level.toUpperCase()}',
              style: const TextStyle(color: AppColors.muted, fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: .6)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
      if (drill.isCustom) ...[
        const Divider(height: 21),
        Row(children: [
          const Expanded(child: Text('YOUR CUSTOM DRILL',
            style: TextStyle(fontSize: 10, letterSpacing: 1.2,
              fontWeight: FontWeight.w800, color: AppColors.muted))),
          TextButton.icon(onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Edit')),
          IconButton(onPressed: onDelete, tooltip: 'Delete drill',
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
        ]),
      ],
    ]),
  );
}
