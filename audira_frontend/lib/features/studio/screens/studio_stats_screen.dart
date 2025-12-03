import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/api/services/metrics_service.dart';
import '../../../core/models/artist_metrics_detailed.dart';

class StudioStatsScreen extends StatefulWidget {
  const StudioStatsScreen({super.key});

  @override
  State<StudioStatsScreen> createState() => _StudioDetailedStatsScreenState();
}

class _StudioDetailedStatsScreenState extends State<StudioStatsScreen> {
  final MetricsService _metricsService = MetricsService();
  ArtistMetricsDetailed? _metrics;
  bool _isLoading = true;

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Default: last 30 days
    _endDate = DateTime.now();
    _startDate = _endDate!.subtract(const Duration(days: 30));
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    if (authProvider.currentUser != null) {
      final response = await _metricsService.getArtistMetricsDetailed(
        authProvider.currentUser!.id,
        startDate: _startDate,
        endDate: _endDate,
      );

      if (response.success && response.data != null) {
        setState(() {
          _metrics = response.data;
          _isLoading = false;
        });
      } else {
        debugPrint('❌ Failed to load metrics: ${response.error}');
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundBlack,
        title: const Text('ESTADÍSTICAS DETALLADAS',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
                color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadMetrics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue))
          : _metrics == null
              ? const Center(
                  child: Text('No hay datos disponibles',
                      style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Selector de Rango
                      _buildDateRangeSelector()
                          .animate()
                          .fadeIn()
                          .slideY(begin: -0.2, end: 0),

                      const SizedBox(height: 24),

                      // 2. Tarjetas Resumen Principales
                      Row(
                        children: [
                          Expanded(
                            child: _buildGradientCard(
                              'Ganancias',
                              '\$${_metrics!.totalRevenue.toStringAsFixed(2)}',
                              Icons.attach_money,
                              [Colors.green.shade900, Colors.green.shade600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildGradientCard(
                              'Reproducciones',
                              _formatNumber(_metrics!.totalPlays),
                              Icons.play_arrow_rounded,
                              [AppTheme.darkBlue, AppTheme.primaryBlue],
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 16),

                      // 3. Métricas Secundarias
                      Row(
                        children: [
                          Expanded(
                              child: _buildSecondaryStat(
                                  'Ventas',
                                  '${_metrics!.totalSales}',
                                  Icons.shopping_bag_outlined,
                                  Colors.orange)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildSecondaryStat(
                                  'Comentarios',
                                  '${_metrics!.totalComments}',
                                  Icons.comment_outlined,
                                  Colors.purple)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _buildSecondaryStat(
                                  'Valoración',
                                  _metrics!.averageRating.toStringAsFixed(1),
                                  Icons.star_border,
                                  Colors.amber)),
                        ],
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 32),

                      // 4. Gráfico de Reproducciones
                      _buildChartSection(
                        'Tendencia de Reproducciones',
                        _buildLineChart(
                          _metrics!.dailyMetrics,
                          (m) => m.plays.toDouble(),
                          AppTheme.primaryBlue,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .slideX(begin: 0.1, end: 0),

                      const SizedBox(height: 24),

                      // 5. Gráfico de Ingresos
                      _buildChartSection(
                        'Tendencia de Ingresos',
                        _buildLineChart(
                          _metrics!.dailyMetrics,
                          (m) => m.revenue,
                          Colors.green,
                          isCurrency: true,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 500.ms)
                          .slideX(begin: 0.1, end: 0),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  // --- Widgets ---

  Widget _buildDateRangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 18, color: AppTheme.textGrey),
              const SizedBox(width: 12),
              Text(
                '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          InkWell(
            onTap: _selectDateRange,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Cambiar',
                style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientCard(
      String title, String value, IconData icon, List<Color> colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => c.withValues(alpha: 0.8)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStat(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textGrey, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(String title, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardBlack,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 220, child: chart),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<DailyMetric> data,
      double Function(DailyMetric) valueMapper, Color color,
      {bool isCurrency = false}) {
    if (data.isEmpty) {
      return const Center(
          child: Text("No hay datos", style: TextStyle(color: Colors.white54)));
    }

    // Preparar puntos
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), valueMapper(data[i])));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.white10, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Mostrar solo algunas fechas para no saturar
                int index = value.toInt();
                if (index >= 0 &&
                    index < data.length &&
                    index % (data.length > 10 ? 5 : 2) == 0) {
                  final date =
                      data[index].date; // Asumiendo formato ISO YYYY-MM-DD
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('${date.day}/${date.month}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 10)),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                return Text(
                  isCurrency
                      ? '\$${value.toInt()}'
                      : _formatCompactNumber(value),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                );
              },
              reservedSize: 40,
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF2C2C2C),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  isCurrency
                      ? '\$${spot.y.toStringAsFixed(2)}'
                      : spot.y.toInt().toString(),
                  const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceBlack,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadMetrics();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }

  String _formatCompactNumber(double number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(0)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(0)}K';
    return number.toInt().toString();
  }
}
