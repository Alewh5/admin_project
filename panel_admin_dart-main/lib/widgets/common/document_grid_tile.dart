import 'package:flutter/material.dart';
import '../../models/project_document_model.dart';

class DocumentGridTile extends StatelessWidget {
  final ProjectDocumentModel document;

  const DocumentGridTile({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 48,
            color: Theme.of(context).iconTheme.color,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              document.nombre,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
