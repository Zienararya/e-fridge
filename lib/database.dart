import 'package:supabase_flutter/supabase_flutter.dart';
import 'secrets.dart';

class Database {
  // IMPORTANT: Postgres akan menurunkan huruf jika schema tidak di-quote.
  // Supabase Data API dan CLI lebih cocok dengan nama schema lowercase.
  // Setelah kamu rename schema "RPL" menjadi rpl, ubah ke 'rpl'.
  static final SupabaseClient supabase = SupabaseClient(
    Secrets.supabaseUrl,
    Secrets.supabaseAnonKey,
    postgrestOptions: const PostgrestClientOptions(schema: 'rpl'),
  );
}

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: Secrets.supabaseUrl,
      anonKey: Secrets.supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
