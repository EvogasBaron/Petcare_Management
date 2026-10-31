import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/state_views.dart';
import '../../appointments/providers/appointment_providers.dart';
import '../../health_log/data/health_log_repository.dart';
import '../../health_log/providers/health_log_providers.dart';
import '../../vaccination/data/vaccination_model.dart';
import '../../vaccination/data/vaccination_repository.dart';
import '../../vaccination/providers/vaccination_providers.dart';
import '../data/pet_model.dart';
import '../data/pet_repository.dart';
import '../providers/pet_providers.dart';

class PetDetailScreen extends ConsumerWidget {
  const PetDetailScreen({super.key, required this.petId});
  final String petId;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Pet pet) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa hồ sơ thú cưng?'),
        content: Text('Bạn có chắc muốn xóa hồ sơ của ${pet.name}? Toàn bộ dữ liệu cân nặng, tiêm phòng và nhật ký của bé sẽ bị xóa.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(petRepositoryProvider).deletePet(pet.id);
      if (context.mounted) context.go('/home/pets');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppException.messageOf(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petAsync = ref.watch(petByIdProvider(petId));
    final allPets = ref.watch(petListProvider).valueOrNull ?? const [];

    return AsyncValueView(
      value: petAsync,
      isEmpty: (p) => p == null,
      emptyMessage: 'Không tìm thấy hồ sơ thú cưng.',
      builder: (p) {
        final pet = p!;
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            appBar: AppBar(
              title: allPets.length > 1
                  ? DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: allPets.any((x) => x.id == pet.id) ? pet.id : null,
                        items: allPets
                            .map((x) => DropdownMenuItem(value: x.id, child: Text(x.name)))
                            .toList(),
                        onChanged: (nextId) {
                          if (nextId != null && nextId != pet.id) {
                            ref.read(selectedPetIdProvider.notifier).state = nextId;
                            context.pushReplacement('/home/pets/$nextId');
                          }
                        },
                      ),
                    )
                  : Text(pet.name),
              actions: [
                IconButton(
                  tooltip: 'Sửa hồ sơ',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push('/home/pets/${pet.id}/edit'),
                ),
                IconButton(
                  tooltip: 'Xóa hồ sơ',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref, pet),
                ),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Cân nặng'),
                  Tab(text: 'Tiêm phòng'),
                  Tab(text: 'Nhật ký'),
                  Tab(text: 'Lịch sử khám'),
                ],
              ),
            ),
            body: Column(
              children: [
                _PetHeaderCard(pet: pet),
                Expanded(
                  child: TabBarView(
                    children: [
                      _WeightsTab(pet: pet),
                      _VaccinationsTab(pet: pet),
                      _HealthLogsTab(pet: pet),
                      _MedicalHistoryTab(petId: pet.id),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PetHeaderCard extends StatelessWidget {
  const _PetHeaderCard({required this.pet});
  final Pet pet;

  @override
  Widget build(BuildContext context) {
    final birth = pet.birthDate == null ? 'Chưa rõ' : DateFormat('dd/MM/yyyy').format(pet.birthDate!);
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AppAvatar(imageUrl: pet.photoUrl, radius: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pet.name, style: Theme.of(context).textTheme.titleMedium),
                  Text('${pet.species}${pet.breed.isEmpty ? '' : ' • ${pet.breed}'} • ${pet.gender}'),
                  Text('Ngày sinh: $birth', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightsTab extends ConsumerWidget {
  const _WeightsTab({required this.pet});
  final Pet pet;

  Future<void> _addWeightDialog(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    DateTime selectedDate = DateUtils.dateOnly(DateTime.now());
    bool? ok;
    try {
      ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Ghi nhận cân nặng'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ctrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Cân nặng (kg), ví dụ: 4.5'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Ngày: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final today = DateUtils.dateOnly(DateTime.now());
                      final d = await showDatePicker(
                        context: ctx,
                        initialDate: DateUtils.dateOnly(selectedDate),
                        firstDate: DateTime(2010),
                        lastDate: today,
                      );
                      if (d != null) setState(() => selectedDate = d);
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
            ],
          ),
        ),
      );
    } finally {
      // Đợi lấy giá trị xong mới dispose
    }
    if (ok != true) {
      ctrl.dispose();
      return;
    }
    final val = double.tryParse(ctrl.text.replaceAll(',', '.').trim());
    ctrl.dispose();
    if (val == null || val <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cân nặng không hợp lệ.')));
      }
      return;
    }
    try {
      await ref.read(petRepositoryProvider).addWeight(pet.id, val, selectedDate);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppException.messageOf(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weightsAsync = ref.watch(petWeightsProvider(pet.id));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addWeightDialog(context, ref),
        icon: const Icon(Icons.monitor_weight_outlined),
        label: const Text('Thêm cân nặng'),
      ),
      body: AsyncValueView(
        value: weightsAsync,
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Chưa có dữ liệu cân nặng.',
        builder: (weights) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (weights.length >= 2) ...[
              Text('Biểu đồ cân nặng (kg)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: const FlTitlesData(
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        spots: [
                          for (int i = 0; i < weights.length; i++) FlSpot(i.toDouble(), weights[i].weightKg),
                        ],
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            for (final w in weights.reversed)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.scale_outlined),
                  title: Text('${w.weightKg.toStringAsFixed(2)} kg'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(w.date)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(petRepositoryProvider).deleteWeight(pet.id, w.id),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VaccinationsTab extends ConsumerWidget {
  const _VaccinationsTab({required this.pet});
  final Pet pet;

  Future<void> _addVaccinationDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String type = 'vaccine';
    DateTime dueDate = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 7));

    bool? ok;
    try {
      ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Thêm lịch tiêm / chăm sóc y tế'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'Loại'),
                    items: const [
                      DropdownMenuItem(value: 'vaccine', child: Text('Tiêm phòng')),
                      DropdownMenuItem(value: 'deworm', child: Text('Tẩy giun')),
                      DropdownMenuItem(value: 'checkup', child: Text('Khám định kỳ')),
                    ],
                    onChanged: (v) => setState(() => type = v ?? 'vaccine'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên mũi tiêm / nội dung'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Ghi chú (không bắt buộc)'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Ngày hẹn: ${DateFormat('dd/MM/yyyy').format(dueDate)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: DateUtils.dateOnly(dueDate),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (d != null) setState(() => dueDate = d);
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thêm')),
            ],
          ),
        ),
      );
    } finally {
      // Đợi lấy thông tin xong mới dispose
    }
    if (ok != true || nameCtrl.text.trim().isEmpty) {
      nameCtrl.dispose();
      noteCtrl.dispose();
      return;
    }
    final name = nameCtrl.text;
    final note = noteCtrl.text;
    nameCtrl.dispose();
    noteCtrl.dispose();
    try {
      await ref.read(vaccinationRepositoryProvider).addVaccination(
            petId: pet.id,
            petName: pet.name,
            type: type,
            name: name,
            dueDate: dueDate,
            note: note,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppException.messageOf(e))));
      }
    }
  }

  Future<void> _markDoneDialog(BuildContext context, WidgetRef ref, VaccinationRecord rec) async {
    final daysCtrl = TextEditingController();
    bool? ok;
    try {
      ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Đánh dấu đã hoàn thành'),
          content: TextField(
            controller: daysCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Số ngày lặp lại mũi tiếp theo (để trống nếu không lặp)',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xác nhận')),
          ],
        ),
      );
    } finally {
      // Đợi lấy giá trị xong mới dispose
    }
    if (ok != true) {
      daysCtrl.dispose();
      return;
    }
    final nextDays = int.tryParse(daysCtrl.text.trim());
    daysCtrl.dispose();
    try {
      await ref.read(vaccinationRepositoryProvider).markDone(
            petId: pet.id,
            petName: pet.name,
            record: rec,
            nextDueDays: nextDays,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppException.messageOf(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(petVaccinationsProvider(pet.id));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addVaccinationDialog(context, ref),
        icon: const Icon(Icons.vaccines_outlined),
        label: const Text('Thêm lịch tiêm'),
      ),
      body: AsyncValueView(
        value: listAsync,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: 'Chưa có lịch tiêm phòng hoặc tẩy giun.',
        builder: (items) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final rec = items[idx];
            final isDone = rec.status == 'done';
            return Card(
              child: ListTile(
                leading: Icon(
                  isDone ? Icons.check_circle : Icons.schedule,
                  color: isDone ? Colors.green : Theme.of(context).colorScheme.primary,
                ),
                title: Text('${rec.typeLabel}: ${rec.name}'),
                subtitle: Text(
                  'Hạn: ${DateFormat('dd/MM/yyyy').format(rec.dueDate)}'
                  '${rec.note.isEmpty ? '' : '\n${rec.note}'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isDone)
                      IconButton(
                        tooltip: 'Đánh dấu đã tiêm',
                        icon: const Icon(Icons.done_all),
                        onPressed: () => _markDoneDialog(context, ref, rec),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref.read(vaccinationRepositoryProvider).deleteVaccination(pet.id, rec),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HealthLogsTab extends ConsumerWidget {
  const _HealthLogsTab({required this.pet});
  final Pet pet;

  Future<void> _addLogDialog(BuildContext context, WidgetRef ref) async {
    final symCtrl = TextEditingController();
    DateTime date = DateUtils.dateOnly(DateTime.now());
    final pickedFiles = <XFile>[];
    final uid = ref.read(authStateProvider).valueOrNull?.uid ?? '';

    bool? ok;
    try {
      ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Ghi nhật ký sức khỏe'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: symCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Triệu chứng / biểu hiện'),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Ngày: ${DateFormat('dd/MM/yyyy').format(date)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final today = DateUtils.dateOnly(DateTime.now());
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: DateUtils.dateOnly(date),
                          firstDate: DateTime(2015),
                          lastDate: today,
                        );
                        if (d != null) setState(() => date = d);
                      },
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: pickedFiles.length >= AppConstants.maxHealthLogPhotos
                        ? null
                        : () async {
                            final file = await ref.read(storageServiceProvider).pickImage();
                            if (file != null) {
                              setState(() => pickedFiles.add(file));
                            }
                          },
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      pickedFiles.length >= AppConstants.maxHealthLogPhotos
                          ? 'Đã đạt tối đa ${AppConstants.maxHealthLogPhotos} ảnh'
                          : 'Đính kèm ảnh (${pickedFiles.length}/${AppConstants.maxHealthLogPhotos})',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Lưu')),
            ],
          ),
        ),
      );
    } finally {
      // Đợi lấy nội dung xong mới dispose
    }
    if (ok != true || symCtrl.text.trim().isEmpty) {
      symCtrl.dispose();
      return;
    }
    final symText = symCtrl.text.trim();
    symCtrl.dispose();
    try {
      final uploadedUrls = <String>[];
      for (int i = 0; i < pickedFiles.length; i++) {
        final f = pickedFiles[i];
        final url = await ref.read(storageServiceProvider).uploadOrFallback(
              file: f,
              storagePath: 'health_logs/$uid/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            );
        uploadedUrls.add(url);
      }
      await ref.read(healthLogRepositoryProvider).addHealthLog(
            petId: pet.id,
            date: date,
            symptoms: symText,
            photos: uploadedUrls,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppException.messageOf(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(petHealthLogsProvider(pet.id));
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addLogDialog(context, ref),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Thêm nhật ký'),
      ),
      body: AsyncValueView(
        value: logsAsync,
        isEmpty: (l) => l.isEmpty,
        emptyMessage: 'Chưa có nhật ký sức khỏe.',
        builder: (logs) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, idx) {
            final log = logs[idx];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.assignment_outlined),
                title: Text(DateFormat('dd/MM/yyyy').format(log.date)),
                subtitle: Text(
                  '${log.symptoms}${log.photos.isEmpty ? '' : '\n(${log.photos.length} ảnh đính kèm)'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => ref
                      .read(healthLogRepositoryProvider)
                      .deleteHealthLog(pet.id, log.id, photos: log.photos),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MedicalHistoryTab extends ConsumerWidget {
  const _MedicalHistoryTab({required this.petId});
  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(petMedicalHistoryProvider(petId));
    return AsyncValueView(
      value: historyAsync,
      isEmpty: (l) => l.isEmpty,
      emptyMessage: 'Chưa có lịch sử khám bệnh hoàn thành.',
      builder: (appts) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: appts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, idx) {
          final a = appts[idx];
          final r = a.result;
          return Card(
            child: ListTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: Text('${a.serviceName} • ${a.clinicName}'),
              subtitle: Text(
                'Ngày khám: ${DateFormat('dd/MM/yyyy HH:mm').format(a.startTime)}\n'
                'Chẩn đoán: ${r?.diagnosis.isNotEmpty == true ? r!.diagnosis : "Chưa ghi"}\n'
                'Đơn thuốc: ${r?.prescription.isNotEmpty == true ? r!.prescription : "Chưa ghi"}',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/home/appointments/${a.id}'),
            ),
          );
        },
      ),
    );
  }
}
