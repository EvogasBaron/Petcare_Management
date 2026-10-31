import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/services/notification_service.dart';
import 'pet_model.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) => PetRepository());

class PetRepository {
  PetRepository({FirebaseFirestore? db}) : _dbInstance = db;
  final FirebaseFirestore? _dbInstance;
  FirebaseFirestore get _db => _dbInstance ?? FirebaseFirestore.instance;

  Stream<List<Pet>> watchPets(String ownerId) => _db
      .collection('pets')
      .where('ownerId', isEqualTo: ownerId)
      .snapshots()
      .map((s) {
        final list = s.docs.map(Pet.fromFirestore).toList();
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
      });

  Stream<Pet?> watchPet(String petId) => _db
      .collection('pets')
      .doc(petId)
      .snapshots()
      .map((s) => s.exists ? Pet.fromFirestore(s) : null);

  Future<String> createPet(Pet pet) async {
    try {
      final doc = await _db.collection('pets').add(pet.toMap());
      return doc.id;
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  Future<void> updatePet(Pet pet) async {
    try {
      await _db.collection('pets').doc(pet.id).update(pet.toUpdateMap());
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  Future<void> deletePet(String petId) async {
    try {
      for (final sub in ['weights', 'vaccinations', 'reminders', 'health_logs']) {
        final snap = await _db.collection('pets').doc(petId).collection(sub).get();
        for (final d in snap.docs) {
          if (sub == 'reminders' || sub == 'vaccinations') {
            final notifId = (d.data()['notificationId'] as num?)?.toInt();
            if (notifId != null && notifId > 0) {
              await NotificationService.instance.cancel(notifId);
            }
          }
          await d.reference.delete();
        }
      }
      await _db.collection('pets').doc(petId).delete();
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  Stream<List<WeightRecord>> watchWeights(String petId) => _db
      .collection('pets')
      .doc(petId)
      .collection('weights')
      .orderBy('date', descending: false)
      .snapshots()
      .map((s) => s.docs.map(WeightRecord.fromFirestore).toList());

  Future<void> addWeight(String petId, double weightKg, DateTime date) async {
    try {
      final rec = WeightRecord(id: '', date: date, weightKg: weightKg);
      await _db.collection('pets').doc(petId).collection('weights').add(rec.toMap());
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }

  Future<void> deleteWeight(String petId, String weightId) async {
    try {
      await _db.collection('pets').doc(petId).collection('weights').doc(weightId).delete();
    } catch (e) {
      throw AppException.fromFirebase(e);
    }
  }
}
