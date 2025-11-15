// chart_page.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart'; // ✅ Tambahkan ini untuk DateFormat
import '../services/fetchsensor_jam.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  late Future<List<Map<String, dynamic>>> _sensorDataFuture;

  @override
  void initState() {
    super.initState();
    _sensorDataFuture = sensor_jamService
        .fetchSensorJam(); // ✅ Langsung panggil service
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histori Sensor Hari Ini')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _sensorDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final dataList = snapshot.data ?? [];

          if (dataList.isEmpty) {
            return const Center(child: Text('Tidak ada data sensor.'));
          }

          // Konversi data ke format grafik
          final seriesData = dataList.map((item) {
            // Parse timestamp dari string ke DateTime
            DateTime? time;
            final ts = item['timestamp'];
            if (ts is String) {
              time = DateTime.tryParse(ts);
            } else if (ts is DateTime) {
              time = ts;
            }

            final temp = (item['temp'] as num?)?.toDouble() ?? 0.0;
            final humidity = (item['humidity'] as num?)?.toDouble() ?? 0.0;
            return ChartData(time ?? DateTime.now(), temp, humidity);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Grafik Suhu
                Expanded(
                  child: SfCartesianChart(
                    title: ChartTitle(text: 'Temperatur Tiap Jam'),
                    primaryXAxis: DateTimeAxis(
                      title: AxisTitle(text: 'Waktu (HH:mm)'),
                      dateFormat:
                          DateFormat.Hm(), // tampilkan jam:menit untuk data hari ini
                    ),
                    primaryYAxis: NumericAxis(
                      title: AxisTitle(text: 'Temperatur (°C)'),
                    ),
                    series: <CartesianSeries<ChartData, DateTime>>[
                      // ✅ Tipe eksplisit
                      LineSeries<ChartData, DateTime>(
                        dataSource: seriesData,
                        xValueMapper: (ChartData data, _) => data.time,
                        yValueMapper: (ChartData data, _) => data.temperature,
                        name: 'Temperatur',
                        color: Colors.blue,
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Grafik Kelembapan
                Expanded(
                  child: SfCartesianChart(
                    title: ChartTitle(text: 'Kelembapan Tiap Jam'),
                    primaryXAxis: DateTimeAxis(
                      title: AxisTitle(text: 'Waktu (HH:mm)'),
                      dateFormat: DateFormat.Hm(),
                    ),
                    primaryYAxis: NumericAxis(
                      title: AxisTitle(text: 'Kelembapan (%)'),
                    ),
                    series: <CartesianSeries<ChartData, DateTime>>[
                      // ✅
                      LineSeries<ChartData, DateTime>(
                        dataSource: seriesData,
                        xValueMapper: (ChartData data, _) => data.time,
                        yValueMapper: (ChartData data, _) => data.humidity,
                        name: 'Kelembapan',
                        color: Colors.green,
                        markerSettings: const MarkerSettings(isVisible: true),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ChartData {
  ChartData(this.time, this.temperature, this.humidity);

  final DateTime time;
  final double temperature;
  final double humidity;
}
