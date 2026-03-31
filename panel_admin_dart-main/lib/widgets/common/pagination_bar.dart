import 'package:flutter/material.dart';

/// Barra de paginación reutilizable con botones anterior/siguiente.
///
/// Ejemplo:
/// ```dart
/// PaginationBar(
///   currentPage: _currentPage,
///   totalPages: _totalPages,
///   onPrevious: () => _loadPage(_currentPage - 1),
///   onNext: () => _loadPage(_currentPage + 1),
/// )
/// ```
class PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final canGoBack = currentPage > 1;
    final canGoNext = currentPage < totalPages;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Página anterior',
            onPressed: canGoBack ? onPrevious : null,
            color: canGoBack ? theme.colorScheme.primary : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            'Página $currentPage de $totalPages',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Página siguiente',
            onPressed: canGoNext ? onNext : null,
            color: canGoNext ? theme.colorScheme.primary : Colors.grey,
          ),
        ],
      ),
    );
  }
}
