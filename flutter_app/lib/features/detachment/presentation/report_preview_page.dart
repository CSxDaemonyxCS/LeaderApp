import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/strings.dart';
import '../data/report_builder.dart';
import '../domain/report_models.dart';
import 'report_export_page.dart';

/// The report as it will be exported.
///
/// Rendered on a single page-shaped surface rather than as another app
/// screen: the point of a preview is to answer "is this what I am about to
/// send", and that question is not answered by a differently-styled list.
class ReportPreviewPage extends ConsumerWidget {
  const ReportPreviewPage({
    super.key,
    required this.detachmentId,
    required this.spec,
  });

  final String detachmentId;
  final ReportSpec spec;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        title: const Text(S.exportPreview),
        actions: [
          IconButton(
            tooltip: S.exportCopy,
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: () => _copy(context, ref),
          ),
        ],
      ),
      body: ReportView(
        detachmentId: detachmentId,
        spec: spec,
        builder: (context, doc) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.line),
                borderRadius: BorderRadius.circular(AppRadii.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReportHeader(doc: doc),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(color: c.line, height: 1),
                  const SizedBox(height: AppSpacing.lg),
                  if (doc.isEmpty)
                    Text(S.exportNothingSelected,
                        style: TextStyle(color: c.ink3, fontSize: 13))
                  else
                    for (int i = 0; i < doc.blocks.length; i++) ...[
                      ReportBlockView(block: doc.blocks[i]),
                      if (i != doc.blocks.length - 1) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Divider(color: c.line, height: 1),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => _copy(context, ref),
              icon: const Icon(Icons.copy_all_rounded, size: 19),
              label: Text('${S.exportCopy} · ${spec.format.label}'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(
      reportProvider(ReportQuery(detachmentId: detachmentId, spec: spec))
          .future,
    );
    if (!context.mounted) return;
    result.when(
      success: (doc, {stale = false}) async {
        await Clipboard.setData(ClipboardData(
          text: spec.format == ReportFormat.excel
              ? doc.toCsv()
              : doc.toPlainText(),
        ));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text(S.exportCopied)));
      },
      failure: (message, _) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message))),
      offline: (_) => ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(S.offlineTitle))),
    );
  }
}
