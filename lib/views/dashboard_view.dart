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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _searchCommentController = TextEditingController();

  static const Color _headerNavy = Color(0xFF0F172A);
  static const Color _fbBlue = Color(0xFF1877F2);
  static const Color _bgAnalytical = Color(0xFFF4F6F9);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  bool _isLoading = false;
  bool _hasAnalyzed = false;
  int _touchedIndex = -1;

  Timer? _loadingTimer;
  int _elapsedSeconds = 0;
  double _progressValue = 0.0;
  String _loadingStageText = 'Preparando consulta...';

  int? _idAnalisis;
  String _contextoPost = '';
  String _contextoMultimedia = '';
  int _likes = 0;
  int _compartidos = 0;
  int _totalComentarios = 0;
  double _porcPositivo = 0;
  double _porcNegativo = 0;
  double _porcNeutro = 0;

  int _reacPositivo = 0;
  int _reacNegativo = 0;
  int _reacNeutro = 0;
  bool _meDivierteComoBurla = false;

  String _resumenIA = '';
  List<Map<String, dynamic>> _palabrasFrecuentes = [];
  List<Map<String, dynamic>> _reaccionesLista = [];
  List<Map<String, dynamic>> _comments = [];

  String _filtroReacciones = 'Todos';
  String _filtroSentimiento = 'Todos';
  String _busquedaTexto = '';
  List<Map<String, dynamic>> _historialList = [];
  bool _loadingHistorial = false;

