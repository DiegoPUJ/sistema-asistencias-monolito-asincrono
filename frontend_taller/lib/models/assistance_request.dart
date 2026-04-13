class AssistanceRequest {
  final int id;
  final String clientName;
  final String vehiclePlate;
  final String location;
  final String description;
  final int providerId;
  final String status;
  final String? assignedTechnician;
  final Map<String, dynamic>? provider;

  AssistanceRequest({
    required this.id,
    required this.clientName,
    required this.vehiclePlate,
    required this.location,
    required this.description,
    required this.providerId,
    required this.status,
    this.assignedTechnician,
    this.provider,
  });

  factory AssistanceRequest.fromJson(Map<String, dynamic> json) {
    return AssistanceRequest(
      id: json['id'],
      clientName: json['client_name'],
      vehiclePlate: json['vehicle_plate'],
      location: json['location'],
      description: json['description'],
      providerId: json['provider_id'],
      status: json['status'],
      assignedTechnician: json['assigned_technician'],
      provider: json['provider'],
    );
  }

  String get providerName {
    if (provider == null) return 'No disponible';
    return provider!['name'] ?? 'No disponible';
  }
}