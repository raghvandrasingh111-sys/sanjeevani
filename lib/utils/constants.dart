import 'package:flutter/material.dart';

class Constants {
  // Supabase - Replace with your project URL and anon key from Supabase dashboard
  static const String supabaseUrl = 'https://yhsoxjhwewjjgfutcbdx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inloc294amh3ZXdqamdmdXRjYmR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0OTE1MDYsImV4cCI6MjA4NTA2NzUwNn0.uEvdI4tCGfsTEzdHPlh3sJbUEE51SA5g1J4BO-dpkBM';
  // static const String supabaseUrl = 'https://xjixpmxichjrlagwomev.supabase.co';
  // static const String supabaseAnonKey =
  //     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhqaXhwbXhpY2hqcmxhZ3dvbWV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk1MDU0NTcsImV4cCI6MjA4NTA4MTQ1N30.KJ7BWOvWv_w1RUbpqeiGmre41D8777bKdCL2lzapGLo';

  // Google Generative AI - Replace with your API key
  static const String geminiApiKey = 'AIzaSyB9KZPb_CU5ZZJURK_N682T153qJHThSzo';

  // App Colors
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color secondaryColor = Color(0xFF66BB6A);
  static const Color accentColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFE53935);
  static const Color successColor = Color(0xFF43A047);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
}
