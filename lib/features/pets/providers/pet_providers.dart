import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/session_providers.dart';
import '../data/pet_model.dart';
import '../data/pet_repository.dart';

final petListProvider = StreamProvider<List<Pet>>((ref) {
  final uid = ref.watch(authStateProvider).when(
        data: (u) => u?.uid,
        loading: () => null,
        error: (_, __) => null,
      );
  if (uid == null) return Stream.value(const []);
  return ref.watch(petRepositoryProvider).watchPets(uid);
});

final selectedPetIdProvider = StateProvider<String?>((ref) => null);

final petByIdProvider = StreamProvider.family<Pet?, String>((ref, petId) =>
    ref.watch(petRepositoryProvider).watchPet(petId));

final petWeightsProvider = StreamProvider.family<List<WeightRecord>, String>((ref, petId) =>
    ref.watch(petRepositoryProvider).watchWeights(petId));
