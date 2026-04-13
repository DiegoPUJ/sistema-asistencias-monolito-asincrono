import 'dart:async';
import 'package:flutter/material.dart';
import 'models/assistance_request.dart';
import 'models/provider.dart';
import 'services/assistance_service.dart';
import 'admin_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Asistencias Vehiculares',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        useMaterial3: true,
      ),
      home: const HomeTabs(),
    );
  }
}

class HomeTabs extends StatefulWidget {
  const HomeTabs({super.key});

  @override
  State<HomeTabs> createState() => _HomeTabsState();
}

class _HomeTabsState extends State<HomeTabs> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AssistanceScreen(),
    AdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            selectedIcon: Icon(Icons.support_agent),
            label: 'Cliente',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ],
      ),
    );
  }
}

class AssistanceScreen extends StatefulWidget {
  const AssistanceScreen({super.key});

  @override
  State<AssistanceScreen> createState() => _AssistanceScreenState();
}

class _AssistanceScreenState extends State<AssistanceScreen> {
  Future<void> _restoreLastRequest() async {
  final prefs = await SharedPreferences.getInstance();
  final lastRequestId = prefs.getInt(_lastRequestIdKey);

  if (lastRequestId == null) return;

  try {
    final result = await _service.getRequestById(lastRequestId);

    setState(() {
      _currentRequest = result;
      _isLoading = result.status != 'completed';
    });

    if (result.status != 'completed') {
      _startPolling(lastRequestId);
    }
  } catch (_) {
    // Si no se encuentra o falla, limpiamos el valor guardado
    await prefs.remove(_lastRequestIdKey);
  }
}
  static const String _lastRequestIdKey = 'last_request_id';
  final AssistanceService _service = AssistanceService();

  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _vehiclePlateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  AssistanceRequest? _currentRequest;
  Timer? _pollingTimer;

  bool _isLoading = false;
  bool _loadingProviders = true;

  List<ProviderModel> _providers = [];
  int? _selectedProviderId;

  @override
void initState() {
  super.initState();
  _loadProviders();
  _restoreLastRequest();
}

  Future<void> _loadProviders() async {
    try {
      final providers = await _service.getProviders();

      debugPrint('Providers cargados: ${providers.length}');
      for (final p in providers) {
        debugPrint('Provider: ${p.id} - ${p.name}');
      }

      setState(() {
        _providers = providers;
        if (providers.isNotEmpty) {
          _selectedProviderId = providers.first.id;
        }
        _loadingProviders = false;
      });
    } catch (e) {
      debugPrint('Error cargando providers: $e');

      setState(() {
        _loadingProviders = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar aseguradoras: $e')),
      );
    }
  }

  Future<void> _createRequest() async {
  final clientName = _clientNameController.text.trim();
  final vehiclePlate = _vehiclePlateController.text.trim();
  final location = _locationController.text.trim();
  final description = _descriptionController.text.trim();

  if (clientName.isEmpty ||
      vehiclePlate.isEmpty ||
      location.isEmpty ||
      description.isEmpty ||
      _selectedProviderId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Por favor completa todos los campos.'),
      ),
    );
    return;
  }

  setState(() {
    _isLoading = true;
    _currentRequest = null;
  });

  try {
    final response = await _service.createRequest(
      clientName: clientName,
      vehiclePlate: vehiclePlate,
      location: location,
      description: description,
      providerId: _selectedProviderId!,
    );

    final requestId = response['id'] as int;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastRequestIdKey, requestId);

    _clientNameController.clear();
    _vehiclePlateController.clear();
    _locationController.clear();
    _descriptionController.clear();

