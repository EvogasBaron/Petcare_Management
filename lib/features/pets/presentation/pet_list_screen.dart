import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/home_bottom_nav.dart';
import '../../../core/widgets/state_views.dart';
import '../providers/pet_providers.dart';

class PetListScreen extends ConsumerWidget {
  const PetListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ thú cưng')),
      bottomNavigationBar: const HomeBottomNav(currentIndex: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/home/pets/new'),
        icon: const Icon(Icons.add),
        label: const Text('Thêm thú cưng'),
      ),
      body: AsyncValueView(
        value: petsAsync,
        onRetry: () => ref.invalidate(petListProvider),
        isEmpty: (list) => list.isEmpty,
        emptyMessage: 'Bạn chưa thêm hồ sơ thú cưng nào.\nNhấn "Thêm thú cưng" để bắt đầu.',
        builder: (pets) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final pet = pets[index];
            final birthStr = pet.birthDate == null ? 'Chưa rõ ngày sinh' : DateFormat('dd/MM/yyyy').format(pet.birthDate!);
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: AppAvatar(imageUrl: pet.photoUrl, radius: 28),
                title: Text(pet.name, style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text('${pet.species}${pet.breed.isEmpty ? '' : ' • ${pet.breed}'} • ${pet.gender}\nSinh: $birthStr'),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(selectedPetIdProvider.notifier).state = pet.id;
                  context.push('/home/pets/${pet.id}');
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
