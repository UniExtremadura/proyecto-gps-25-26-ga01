import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/receipt.dart';
import '../../../core/api/services/receipt_service.dart';
import '../../common/widgets/loading_indicator.dart';

class ReceiptScreen extends StatefulWidget {
  final Payment payment;

  const ReceiptScreen({super.key, required this.payment});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final _receiptService = ReceiptService();
  Receipt? _receipt;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await _receiptService.getReceiptByPaymentId(widget.payment.id);

      if (response.success && response.data != null) {
        setState(() {
          _receipt = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Error al cargar el recibo';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recibo de Pago'),
        centerTitle: true,
        actions: [
          if (_receipt != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _shareReceipt,
              tooltip: 'Compartir',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Cargando recibo...');
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadReceipt,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_receipt == null) {
      return const Center(
        child: Text('No se pudo cargar el recibo'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildReceiptCard(),
          const SizedBox(height: 16),
          _buildActionsRow(),
        ],
      ),
    );
  }

  Widget _buildReceiptCard() {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'RECIBO DE PAGO',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _receipt!.receiptNumber,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Customer Info
            _buildInfoSection(
              'Información del Cliente',
              [
                _buildInfoRow('Nombre:', _receipt!.customerName),
                _buildInfoRow('Email:', _receipt!.customerEmail),
              ],
            ),
            const SizedBox(height: 16),

            // Payment Info
            _buildInfoSection(
              'Información del Pago',
              [
                _buildInfoRow(
                  'Fecha:',
                  dateFormat.format(_receipt!.issuedAt),
                ),
                _buildInfoRow(
                  'ID Transacción:',
                  _receipt!.payment.transactionId,
                ),
                _buildInfoRow(
                  'Método de Pago:',
                  _receipt!.payment.paymentMethod.displayName,
                ),
                _buildInfoRow(
                  'Estado:',
                  _receipt!.payment.status.displayName,
                  statusColor: _getStatusColor(_receipt!.payment.status),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Order Info
            _buildInfoSection(
              'Información de la Orden',
              [
                _buildInfoRow(
                  'Número de Orden:',
                  _receipt!.order.orderNumber,
                ),
                _buildInfoRow(
                  'Fecha de Orden:',
                  dateFormat.format(_receipt!.order.createdAt!),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Items
            const Text(
              'Artículos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildItemsTable(),
            const SizedBox(height: 24),

            // Totals
            const Divider(),
            const SizedBox(height: 12),
            _buildTotalRow(
              'Subtotal:',
              _receipt!.subtotal,
              isBold: false,
            ),
            const SizedBox(height: 8),
            _buildTotalRow(
              'Impuestos (10%):',
              _receipt!.tax,
              isBold: false,
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            _buildTotalRow(
              'TOTAL:',
              _receipt!.total,
              isBold: true,
              color: Colors.green.shade700,
              fontSize: 20,
            ),
            const SizedBox(height: 24),

            // Footer
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pago Completado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Gracias por tu compra!',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
      ),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
          ),
          children: const [
            _TableCell(text: 'Artículo', isHeader: true),
            _TableCell(text: 'Cant.', isHeader: true),
            _TableCell(text: 'Precio', isHeader: true),
            _TableCell(text: 'Total', isHeader: true),
          ],
        ),
        // Items
        ..._receipt!.items.map((item) {
          return TableRow(
            children: [
              _TableCell(
                text: item.itemName,
                subtitle: item.itemType,
              ),
              _TableCell(text: item.quantity.toString()),
              _TableCell(text: '\$${item.unitPrice.toStringAsFixed(2)}'),
              _TableCell(text: '\$${item.totalPrice.toStringAsFixed(2)}'),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    double amount, {
    bool isBold = false,
    Color? color,
    double fontSize = 16,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _downloadReceipt,
            icon: const Icon(Icons.download),
            label: const Text('Descargar'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home),
            label: const Text('Inicio'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.processing:
        return Colors.orange;
      case PaymentStatus.pending:
        return Colors.blue;
      case PaymentStatus.refunded:
        return Colors.purple;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  void _shareReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir próximamente'),
      ),
    );
  }

  void _downloadReceipt() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de descarga próximamente'),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final String text;
  final String? subtitle;
  final bool isHeader;

  const _TableCell({
    required this.text,
    this.subtitle,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              fontSize: isHeader ? 14 : 13,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
