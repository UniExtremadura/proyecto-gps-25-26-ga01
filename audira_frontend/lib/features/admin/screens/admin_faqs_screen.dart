import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/models/faq.dart';
import '../../../core/api/services/faq_service.dart';

class AdminFaqsScreen extends StatefulWidget {
  const AdminFaqsScreen({super.key});

  @override
  State<AdminFaqsScreen> createState() => _AdminFaqsScreenState();
}

class _AdminFaqsScreenState extends State<AdminFaqsScreen> {
  final FaqService _faqService = FaqService();

  List<FAQ> _faqs = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFaqs();
  }

  Future<void> _loadFaqs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _faqService.getAllFaqs();
      if (response.success && response.data != null) {
        setState(() => _faqs = response.data!);
      } else {
        setState(() => _error = response.error ?? 'Fallo al cargar las FAQs');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFaq(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar FAQs'),
        content: const Text('¿Estás seguro de que quieres eliminar esta FAQ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final currentContext = context;
      try {
        final response = await _faqService.deleteFaq(id);
        if (!currentContext.mounted) return;
        if (response.success) {
          if (!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            const SnackBar(content: Text('FAQ borrada correctamente')),
          );
          _loadFaqs();
        } else {
          if (!currentContext.mounted) return;
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Fallo al borrar la FAQ')),
          );
        }
      } catch (e) {
        if (!currentContext.mounted) return;
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar FAQs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showFaqForm(null),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(_error!),
                      ElevatedButton(
                        onPressed: _loadFaqs,
                        child: const Text('Volver a intentar'),
                      ),
                    ],
                  ),
                )
              : _faqs.isEmpty
                  ? const Center(child: Text('No se encontraron FAQs'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _faqs.length,
                      itemBuilder: (context, index) {
                        final faq = _faqs[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primaryBlue,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(
                              faq.question,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Categoría: ${faq.category}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Vistas: ${faq.viewCount}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton(
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Borrar'),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      _showFaqForm(faq);
                                    } else if (value == 'delete') {
                                      _deleteFaq(faq.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Respuesta:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(faq.answer),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (index * 50).ms);
                      },
                    ),
    );
  }

  void _showFaqForm(FAQ? faq) {
    final currentContext = context;
    final isEditing = faq != null;
    final questionController = TextEditingController(text: faq?.question ?? '');
    final answerController = TextEditingController(text: faq?.answer ?? '');
    final categoryController = TextEditingController(text: faq?.category ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar FAQ' : 'Añadir nueva FAQ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionController,
                decoration: const InputDecoration(
                  labelText: 'Pregunta',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: answerController,
                decoration: const InputDecoration(
                  labelText: 'Respuesta',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final question = questionController.text.trim();
              final answer = answerController.text.trim();
              final category = categoryController.text.trim();

              if (question.isEmpty || answer.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Pregunta y respuesta necesarias')),
                );
                return;
              }

              Navigator.pop(context);

              try {
                if (isEditing) {
                  await _faqService.updateFaq(
                    id: faq.id,
                    question: question,
                    answer: answer,
                    category: category,
                  );
                } else {
                  await _faqService.createFaq(
                    question: question,
                    answer: answer,
                    category: category,
                  );
                }
                if (!currentContext.mounted) return;
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEditing
                          ? 'FAQ actualizada correctamente'
                          : 'FAQ creada correctamente',
                    ),
                  ),
                );
                _loadFaqs();
              } catch (e) {
                if (!currentContext.mounted) return;
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }
}
