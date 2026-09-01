import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entities/client.dart';

class SupabaseClientRepository {
  const SupabaseClientRepository(this._client);

  final SupabaseClient _client;

  Future<List<Client>> getClients() async {
    final rows = await _client.from('clients').select().order('name');
    return (rows as List)
        .map((row) => Client.fromMap(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<Client> createClient({
    required String name,
    String? clientCode,
    String? companyName,
    String? phone,
    String? whatsapp,
    String? email,
    String? address,
    String? clientType,
    required String status,
    String? notes,
  }) async {
    final userId = _requireUserId();
    final row = await _client.from('clients').insert({
      'owner_id': userId,
      'name': name,
      'client_code': clientCode,
      'company_name': companyName,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'address': address,
      'client_type': clientType,
      'status': status,
      'notes': notes,
    }).select().single();
    return Client.fromMap(Map<String, dynamic>.from(row));
  }

  Future<Client> updateClient({
    required String id,
    required String name,
    String? clientCode,
    String? companyName,
    String? phone,
    String? whatsapp,
    String? email,
    String? address,
    String? clientType,
    required String status,
    String? notes,
  }) async {
    final row = await _client.from('clients').update({
      'name': name,
      'client_code': clientCode,
      'company_name': companyName,
      'phone': phone,
      'whatsapp': whatsapp,
      'email': email,
      'address': address,
      'client_type': clientType,
      'status': status,
      'notes': notes,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id).select().single();
    return Client.fromMap(Map<String, dynamic>.from(row));
  }

  Future<void> deleteClient(String id) async {
    await _client.from('clients').delete().eq('id', id);
  }

  String _requireUserId() {
    final user = _client.auth.currentUser;
    if (user == null) throw AuthException('No authenticated Supabase session.');
    return user.id;
  }
}
