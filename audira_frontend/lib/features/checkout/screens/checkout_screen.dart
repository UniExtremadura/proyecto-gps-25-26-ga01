import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/models/payment.dart';
import '../../../core/api/services/payment_service.dart';
import '../../../core/models/order.dart';
import '../../receipt/screens/receipt_screen.dart';
import 'payment_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Order order;

  const CheckoutScreen({super.key, required this.order});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _paymentService = PaymentService();

  PaymentMethod _selectedPaymentMethod = PaymentMethod.creditCard;

  // Card details
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isProcessing = false;
  static const double taxRate = 0.21;

  double get subtotal => widget.order.totalAmount;
  double get taxAmount => subtotal * taxRate;
  double get totalWithTax => subtotal + taxAmount;

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'CHECKOUT',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Resumen de Orden
              _buildSectionTitle('RESUMEN'),
              _buildOrderSummary()
                  .animate()
                  .fadeIn()
                  .slideY(begin: 0.1, end: 0),

              const SizedBox(height: 32),

              // 2. Método de Pago
              _buildSectionTitle('MÉTODO DE PAGO'),
              _buildPaymentMethodSelector().animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 32),

              // 3. Formulario de Tarjeta o Info Stripe
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _selectedPaymentMethod == PaymentMethod.stripe
                    ? _buildStripeInfo()
                    : _buildCardForm(),
              ),

              const SizedBox(height: 40),

              // 4. Botón de Pago
              _buildPayButton().animate().fadeIn(delay: 300.ms).scale(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textGrey,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Orden #${widget.order.orderNumber}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              Text('${widget.order.items.length} ítems',
                  style: const TextStyle(color: AppTheme.textGrey)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),
          _buildSummaryRow('Subtotal', subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('IVA (21%)', taxAmount),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white10),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 16)),
              Text('\$${totalWithTax.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textGrey)),
        Text('\$${value.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      children: [
        _buildPaymentOptionCard(
          method: PaymentMethod.creditCard,
          icon: Icons.credit_card,
          label: 'Tarjeta de Crédito',
        ),
        const SizedBox(height: 12),
        _buildPaymentOptionCard(
          method: PaymentMethod.debitCard,
          icon: Icons.credit_card_outlined,
          label: 'Tarjeta de Débito',
        ),
        const SizedBox(height: 12),
        _buildPaymentOptionCard(
          method: PaymentMethod.stripe,
          icon: Icons.webhook, // Icono genérico para Stripe/Web
          label: 'Stripe Checkout',
        ),
      ],
    );
  }

  Widget _buildPaymentOptionCard({
    required PaymentMethod method,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.15)
              : AppTheme.surfaceBlack,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.primaryBlue : AppTheme.textGrey),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textGrey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppTheme.primaryBlue, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- Visual Credit Card Representation (Decorativo) ---
        Container(
          height: 200,
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryBlue.withValues(alpha: 0.8),
                Colors.purple.shade900,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.nfc, color: Colors.white54, size: 30),
                  Icon(Icons.credit_card, color: Colors.white, size: 30),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _cardNumberController.text.isEmpty
                        ? '0000 0000 0000 0000'
                        : _cardNumberController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontFamily: 'Courier', // Monospaced para números
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TITULAR',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 10)),
                          Text(
                            _cardHolderController.text.isEmpty
                                ? 'NOMBRE APELLIDO'
                                : _cardHolderController.text.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EXPIRA',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 10)),
                          Text(
                            _expiryDateController.text.isEmpty
                                ? 'MM/AA'
                                : _expiryDateController.text,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  )
                ],
              )
            ],
          ),
        ).animate().scale(curve: Curves.easeOutBack),

        // --- Inputs ---
        _buildDarkInput(
          controller: _cardNumberController,
          label: 'Número de Tarjeta',
          hint: '0000 0000 0000 0000',
          icon: Icons.credit_card,
          isNumeric: true,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberFormatter(),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return 'Requerido';
            final digits = value.replaceAll(' ', '');
            if (digits.length < 13 || digits.length > 16) return 'Inválido';
            return null;
          },
          onChanged: (val) =>
              setState(() {}), // Para actualizar la tarjeta visual
        ),

        const SizedBox(height: 16),

        _buildDarkInput(
          controller: _cardHolderController,
          label: 'Nombre del Titular',
          hint: 'Como aparece en la tarjeta',
          icon: Icons.person_outline,
          isUpperCase: true,
          formatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
          ],
          validator: (value) =>
              (value == null || value.isEmpty) ? 'Requerido' : null,
          onChanged: (val) => setState(() {}),
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildDarkInput(
                controller: _expiryDateController,
                label: 'Vencimiento',
                hint: 'MM/AA',
                icon: Icons.calendar_today_outlined,
                isNumeric: true,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(5),
                  _ExpiryDateFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (value.length != 5) return 'Incompleto';
                  return null;
                },
                onChanged: (val) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDarkInput(
                controller: _cvvController,
                label: 'CVV',
                hint: '123',
                icon: Icons.lock_outline,
                isNumeric: true,
                isObscure: true,
                formatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requerido';
                  if (value.length != 3) return '3 dígitos';
                  return null;
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Info Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border:
                Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ambiente de pruebas: Tarjetas que inician con 4000 fallarán intencionalmente.',
                  style: TextStyle(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.8),
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStripeInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF635BFF)
            .withValues(alpha: 0.1), // Color marca Stripe
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF635BFF).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.webhook, size: 48, color: Color(0xFF635BFF)),
          const SizedBox(height: 16),
          const Text(
            'Redirección Segura',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Serás redirigido a la pasarela de pago segura de Stripe para completar tu transacción.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'PAGAR \$${totalWithTax.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // --- Helper para Inputs Dark ---
  Widget _buildDarkInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool isNumeric = false,
    bool isObscure = false,
    bool isUpperCase = false,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      obscureText: isObscure,
      textCapitalization:
          isUpperCase ? TextCapitalization.characters : TextCapitalization.none,
      inputFormatters: formatters,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.3)),
        labelStyle: const TextStyle(color: AppTheme.textGrey),
        prefixIcon: Icon(icon, color: AppTheme.textGrey),
        filled: true,
        fillColor: AppTheme.cardBlack,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryBlue)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.errorRed)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  // --- Lógica de Pago (Mantenida intacta) ---
  Future<void> _processPayment() async {
    if (_selectedPaymentMethod != PaymentMethod.stripe &&
        !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      Map<String, String>? paymentDetails;
      if (_selectedPaymentMethod == PaymentMethod.creditCard ||
          _selectedPaymentMethod == PaymentMethod.debitCard) {
        paymentDetails = {
          'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
          'cardHolder': _cardHolderController.text,
          'expiryDate': _expiryDateController.text,
          'cvv': _cvvController.text,
        };
      }

      final response = await _paymentService.processPayment(
        orderId: widget.order.id,
        userId: widget.order.userId,
        paymentMethod: _selectedPaymentMethod,
        amount: totalWithTax,
        paymentDetails: paymentDetails,
      );

      if (response.success && response.data != null) {
        final paymentResponse = response.data!;
        if (paymentResponse.success) {
          if (paymentResponse.payment != null) {
            await _waitForPaymentCompletion(paymentResponse.payment!);
          } else {
            setState(() => _isProcessing = false);
            _showError('Error: Pago procesado pero respuesta incompleta');
          }
        } else {
          setState(() => _isProcessing = false);
          _showPaymentResult(
            success: false,
            errorMessage: paymentResponse.message,
            payment: paymentResponse.payment,
          );
        }
      } else {
        setState(() => _isProcessing = false);
        _showError(response.error ?? 'Error al procesar el pago');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error inesperado: $e');
    }
  }

  Future<void> _waitForPaymentCompletion(Payment initialPayment) async {
    Payment currentPayment = initialPayment;
    int attempts = 0;
    const maxAttempts = 10;
    const pollInterval = Duration(seconds: 1);

    if (currentPayment.status == PaymentStatus.completed) {
      setState(() => _isProcessing = false);
      _showPaymentResult(success: true, payment: currentPayment);
      return;
    }

    while (attempts < maxAttempts) {
      await Future.delayed(pollInterval);
      attempts++;

      final response = await _paymentService.getPaymentById(currentPayment.id);
      if (response.success && response.data != null) {
        currentPayment = response.data!;
        if (currentPayment.status == PaymentStatus.completed) {
          setState(() => _isProcessing = false);
          _showPaymentResult(success: true, payment: currentPayment);
          return;
        } else if (currentPayment.status == PaymentStatus.failed) {
          setState(() => _isProcessing = false);
          _showPaymentResult(
            success: false,
            payment: currentPayment,
            errorMessage:
                'El pago falló: ${currentPayment.errorMessage ?? "Error desconocido"}',
          );
          return;
        }
      }
    }

    setState(() => _isProcessing = false);
    _showError(
        'El pago está siendo procesado. Por favor verifica el estado más tarde.');
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showPaymentResult(
      {required bool success, Payment? payment, String? errorMessage}) {
    if (success && payment != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              PaymentSuccessScreen(payment: payment, order: widget.order),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => PaymentResultScreen(
            success: false,
            payment: payment,
            errorMessage: errorMessage,
            order: widget.order,
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// --- Formatters ---
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) buffer.write(' ');
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.length >= 2) {
      final buffer = StringBuffer();
      buffer.write(text.substring(0, 2));
      if (text.length > 2) {
        buffer.write('/');
        buffer.write(text.substring(2));
      }
      return TextEditingValue(
        text: buffer.toString(),
        selection: TextSelection.collapsed(offset: buffer.length),
      );
    }
    return newValue;
  }
}

// --- Pantalla de Resultado (Dark Mode) ---
class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final Payment? payment;
  final String? errorMessage;
  final Order order;

  const PaymentResultScreen({
    super.key,
    required this.success,
    this.payment,
    this.errorMessage,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        title: const Text('RESULTADO',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                letterSpacing: 1,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                success ? Icons.check_circle_outline : Icons.error_outline,
                color: success ? AppTheme.successGreen : AppTheme.errorRed,
                size: 100,
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              Text(
                success ? '¡Pago Exitoso!' : 'Pago Fallido',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardBlack,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    if (payment != null) ...[
                      _buildResultRow('Transacción', payment!.transactionId),
                      const SizedBox(height: 12),
                      _buildResultRow(
                          'Monto', '\$${payment!.amount.toStringAsFixed(2)}'),
                    ],
                    if (errorMessage != null) ...[
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.white10)),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppTheme.errorRed, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ).animate().slideY(begin: 0.2, end: 0, delay: 300.ms),

              const SizedBox(height: 40),

              // Actions
              if (success) ...[
                _buildActionButton(context,
                    label: 'VER RECIBO',
                    icon: Icons.receipt_long,
                    color: AppTheme.successGreen, onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => ReceiptScreen(payment: payment!)),
                  );
                }),
              ] else if (payment != null) ...[
                _buildActionButton(context,
                    label: 'REINTENTAR PAGO',
                    icon: Icons.refresh,
                    color: AppTheme.primaryBlue, onPressed: () async {
                  final paymentService = PaymentService();
                  // Lógica de reintento simplificada para UI
                  final response =
                      await paymentService.retryPayment(payment!.id);
                  if (context.mounted) {
                    if (response.success && response.data != null) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => PaymentResultScreen(
                            success: response.data!.success,
                            payment: response.data!.payment,
                            errorMessage: response.data!.success
                                ? null
                                : response.data!.message,
                            order: order,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(response.error ?? 'Error al reintentar'),
                            backgroundColor: AppTheme.errorRed),
                      );
                    }
                  }
                }),
              ],

              const SizedBox(height: 16),

              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('VOLVER AL INICIO',
                    style: TextStyle(color: AppTheme.textGrey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textGrey)),
        SelectableText(value,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context,
      {required String label,
      required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
