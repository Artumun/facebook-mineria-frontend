import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _urlController = TextEditingController();

  bool _isLoading = false;
  bool _hasAnalyzed = false;
  int _touchedIndex = -1;

  // Variables para la barra de progreso y temporizador
  Timer? _loadingTimer;
  int _elapsedSeconds = 0;
  final int _estimatedTotalSeconds = 10;
  double _progressValue = 0.0;
  String _loadingStageText = 'Iniciando conexión con el servidor...';

  // Estado de datos reales provenientes del backend
  int? _idAnalisis;
  int _likes = 0;
  int _compartidos = 0;
  int _totalComentarios = 0;
  double _porcPositivo = 0;
  double _porcNegativo = 0;
  double _porcNeutro = 0;
  String _resumenIA = '';
  List<Map<String, dynamic>> _comments = [];

  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    _elapsedSeconds = 0;
    _progressValue = 0.05;
    _loadingStageText = 'Abriendo enlace público de Facebook...';

    _loadingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsedSeconds++;
        if (_elapsedSeconds <= 3) {
          _loadingStageText = 'Resolviendo enlace y cargando publicación...';
          _progressValue = (_elapsedSeconds / _estimatedTotalSeconds).clamp(0.1, 0.35);
        } else if (_elapsedSeconds <= 6) {
          _loadingStageText = 'Desplegando hilo y extrayendo comentarios públicos...';
          _progressValue = (_elapsedSeconds / _estimatedTotalSeconds).clamp(0.4, 0.65);
        } else if (_elapsedSeconds <= 9) {
          _loadingStageText = 'Clasificando sentimientos con red neuronal RoBERTa...';
          _progressValue = (_elapsedSeconds / _estimatedTotalSeconds).clamp(0.7, 0.9);
        } else {
          _loadingStageText = 'Almacenando resultados en MariaDB y generando métricas...';
          _progressValue = 0.95;
        }
      });
    });
  }

  void _stopLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  @override
  void dispose() {
    _stopLoadingTimer();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _triggerAnalysis() async {
    final urlText = _urlController.text.trim();
    if (urlText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese una URL válida de Facebook'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    _startLoadingTimer();

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/api/analizar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': urlText}),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _progressValue = 1.0;
          _idAnalisis = data['id_analisis'];
          _likes = data['likes'] ?? 0;
          _compartidos = data['compartidos'] ?? 0;
          _totalComentarios = data['total_comentarios'] ?? 0;
          _porcPositivo = (data['porcentajes']['positivo'] ?? 0).toDouble();
          _porcNegativo = (data['porcentajes']['negativo'] ?? 0).toDouble();
          _porcNeutro = (data['porcentajes']['neutro'] ?? 0).toDouble();
          _resumenIA = data['resumen_ia'] ?? '';
          _comments = List<Map<String, dynamic>>.from(data['comentarios'] ?? []);
          _hasAnalyzed = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Análisis completado en $_elapsedSeconds segundos'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Error al analizar la publicación'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión con el servidor backend'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _stopLoadingTimer();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _descargarExcel() async {
    if (_idAnalisis == null) return;
    final Uri url = Uri.parse('http://127.0.0.1:5000/api/exportar/$_idAnalisis');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo iniciar la descarga del archivo Excel'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 4,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: Colors.lightBlueAccent,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sistema de Minería & Análisis de IA - Facebook',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Dashboard de Resultados • Proyecto de Estadía',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_hasAnalyzed && _idAnalisis != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: ElevatedButton.icon(
                onPressed: _descargarExcel,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Descargar Excel (.xlsx)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAnalysisInputCard(),
                const SizedBox(height: 24),
                if (_isLoading)
                  _buildLoadingIndicator()
                else if (_hasAnalyzed) ...[
                  _buildMetricsCards(),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 800;
                      if (isMobile) {
                        return Column(
                          children: [
                            _buildSentimentChartCard(),
                            const SizedBox(height: 20),
                            _buildExecutiveSummaryCard(),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _buildSentimentChartCard(),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 4,
                            child: _buildExecutiveSummaryCard(),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildCommentsTableCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisInputCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.link_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text(
                  'Recolector de Publicaciones de Facebook',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 600;
                return isMobile
                    ? Column(
                        children: [
                          _buildTextField(),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _buildAnalyzeButton(),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: _buildTextField()),
                          const SizedBox(width: 12),
                          _buildAnalyzeButton(),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _urlController,
      decoration: InputDecoration(
        hintText: 'https://www.facebook.com/share/p/...',
        labelText: 'URL de la publicación de Facebook a analizar',
        prefixIcon: const Icon(Icons.travel_explore_rounded),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildAnalyzeButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _triggerAnalysis,
      icon: const Icon(Icons.search_rounded),
      label: const Text('Analizar Publicación'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final int remainingSeconds = (_estimatedTotalSeconds - _elapsedSeconds).clamp(1, 30);
    final int percentText = (_progressValue * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(36.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _loadingStageText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                '$percentText%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressValue,
              minHeight: 12,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Tiempo transcurrido: ${_elapsedSeconds}s',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              Text(
                _elapsedSeconds < _estimatedTotalSeconds
                    ? 'Tiempo estimado restante: ~${remainingSeconds}s'
                    : 'Finalizando procesamiento...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final cards = [
          _buildMetricCard(
            title: 'Reacciones / Likes',
            value: '$_likes',
            icon: Icons.thumb_up_alt_rounded,
            color: const Color(0xFFE11D48),
            badgeText: 'Interacción directa',
          ),
          _buildMetricCard(
            title: 'Compartidos',
            value: '$_compartidos',
            icon: Icons.share_rounded,
            color: const Color(0xFF059669),
            badgeText: 'Alcance de difusión',
          ),
          _buildMetricCard(
            title: 'Muestra Analizada',
            value: '$_totalComentarios',
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF2563EB),
            badgeText: 'Comentarios evaluados con IA',
          ),
        ];

        if (isMobile) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: c,
                    ))
                .toList(),
          );
        }

        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String badgeText,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildSentimentChartCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 8),
                Text(
                  'Distribución de Sentimientos (NLP)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedIndex = -1;
                                return;
                              }
                              _touchedIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 3,
                        centerSpaceRadius: 45,
                        sections: _generatePieChartSections(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendIndicator(
                        color: const Color(0xFF10B981),
                        text: 'Positivo (${_porcPositivo.toInt()}%)',
                        isSquare: false,
                      ),
                      const SizedBox(height: 12),
                      _buildLegendIndicator(
                        color: const Color(0xFFEF4444),
                        text: 'Negativo (${_porcNegativo.toInt()}%)',
                        isSquare: false,
                      ),
                      const SizedBox(height: 12),
                      _buildLegendIndicator(
                        color: const Color(0xFF64748B),
                        text: 'Neutro (${_porcNeutro.toInt()}%)',
                        isSquare: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieChartSections() {
    final sinDatos = _porcPositivo == 0 && _porcNegativo == 0 && _porcNeutro == 0;
    final valPos = sinDatos ? 0.0 : _porcPositivo;
    final valNeg = sinDatos ? 0.0 : _porcNegativo;
    final valNeu = sinDatos ? 100.0 : _porcNeutro;

    return List.generate(3, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 65.0 : 55.0;

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color(0xFF10B981),
            value: valPos,
            title: '${_porcPositivo.toInt()}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: const Color(0xFFEF4444),
            value: valNeg,
            title: '${_porcNegativo.toInt()}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: const Color(0xFF64748B),
            value: valNeu,
            title: '${_porcNeutro.toInt()}%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        default:
          throw Error();
      }
    });
  }

  Widget _buildLegendIndicator({
    required Color color,
    required String text,
    required bool isSquare,
  }) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildExecutiveSummaryCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFF7C3AED)),
                SizedBox(width: 8),
                Text(
                  'Resumen Automático (IA)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _resumenIA,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.psychology_rounded,
                  size: 18,
                  color: Colors.purple[700],
                ),
                const SizedBox(width: 8),
                Text(
                  'Modelo: RoBERTa-Sentiment-ES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsTableCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.table_chart_rounded, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 8),
                    Text(
                      'Muestreo de Comentarios Analizados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${_comments.length} comentarios mostrados',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No se encontraron comentarios públicos visibles en esta publicación.',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFF1F5F9),
                      ),
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Usuario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Texto del Comentario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Sentimiento',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                      rows: _comments.map((item) {
                        final username = (item['username'] ?? 'Usuario').toString();
                        final commentText = (item['comment'] ?? '').toString();
                        final sentiment = (item['sentiment'] ?? 'Neutro').toString();

                        Color badgeBgColor;
                        Color badgeTextColor;

                        if (sentiment == 'Positivo') {
                          badgeBgColor = const Color(0xFFD1FAE5);
                          badgeTextColor = const Color(0xFF065F46);
                        } else if (sentiment == 'Negativo') {
                          badgeBgColor = const Color(0xFFFEE2E2);
                          badgeTextColor = const Color(0xFF991B1B);
                        } else {
                          badgeBgColor = const Color(0xFFE2E8F0);
                          badgeTextColor = const Color(0xFF1E293B);
                        }

                        final inicial = username.isNotEmpty
                            ? username[0].toUpperCase()
                            : 'U';

                        return DataRow(
                          cells: [
                            DataCell(
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFF1E3A8A)
                                        .withValues(alpha: 0.1),
                                    child: Text(
                                      inicial,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              SizedBox(
                                width: 450,
                                child: Text(
                                  commentText,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  sentiment,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: badgeTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}