import 'package:flutter/material.dart';

class MedicalDocumentListScreen extends StatefulWidget {
  const MedicalDocumentListScreen({super.key});

  @override
  State<MedicalDocumentListScreen> createState() =>
      _MedicalDocumentListScreenState();
}

class _MedicalDocumentListScreenState extends State<MedicalDocumentListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MedicalDocumentListScreen')),
      body: const Center(
        child: Text('Placeholder for MedicalDocumentListScreen UI'),
      ),
    );
  }
}
