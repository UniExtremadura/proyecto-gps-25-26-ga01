import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../config/theme.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/receipt.dart';
import '../../../core/api/services/receipt_service.dart';

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

  // YA NO NECESITAMOS _barcodeUrl PORQUE GENERAREMOS EL QR NATIVO

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
      var response =
          await _receiptService.getReceiptByPaymentId(widget.payment.id);

      if (!response.success) {
        // Intento de generar si no existe
        response = await _receiptService.generateReceipt(widget.payment.id);
      }

      if (response.success && response.data != null) {
        if (mounted) {
          setState(() {
            _receipt = response.data;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = response.error ?? 'No se pudo obtener el recibo digital.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Ocurrió un error inesperado de conexión.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usamos un Scaffold con fondo oscuro puro para resaltar el ticket
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Fondo muy oscuro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'COMPROBANTE',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _error != null
              ? _buildErrorState()
              : _buildSuccessContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded,
                size: 80, color: Colors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 24),
            Text(
              "Ups, algo salió mal",
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _loadReceipt,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text("Reintentar"),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Column(
        children: [
          // 1. EL TICKET (Componente Principal)
          _buildReceiptCard()
              .animate()
              .slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutQuart)
              .fadeIn(duration: 400.ms),

          const SizedBox(height: 30),

          // 2. BOTONES DE ACCIÓN
          _buildActionButtons()
              .animate(delay: 400.ms)
              .fadeIn()
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildReceiptCard() {
    return ClipPath(
      clipper: const ReceiptZigZagClipper(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF252836),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2C3040),
              Color(0xFF222532),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- HEADER ---
              _buildTicketHeader(),

              const SizedBox(height: 24),
              _buildDashedDivider(),
              const SizedBox(height: 24),

              // --- DETALLES ---
              Column(
                children: [
                  _buildDetailRow(
                      "CLIENTE", _receipt!.customerName.toUpperCase()),
                  _buildDetailRow("EMAIL", _receipt!.customerEmail,
                      isSmall: true),
                  _buildDetailRow(
                      "FECHA",
                      DateFormat('dd MMM yyyy, hh:mm a')
                          .format(_receipt!.issuedAt)),

                  // Lógica Copy + Overflow
                  _buildTransactionIdRow(_receipt!.payment.transactionId),
                ],
              ),

              const SizedBox(height: 24),
              _buildDashedDivider(),
              const SizedBox(height: 24),

              // --- ITEMS ---
              Align(
                alignment: Alignment.centerLeft,
                child: Text("DETALLE DE ORDEN", style: _labelStyle()),
              ),
              const SizedBox(height: 12),
              ..._receipt!.items.map((item) => _buildItemRow(item)),

              const SizedBox(height: 24),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 24),

              // --- TOTALES ---
              _buildDetailRow(
                  "Subtotal", "\$${_receipt!.subtotal.toStringAsFixed(2)}"),
              _buildDetailRow(
                  "Impuestos (IVA)", "\$${_receipt!.tax.toStringAsFixed(2)}"),

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "TOTAL PAGADO",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "\$${_receipt!.total.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // --- SECCIÓN QR (MEJORADA) ---
              _buildQrSection(),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS INTERNOS ---

  Widget _buildTicketHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppTheme.successGreen.withValues(alpha: 0.3), width: 2),
          ),
          child: const Icon(Icons.check_rounded,
              color: AppTheme.successGreen, size: 32),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 16),
        const Text(
          "Transacción Exitosa",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Gracias por tu compra en Audira Music",
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTransactionIdRow(String id) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("ID TRANSACCIÓN", style: _labelStyle()),
          const SizedBox(width: 16),
          Flexible(
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("ID copiado al portapapeles"),
                    backgroundColor: Color(0xFF333333),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        id,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy_rounded,
                        size: 14, color: AppTheme.primaryBlue),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: _labelStyle()),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: isSmall ? 12 : 14,
                fontWeight: isSmall ? FontWeight.normal : FontWeight.w500,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(ReceiptItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${item.quantity}x",
            style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.itemName,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "\$${item.totalPrice.toStringAsFixed(2)}",
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Courier'),
          ),
        ],
      ),
    );
  }

  // --- SECCIÓN ACTUALIZADA: QR REAL ---
  Widget _buildQrSection() {
    return Column(
      children: [
        Container(
          // Quitamos altura fija para que se adapte al contenido (el QR)
          // El QR necesita ser cuadrado, por lo que el padding lo hará respirar
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white, // Fondo blanco para que el QR sea legible
            borderRadius: BorderRadius.circular(8),
          ),
          child: QrImageView(
            data: _receipt!.payment.transactionId, // Generamos QR del ID
            version: QrVersions.auto,
            size: 140.0, // Tamaño del QR
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Escanear para verificar",
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          _receipt!.order.orderNumber,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 10,
              letterSpacing: 2,
              fontFamily: 'Courier'),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2C3040),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share_outlined, size: 20),
                SizedBox(width: 8),
                Text("Compartir"),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Finalizar",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // --- UTILIDADES ---

  TextStyle _labelStyle() {
    return TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
    );
  }

  Widget _buildDashedDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(color: Colors.white.withValues(alpha: 0.1)),
              ),
            );
          }),
        );
      },
    );
  }
}

class ReceiptZigZagClipper extends CustomClipper<Path> {
  const ReceiptZigZagClipper();

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height);
    const double toothWidth = 10.0;
    const double toothHeight = 6.0;
    double x = 0;
    while (x < size.width) {
      path.lineTo(x + toothWidth / 2, size.height - toothHeight);
      path.lineTo(x + toothWidth, size.height);
      x += toothWidth;
    }
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
