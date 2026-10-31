import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  const Pet({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed = '',
    this.gender = 'Đực',
    this.birthDate,
    this.photoUrl,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String name;
  final String species; // 'Chó' | 'Mèo' | 'Khác'
  final String breed;
  final String gender; // 'Đực' | 'Cái'
  final DateTime? birthDate;
  final String? photoUrl;
  final DateTime? createdAt;

  factory Pet.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Pet(
      id: doc.id,
      ownerId: d['ownerId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      species: d['species'] as String? ?? 'Chó',
      breed: d['breed'] as String? ?? '',
      gender: d['gender'] as String? ?? 'Đực',
      birthDate: (d['birthDate'] as Timestamp?)?.toDate(),
      photoUrl: d['photoUrl'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'name': name.trim(),
        'species': species,
        'breed': breed.trim(),
        'gender': gender,
        'birthDate': birthDate == null ? null : Timestamp.fromDate(birthDate!),
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toUpdateMap() => {
        'ownerId': ownerId,
        'name': name.trim(),
        'species': species,
        'breed': breed.trim(),
        'gender': gender,
        'birthDate': birthDate == null ? null : Timestamp.fromDate(birthDate!),
        'photoUrl': photoUrl,
      };
}

class WeightRecord {
  const WeightRecord({
    required this.id,
    required this.date,
    required this.weightKg,
  });

  final String id;
  final DateTime date;
  final double weightKg;

  factory WeightRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return WeightRecord(
      id: doc.id,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weightKg: (d['weightKg'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'weightKg': weightKg,
      };
}
