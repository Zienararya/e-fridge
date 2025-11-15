import 'package:efridge/component/header.dart';
import 'package:efridge/component/temperature_dial.dart';
import 'package:flutter/material.dart';
import '../services/fetchdevice.dart';
import '../services/fetch_score.dart';
import 'chart_page.dart';

class Mainpage extends StatefulWidget {
  const Mainpage({super.key});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  late Stream<List<Map<String, dynamic>>> _deviceStream;
  // Menyimpan logid terakhir dan waktu terakhir logid berubah
  int? _lastLogId;
  DateTime? _lastLogIdChange;
  // Menyimpan hasil kategori skor dari API
  String? _scoreCategory;
  DateTime? _lastScoreFetch;
  static const Duration _scoreRefreshTtl = Duration(minutes: 2);
  // Prediksi berikutnya (suhu & kelembapan)
  double? _predictedTemp;
  double? _predictedHumidity;
  DateTime? _lastPredictFetch;

  @override
  void initState() {
    super.initState();
    _deviceStream = Fetchdevice.watchDevices(
      interval: const Duration(seconds: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _deviceStream,
          builder: (context, snapshot) {
            double temperature = 0.0; // fallback default
            String doorStatus = 'Tertutup';
            String humidityDisplay = '—%'; // default jika tidak ada data
            String electricityStatus = 'Aktif'; // default aktif
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final device = snapshot.data![0];

              // Ambil suhu
              final tempValue = device['temp'];
              if (tempValue is num) {
                temperature = tempValue.toDouble();
              }

              // Ambil status pintu
              final doorValue = device['door_sensor'];
              if (doorValue is int) {
                doorStatus = doorValue == 1 ? 'Terbuka' : 'Tertutup';
              }

              // Ambil kelembapan (humidity)
              final humidityValue = device['humidity'];
              if (humidityValue is num) {
                humidityDisplay = '${humidityValue.toStringAsFixed(1)}%';
              }

              // Pantau perubahan logid dari perangkat
              final logIdValue = device['logid'];
              if (logIdValue is num) {
                final currentLogId = logIdValue.toInt();
                if (_lastLogId == null || currentLogId != _lastLogId) {
                  _lastLogId = currentLogId;
                  _lastLogIdChange = DateTime.now();
                }
              }

              // Ambil kategori skor dari API (throttle agar tidak terlalu sering)
              final deviceId = device['id'];
              if (deviceId is int) {
                final now = DateTime.now();
                final shouldFetch =
                    _lastScoreFetch == null ||
                    now.difference(_lastScoreFetch!) > _scoreRefreshTtl ||
                    _scoreCategory == null;
                if (shouldFetch) {
                  ScoreService.fetchKategori(deviceId: deviceId).then((cat) {
                    if (!mounted) return;
                    setState(() {
                      _scoreCategory = cat ?? 'Tidak tersedia';
                      _lastScoreFetch = DateTime.now();
                    });
                  });
                }

                // Ambil prediksi suhu & kelembapan berikutnya (/predict)
                final shouldFetchPredict =
                    _lastPredictFetch == null ||
                    now.difference(_lastPredictFetch!) > _scoreRefreshTtl ||
                    _predictedTemp == null ||
                    _predictedHumidity == null;
                if (shouldFetchPredict) {
                  ScoreService.fetchPrediksiNext(
                    deviceId: deviceId,
                    steps: 1,
                  ).then((result) {
                    if (!mounted || result == null) return;
                    setState(() {
                      _predictedTemp = result['suhu'];
                      _predictedHumidity = result['kelembapan'];
                      _lastPredictFetch = DateTime.now();
                    });
                  });
                }
              }
            }

            // Jika logid tidak berubah selama 5 menit, anggap listrik mati
            final lastChange = _lastLogIdChange;
            if (lastChange != null) {
              final inactivity = DateTime.now().difference(lastChange);
              electricityStatus = inactivity >= const Duration(seconds: 30)
                  ? 'Mati'
                  : 'Nyala';
            } else {
              // Belum ada data logid sama sekali
              electricityStatus = 'Mati';
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'Halo Pengguna, Pintunya sedang',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$doorStatus',
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Temperature dial
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChartPage(),
                          ),
                        );
                      },
                      child: TemperatureDial(
                        temperature: temperature,
                        mode: humidityDisplay,
                        // Skala 0°C (sangat dingin) sampai 100°C (sangat panas)
                        minTemp: -100,
                        maxTemp: 100,
                        size: 240,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ketuk untuk menampilkan grafik',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 32),
                  // Cards grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.25,
                    children: [
                      _ControlCard(
                        icon: Icons.ac_unit,
                        label: 'Kelembapan',
                        value: humidityDisplay,
                      ),
                      _ControlCard(
                        icon: Icons.thermostat,
                        label: 'Suhu',
                        value: temperature.toStringAsFixed(1) + '°C',
                      ),
                      _ControlCard(
                        icon: Icons.electric_bolt,
                        label: 'Listrik',
                        value: electricityStatus,
                      ),
                      _ControlCard(
                        icon: Icons.check_circle,
                        label: 'Status',
                        value: _scoreCategory ?? '—',
                      ),
                      _ControlCard(
                        icon: Icons.trending_up,
                        label: 'Prediksi Suhu',
                        value: _predictedTemp != null
                            ? '${_predictedTemp!.toStringAsFixed(2)}°C'
                            : '—',
                      ),
                      _ControlCard(
                        icon: Icons.water_drop,
                        label: 'Prediksi Kelembapan',
                        value: _predictedHumidity != null
                            ? '${_predictedHumidity!.toStringAsFixed(2)}%'
                            : '—',
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  const _ControlCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black54, size: 20),
          const Spacer(),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 12,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
