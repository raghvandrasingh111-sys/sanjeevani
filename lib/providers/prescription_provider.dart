import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/prescription_model.dart';
import '../services/ai_service.dart';

class PrescriptionProvider with ChangeNotifier {
  SupabaseClient get _client => Supabase.instance.client;
  final AIService _aiService = AIService();

  List<Prescription> _prescriptions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Prescription> get prescriptions => _prescriptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Upload image to Supabase Storage; returns public URL.
  /// Throws on failure (e.g. StorageException with 403 if RLS policies missing).
  Future<String> uploadImage(Uint8List imageBytes, String userId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$fileName';
      await _client.storage.from('prescriptions').uploadBinary(
            path,
            imageBytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from('prescriptions').getPublicUrl(path);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> fetchPrescriptions(String userId, String userType) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final List<Map<String, dynamic>> data;
      if (userType == 'patient') {
        data = await _client
            .from('prescriptions')
            .select()
            .eq('patient_id', userId)
            .order('created_at', ascending: false);
      } else {
        data = await _client
            .from('prescriptions')
            .select()
            .eq('doctor_id', userId)
            .order('created_at', ascending: false);
      }

      _prescriptions = data.map((r) => Prescription.fromJson(_rowToJson(r))).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Runs AI analysis on image bytes (works on web; no URL fetch). Use before upload.
  Future<Map<String, dynamic>> analyzePrescriptionFromBytes(Uint8List imageBytes) async {
    return _aiService.analyzePrescriptionFromBytes(imageBytes);
  }

  /// Resolve patient user id from 12-digit Aadhar. Returns null if not found.
  Future<String?> getPatientIdByAadhar(String aadhar) async {
    try {
      final normalized = aadhar.replaceAll(RegExp(r'\D'), '');
      if (normalized.length != 12) return null;
      final row = await _client
          .from('profiles')
          .select('id')
          .eq('aadhar_number', normalized)
          .eq('user_type', 'patient')
          .maybeSingle();
      return row?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> createPrescription({
    required String doctorId,
    required String patientId,
    required String imageUrl,
    String? notes,
    Map<String, dynamic>? aiSummary,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final resolved = aiSummary ?? await _aiService.analyzePrescription(imageUrl);
      final now = DateTime.now().toIso8601String();

      await _client.from('prescriptions').insert({
        'doctor_id': doctorId,
        'patient_id': patientId,
        'image_url': imageUrl,
        'notes': notes,
        'ai_summary': resolved['summary'],
        'medications': resolved['medications'] ?? [],
        'dosage': resolved['dosage'],
        'instructions': resolved['instructions'],
        'created_at': now,
        'updated_at': now,
      });

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> deletePrescription(String id) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _client.from('prescriptions').delete().eq('id', id);
      _prescriptions.removeWhere((p) => p.id == id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  static Map<String, dynamic> _rowToJson(Map<String, dynamic> r) {
    final data = Map<String, dynamic>.from(r);
    final id = data['id'];
    data['id'] = id?.toString() ?? '';
    final created = data['created_at'];
    final updated = data['updated_at'];
    data['created_at'] = created is String ? created : (created as DateTime?)?.toIso8601String() ?? DateTime.now().toIso8601String();
    data['updated_at'] = updated is String ? updated : (updated as DateTime?)?.toIso8601String() ?? DateTime.now().toIso8601String();
    if (data['medications'] is List) {
      data['medications'] = (data['medications'] as List).map((e) => e.toString()).toList();
    }
    return data;
  }
}
