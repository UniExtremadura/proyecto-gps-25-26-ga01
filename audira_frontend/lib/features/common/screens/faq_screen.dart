import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports de tu proyecto
import '../../../core/models/faq.dart';
import '../../../core/api/services/faq_service.dart';
import '../../../config/theme.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final FaqService _faqService = FaqService();
  List<FAQ> _faqs = [];
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'ALL';

  final List<String> _categories = [
    'ALL',
    'ACCOUNT',
    'BILLING',
    'TECHNICAL',
    'ARTISTS',
    'CONTENT',
    'PRIVACY',
    'GENERAL',
  ];

  @override
  void initState() {
    super.initState();
    _loadFAQs();
  }

  Future<void> _loadFAQs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = _selectedCategory == 'ALL'
          ? await _faqService.getActiveFaqs()
          : await _faqService.getFaqsByCategory(_selectedCategory);

      if (response.success && response.data != null) {
        setState(() {
          _faqs = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Failed to load FAQs';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
    });
    _loadFAQs();
  }

  Future<void> _markFAQAsHelpful(int faqId) async {
    try {
      await _faqService.markAsHelpful(faqId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gracias por tu feedback!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _markFAQAsNotHelpful(int faqId) async {
    try {
      await _faqService.markAsNotHelpful(faqId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gracias por tu feedback!'),
              backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('Preguntas Frecuentes',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.backgroundBlack,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.primaryBlue))
                : _error != null
                    ? _buildErrorView()
                    : _faqs.isEmpty
                        ? _buildEmptyView()
                        : _buildFAQList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return ChoiceChip(
            label: Text(category),
            selected: isSelected,
            selectedColor: AppTheme.primaryBlue,
            backgroundColor: AppTheme.surfaceBlack,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (selected) {
              if (selected) _onCategorySelected(category);
            },
            side: BorderSide(
                color: isSelected ? AppTheme.primaryBlue : Colors.transparent),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  Widget _buildFAQList() {
    return RefreshIndicator(
      onRefresh: _loadFAQs,
      color: AppTheme.primaryBlue,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length + 1, // +1 para el footer de contacto
        itemBuilder: (context, index) {
          if (index == _faqs.length) {
            return _buildContactSection().animate().fadeIn(delay: 300.ms);
          }
          final faq = _faqs[index];
          return _buildFAQItem(faq, index);
        },
      ),
    );
  }

  Widget _buildFAQItem(FAQ faq, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        iconColor: AppTheme.primaryBlue,
        collapsedIconColor: Colors.grey,
        title: Text(
          faq.question,
          style:
              const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            faq.category,
            style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue),
          ),
        ),
        onExpansionChanged: (expanded) {
          if (expanded) {
            _faqService.incrementViewCount(faq.id);
          }
        },
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                Text(
                  faq.answer,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('¿Fue útil?',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    _buildFeedbackButton(Icons.thumb_up_alt_outlined,
                        '${faq.helpfulCount}', () => _markFAQAsHelpful(faq.id)),
                    const SizedBox(width: 16),
                    _buildFeedbackButton(
                        Icons.thumb_down_alt_outlined,
                        '${faq.notHelpfulCount}',
                        () => _markFAQAsNotHelpful(faq.id)),
                  ],
                ),
                if (faq.viewCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Visto ${faq.viewCount} veces',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _buildFeedbackButton(IconData icon, String count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(count,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.only(top: 20, bottom: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.1),
            Colors.transparent
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.support_agent_rounded,
              size: 48, color: AppTheme.primaryBlue),
          const SizedBox(height: 16),
          const Text(
            '¿No encuentras tu respuesta?',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nuestro equipo de soporte está listo para ayudarte.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/contact'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text('Contactar Soporte'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 64, color: AppTheme.errorRed),
          const SizedBox(height: 16),
          Text(_error ?? 'Error cargando FAQs',
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFAQs,
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child:
                const Text('Reintentar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No se encontraron preguntas',
              style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadFAQs,
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue),
            child:
                const Text('Recargar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
