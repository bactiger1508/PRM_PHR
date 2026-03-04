import 'package:flutter/material.dart';

class CreatePatientProfileScreen extends StatefulWidget {
  const CreatePatientProfileScreen({super.key});

  @override
  State<CreatePatientProfileScreen> createState() =>
      _CreatePatientProfileScreenState();
}

class _CreatePatientProfileScreenState
    extends State<CreatePatientProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CreatePatientProfileScreen')),
      body: const Center(
        child: Text('Placeholder for CreatePatientProfileScreen UI'),
      ),
    );
  }
}
