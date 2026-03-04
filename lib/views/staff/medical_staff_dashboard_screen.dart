import 'package:flutter/material.dart';

class MedicalStaffDashboardScreen extends StatefulWidget {
  const MedicalStaffDashboardScreen({super.key});

  @override
  State<MedicalStaffDashboardScreen> createState() =>
      _MedicalStaffDashboardScreenState();
}

class _MedicalStaffDashboardScreenState
    extends State<MedicalStaffDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MedicalStaffDashboardScreen')),
      body: const Center(
        child: Text('Placeholder for MedicalStaffDashboardScreen UI'),
      ),
    );
  }
}
