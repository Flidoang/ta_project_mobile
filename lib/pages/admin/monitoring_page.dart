import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage>
    with SingleTickerProviderStateMixin {
  MqttServerClient? client;
  bool _isConnected = false;
  Map<String, dynamic>? _latestData;
  final String _broker = 'broker.hivemq.com';
  final String _topic = 'proyek/sepeda-01/full_status';

  late AnimationController _animationController;
  final MapController _mapController = MapController();
  late final ValueNotifier<LatLng> _positionNotifier;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _positionNotifier = ValueNotifier(const LatLng(-6.9175, 107.6191));
    _connectToMqtt();
  }

  void _connectToMqtt() async {
    final String clientId = 'flutter_client_${math.Random().nextInt(10000)}';
    client = MqttServerClient(_broker, clientId);
    client!.port = 1883;
    client!.logging(on: false);
    client!.keepAlivePeriod = 60;
    client!.autoReconnect = true;

    client!.onConnected = () {
      if (!mounted) return;
      setState(() {
        _isConnected = true;
      });
      print('MQTT Client terhubung.');
      client!.subscribe(_topic, MqttQos.atLeastOnce);
    };

    client!.onDisconnected = () {
      if (!mounted) return;
      setState(() {
        _isConnected = false;
      });
      print('MQTT Client terputus.');
    };

    client!.onSubscribed = (String topic) {
      print('Berhasil subscribe ke topic: $topic');
    };

    try {
      print('Mencoba terhubung ke broker MQTT...');
      await client!.connect();
    } catch (e) {
      print('Koneksi Gagal: $e');
      client!.disconnect();
    }

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      if (c != null && c.isNotEmpty) {
        final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;
        final String payload = MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );
        _handleMessage(payload);
      }
    });
  }

  void _handleMessage(String payload) {
    print('Pesan diterima: $payload');
    if (!mounted) return;
    try {
      final Map<String, dynamic> decodedData = json.decode(payload);
      setState(() {
        _latestData = decodedData;
      });
    } catch (e) {
      print('Gagal mem-parsing JSON: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController.dispose();
    _positionNotifier.dispose();
    client?.disconnect();
    super.dispose();
  }

  void _updateMapPosition(LatLng newPosition) {
    if (!mounted) return;
    if (newPosition.latitude == 0 && newPosition.longitude == 0) return;

    if (_positionNotifier.value.latitude != newPosition.latitude ||
        _positionNotifier.value.longitude != newPosition.longitude) {
      _positionNotifier.value = newPosition;
    }
    _mapController.move(newPosition, 18.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Realtime IoT Monitor'),
        backgroundColor: const Color(0xFF1E2A38),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFF1E2A38),
      body: !_isConnected || _latestData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.orangeAccent),
                  const SizedBox(height: 20),
                  Text(
                    !_isConnected
                        ? 'Menghubungkan ke broker: $_broker...'
                        : 'Menunggu data dari topic:\n"$_topic"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, height: 1.5),
                  ),
                ],
              ),
            )
          : _buildDashboard(_latestData!),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> data) {
    final accelerometer = Map<String, dynamic>.from(
      data['accelerometer'] as Map,
    );
    final gpsData = Map<String, dynamic>.from(data['gps'] as Map);
    final movingAverageData = Map<String, dynamic>.from(
      data['moving_average'] as Map,
    );

    final double x = double.tryParse(accelerometer['x'].toString()) ?? 0.0;
    final double y = double.tryParse(accelerometer['y'].toString()) ?? 0.0;
    final double z = double.tryParse(accelerometer['z'].toString()) ?? 0.0;

    final double latitude =
        double.tryParse(gpsData['latitude'].toString()) ??
        _positionNotifier.value.latitude;
    final double longitude =
        double.tryParse(gpsData['longitude'].toString()) ??
        _positionNotifier.value.longitude;
    final int satellites = int.tryParse(gpsData['satellites'].toString()) ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateMapPosition(LatLng(latitude, longitude));
    });

    final bool isAnomaly = movingAverageData['is_anomaly'] ?? false;
    final String dynamicThreshold =
        movingAverageData['dynamic_threshold']?.toStringAsFixed(2) ?? 'N/A';
    final String averageMagnitude =
        movingAverageData['average_magnitude']?.toStringAsFixed(2) ?? 'N/A';
    final String currentMagnitude =
        movingAverageData['current_magnitude']?.toStringAsFixed(2) ?? 'N/A';

    final String deviceId = data['device_id'] ?? 'N/A';
    final int timestamp =
        data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch;
    final String lastUpdate = DateFormat(
      'dd MMM yy, HH:mm:ss',
    ).format(DateTime.fromMillisecondsSinceEpoch(timestamp));

    if (isAnomaly) {
      if (!_animationController.isAnimating) {
        _animationController.repeat(reverse: true);
      }
    } else {
      if (_animationController.isAnimating) {
        _animationController.stop();
        _animationController.reset();
      }
    }

    final double tiltY = (x / 10).clamp(-1.0, 1.0) * (math.pi / 4);
    final double tiltX = -(y / 10).clamp(-1.0, 1.0) * (math.pi / 4);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStatusCard(isAnomaly, dynamicThreshold),
          const SizedBox(height: 30),
          _buildMapView(satellites),
          const SizedBox(height: 30),
          _buildMagnitudeSection(currentMagnitude, averageMagnitude),
          const SizedBox(height: 30),
          const Text(
            'Visualisasi Kemiringan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            width: 200,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final shakeOffset = isAnomaly
                    ? math.sin(_animationController.value * math.pi * 10) * 5
                    : 0.0;
                return Transform.translate(
                  offset: Offset(shakeOffset, 0),
                  child: child,
                );
              },
              child: Transform(
                alignment: FractionalOffset.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(tiltX)
                  ..rotateY(tiltY),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isAnomaly ? Colors.redAccent : Colors.transparent,
                      width: 4,
                    ),
                    gradient: const LinearGradient(
                      colors: [Colors.deepOrange, Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isAnomaly
                            ? Colors.red.withOpacity(0.7)
                            : Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.explore, color: Colors.white, size: 60),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDataCard('Sumbu X', x.toStringAsFixed(2), Colors.cyan),
              _buildDataCard(
                'Sumbu Y',
                y.toStringAsFixed(2),
                Colors.pinkAccent,
              ),
              _buildDataCard(
                'Sumbu Z',
                z.toStringAsFixed(2),
                Colors.lightGreenAccent,
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildDeviceInfoCard(deviceId, lastUpdate),
        ],
      ),
    );
  }

  Widget _buildMapView(int satellites) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi Real-time',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orangeAccent),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _positionNotifier.value,
                initialZoom: 16.0,
                maxZoom: 19.0,
              ),
              children: [
                // --- PERUBAHAN UTAMA DI SINI ---
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // Menggunakan NetworkTileProvider untuk menambahkan header
                  tileProvider: NetworkTileProvider(
                    headers: {
                      'User-Agent':
                          'com.example.app/1.0', // Ganti dengan nama paket aplikasi Anda
                    },
                  ),
                ),
                ValueListenableBuilder<LatLng>(
                  valueListenable: _positionNotifier,
                  builder: (context, position, child) {
                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: position,
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Satelit Terhubung: $satellites',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool isAnomaly, String thresholdValue) {
    final statusColor = isAnomaly ? Colors.red.shade400 : Colors.green.shade400;
    final statusText = isAnomaly ? 'BAHAYA' : 'AMAN';
    final statusIcon = isAnomaly
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;
    final message = isAnomaly
        ? 'Terdeteksi Anomali Getaran!'
        : 'Sistem Beroperasi Secara Normal';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              Text(
                statusText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white70)),
          const Divider(color: Colors.white24, height: 24),
          Text(
            'Ambang Batas Dinamis: $thresholdValue m/s²',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMagnitudeSection(String current, String average) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDataCard('Getaran Saat Ini', current, Colors.amberAccent),
          _buildDataCard('Rata-rata Getaran', average, Colors.lightBlueAccent),
        ],
      ),
    );
  }

  Widget _buildDataCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfoCard(String deviceId, String lastUpdate) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.developer_board, color: Colors.white70),
                const SizedBox(width: 12),
                const Text(
                  'Device ID:',
                  style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                Text(
                  deviceId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            Row(
              children: [
                const Icon(Icons.update, color: Colors.white70),
                const SizedBox(width: 12),
                const Text(
                  'Last Update:',
                  style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                Text(
                  lastUpdate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
