import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/constants.dart';
import '../models/prescription_model.dart';

class AIService {
  final String _apiKey = Constants.geminiApiKey;
  late final GenerativeModel _model;

  AIService() {
    // Using gemini-pro for text generation
    // For vision capabilities, use gemini-1.5-pro or gemini-1.5-flash
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );
  }

  Future<Map<String, dynamic>> analyzePrescription(String imageUrl) async {
    try {
      // Download image
      final imageResponse = await http.get(Uri.parse(imageUrl));
      final imageBytes = imageResponse.bodyBytes;

      // Use Gemini Vision API to analyze prescription
      final prompt = '''
Analyze this prescription image and extract the following information:
1. List all medications mentioned
2. Dosage information for each medication
3. Instructions for taking the medications
4. Any special notes or warnings

Provide a brief summary in simple language that a patient can understand.
Format the response as JSON with the following structure:
{
  "summary": "Brief summary of the prescription",
  "medications": ["medication1", "medication2", ...],
  "dosage": "Dosage information",
  "instructions": "How to take the medications"
}
''';

      // Note: This is a simplified version. In production, you'd need to
      // properly handle image input with Gemini Vision API
      // For now, we'll use a text-based approach
      
      final content = [
        Content.text(prompt),
        // In production, add image content here
      ];

      final response = await _model.generateContent(content);
      final text = response.text ?? '';

      // Try to parse JSON from response
      try {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch != null) {
          return json.decode(jsonMatch.group(0)!);
        }
      } catch (e) {
        // If JSON parsing fails, create a structured response
      }

      // Fallback response
      return {
        'summary': text.isNotEmpty
            ? text
            : 'Prescription analyzed. Please review the image for details.',
        'medications': [],
        'dosage': 'As prescribed',
        'instructions': 'Follow doctor\'s instructions',
      };
    } catch (e) {
      // Fallback in case of error
      return {
        'summary': 'Unable to analyze prescription at this time. Please review the image manually.',
        'medications': [],
        'dosage': 'As prescribed',
        'instructions': 'Follow doctor\'s instructions',
      };
    }
  }

  Future<String> generatePatientBriefing(Prescription prescription) async {
    try {
      final prompt = '''
You are a medical assistant. Create a patient-friendly briefing for this prescription:

Medications: ${prescription.medications?.join(', ') ?? 'Not specified'}
Dosage: ${prescription.dosage ?? 'As prescribed'}
Instructions: ${prescription.instructions ?? 'Follow doctor\'s instructions'}
Notes: ${prescription.notes ?? 'None'}

Create a clear, simple explanation that helps the patient understand:
1. What medications they need to take
2. When and how to take them
3. Any important warnings or side effects
4. What to do if they miss a dose

Keep it friendly, clear, and easy to understand.
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      
      return response.text ?? 'Unable to generate briefing at this time.';
    } catch (e) {
      return 'Unable to generate briefing at this time. Please contact your doctor for clarification.';
    }
  }
}