int _remainingSeconds = 0;

  void _startLoadingTimer() {
    _loadingTimer?.cancel();
    _elapsedSeconds = 0;
    _remainingSeconds = 12;
    _progressValue = 0.04;
    _loadingStageText = 'Iniciando comunicación con el servidor...';

    _loadingTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) async {
      if (!mounted || !_isLoading) {
        timer.cancel();
        return;
      }
      try {
        final resp = await http.get(Uri.parse('http://127.0.0.1:5000/api/progreso'));
        if (resp.statusCode == 200 && mounted && _isLoading) {
          final data = jsonDecode(resp.body);
          setState(() {
            final int porc = data['porcentaje'] ?? 5;
            _progressValue = (porc / 100.0).clamp(0.02, 1.0);
            _loadingStageText = data['etapa'] ?? 'Procesando publicación...';
            _elapsedSeconds = data['tiempo_transcurrido'] ?? _elapsedSeconds;
            _remainingSeconds = data['tiempo_restante'] ?? 1;
          });
        }
      } catch (_) {}
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
    _searchCommentController.dispose();
    super.dispose();
  }

  void _aplicarDatosRecibidos(Map<String, dynamic> data) {
    final reacSent = data['reacciones_sentimiento'] ?? {};
    setState(() {
      _progressValue = 1.0;
      _idAnalisis = data['id_analisis'];
      _contextoPost = data['contexto_post'] ?? '';
      _contextoMultimedia = data['contexto_multimedia'] ?? '';
      _likes = data['likes'] ?? 0;
      _compartidos = data['compartidos'] ?? 0;
      _totalComentarios = data['total_comentarios'] ?? 0;
      _porcPositivo = (data['porcentajes']['positivo'] ?? 0).toDouble();
      _porcNegativo = (data['porcentajes']['negativo'] ?? 0).toDouble();
      _porcNeutro = (data['porcentajes']['neutro'] ?? 0).toDouble();
      _reacPositivo = reacSent['positivo'] ?? 100;
      _reacNegativo = reacSent['negativo'] ?? 0;
      _reacNeutro = reacSent['neutro'] ?? 0;
      _meDivierteComoBurla = reacSent['me_divierte_como_burla'] ?? false;
      _resumenIA = data['resumen_ia'] ?? '';
      _palabrasFrecuentes = List<Map<String, dynamic>>.from(data['palabras_frecuentes'] ?? []);
      _reaccionesLista = List<Map<String, dynamic>>.from(data['reacciones_lista'] ?? []);
      _comments = List<Map<String, dynamic>>.from(data['comentarios'] ?? []);
      _filtroReacciones = 'Todos';
      _filtroSentimiento = 'Todos';
      _busquedaTexto = '';
      _searchCommentController.clear();
      _hasAnalyzed = true;
    });
  }

  Future<void> _triggerAnalysis() async {
    final urlText = _urlController.text.trim();
    if (urlText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor pega un enlace válido de Facebook'),
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
        _aplicarDatosRecibidos(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Análisis finalizado en $_elapsedSeconds segundos'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'No fue posible analizar la publicación'),
            backgroundColor: const Color(0xFFE41E3F),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión con el servidor local'),
          backgroundColor: Color(0xFFE41E3F),
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

  Future<void> _cargarHistorial() async {
    setState(() {
      _loadingHistorial = true;
    });
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/api/historial'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _historialList = List<Map<String, dynamic>>.from(data['historial'] ?? []);
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _loadingHistorial = false;
        });
      }
    }
  }

  Future<void> _seleccionarItemHistorial(int id) async {
    Navigator.pop(context);
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('http://127.0.0.1:5000/api/historial/$id'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _urlController.text = data['url_post'] ?? '';
        _aplicarDatosRecibidos(data);
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _eliminarItemHistorial(int id) async {
    try {
      final response = await http.delete(Uri.parse('http://127.0.0.1:5000/api/historial/$id'));
      if (response.statusCode == 200) {
        _cargarHistorial();
      }
    } catch (_) {}
  }

  Future<void> _descargarExcel() async {
    if (_idAnalisis == null) return;
    final Uri url = Uri.parse('http://127.0.0.1:5000/api/exportar/$_idAnalisis');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir la descarga del archivo de Excel'),
          backgroundColor: Color(0xFFE41E3F),
        ),
      );
    }
  }

  BoxDecoration _analyticalCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> get _reaccionesFiltradas {
    return _reaccionesLista.where((item) {
      final sent = (item['sentiment'] ?? 'Neutro').toString();
      return _filtroReacciones == 'Todos' ||
          (_filtroReacciones == 'Positivos' && sent == 'Positivo') ||
          (_filtroReacciones == 'Negativos' && sent == 'Negativo') ||
          (_filtroReacciones == 'Neutros' && sent == 'Neutro');
    }).toList();
  }

  List<Map<String, dynamic>> get _comentariosFiltrados {
    return _comments.where((item) {
      final sent = (item['sentiment'] ?? 'Neutro').toString();
      final user = (item['username'] ?? '').toString().toLowerCase();
      final text = (item['comment'] ?? '').toString().toLowerCase();

      final pasaSentimiento = _filtroSentimiento == 'Todos' ||
          (_filtroSentimiento == 'Positivos' && sent == 'Positivo') ||
          (_filtroSentimiento == 'Negativos' && sent == 'Negativo') ||
          (_filtroSentimiento == 'Neutros' && sent == 'Neutro');

      final pasaBusqueda = _busquedaTexto.isEmpty ||
          user.contains(_busquedaTexto.toLowerCase()) ||
          text.contains(_busquedaTexto.toLowerCase());

      return pasaSentimiento && pasaBusqueda;
    }).toList();
  }

  IconData _iconoPorReaccion(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('encanta')) return Icons.favorite_rounded;
    if (n.contains('importa')) return Icons.volunteer_activism_rounded;
    if (n.contains('divierte')) return Icons.sentiment_very_satisfied_rounded;
    if (n.contains('asombra')) return Icons.sentiment_neutral_rounded;
    if (n.contains('entristece')) return Icons.sentiment_dissatisfied_rounded;
    if (n.contains('enoja')) return Icons.sentiment_very_dissatisfied_rounded;
    return Icons.thumb_up_alt_rounded;
  }

  Color _colorPorReaccion(String nombre) {
    final n = nombre.toLowerCase();
    if (n.contains('encanta') || n.contains('importa')) return const Color(0xFFE41E3F);
    if (n.contains('divierte') || n.contains('asombra')) return const Color(0xFFF59E0B);
    if (n.contains('entristece') || n.contains('enoja')) return const Color(0xFFDC2626);
    return _fbBlue;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final nombreUsuario = args?['nombre'] ?? 'Usuario';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bgAnalytical,
      drawer: _buildHistorialDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _headerNavy,
        foregroundColor: Colors.white,
        elevation: 2,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(color: _fbBlue, height: 3),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _fbBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.insights_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sistema de minería y análisis con IA • Módulo Facebook',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Panel de resultados • Usuario activo: $nombreUsuario',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              _cargarHistorial();
              _scaffoldKey.currentState?.openDrawer();
            },
            icon: const Icon(Icons.history_rounded, color: Colors.white, size: 19),
            label: const Text(
              'Historial de consultas',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
          if (_hasAnalyzed && _idAnalisis != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              child: ElevatedButton.icon(
                onPressed: _descargarExcel,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Descargar reporte en Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
            constraints: const BoxConstraints(maxWidth: 1150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAnalysisInputCard(),
                const SizedBox(height: 20),
                if (_isLoading)
                  _buildLoadingIndicator()
                else if (_hasAnalyzed) ...[
                  _buildMetricsCards(),
                  const SizedBox(height: 20),
                  _buildContextAndKeywordsCard(),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 850;
                      if (isMobile) {
                        return Column(
                          children: [
                            _buildSentimentChartCard(),
                            const SizedBox(height: 20),
                            _buildReactionsAndSummaryCard(),
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
                            flex: 5,
                            child: _buildReactionsAndSummaryCard(),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildReactionsTableCard(),
                  const SizedBox(height: 20),
                  _buildCommentsTableCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorialDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 44, 20, 20),
            color: _headerNavy,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history_rounded, color: _fbBlue, size: 26),
                    SizedBox(width: 10),
                    Text(
                      'Historial de consultas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Selecciona una publicación guardada para cargarla al instante',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingHistorial
                ? const Center(child: CircularProgressIndicator(color: _fbBlue))
                : _historialList.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'Todavía no hay publicaciones guardadas en el historial.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _textSecondary),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _historialList.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = _historialList[index];
                          final id = item['id'] as int;
                          return ListTile(
                            onTap: () => _seleccionarItemHistorial(id),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE7F3FF),
                              child: Icon(Icons.analytics_outlined, color: _fbBlue),
                            ),
                            title: Text(
                              item['url_post'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              'Reacciones: ${item['total_likes']} • Comentarios: ${item['total_comentarios']}\nFecha: ${item['fecha_analisis']}',
                              style: const TextStyle(fontSize: 11, color: _textSecondary),
                            ),
                            isThreeLine: true,
                            trailing: IconButton(
                              tooltip: 'Eliminar registro',
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                              onPressed: () => _eliminarItemHistorial(id),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisInputCard() {
    return Container(
      decoration: _analyticalCardDecoration(),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F3FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.facebook_rounded, color: _fbBlue, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Módulo Facebook',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _fbBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Extracción y análisis contextual de publicaciones',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: 'https://www.facebook.com/...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                    labelText: 'Enlace de la publicación a analizar',
                    labelStyle: const TextStyle(color: _textSecondary),
                    prefixIcon: const Icon(Icons.link_rounded, color: _fbBlue),
                    filled: true,
                    fillColor: _bgAnalytical,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _fbBlue, width: 1.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _triggerAnalysis,
                  icon: const Icon(Icons.radar_rounded),
                  label: const Text(
                    'Analizar publicación',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _headerNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildLoadingIndicator() {
    final int percentText = (_progressValue * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: _analyticalCardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(_fbBlue),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _loadingStageText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percentText%',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _fbBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progressValue,
              minHeight: 10,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(_fbBlue),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tiempo transcurrido real: ${_elapsedSeconds}s',
                style: const TextStyle(fontSize: 13, color: _textSecondary),
              ),
              Text(
                _remainingSeconds > 0
                    ? 'Tiempo restante calculado: ~${_remainingSeconds}s'
                    : 'Finalizando...',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _fbBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Reacciones totales',
            value: '$_likes',
            icon: Icons.thumb_up_alt_rounded,
            color: _fbBlue,
            badgeText: '$_reacPositivo% de aprobación',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Veces compartido',
            value: '$_compartidos',
            icon: Icons.share_rounded,
            color: const Color(0xFF10B981),
            badgeText: 'Difusión de la publicación',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            title: 'Comentarios analizados',
            value: '$_totalComentarios',
            icon: Icons.forum_rounded,
            color: const Color(0xFF6366F1),
            badgeText: 'Evaluados con contexto e IA',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String badgeText,
  }) {
    return Container(
      decoration: _analyticalCardDecoration(),
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: _textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextAndKeywordsCard() {
    return Container(
      decoration: _analyticalCardDecoration(),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons. psychology_outlined, color: _fbBlue),
              SizedBox(width: 8),
              Text(
                'Contexto general utilizado por la IA y términos frecuentes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _bgAnalytical,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_contextoPost (${_contextoMultimedia})',
              style: const TextStyle(
                fontSize: 13.5,
                color: _textPrimary,
                height: 1.4,
              ),
            ),
          ),
          if (_palabrasFrecuentes.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Términos más repetidos en los comentarios:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _palabrasFrecuentes.map((item) {
                return Chip(
                  backgroundColor: _bgAnalytical,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  label: Text(
                    '${item['palabra']} (${item['frecuencia']})',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSentimentChartCard() {
    return Container(
      decoration: _analyticalCardDecoration(),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, color: _fbBlue),
              SizedBox(width: 8),
              Text(
                'Distribución de sentimientos en comentarios',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
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
                      text: 'Positivos (${_porcPositivo.toInt()}%)',
                    ),
                    const SizedBox(height: 14),
                    _buildLegendIndicator(
                      color: const Color(0xFFE41E3F),
                      text: 'Negativos (${_porcNegativo.toInt()}%)',
                    ),
                    const SizedBox(height: 14),
                    _buildLegendIndicator(
                      color: _textSecondary,
                      text: 'Neutros (${_porcNeutro.toInt()}%)',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
      final fontSize = isTouched ? 17.0 : 13.0;
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
            color: const Color(0xFFE41E3F),
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
            color: _textSecondary,
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

  Widget _buildLegendIndicator({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildReactionsAndSummaryCard() {
    return Container(
      decoration: _analyticalCardDecoration(),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: _fbBlue),
              SizedBox(width: 8),
              Text(
                'Balance de reacciones y resumen general',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.sentiment_satisfied_alt_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Positivas: $_reacPositivo%',
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.sentiment_neutral_rounded, color: _fbBlue, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Neutras: $_reacNeutro%',
                    style: const TextStyle(
                      color: _fbBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.sentiment_very_dissatisfied_rounded, color: Color(0xFFE41E3F), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _meDivierteComoBurla
                        ? 'Negativas/burla: $_reacNegativo%'
                        : 'Negativas: $_reacNegativo%',
                    style: const TextStyle(
                      color: Color(0xFFE41E3F),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (_reacPositivo > 0)
                    Expanded(
                      flex: _reacPositivo,
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (_reacNeutro > 0)
                    Expanded(
                      flex: _reacNeutro,
                      child: Container(color: _fbBlue),
                    ),
                  if (_reacNegativo > 0)
                    Expanded(
                      flex: _reacNegativo,
                      child: Container(color: const Color(0xFFE41E3F)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          const Text(
            'Interpretación contextual con IA:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _resumenIA,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsTableCard() {
    final listaReacFiltrada = _reaccionesFiltradas;

    return Container(
      decoration: _analyticalCardDecoration(),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.thumb_up_alt_outlined, color: _fbBlue),
                  SizedBox(width: 8),
                  Text(
                    'Listado y desglose de reacciones por sentimiento',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'Mostrando ${listaReacFiltrada.length} tipos de reacción con actividad',
                style: const TextStyle(fontSize: 12.5, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final filtro in ['Todos', 'Positivos', 'Negativos', 'Neutros'])
                ChoiceChip(
                  label: Text(filtro),
                  selected: _filtroReacciones == filtro,
                  selectedColor: const Color(0xFFE7F3FF),
                  labelStyle: TextStyle(
                    color: _filtroReacciones == filtro ? _fbBlue : _textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _filtroReacciones = filtro;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (listaReacFiltrada.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text(
                  'No se registraron reacciones con el filtro seleccionado.',
                  style: TextStyle(color: _textSecondary),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(_bgAnalytical),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Tipo de reacción',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Cantidad y proporción',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Interpretación contextual (IA)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Sentimiento',
                          style: TextStyle(fontWeight: FontWeight.bold, color: _textPrimary),
                        ),
                      ),
                    ],
                    rows: listaReacFiltrada.map((item) {
                      final nombre = (item['reaccion'] ?? 'Me gusta').toString();
                      final cantidad = item['cantidad'] ?? 0;
                      final porcentaje = item['porcentaje'] ?? 0;
                      final explicacion = (item['explicacion'] ?? '').toString();
                      final sentiment = (item['sentiment'] ?? 'Positivo').toString();

                      Color badgeBg;
                      Color badgeText;
                      if (sentiment == 'Positivo') {
                        badgeBg = const Color(0xFFD1FAE5);
                        badgeText = const Color(0xFF065F46);
                      } else if (sentiment == 'Negativo') {
                        badgeBg = const Color(0xFFFFEBE8);
                        badgeText = const Color(0xFFE41E3F);
                      } else {
                        badgeBg = const Color(0xFFE2E8F0);
                        badgeText = _textPrimary;
                      }

                      final colorIcono = _colorPorReaccion(nombre);

                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: colorIcono.withValues(alpha: 0.12),
                                  child: Icon(
                                    _iconoPorReaccion(nombre),
                                    size: 16,
                                    color: colorIcono,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(
                              '$cantidad usuarios ($porcentaje%)',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 400,
                              child: Text(
                                explicacion,
                                style: const TextStyle(fontSize: 13, color: _textSecondary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                sentiment,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: badgeText,
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
    );
  }

  Widget _buildCommentsTableCard() {
    final listaFiltrada = _comentariosFiltrados;

    return Container(
      decoration: _analyticalCardDecoration(),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.forum_outlined, color: _fbBlue),
                  SizedBox(width: 8),
                  Text(
                    'Listado de comentarios analizados',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'Mostrando ${listaFiltrada.length} de ${_comments.length} comentarios',
                style: const TextStyle(fontSize: 12.5, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final filtro in ['Todos', 'Positivos', 'Negativos', 'Neutros'])
                ChoiceChip(
                  label: Text(filtro),
                  selected: _filtroSentimiento == filtro,
                  selectedColor: const Color(0xFFE7F3FF),
                  labelStyle: TextStyle(
                    color: _filtroSentimiento == filtro ? _fbBlue : _textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _filtroSentimiento = filtro;
                    });
                  },
                ),
              SizedBox(
                width: 280,
                height: 38,
                child: TextField(
                  controller: _searchCommentController,
                  onChanged: (val) {
                    setState(() {
                      _busquedaTexto = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar por usuario o palabra...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    filled: true,
                    fillColor: _bgAnalytical,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (listaFiltrada.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28.0),
              child: Center(
                child: Text(
                  'No hay comentarios que coincidan con el filtro seleccionado.',
                  style: TextStyle(color: _textSecondary),
                ),
              ),
            )
          else
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(_bgAnalytical),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Nombre del usuario',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Comentario',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Sentimiento',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                    ],
                    rows: listaFiltrada.map((item) {
                      final username = (item['username'] ?? 'Usuario').toString();
                      final commentText = (item['comment'] ?? '').toString();
                      final sentiment = (item['sentiment'] ?? 'Neutro').toString();

                      Color badgeBg;
                      Color badgeText;
                      if (sentiment == 'Positivo') {
                        badgeBg = const Color(0xFFD1FAE5);
                        badgeText = const Color(0xFF065F46);
                      } else if (sentiment == 'Negativo') {
                        badgeBg = const Color(0xFFFFEBE8);
                        badgeText = const Color(0xFFE41E3F);
                      } else {
                        badgeBg = const Color(0xFFE2E8F0);
                        badgeText = _textPrimary;
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
                                  radius: 13,
                                  backgroundColor: const Color(0xFFE7F3FF),
                                  child: Text(
                                    inicial,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _fbBlue,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 480,
                              child: Text(
                                commentText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                sentiment,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: badgeText,
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
    );
  }
}