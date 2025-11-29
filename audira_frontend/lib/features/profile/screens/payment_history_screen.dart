import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/payment_service.dart';
import '../../../core/models/payment.dart';
import '../../receipt/screens/receipt_screen.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();

  // --- Colores del Tema Oscuro ---
  final Color darkBg = Colors.black;
  final Color darkCardBg = const Color(0xFF212121);
  final Color lightText = Colors.white;
  final Color subText = Colors.grey;

  List<Payment> _payments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaymentHistory();
  }

  Future<void> _loadPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    if (userId == null) {
      setState(() {
        _error = 'User not identified';
        _isLoading = false;
      });
      return;
    }

    final response = await _paymentService.getPaymentsByUserId(userId);

    if (response.success && response.data != null) {
      setState(() {
        _payments = response.data!;
        _payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = response.error ?? 'Error loading payment history';
        _isLoading = false;
      });
    }
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('Payment History',
            style: TextStyle(
                color: AppTheme.primaryBlue, fontWeight: FontWeight.w800)),
        backgroundColor: darkBg,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primaryBlue),
              onPressed: _loadPaymentHistory)
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _error != null
              ? _buildErrorView()
              : _payments.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadPaymentHistory,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _payments.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildTransactionCard(_payments[index], index);
                        },
                      ),
                    ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration:
                BoxDecoration(color: darkCardBg, shape: BoxShape.circle),
            child: Icon(Icons.receipt_long_outlined,
                size: 64, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          Text('No payments yet',
              style: TextStyle(color: subText, fontSize: 18)),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red[900]),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: _loadPaymentHistory, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Payment payment, int index) {
    final statusColor = _getStatusColor(payment.status);

    return InkWell(
      onTap: () => _showPaymentDetails(payment),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: darkCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[850]!),
        ),
        child: Row(
          children: [
            // Icono Metodo Pago
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getPaymentMethodIcon(payment.paymentMethod),
                  color: Colors.grey[400], size: 24),
            ),
            const SizedBox(width: 16),

            // Info Principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.paymentMethod.displayName,
                    style: TextStyle(
                        color: lightText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(payment.createdAt),
                    style: TextStyle(color: subText, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Monto y Estado
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${payment.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: lightText, // Monto en blanco para claridad
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    payment.status.displayName.toUpperCase(),
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.1, end: 0);
  }

  // --- DETAILS SHEET (DARK MODE) ---

  void _showPaymentDetails(Payment payment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: darkCardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 30),

              // Big Amount Header
              Center(
                child: Column(
                  children: [
                    Icon(_getStatusIcon(payment.status),
                        size: 48, color: _getStatusColor(payment.status)),
                    const SizedBox(height: 16),
                    Text('\$${payment.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                            color: lightText,
                            fontSize: 32,
                            fontWeight: FontWeight.bold)),
                    Text(payment.status.displayName,
                        style: TextStyle(
                            color: _getStatusColor(payment.status),
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Details Grid
              _buildDetailItem('Date', _formatDateLong(payment.createdAt),
                  Icons.calendar_today),
              _buildDetailItem(
                  'Method', payment.paymentMethod.displayName, Icons.payment),
              _buildDetailItem(
                  'Transaction ID', payment.transactionId, Icons.receipt,
                  isCopyable: true),

              if (payment.completedAt != null)
                _buildDetailItem(
                    'Completed At',
                    _formatDateLong(payment.completedAt!),
                    Icons.check_circle_outline),

              if (payment.errorMessage != null)
                _buildDetailItem(
                    'Error', payment.errorMessage!, Icons.error_outline,
                    color: AppTheme.errorRed),

              const SizedBox(height: 30),

              // Actions
              if (payment.status == PaymentStatus.completed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ReceiptScreen(payment: payment)));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16)),
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('View Receipt'),
                  ),
                ),

              if (payment.status == PaymentStatus.failed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _retryPayment(payment);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16)),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Payment'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon,
      {bool isCopyable = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: subText, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: subText, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        color: color ?? lightText,
                        fontSize: 15,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (isCopyable) Icon(Icons.copy, size: 16, color: subText),
        ],
      ),
    );
  }

  // --- HELPERS ---

  Future<void> _retryPayment(Payment payment) async {
    // ... (Mantengo la lógica de reintento original, solo adaptando colores si hay UI de carga)
    // El código original está bien aquí
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
    );

    final response = await _paymentService.retryPayment(payment.id);

    if (mounted) {
      Navigator.of(context).pop();
      if (response.success && response.data != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response.data!.success
              ? 'Payment processed'
              : 'Payment failed again'),
          backgroundColor: response.data!.success ? Colors.green : Colors.red,
        ));
        _loadPaymentHistory();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(response.error ?? 'Retry error'),
            backgroundColor: Colors.red));
      }
    }
  }

  String _formatDate(DateTime date) => DateFormat('MMM dd, yyyy').format(date);
  String _formatDateLong(DateTime date) =>
      DateFormat('MMM dd, yyyy - HH:mm').format(date);

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.greenAccent;
      case PaymentStatus.failed:
        return Colors.redAccent;
      case PaymentStatus.pending:
        return Colors.orangeAccent;
      case PaymentStatus.processing:
        return Colors.blueAccent;
      case PaymentStatus.refunded:
        return Colors.purpleAccent;
      case PaymentStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Icons.check_circle;
      case PaymentStatus.failed:
        return Icons.error_outline;
      case PaymentStatus.pending:
        return Icons.hourglass_top;
      case PaymentStatus.processing:
        return Icons.sync;
      case PaymentStatus.refunded:
        return Icons.undo;
      case PaymentStatus.cancelled:
        return Icons.block;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.creditCard:
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.stripe:
        return Icons.payment; // O icono de stripe si tienes
      case PaymentMethod.paypal:
        return Icons.paypal; // O icono paypal
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
    }
  }
}
