import 'package:flutter/material.dart';

class DeleteDocumentDialog extends StatefulWidget {
  const DeleteDocumentDialog({super.key});

  @override
  State<DeleteDocumentDialog> createState() => _DeleteDocumentDialogState();
}

class _DeleteDocumentDialogState extends State<DeleteDocumentDialog> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DeleteDocumentDialog')),
      body: const Center(
        child: Text('Placeholder for DeleteDocumentDialog UI'),
      ),
    );
  }
}