    _startPolling(requestId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Solicitud enviada correctamente.'),
      ),
    );
  } catch (e) {
    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al enviar solicitud: $e')),
    );
  }
}

  void _startPolling(int requestId) {
  _pollingTimer?.cancel();

  _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
    try {
      final result = await _service.getRequestById(requestId);

      setState(() {
        _currentRequest = result;
        _isLoading = result.status != 'completed';
      });

      if (result.status == 'completed') {
        timer.cancel();

        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_lastRequestIdKey);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La solicitud fue completada exitosamente.'),
          ),
        );
      }
    } catch (_) {
      timer.cancel();
      setState(() {
        _isLoading = false;
      });
    }
  });
}

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _clientNameController.dispose();
    _vehiclePlateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  Color _statusBgColor(String status) {
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

  String _providerNameById(int? providerId) {
    if (providerId == null) return 'No disponible';

    for (final provider in _providers) {
      if (provider.id == providerId) {
        return provider.name;
      }
    }

    return _currentRequest?.providerName ?? 'No disponible';
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.indigo),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sistema de Asistencias Vehiculares 24/7',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo.shade900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Registra una solicitud de asistencia y realiza seguimiento del proceso en tiempo real.',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.indigo.shade700),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'La solicitud se registra de inmediato. La validación con la aseguradora se procesa en segundo plano y el estado se actualiza automáticamente.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return _sectionCard(
      title: 'Registrar solicitud',
      icon: Icons.assignment_outlined,
      child: Column(
        children: [
          TextField(
            controller: _clientNameController,
            decoration: const InputDecoration(
              labelText: 'Nombre del cliente',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vehiclePlateController,
            decoration: const InputDecoration(
              labelText: 'Placa del vehículo',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.directions_car_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Ubicación',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Descripción del incidente',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.description_outlined),
            ),
          ),
          const SizedBox(height: 12),
          if (_loadingProviders)
            const LinearProgressIndicator()
          else ...[
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Aseguradora',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business_outlined),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _providers.any((p) => p.id == _selectedProviderId)
                      ? _selectedProviderId
                      : null,
                  hint: const Text('Selecciona una aseguradora'),
                  items: _providers.map((provider) {
                    return DropdownMenuItem<int>(
                      value: provider.id,
                      child: Text(provider.name),
                    );
                  }).toList(),
                  onChanged: _providers.isEmpty
                      ? null
                      : (value) {
                          setState(() {
                            _selectedProviderId = value;
                          });
                        },
                ),
              ),
            ),
            if (_providers.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No hay aseguradoras disponibles.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (_isLoading || _loadingProviders || _providers.isEmpty)
                  ? null
                  : _createRequest,
              icon: Icon(_isLoading ? Icons.sync : Icons.send_outlined),
              label: Text(
                _isLoading ? 'Procesando solicitud...' : 'Enviar solicitud',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final status = _currentRequest?.status;

    final step1 = _currentRequest != null;
    final step2 = status == 'processing' || status == 'completed';
    final step3 = status == 'completed';

    Widget processTile({
      required String title,
      required String subtitle,
      required bool active,
      required IconData icon,
    }) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: active ? Colors.indigo : Colors.grey.shade300,
            child: Icon(
              icon,
              size: 18,
              color: active ? Colors.white : Colors.black45,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.black87 : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? Colors.black54 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _sectionCard(
      title: 'Estado del proceso',
      icon: Icons.route_outlined,
      child: Column(
        children: [
          processTile(
            title: 'Solicitud registrada',
            subtitle: 'La API recibió la solicitud y respondió de inmediato.',
            active: step1,
            icon: Icons.assignment_turned_in_outlined,
          ),
          const SizedBox(height: 16),
          processTile(
            title: 'Validación en segundo plano',
            subtitle: 'El worker procesa la solicitud sin bloquear al usuario.',
            active: step2,
            icon: Icons.settings_backup_restore,
          ),
          const SizedBox(height: 16),
          processTile(
            title: 'Resultado disponible',
            subtitle: 'El estado se actualiza automáticamente mediante polling.',
            active: step3,
            icon: Icons.check_circle_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_currentRequest == null) {
      return _sectionCard(
        title: 'Seguimiento de solicitud',
        icon: Icons.visibility_outlined,
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 46, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            const Text(
              'Aún no hay una solicitud activa',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando registres una solicitud, aquí verás el detalle y el estado del proceso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      );
    }

    return _sectionCard(
      title: 'Seguimiento de solicitud',
      icon: Icons.track_changes_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('ID de solicitud', '${_currentRequest!.id}'),
          _infoRow('Cliente', _currentRequest!.clientName),
          _infoRow('Placa', _currentRequest!.vehiclePlate),
          _infoRow('Ubicación', _currentRequest!.location),
          _infoRow('Descripción', _currentRequest!.description),
          _infoRow('Aseguradora', _providerNameById(_currentRequest!.providerId)),
          _infoRow(
            'Técnico asignado',
            (_currentRequest!.assignedTechnician?.isNotEmpty ?? false)
                ? _currentRequest!.assignedTechnician!
                : 'Sin asignar',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Estado actual:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Chip(
                label: Text(
                  _statusLabel(_currentRequest!.status),
                  style: TextStyle(
                    color: _statusTextColor(_currentRequest!.status),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: _statusBgColor(_currentRequest!.status),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistema de Asistencias Vehiculares'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(),
            _buildInfoBanner(),
            _buildFormCard(),
            _buildProgressCard(),
            _buildStatusCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}