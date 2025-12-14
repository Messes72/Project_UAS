import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'field_model.dart';

final fieldRepositoryProvider = Provider<FieldRepository>((ref) {
  return FieldRepository(Supabase.instance.client);
});

final myFieldsProvider = FutureProvider<List<FieldModel>>((ref) async {
  return ref.watch(fieldRepositoryProvider).getMyFields();
});

class FieldRepository {
  final SupabaseClient _client;

  FieldRepository(this._client);

  Future<List<FieldModel>> getMyFields() async {
    final response = await _client
        .from('fields')
        .select()
        .eq('owner_id', _client.auth.currentUser!.id);

    return (response as List).map((e) => FieldModel.fromJson(e)).toList();
  }

  Future<List<FieldModel>> getAllActiveFields() async {
    final response = await _client
        .from('fields')
        .select()
        .eq('is_active', true);

    return (response as List).map((e) => FieldModel.fromJson(e)).toList();
  }

  Future<void> addField(FieldModel field) async {
    await _client.from('fields').insert({
      ...field.toJson(),
      'owner_id': _client.auth.currentUser!.id,
    });
  }

  Future<void> updateField(String id, Map<String, dynamic> updates) async {
    await _client.from('fields').update(updates).eq('id', id);
  }

  Future<void> deleteField(String id) async {
    await _client.from('fields').delete().eq('id', id);
  }
}
