import 'dart:math' as math;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage>
    with SingleTickerProviderStateMixin {
  final DatabaseReference _sensorParentRef = FirebaseDatabase.instance.ref(
    'data_iot_esp32',
  );

  // AnimationController untuk efek getaran
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // PERBAIKAN: Hapus listener yang memanggil setState()
    // Kita akan gunakan AnimatedBuilder yang lebih efisien.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    // ..addListener(() {
    //   setState(() {});
    // }); // <-- INI PENYEBAB LOOP, KITA HAPUS
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text('Realtime IoT Monitor'),
        backgroundColor: const Color(0xFF1E2A38),
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
          final accelerometer = Map<String, dynamic>.from(
            data['accelerometer'] as Map,
          );

          final bool isThresholdExceeded = data['threshold_exceeded'] ?? false;
          final String thresholdValue =
              data['threshold_value_mps2']?.toString() ?? 'N/A';

          final double x =
              double.tryParse(accelerometer['x'].toString()) ?? 0.0;
          final double y =
              double.tryParse(accelerometer['y'].toString()) ?? 0.0;
          final double z =
              double.tryParse(accelerometer['z'].toString()) ?? 0.0;
          final String deviceId = data['device_id'] ?? 'N/A';
          final int timestamp = data['timestamp'] ?? 0;
          final String lastUpdate = DateFormat(
            'dd MMM yy, HH:mm:ss',
          ).format(DateTime.fromMillisecondsSinceEpoch(timestamp));

          // PERBAIKAN: Logika untuk memulai dan menghentikan animasi
          if (isThresholdExceeded) {
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
                _buildStatusCard(isThresholdExceeded, thresholdValue),
                const SizedBox(height: 30),

                const Text(
                  'Visualisasi Kemiringan',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  width: 200,
                  // PERBAIKAN: Gunakan AnimatedBuilder untuk animasi yang efisien
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      // Efek getaran hanya terjadi saat animasi berjalan
                      final shakeOffset = isThresholdExceeded
                          ? math.sin(
                                  _animationController.value * math.pi * 10,
                                ) *
                                5
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(shakeOffset, 0),
                        child:
                            child, // 'child' adalah widget Transform di bawah
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
                            color: isThresholdExceeded
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
                              color: isThresholdExceeded
                                  ? Colors.red.withOpacity(0.7)
                                  : Colors.black.withOpacity(0.5),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.screen_rotation_alt,
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
                const SizedBox(height: 24),

                const Text(
                  'Indikator Gravitasi (Z)',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (z / 12).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade700,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.lightGreenAccent,
                  ),
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

  Widget _buildStatusCard(bool isExceeded, String thresholdValue) {
    //... (Tidak ada perubahan di widget ini)
    final statusColor = isExceeded
        ? Colors.red.shade400
        : Colors.green.shade400;
    final statusText = isExceeded ? 'BAHAYA' : 'AMAN';
    final statusIcon = isExceeded
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline_rounded;
    final message = isExceeded
        ? 'Getaran Melebihi Batas Normal!'
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
            'Ambang Batas Getaran: $thresholdValue m/s²',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(String title, String value, Color color) {
    //... (Tidak ada perubahan di widget ini)
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceInfoCard(String deviceId, String lastUpdate) {
    //... (Tidak ada perubahan di widget ini)
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
