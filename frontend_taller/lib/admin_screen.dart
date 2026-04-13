import 'package:flutter/material.dart';
import 'models/assistance_request.dart';
import 'services/assistance_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AssistanceService _service = AssistanceService();

  List<AssistanceRequest> _requests = [];
  bool _isLoading = true;
  String _selectedStatus = '';

  final List<Map<String, String>> _statusOptions = [
    {'label': 'Todas', 'value': ''},
    {'label': 'Pendientes', 'value': 'pending'},
    {'label': 'En proceso', 'value': 'processing'},
    {'label': 'Completadas', 'value': 'completed'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _service.getAllRequests(status: _selectedStatus);

      setState(() {
        _requests = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar solicitudes: $e')),
      );
    }
  }

  Future<void> _showAssignDialog(AssistanceRequest request) async {
    final controller = TextEditingController(
      text: request.assignedTechnician ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Asignar técnico'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nombre del técnico',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) return;

    try {
      await _service.assignTechnician(
        requestId: request.id,
        technicianName: result,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Técnico asignado correctamente.')),
      );

      _loadRequests();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al asignar técnico: $e')),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade100;
      case 'processing':
        return Colors.blue.shade100;
      case 'completed':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade900;
      case 'processing':
        return Colors.blue.shade900;
      case 'completed':
        return Colors.green.shade900;
      default:
        return Colors.black87;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'processing':
        return 'En proceso';
      case 'completed':
        return 'Completada';
      default:
        return status;
    }
  }

  Widget _buildRequestCard(AssistanceRequest request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Solicitud #${request.id}',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 8),
            Text('Cliente: ${request.clientName}'),
            Text('Placa: ${request.vehiclePlate}'),
            Text('Ubicación: ${request.location}'),
            Text('Descripción: ${request.description}'),
            Text('Aseguradora: ${request.providerName}'),
            Text(
              'Técnico asignado: ${request.assignedTechnician?.isNotEmpty == true ? request.assignedTechnician : 'Sin asignar'}',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                Chip(
                  label: Text(
                    _statusLabel(request.status),
                    style: TextStyle(
                      color: _statusTextColor(request.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _statusColor(request.status),
                ),
                FilledButton.icon(
                  onPressed: () => _showAssignDialog(request),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Asignar técnico'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Admin'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Filtrar por estado',
                border: OutlineInputBorder(),
              ),
              items: _statusOptions.map((option) {
                return DropdownMenuItem<String>(
                  value: option['value'],
                  child: Text(option['label']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value ?? '';
                });
                _loadRequests();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? const Center(
                        child: Text('No hay solicitudes para mostrar.'),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadRequests,
                        child: ListView.builder(
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            return _buildRequestCard(_requests[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}