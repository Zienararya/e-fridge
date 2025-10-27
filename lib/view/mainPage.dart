import 'package:efridge/component/Header.dart';
import 'package:efridge/component/temperature_dial.dart';
import 'package:flutter/material.dart';

class Mainpage extends StatefulWidget {
  const Mainpage({super.key});

  @override
  State<Mainpage> createState() => _MainpageState();
}

class _MainpageState extends State<Mainpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Kitchen',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Fridge',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 20),
              // Temperature dial
              const Center(
                child: TemperatureDial(
                  temperature: 23.5,
                  mode: 'Cold',
                  minTemp: 12,
                  maxTemp: 28,
                  size: 240,
                ),
              ),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('12°', style: TextStyle(fontSize: 13)),
                    Text('28°', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              // Cards grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.25,
                children: const [
                  _ControlCard(
                    icon: Icons.ac_unit,
                    label: 'Mode',
                    value: 'Cold',
                  ),
                  _ControlCard(
                    icon: Icons.door_front_door,
                    label: 'Door',
                    value: 'Closed',
                  ),
                  _ControlCard(
                    icon: Icons.electric_bolt,
                    label: 'Electricity',
                    value: 'Active',
                  ),
                  _ControlCard(
                    icon: Icons.percent,
                    label: 'Score',
                    value: '100%',
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
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
