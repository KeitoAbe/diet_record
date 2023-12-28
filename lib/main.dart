import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await initializeDateFormatting('ja_JP', null);
  Intl.defaultLocale = 'ja_JP';
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: '食事記録',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("ja", "JP"),
      ],
      home: const DietRecord(title: '食事記録'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DietRecord extends StatefulWidget {
  const DietRecord({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<DietRecord> createState() => _DietRecordState();
}

class DailyRecord {
  String breakfast;
  String lunch;
  String dinner;
  String snack;
  String weight;
  String bodyFat;

  DailyRecord({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
    required this.weight,
    required this.bodyFat,
  });
}

class _DietRecordState extends State<DietRecord> {
  Map<String, DailyRecord> records = {};
  List<DateTime> dates = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeDates();
      loadDietRecords();
    });
  }

  void initializeDates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    DateTime? firstDate = prefs.getString('firstDate') != null
        ? DateTime.parse(prefs.getString('firstDate')!)
        : null;

    if (firstDate == null) {
      firstDate = DateTime.now();
      await prefs.setString('firstDate', firstDate.toIso8601String());
    }

    DateTime currentDate = DateTime.now();
    while (currentDate.isAfter(firstDate)) {
      dates.add(currentDate);
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    setState(() {});
  }

  void loadDietRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      for (DateTime date in dates) {
        String dateKey = DateFormat('yyyyMMdd').format(date);
        records[dateKey] = DailyRecord(
          breakfast: prefs.getString('breakfast_$dateKey') ?? '',
          lunch: prefs.getString('lunch_$dateKey') ?? '',
          dinner: prefs.getString('dinner_$dateKey') ?? '',
          snack: prefs.getString('snack_$dateKey') ?? '',
          weight: prefs.getString('weight_$dateKey') ?? '',
          bodyFat: prefs.getString('bodyFat_$dateKey') ?? '',
        );
      }
    });
  }

  void navigateToDetailPage(BuildContext context, DateTime date) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DetailPage(date: date),
      ),
    );
    if (result == 'saved') {
      loadDietRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: dates.length,
        itemBuilder: (context, index) {
          String dateKey = DateFormat('yyyyMMdd').format(dates[index]);
          return Card(
            child: ListTile(
              title: Text(
                '${dates[index].month}月${dates[index].day}日 (${DateFormat('E', 'ja_JP').format(dates[index])})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                (records[dateKey]?.breakfast.isNotEmpty ?? false) ||
                        (records[dateKey]?.lunch.isNotEmpty ?? false) ||
                        (records[dateKey]?.dinner.isNotEmpty ?? false) ||
                        (records[dateKey]?.snack.isNotEmpty ?? false) ||
                        (records[dateKey]?.weight.isNotEmpty ?? false) ||
                        (records[dateKey]?.bodyFat.isNotEmpty ?? false)
                    ? '${records[dateKey]?.breakfast.isNotEmpty ?? false ? '朝食: ${records[dateKey]?.breakfast.replaceAll('\n', '\n          ')}\n' : ''}'
                            '${records[dateKey]?.lunch.isNotEmpty ?? false ? '昼食: ${records[dateKey]?.lunch.replaceAll('\n', '\n          ')}\n' : ''}'
                            '${records[dateKey]?.dinner.isNotEmpty ?? false ? '夕食: ${records[dateKey]?.dinner.replaceAll('\n', '\n          ')}\n' : ''}'
                            '${records[dateKey]?.snack.isNotEmpty ?? false ? '間食: ${records[dateKey]?.snack.replaceAll('\n', '\n          ')}\n' : ''}'
                            '${records[dateKey]?.weight.isNotEmpty ?? false ? '体重: ${records[dateKey]?.weight}kg\n' : ''}'
                            '${records[dateKey]?.bodyFat.isNotEmpty ?? false ? '体脂肪率: ${records[dateKey]?.bodyFat}%\n' : ''}'
                        .trim()
                    : '記録なし',
              ),
              onTap: () => navigateToDetailPage(context, dates[index]),
            ),
          );
        },
      ),
    );
  }
}

class _DetailPage extends StatefulWidget {
  final DateTime date;

  const _DetailPage({Key? key, required this.date}) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<_DetailPage> {
  final breakfastController = TextEditingController();
  final lunchController = TextEditingController();
  final dinnerController = TextEditingController();
  final snackController = TextEditingController();
  final weightController = TextEditingController();
  final bodyFatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadDetailPageData();
    });
  }

  void loadDetailPageData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dateKey = DateFormat('yyyyMMdd').format(widget.date);
    breakfastController.text = prefs.getString('breakfast_$dateKey') ?? '';
    lunchController.text = prefs.getString('lunch_$dateKey') ?? '';
    dinnerController.text = prefs.getString('dinner_$dateKey') ?? '';
    snackController.text = prefs.getString('snack_$dateKey') ?? '';
    weightController.text = prefs.getString('weight_$dateKey') ?? '';
    bodyFatController.text = prefs.getString('bodyFat_$dateKey') ?? '';
  }

  Future<void> saveDataAndReload() async {
    final contextBeforeAsync = context;
    Navigator.pop(contextBeforeAsync);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String dateKey = DateFormat('yyyyMMdd').format(widget.date);
    await prefs.setString('breakfast_$dateKey', breakfastController.text);
    await prefs.setString('lunch_$dateKey', lunchController.text);
    await prefs.setString('dinner_$dateKey', dinnerController.text);
    await prefs.setString('snack_$dateKey', snackController.text);
    await prefs.setString('weight_$dateKey', weightController.text);
    await prefs.setString('bodyFat_$dateKey', bodyFatController.text);

    Fluttertoast.showToast(
      msg: "保存しました",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );

    // Add this line to reload the top page after saving.
    navigatorKey.currentState!.pushReplacement(
      MaterialPageRoute(builder: (context) => const DietRecord(title: '食事記録')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.date.month}月${widget.date.day}日 (${DateFormat('E', 'ja_JP').format(widget.date)})'),
        actions: <Widget>[
          TextButton(
            child: const Text('保存'),
            onPressed: () => saveDataAndReload(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: <Widget>[
            _buildTextField('朝食',
                controller: breakfastController,
                maxLines: null,
                keyboardType: TextInputType.multiline),
            _buildTextField('昼食',
                controller: lunchController,
                maxLines: null,
                keyboardType: TextInputType.multiline),
            _buildTextField('夕食',
                controller: dinnerController,
                maxLines: null,
                keyboardType: TextInputType.multiline),
            _buildTextField('間食',
                controller: snackController,
                maxLines: null,
                keyboardType: TextInputType.multiline),
            _buildTextField('体重 (kg)',
                controller: weightController,
                keyboardType: TextInputType.number),
            _buildTextField('体脂肪率 (%)',
                controller: bodyFatController,
                keyboardType: TextInputType.number),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label,
      {required TextEditingController controller,
      TextInputType keyboardType = TextInputType.text,
      int? maxLines}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 18.0),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }
}
