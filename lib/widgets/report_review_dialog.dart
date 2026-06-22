import 'package:flutter/material.dart';

class ReportReviewDialog extends StatefulWidget {
  const ReportReviewDialog({
    super.key,
    required this.reviewId,
    required this.onSubmit,
  });

  final String reviewId;
  final Future<void> Function(String reportType, String reason) onSubmit;

  @override
  State<ReportReviewDialog> createState() => _ReportReviewDialogState();
}

class _ReportReviewDialogState extends State<ReportReviewDialog> {
  String _selectedType = 'spam';
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  final _reportTypes = const [
    {'value': 'spam', 'label': 'Spam'},
    {'value': 'false_review', 'label': 'Faux avis'},
    {'value': 'offensive', 'label': 'Contenu offensant'},
    {'value': 'incorrect_info', 'label': 'Informations incorrectes'},
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez fournir une raison pour ce signalement.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(_selectedType, _reasonController.text.trim());
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre signalement a été envoyé avec succès.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'envoi du signalement. Êtes-vous connecté ?')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Signaler cet avis'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pourquoi signalez-vous cet avis ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ..._reportTypes.map((type) {
              return RadioListTile<String>(
                title: Text(type['label']!),
                value: type['value']!,
                groupValue: _selectedType,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (obligatoire)',
                hintText: 'Expliquez en détail...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Signaler'),
        ),
      ],
    );
  }
}
