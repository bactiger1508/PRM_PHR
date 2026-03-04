import 'package:flutter/material.dart';

class DocumentTrashScreen extends StatefulWidget {
  const DocumentTrashScreen({super.key});

  @override
  State<DocumentTrashScreen> createState() => _DocumentTrashScreenState();
}

class _DocumentTrashScreenState extends State<DocumentTrashScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DocumentTrashScreen')),
      body: const Center(child: Text('Placeholder for DocumentTrashScreen UI')),
    );
  }
}
