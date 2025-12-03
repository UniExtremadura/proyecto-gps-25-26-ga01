import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/collaborator.dart';
import '../../../core/api/services/collaboration_service.dart';

class RevenueSettingsDialog extends StatefulWidget {
  final Collaborator collaboration;

  const RevenueSettingsDialog({
    super.key,
    required this.collaboration,
  });

  @override
  State<RevenueSettingsDialog> createState() => _RevenueSettingsDialogState();
}

class _RevenueSettingsDialogState extends State<RevenueSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _percentageController = TextEditingController();
  final CollaborationService _collaborationService = CollaborationService();

  // --- Colores ---
  final Color darkCardBg = const Color(0xFF212121);
  final Color moneyColor = Colors.greenAccent;
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  bool _isLoading = false;
  double?
      _currentTotalRevenue; // % total asignado actualmente (incluyendo este collab)

  @override
  void initState() {
    super.initState();
    _percentageController.text =
        widget.collaboration.revenuePercentage.toStringAsFixed(1);
    _loadTotalRevenue();
  }

  @override
  void dispose() {
    _percentageController.dispose();
    super.dispose();
  }

  Future<void> _loadTotalRevenue() async {
    try {
      final response = widget.collaboration.isForSong
          ? await _collaborationService
              .getSongTotalRevenue(widget.collaboration.songId!)
          : await _collaborationService
              .getAlbumTotalRevenue(widget.collaboration.albumId!);

      if (response.success && response.data != null) {
        setState(() => _currentTotalRevenue = response.data);
      }
    } catch (_) {
    } finally {}
  }

  Future<void> _updateRevenue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final percentage = double.parse(_percentageController.text);
      final response = await _collaborationService.updateRevenuePercentage(
        collaborationId: widget.collaboration.id,
        percentage: percentage,
      );

      if (response.success) {
        if (!mounted) return;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Revenue updated'), backgroundColor: Colors.green));
      } else {
        throw Exception(response.error ?? 'Unknown error');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcular cuánto queda disponible para ASIGNAR AHORA.
    // Lógica: 100 - (Total actual - Lo que tiene este usuario actualmente) = Máximo teórico para este usuario
    final double currentAssignedToOthers =
        (_currentTotalRevenue ?? 0) - widget.collaboration.revenuePercentage;
    final double maxAssignable = 100.0 - currentAssignedToOthers;

    return Dialog(
      backgroundColor: darkCardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: moneyColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.attach_money, color: moneyColor),
                  ),
                  const SizedBox(width: 12),
                  Text('Revenue Share',
                      style: TextStyle(
                          color: lightText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),

              // Distribution Bar
              if (_currentTotalRevenue != null) ...[
                Text('Current Distribution',
                    style: TextStyle(
                        color: subText,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        // Parte de otros
                        Expanded(
                            flex: (currentAssignedToOthers * 10).toInt(),
                            child: Container(color: Colors.blueGrey)),
                        // Parte actual de este usuario
                        Expanded(
                            flex: (widget.collaboration.revenuePercentage * 10)
                                .toInt(),
                            child: Container(color: moneyColor)),
                        // Parte disponible (Libre)
                        Expanded(
                            flex: ((100 - _currentTotalRevenue!) * 10).toInt(),
                            child: Container(color: Colors.grey[800])),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Used: ${currentAssignedToOthers.toStringAsFixed(1)}%',
                        style: TextStyle(color: subText, fontSize: 10)),
                    Text('Max for user: ${maxAssignable.toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: moneyColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Input
              Text('Percentage Share',
                  style: TextStyle(
                      color: subText,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _percentageController,
                style: TextStyle(
                    color: lightText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                decoration: InputDecoration(
                  suffixText: '%',
                  suffixStyle: TextStyle(
                      color: moneyColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: moneyColor)),
                ),
                validator: (val) {
                  final n = double.tryParse(val ?? '');
                  if (n == null) return 'Invalid number';
                  if (n < 0) return 'Cannot be negative';
                  if (n > maxAssignable) {
                    return 'Max allowed: ${maxAssignable.toStringAsFixed(1)}%';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Quick Buttons
              Wrap(
                spacing: 8,
                children: [10, 20, 25, 50].map((p) {
                  final isPossible = p <= maxAssignable;
                  return ActionChip(
                    label: Text('$p%',
                        style: TextStyle(
                            fontSize: 12,
                            color: isPossible ? lightText : Colors.grey)),
                    backgroundColor: Colors.transparent,
                    side: BorderSide(
                        color:
                            isPossible ? Colors.grey[700]! : Colors.grey[900]!),
                    onPressed: isPossible
                        ? () => _percentageController.text = p.toString()
                        : null,
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _updateRevenue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: moneyColor,
                      foregroundColor: Colors
                          .black, // Texto negro sobre verde brillante para contraste
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Text('Save Changes'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
