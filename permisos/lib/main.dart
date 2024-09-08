import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pedometer/pedometer.dart';
import 'package:charts_flutter/flutter.dart' as charts;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StepCounterPage(),
    );
  }
}

class StepCounterPage extends StatefulWidget {
  @override
  _StepCounterPageState createState() => _StepCounterPageState();
}

class _StepCounterPageState extends State<StepCounterPage> {
  int _steps = 0;
  double _caloriesBurned = 0.0;
  Stream<StepCount>? _stepCountStream;
  List<charts.Series<int, String>> _seriesList = [];
  bool _stepCountAvailable = false; // New variable to track availability

  List<int> _stepsData = List.generate(7, (index) => 0);

  @override
  void initState() {
    super.initState();
    _requestPermission();
    _initPedometer();
    _updateGraph();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSyncNotice();
    });
  }

  void _showSyncNotice() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sincronización de Datos'),
          content: const Text(
            'Esta aplicación utiliza Internet para sincronizar tus datos de fitness con el servidor. Asegúrate de estar conectado a una red Wi-Fi o tener datos móviles disponibles.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Entendido'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _requestPermission() async {
    PermissionStatus status = await Permission.activityRecognition.request();
    if (status != PermissionStatus.granted) {
      print("Permiso no concedido");
    }
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    if (_stepCountStream != null) {
      _stepCountAvailable = true;
      _stepCountStream?.listen(_onStepCount).onError((error) {
        print("Error: $error");
      });
    } else {
      _stepCountAvailable = false;
    }
  }

  void _onStepCount(StepCount event) {
    setState(() {
      _steps = event.steps;
      _caloriesBurned = _steps / 20.0;
      _updateGraph();
    });
  }

  void _updateGraph() {
    int dayOfWeek = DateTime.now().weekday - 1;
    _stepsData[dayOfWeek] = _steps;

    _seriesList = [
      charts.Series<int, String>(
        id: 'Steps',
        colorFn: (_, __) => charts.MaterialPalette.deepOrange.shadeDefault,
        domainFn: (int steps, index) => _getDayLabel(index!),
        measureFn: (int steps, _) => steps,
        data: _stepsData,
      ),
    ];
  }

  String _getDayLabel(int index) {
    const List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[index];
  }

  Future<void> _refreshSteps() async {
    if (_stepCountAvailable) {
      _initPedometer();
    } else {
      _showErrorNotification();
    }
  }

  void _showErrorNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
            'Datos de pasos no disponibles. Asegúrate de que el dispositivo es compatible.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Contador de Pasos')),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Text(
              'Haz caminado ${_steps.toString()} pasos hoy',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              'Calorías quemadas: ${_caloriesBurned.toStringAsFixed(2)} cal',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              value: _steps / 10000,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
              strokeWidth: 10,
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('${_caloriesBurned.toStringAsFixed(2)} cal',
                        style: const TextStyle(fontSize: 18)),
                    const Text('Cal quemadas',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text('Estadística',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(
              height: 250,
              child: charts.BarChart(
                _seriesList,
                animate: true,
                domainAxis: const charts.OrdinalAxisSpec(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshSteps,
              child: const Text('Sincronizar'),
            ),
          ],
        ),
      ),
    );
  }
}
