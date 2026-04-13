import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/assistance_request.dart';
import '../models/provider.dart';

class AssistanceService {
  static const String baseUrl = 'http://localhost:8000';

  Future<List<ProviderModel>> getProviders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/providers'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProviderModel.fromJson(json)).toList();
    }

    throw Exception('Error al cargar aseguradoras');
  }

  Future<Map<String, dynamic>> createRequest({
    required String clientName,
    required String vehiclePlate,
    required String location,
    required String description,
    required int providerId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/assistance-requests'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'client_name': clientName,
        'vehicle_plate': vehiclePlate,
        'location': location,
        'description': description,
        'provider_id': providerId,
      }),
    );

    if (response.statusCode == 202) {
      return jsonDecode(response.body);
    }

    throw Exception('Error al crear la solicitud');
  }

  Future<AssistanceRequest> getRequestById(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/assistance-requests/$id'),
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return AssistanceRequest.fromJson(jsonDecode(response.body));
    }

    throw Exception('Error al consultar la solicitud');
  }

  Future<List<AssistanceRequest>> getAllRequests({String? status}) async {
    final uri = status == null || status.isEmpty
        ? Uri.parse('$baseUrl/assistance-requests')
        : Uri.parse('$baseUrl/assistance-requests?status=$status');

    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => AssistanceRequest.fromJson(json)).toList();
    }

    throw Exception('Error al cargar solicitudes');
  }

  Future<void> assignTechnician({
    required int requestId,
    required String technicianName,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/assistance-requests/$requestId/assign'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'assigned_technician': technicianName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al asignar técnico');
    }
  }
}