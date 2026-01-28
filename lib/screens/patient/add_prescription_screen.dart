import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/prescription_provider.dart';
import '../../utils/constants.dart';

class AddPrescriptionScreen extends StatefulWidget {
  const AddPrescriptionScreen({super.key});

  @override
  State<AddPrescriptionScreen> createState() => _AddPrescriptionScreenState();
}

class _AddPrescriptionScreenState extends State<AddPrescriptionScreen> {
  final _notesController = TextEditingController();
  final _patientAadharController = TextEditingController();
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _notesController.dispose();
    _patientAadharController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    }
  }

  Future<void> _takePhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    }
  }

  Future<String> _uploadImage(Uint8List imageBytes) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prescriptionProvider =
        Provider.of<PrescriptionProvider>(context, listen: false);
    return prescriptionProvider.uploadImage(imageBytes, authProvider.currentUser!.id);
  }

  Future<void> _savePrescription() async {
    if (_selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
          backgroundColor: Constants.errorColor,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final prescriptionProvider =
        Provider.of<PrescriptionProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      String? patientId;
      if (authProvider.currentUser!.userType == 'doctor') {
        final aadhar = _patientAadharController.text.trim();
        if (aadhar.isEmpty) {
          if (mounted) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please enter the patient\'s Aadhar number'),
                backgroundColor: Constants.errorColor,
              ),
            );
          }
          return;
        }
        patientId = await prescriptionProvider.getPatientIdByAadhar(aadhar);
        if (patientId == null && mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No patient found with this Aadhar number. Ask them to sign up with this Aadhar first.'),
              backgroundColor: Constants.errorColor,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
      } else {
        patientId = authProvider.currentUser!.id;
      }

      // Analyze image with AI from bytes (works on web; avoids CORS)
      final aiSummary = await prescriptionProvider.analyzePrescriptionFromBytes(_selectedImageBytes!);

      // Upload image to Supabase Storage (can fail with 403 if Storage policies missing)
      String imageUrl;
      try {
        imageUrl = await _uploadImage(_selectedImageBytes!);
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_formatUploadError(e)),
              backgroundColor: Constants.errorColor,
              duration: const Duration(seconds: 6),
            ),
          );
        }
        return;
      }

      // Create prescription record in database
      final success = await prescriptionProvider.createPrescription(
        doctorId: authProvider.currentUser!.id,
        patientId: patientId!,
        imageUrl: imageUrl,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        aiSummary: aiSummary,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          Navigator.of(context).pop(); // Go back to dashboard
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prescription added successfully!'),
              backgroundColor: Constants.primaryColor,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                prescriptionProvider.errorMessage ?? 'Failed to save prescription.',
              ),
              backgroundColor: Constants.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_formatPrescriptionError(e)),
            backgroundColor: Constants.errorColor,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  /// Message when Storage upload fails (403/RLS or network).
  static String _formatUploadError(dynamic e) {
    final s = e.toString().toLowerCase();
    if (s.contains('storageexception') ||
        s.contains('row-level security') ||
        s.contains('403') ||
        s.contains('unauthorized')) {
      return 'Something went wrong while uploading file. Check that Supabase Storage policies are set (SUPABASE_SETUP.md → Storage policies) and try again.';
    }
    return 'Something went wrong while uploading file. Please try again.';
  }

  /// User-friendly message for other save errors (e.g. DB insert).
  static String _formatPrescriptionError(dynamic e) {
    final s = e.toString().toLowerCase();
    if (s.contains('storageexception') ||
        (s.contains('row-level security') && s.contains('403'))) {
      return 'Upload blocked by server security settings. Add Storage policies in Supabase (see SUPABASE_SETUP.md) and try again.';
    }
    return 'Error: $e';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isDoctor = authProvider.currentUser?.userType == 'doctor';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Prescription'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Constants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Selection
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Choose from Gallery'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage();
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Take Photo'),
                          onTap: () {
                            Navigator.pop(context);
                            _takePhoto();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: _selectedImageBytes == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap to select prescription image',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          _selectedImageBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Patient Aadhar (required for doctors)
            if (isDoctor) ...[
              TextFormField(
                controller: _patientAadharController,
                keyboardType: TextInputType.number,
                maxLength: 14,
                decoration: const InputDecoration(
                  labelText: 'Patient Aadhar Number',
                  hintText: '12-digit Aadhar of the patient',
                  prefixIcon: Icon(Icons.badge),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                prefixIcon: Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _savePrescription,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Save Prescription',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
