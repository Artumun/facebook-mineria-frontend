import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final TextEditingController _urlController = TextEditingController(
    text: 'https://x.com/tech_news/status/17894561230',
  );

  bool _isLoading = false;
  bool _hasAnalyzed = true; // Mostramos los mock datos inicialmente
  int _touchedIndex = -1;

  // Datos mock de comentarios
  final List<Map<String, String>> _mockComments = [
    {
      'username': '@maria_dev',
      'comment':
          '¡Excelente iniciativa! Me parece una propuesta tecnológica increíble para el sector.',
      'sentiment': 'Positivo',
    },
    {
      'username': '@carlos_tech',
      'comment':
          'El sistema presenta ligeras demoras en las horas pico de procesamiento.',
      'sentiment': 'Negativo',
    },
    {
      'username': '@analista_x',
      'comment':
          'Se realizó la prueba correspondiente respetando la documentación establecida.',
      'sentiment': 'Neutro',
    },
    {
      'username': '@sofia_m',
      'comment':
          'Me encanta la nueva interfaz gráfica y el resumen automático generado con IA.',
      'sentiment': 'Positivo',
    },
    {
      'username': '@juan_perez',
      'comment':
          'Ocurrió un error inesperado al intentar exportar la tabla de resultados.',
      'sentiment': 'Negativo',
    },
  ];

  void _triggerAnalysis() async {
    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese una URL válida de X (Twitter)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulación de carga (2.5 segundos de procesamiento simulado)
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _hasAnalyzed = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Análisis completado exitosamente con IA!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A), // Slate 900
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
                  'Sistema de Minería & Análisis de IA',
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
                // 1. Barra de entrada de URL y botón "Analizar"
                _buildAnalysisInputCard(),

                const SizedBox(height: 24),

                // Spinner de carga o contenido principal
                if (_isLoading)
                  _buildLoadingSimulation()
                else if (_hasAnalyzed) ...[
                  // 2. Tarjetas de Métricas
                  _buildMetricsCards(),

                  const SizedBox(height: 24),

                  // 3. Gráfica de Sentimientos y Resumen de Métricas
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

                  // 4. Tabla de Comentarios
                  _buildCommentsTableCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET: Campo URL y Botón Analizar ---
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
                  'Recolector de Publicaciones de X (Multiredes)',
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
        hintText: 'https://x.com/usuario/status/123456789',
        labelText: 'URL del post a analizar',
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
      label: const Text('Analizar Post'),
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

  // --- WIDGET: Simulación de Carga ---
  Widget _buildLoadingSimulation() {
    return Container(
      padding: const EdgeInsets.all(48.0),
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
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ejecutando proceso de extracción y modelos de NLP...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Simulando respuesta del backend (Python / Flask + Workers)...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: 3 Tarjetas de Métricas ---
  Widget _buildMetricsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        final cards = [
          _buildMetricCard(
            title: 'Likes Totales',
            value: '1,420',
            icon: Icons.favorite_rounded,
            color: const Color(0xFFE11D48),
            badgeText: '+14% interacción',
          ),
          _buildMetricCard(
            title: 'Reposts / Compartidos',
            value: '310',
            icon: Icons.repeat_rounded,
            color: const Color(0xFF059669),
            badgeText: '+8% difusión',
          ),
          _buildMetricCard(
            title: 'Respuestas Totales',
            value: '85',
            icon: Icons.chat_bubble_rounded,
            color: const Color(0xFF2563EB),
            badgeText: '5 comentarios clave',
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

  // --- WIDGET: Gráfica de Sentimientos fl_chart ---
  Widget _buildSentimentChartCard() {
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'fl_chart',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1E3A8A),
                      fontWeight: FontWeight.bold,
                    ),
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
                          touchCallback:
                              (FlTouchEvent event, pieTouchResponse) {
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
                        text: 'Positivo (50%)',
                        isSquare: false,
                      ),
                      const SizedBox(height: 12),
                      _buildLegendIndicator(
                        color: const Color(0xFFEF4444),
                        text: 'Negativo (20%)',
                        isSquare: false,
                      ),
                      const SizedBox(height: 12),
                      _buildLegendIndicator(
                        color: const Color(0xFF64748B),
                        text: 'Neutro (30%)',
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
    return List.generate(3, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 14.0;
      final radius = isTouched ? 65.0 : 55.0;

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color(0xFF10B981), // Positivo
            value: 50,
            title: '50%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: const Color(0xFFEF4444), // Negativo
            value: 20,
            title: '20%',
            radius: radius,
            titleStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: const Color(0xFF64748B), // Neutro
            value: 30,
            title: '30%',
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

  // --- WIDGET: Resumen Ejecutivo ---
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
              'La publicación presenta una postura predominantemente positiva (50%). '
              'Los usuarios destacan la innovación tecnológica y el diseño visual. '
              'Se detectó un 20% de opiniones negativas relacionadas con latencias en el procesamiento.',
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
                Icon(Icons.psychology_rounded,
                    size: 18, color: Colors.purple[700]),
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

  // --- WIDGET: Tabla de Comentarios ---
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
                  '5 comentarios mostrados',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                      const Color(0xFFF1F5F9), // Slate 100
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
                    rows: _mockComments.map((item) {
                      final sentiment = item['sentiment']!;
                      Color badgeBgColor;
                      Color badgeTextColor;

                      if (sentiment == 'Positivo') {
                        badgeBgColor = const Color(0xFFD1FAE5); // Emerald 100
                        badgeTextColor = const Color(0xFF065F46); // Emerald 800
                      } else if (sentiment == 'Negativo') {
                        badgeBgColor = const Color(0xFFFEE2E2); // Red 100
                        badgeTextColor = const Color(0xFF991B1B); // Red 800
                      } else {
                        badgeBgColor = const Color(0xFFE2E8F0); // Slate 200
                        badgeTextColor = const Color(0xFF1E293B); // Slate 800
                      }

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
                                    item['username']![1].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item['username']!,
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
                                item['comment']!,
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
