import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_invoice_app/core/services/supabase_service.dart';

final userProvider = StreamProvider<User?>((ref) {
  return ref
      .watch(supabaseServiceProvider)
      .client
      .auth
      .onAuthStateChange
      .map((event) => event.session?.user);
});
