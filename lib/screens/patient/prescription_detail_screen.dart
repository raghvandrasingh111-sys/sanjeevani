import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/prescription_model.dart';
import '../../utils/constants.dart';
import '../../services/ai_service.dart';

class PrescriptionDetailScreen extends StatefulWidget {
  final Prescription prescription;

  const PrescriptionDetailScreen({
    super.key,
    required this.prescription,
  });

  @override
  State<PrescriptionDetailScreen> createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  final AIService _aiService = AIService();
  String? _patientBriefing;
  bool _isLoadingBriefing = false;

  @override
  void initState() {
    super.initState();
    _generateBriefing();
  }

  Future<void> _generateBriefing() async {
    setState(() {
      _isLoadingBriefing = true;
    });

    try {
      final briefing = await _aiService.generatePatientBriefing(widget.prescription);
      setState(() {
        _patientBriefing = briefing;
        _isLoadingBriefing = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBriefing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Details'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Constants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prescription Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: widget.prescription.imageUrl,
                placeholder: (context, url) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Icon(Icons.error),
                ),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 24),

            // Extracted summary from prescription image
            if (widget.prescription.aiSummary != null)
              _buildInfoCard(
                icon: Icons.description,
                title: 'Summary',
                content: widget.prescription.aiSummary!,
                color: Constants.infoColor,
              ),

            // Patient Briefing Card
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'Patient Briefing',
              content: _isLoadingBriefing
                  ? 'Generating briefing...'
                  : (_patientBriefing ??
                      'Unable to generate briefing at this time.'),
              color: Constants.primaryColor,
              isLoading: _isLoadingBriefing,
            ),

            // Medications
            if (widget.prescription.medications != null &&
                widget.prescription.medications!.isNotEmpty)
              _buildInfoCard(
                icon: Icons.medication,
                title: 'Medications',
                content: widget.prescription.medications!.join(', '),
                color: Constants.warningColor,
              ),

            // Dosage
            if (widget.prescription.dosage != null)
              _buildInfoCard(
                icon: Icons.schedule,
                title: 'Dosage',
                content: widget.prescription.dosage!,
                color: Constants.secondaryColor,
              ),

            // Instructions
            if (widget.prescription.instructions != null)
              _buildInfoCard(
                icon: Icons.assignment,
                title: 'Instructions',
                content: widget.prescription.instructions!,
                color: Constants.accentColor,
              ),

            // Notes
            if (widget.prescription.notes != null)
              _buildInfoCard(
                icon: Icons.note,
                title: 'Additional Notes',
                content: widget.prescription.notes!,
                color: Colors.grey[600]!,
              ),

            // Date
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Date',
              content: _formatDate(widget.prescription.createdAt),
              color: Colors.grey[600]!,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    bool isLoading = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: Constants.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(Constants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const LinearProgressIndicator()
            else
              Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
