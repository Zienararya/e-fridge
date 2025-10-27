import 'package:supabase_flutter/supabase_flutter.dart';
import '../secrets.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: Secrets.supabaseUrl,
      anonKey: Secrets.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
