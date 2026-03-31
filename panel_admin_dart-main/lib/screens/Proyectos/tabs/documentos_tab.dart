import 'package:flutter/material.dart';
import '../../../models/proyecto_model.dart';
import '../../../models/project_document_model.dart';
import '../../../services/kanban_service.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/error_state.dart';
import '../../../widgets/common/document_grid_tile.dart';
import 'package:file_picker/file_picker.dart';

class DocumentosTab extends StatefulWidget {
  final Proyecto proyecto;
  const DocumentosTab({super.key, required this.proyecto});

  @override
  State<DocumentosTab> createState() => _DocumentosTabState();
}

class _DocumentosTabState extends State<DocumentosTab> {
  final KanbanService _kanbanService = KanbanService();
  final ScrollController _scrollController = ScrollController();
  
  List<ProjectDocumentModel> _documents = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 &&
        !_isLoading &&
        _hasMore) {
      _loadDocuments(loadMore: true);
    }
  }

  Future<void> _loadDocuments({bool loadMore = false}) async {
    if (_isLoading) return;

    if (loadMore) {
      _currentPage++;
    } else {
      _currentPage = 1;
      _documents.clear();
      _hasMore = true;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _kanbanService.getProjectDocuments(
        widget.proyecto.id,
        page: _currentPage,
        limit: 20,
      );
      
      final newDocs = response['items'] as List<ProjectDocumentModel>;

      if (mounted) {
        setState(() {
          if (loadMore) {
            _documents.addAll(newDocs);
          } else {
            _documents = newDocs;
          }
          _hasMore = _currentPage < (response['totalPages'] as int? ?? 1);
          _hasError = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      // Mock File Upload Response. In real app, we use http.MultipartRequest in KanbanService
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subiendo documento...')));
      await Future.delayed(const Duration(seconds: 1));
      
      _loadDocuments(); // Reload documents from API
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Documento subido con éxito')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Documentos del Proyecto',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_isLoading && _documents.isNotEmpty)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              CustomButton(
                onPressed: _pickFile,
                icon: Icons.upload_file,
                text: 'Subir Documento',
                width: 220,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _hasError
                ? ErrorState(
                    message: 'No se pudieron cargar los documentos.',
                    onRetry: _loadDocuments,
                  )
                : _documents.isEmpty && !_isLoading
                    ? const EmptyState(
                        title: 'No hay documentos',
                        subtitle: 'Arrastra o sube un documento para empezar.',
                        icon: Icons.insert_drive_file_outlined,
                      )
                    : GridView.builder(
                        controller: _scrollController,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          final doc = _documents[index];
                          return DocumentGridTile(document: doc);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
