import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WifiClient {
  final String macAddress;
  final int signal;
  String? ipAddress;
  String? hostname;
  final String band;
  final Map<String, num> rate;
  final Map<String, num> bytes;

  WifiClient({
    required this.macAddress,
    required this.signal,
    this.ipAddress,
    this.hostname,
    required this.rate,
    required this.bytes,
    required this.band,
  });
}

class UciData {
  final List<WifiClient> clients;
  final String system;

  UciData({
    required this.clients,
    required this.system,
  });
}

class OpenWrtService {
  final String baseUrl;
  final String username;
  final String password;
  String? _sessionToken;

  OpenWrtService({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  Future<String> authenticate() async {
    final response = await http.post(
      Uri.parse('$baseUrl/ubus'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'call',
        'params': [
          '00000000000000000000000000000000',
          'session',
          'login',
          {'username': username, 'password': password}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _sessionToken = data['result'][1]['ubus_rpc_session'];
      return _sessionToken!;
    } else {
      throw Exception('Authentication failed');
    }
  }

  Future<List<WifiClient>> _getClientsForBand(
      String interface, String band) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/ubus'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'call',
          'params': [_sessionToken, 'hostapd.$interface', 'get_clients', {}]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['result'] == null ||
            data['result'][1] == null ||
            data['result'][1]['clients'] == null) {
          debugPrint(
              'Invalid response structure for $interface: ${response.body}');
          return [];
        }

        final clients = data['result'][1]['clients'] as Map<String, dynamic>;

        return clients.entries
            .map((entry) {
              try {
                return WifiClient(
                  macAddress: entry.key,
                  signal: (entry.value['signal'] as num?)?.toInt() ??
                      -100, // Default value if null
                  bytes: entry.value['bytes'] != null
                      ? Map<String, num>.from(entry.value['bytes'])
                      : {'rx': 0, 'tx': 0},
                  rate: entry.value['rate'] != null
                      ? Map<String, num>.from(entry.value['rate'])
                      : {'rx': 0, 'tx': 0},
                  band: band,
                );
              } catch (e) {
                debugPrint('Error parsing client data for ${entry.key}: $e');
                return null;
              }
            })
            .where((client) => client != null)
            .cast<WifiClient>()
            .toList();
      }

      debugPrint(
          'HTTP Error ${response.statusCode} for $interface: ${response.body}');
      return [];
    } catch (e) {
      debugPrint('Exception in _getClientsForBand($interface): $e');
      return [];
    }
  }

  Future<Map<String, List<String>>> _getDhcpLeases() async {
    final response = await http.post(
      Uri.parse('$baseUrl/ubus'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'call',
        'params': [
          _sessionToken,
          'file',
          'read',
          {'path': '/tmp/dhcp.leases'}
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final leases = data['result'][1]['data'].toString().split('\n');

      final Map<String, List<String>> result = {};
      for (final lease in leases) {
        final parts = lease.split(' ');
        if (parts.length >= 4) {
          result[parts[1]] = [parts[2], parts[3]];
        }
      }
      return result;
    }
    return {};
  }

  Future<UciData> fetchUciData() async {
    if (_sessionToken == null) {
      await authenticate();
    }

    final clients5G = await _getClientsForBand('phy0-ap0', '5GHz');
    final clients2G = await _getClientsForBand('phy1-ap0', '2.4GHz');
    final dhcpLeases = await _getDhcpLeases();

    final allClients = [...clients5G, ...clients2G];

    for (var client in allClients) {
      if (dhcpLeases.containsKey(client.macAddress)) {
        client
          ..ipAddress = dhcpLeases[client.macAddress]![0]
          ..hostname = dhcpLeases[client.macAddress]![1];
      }
    }

    return UciData(
      clients: allClients,
      system: 'System Status: Online',
    );
  }
}

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  UciData? _uciData;
  Timer? _timer;
  late OpenWrtService _service;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    _service = OpenWrtService(
      baseUrl: prefs.getString('server') ?? 'http://192.168.1.1',
      username: prefs.getString('username') ?? 'root',
      password: prefs.getString('password') ?? '',
    );

    try {
      await _service.authenticate();
      setState(() => _isAuthenticated = true);
      _startDataRefresh();
    } catch (e) {
      debugPrint('Authentication failed: $e');
    }
  }

  void _startDataRefresh() {
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    if (!_isAuthenticated) return;

    try {
      final data = await _service.fetchUciData();
      setState(() {
        _uciData = data;
      });
    } catch (e) {
      debugPrint('Error fetching UCI data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text('Connected Devices (${_uciData?.clients.length ?? 0})'),
      ),
      body: !_isAuthenticated
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ..._uciData?.clients
                        .map((client) => Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: ListTile(
                                title:
                                    Text(client.hostname ?? 'Unknown Device'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('MAC: ${client.macAddress}'),
                                    Text(
                                        'IP: ${client.ipAddress ?? "Unknown"}'),
                                    Text('Signal: ${client.signal} dBm'),
                                    Text('Band: ${client.band}'),
                                  ],
                                ),
                                leading: Icon(
                                  Icons.device_hub,
                                  color: client.signal > -50
                                      ? Colors.green
                                      : client.signal > -70
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ))
                        .toList() ??
                    [],
              ],
            ),
    );
  }
}
