import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage>
    with SingleTickerProviderStateMixin {
  // Mengarahkan ke path database yang benar sesuai gambar Anda
  final DatabaseReference _sensorParentRef = FirebaseDatabase.instance.ref(
    'data_iot_terintegrasi',
  );

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
    _positionNotifier = ValueNotifier(const LatLng(-6.954183, 107.610557));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _mapController.dispose();
    _positionNotifier.dispose();
    super.dispose();
  }

  void _updateMapPosition(LatLng newPosition) {
    if (!mounted) return;

    if (_positionNotifier.value.latitude != newPosition.latitude ||
        _positionNotifier.value.longitude != newPosition.longitude) {
      _positionNotifier.value = newPosition;
    }

    // Menggerakkan kamera peta
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
      body: StreamBuilder(
        stream: _sensorParentRef.orderByKey().limitToLast(1).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.snapshot.value == null) {
            return const Center(
              child: Text(
                'Menunggu data dari sensor...\nPastikan perangkat IoT menyala.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final Map<String, dynamic> latestEntry = Map<String, dynamic>.from(
            snapshot.data!.snapshot.value as Map,
          );
          final data = Map<String, dynamic>.from(
            latestEntry.values.first as Map,
          );

          // Parsing data yang lebih lengkap
          final accelerometer = Map<String, dynamic>.from(
            data['accelerometer'] as Map,
          );
          final gpsData = Map<String, dynamic>.from(data['gps'] as Map);
          final movingAverageData = Map<String, dynamic>.from(
            data['moving_average'] as Map,
          );

          final double x =
              double.tryParse(accelerometer['x'].toString()) ?? 0.0;
          final double y =
              double.tryParse(accelerometer['y'].toString()) ?? 0.0;
          final double z =
              double.tryParse(accelerometer['z'].toString()) ?? 0.0;

          final double latitude =
              double.tryParse(gpsData['latitude'].toString()) ??
              _positionNotifier.value.latitude;
          final double longitude =
              double.tryParse(gpsData['longitude'].toString()) ??
              _positionNotifier.value.longitude;
          final int satellites =
              int.tryParse(gpsData['satellites'].toString()) ?? 0;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateMapPosition(LatLng(latitude, longitude));
          });

          // --- PERBAIKAN UTAMA: Ambil 'is_anomaly' dari 'movingAverageData' ---
          final bool isAnomaly = movingAverageData['is_anomaly'] ?? false;
          final String dynamicThreshold =
              movingAverageData['dynamic_threshold']?.toString() ?? 'N/A';
          final String averageMagnitude =
              movingAverageData['average_magnitude']?.toString() ?? 'N/A';
          final String currentMagnitude =
              movingAverageData['current_magnitude']?.toString() ?? 'N/A';

          final String deviceId = data['device_id'] ?? 'N/A';
          final int timestamp = data['timestamp'] ?? 0;
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
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  width: 200,
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final shakeOffset = isAnomaly
                          ? math.sin(
                                  _animationController.value * math.pi * 10,
                                ) *
                                5
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
                            color: isAnomaly
                                ? Colors.redAccent
                                : Colors.transparent,
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
                          child: Icon(
                            Icons.explore,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDataCard(
                      'Sumbu X',
                      x.toStringAsFixed(2),
                      Colors.cyan,
                    ),
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
        },
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
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.book_app',
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
