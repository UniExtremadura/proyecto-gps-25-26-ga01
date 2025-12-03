import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/models/payment.dart';
import '../../../core/models/order.dart';
import '../../../core/models/song.dart';
import '../../../core/models/album.dart';
import '../../../core/api/services/music_service.dart';
import '../../../core/providers/library_provider.dart';
import '../../../core/providers/cart_provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../receipt/screens/receipt_screen.dart';
import '../../home/screens/main_layout.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final Payment payment;
  final Order order;

  const PaymentSuccessScreen({
    super.key,
    required this.payment,
    required this.order,
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
  final MusicService _musicService = MusicService();
  bool _isAddingToLibrary = true;
  final List<Song> _purchasedSongs = [];
  final List<Album> _purchasedAlbums = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePaymentSuccess();
  }

  Future<void> _initializePaymentSuccess() async {
    await _addPurchasedContentToLibrary();
  }

  // --- Lógica de Negocio (Intacta) ---
  Future<void> _addPurchasedContentToLibrary() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final libraryProvider =
          Provider.of<LibraryProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);

      debugPrint('=== PaymentSuccessScreen: Starting library sync ===');

      // Fetch all purchased items details
      for (final item in widget.order.items) {
        if (item.itemType == 'SONG') {
          final response = await _musicService.getSongById(item.itemId);
          if (response.success && response.data != null) {
            _purchasedSongs.add(response.data!);
          }
        } else if (item.itemType == 'ALBUM') {
          final response = await _musicService.getAlbumById(item.itemId);
          if (response.success && response.data != null) {
            _purchasedAlbums.add(response.data!);
          }
        }
      }

      // Sync Library
      if (authProvider.currentUser != null) {
        await libraryProvider.loadLibrary(authProvider.currentUser!.id);
      }

      // Clear Cart
      if (authProvider.currentUser != null) {
        await cartProvider.clearCart(authProvider.currentUser!.id);
        await cartProvider.loadCart(authProvider.currentUser!.id);
      }

      setState(() {
        _isAddingToLibrary = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');

      setState(() {
        _errorMessage = 'Error al sincronizar la biblioteca: $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: _isAddingToLibrary
          ? _buildLoadingState()
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // 1. Success Animation
                    _buildSuccessHeader(),

                    const SizedBox(height: 40),

                    // 2. Payment Details Card
                    _buildDetailsCard(),

                    const SizedBox(height: 24),

                    // 3. Purchased Content List (if any)
                    if (_purchasedSongs.isNotEmpty ||
                        _purchasedAlbums.isNotEmpty)
                      _buildContentList(),

                    // 4. Error Message (if any)
                    if (_errorMessage != null) _buildErrorMessage(),

                    const SizedBox(height: 40),

                    // 5. Action Buttons
                    _buildActionButtons(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // --- Widgets Modulares ---

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.successGreen),
          SizedBox(height: 24),
          Text(
            'Finalizando tu compra...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Sincronizando biblioteca',
            style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.successGreen.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.successGreen.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              )
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppTheme.successGreen,
            size: 80,
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 24),
        const Text(
          '¡PAGO COMPLETADO!',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        const Text(
          'Gracias por tu compra. Tu música está lista.',
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textGrey,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }

  Widget _buildDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RESUMEN DE TRANSACCIÓN',
            style: TextStyle(
              color: AppTheme.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Transacción ID', widget.payment.transactionId,
              isCopyable: true),
          const Divider(color: Colors.white10, height: 24),
          _buildDetailRow('Orden #', widget.order.orderNumber),
          const Divider(color: Colors.white10, height: 24),
          _buildDetailRow(
            'Monto Total',
            '\$${widget.payment.amount.toStringAsFixed(2)}',
            isHighlight: true,
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildDetailRow('Método', widget.payment.paymentMethod.displayName),
          const Divider(color: Colors.white10, height: 24),
          _buildDetailRow(
            'Fecha',
            _formatDate(widget.payment.completedAt ?? widget.payment.createdAt),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildContentList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBlack,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.library_music_rounded,
                      color: AppTheme.primaryBlue.withValues(alpha: 0.8),
                      size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'AGREGADO A TU BIBLIOTECA',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_purchasedSongs.isNotEmpty) ...[
                const Text('Canciones',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._purchasedSongs
                    .map((song) => _buildItemTile(song.name, Icons.music_note)),
                const SizedBox(height: 16),
              ],
              if (_purchasedAlbums.isNotEmpty) ...[
                const Text('Álbumes',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._purchasedAlbums
                    .map((album) => _buildItemTile(album.name, Icons.album)),
              ],
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildItemTile(String name, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceBlack,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 16, color: AppTheme.textGrey),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.check, size: 16, color: AppTheme.successGreen),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlight = false, bool isCopyable = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textGrey),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: isCopyable
              ? InkWell(
                  onTap: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy,
                          size: 12, color: AppTheme.textGrey),
                    ],
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHighlight ? AppTheme.successGreen : Colors.white,
                    fontSize: isHighlight ? 16 : 14,
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppTheme.errorRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ReceiptScreen(payment: widget.payment),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long_rounded),
            label: const Text(
              'VER RECIBO OFICIAL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppTheme.primaryBlue.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const MainLayout(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.home_rounded),
            label: const Text('VOLVER AL INICIO'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day}/${localDate.month}/${localDate.year} • ${localDate.hour.toString().padLeft(2, '0')}:${localDate.minute.toString().padLeft(2, '0')}';
  }
}
