import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers/session_providers.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/state_views.dart';
import '../data/pet_model.dart';
import '../data/pet_repository.dart';
import '../providers/pet_providers.dart';

class PetFormScreen extends ConsumerStatefulWidget {
  const PetFormScreen({super.key, this.petId});
  final String? petId;

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  String _species = 'Chó';
  String _gender = 'Đực';
  DateTime? _birthDate;
  String? _photoUrl;
  bool _initialized = false;
  bool _busy = false;

  bool get _isEdit => widget.petId != null;

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(String uid) async {
    final file = await ref.read(storageServiceProvider).pickImage();
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final path = 'pets/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final url = await ref.read(storageServiceProvider).uploadOrFallback(file: file, storagePath: path);
      setState(() => _photoUrl = url);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate != null ? DateUtils.dateOnly(_birthDate!) : today,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit(String uid) async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final pet = Pet(
        id: widget.petId ?? '',
        ownerId: uid,
        name: _name.text,
        species: _species,
        breed: _breed.text,
        gender: _gender,
        birthDate: _birthDate,
        photoUrl: _photoUrl,
      );
      if (_isEdit) {
        await ref.read(petRepositoryProvider).updatePet(pet);
      } else {
        await ref.read(petRepositoryProvider).createPet(pet);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppException.messageOf(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid ?? '';
    if (_isEdit) {
      final petAsync = ref.watch(petByIdProvider(widget.petId!));
      return Scaffold(
        appBar: AppBar(title: const Text('Sửa hồ sơ thú cưng')),
        body: AsyncValueView(
          value: petAsync,
          isEmpty: (p) => p == null,
          builder: (p) {
            final pet = p!;
            if (!_initialized) {
              _name.text = pet.name;
              _breed.text = pet.breed;
              _species = pet.species;
              _gender = pet.gender;
              _birthDate = pet.birthDate;
              _photoUrl = pet.photoUrl;
              _initialized = true;
            }
            return _buildForm(uid);
          },
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm thú cưng')),
      body: _buildForm(uid),
    );
  }

  Widget _buildForm(String uid) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            children: [
              GestureDetector(
                onTap: _busy ? null : () => _pickPhoto(uid),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    AppAvatar(imageUrl: _photoUrl, radius: 44),
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên thú cưng'),
                validator: (v) => validateRequired(v, 'tên thú cưng'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _species,
                decoration: const InputDecoration(labelText: 'Loài'),
                items: const [
                  DropdownMenuItem(value: 'Chó', child: Text('Chó')),
                  DropdownMenuItem(value: 'Mèo', child: Text('Mèo')),
                  DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                ],
                onChanged: (v) => setState(() => _species = v ?? 'Chó'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _breed,
                decoration: const InputDecoration(labelText: 'Giống (ví dụ: Poodle, Anh lông ngắn...)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: const InputDecoration(labelText: 'Giới tính'),
                items: const [
                  DropdownMenuItem(value: 'Đực', child: Text('Đực')),
                  DropdownMenuItem(value: 'Cái', child: Text('Cái')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'Đực'),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ngày sinh'),
                subtitle: Text(_birthDate == null ? 'Chưa chọn' : DateFormat('dd/MM/yyyy').format(_birthDate!)),
                trailing: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Chọn ngày'),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : () => _submit(uid),
                  child: _busy
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_isEdit ? 'Lưu thay đổi' : 'Thêm thú cưng'),
                ),
              ),
            ],
          ),
        ),
      );
}
