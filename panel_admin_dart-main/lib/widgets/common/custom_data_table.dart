import 'package:flutter/material.dart';
import 'empty_state.dart';

class CustomDataTable extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool isLoading;
  final bool isEmpty;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final ScrollController? scrollController;

  const CustomDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.isEmpty = false,
    this.emptyTitle = 'No hay datos',
    this.emptySubtitle = 'No se encontraron registros.',
    this.emptyIcon = Icons.inbox_outlined,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isEmpty && !isLoading) {
      return EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: emptyIcon,
      );
    }

    if (isLoading && isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.2)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.resolveWith(
                              (states) => theme
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.5),
                            ),
                            headingTextStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            dataRowMaxHeight: 70,
                            columns: columns,
                            rows: rows,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (isLoading && !isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
