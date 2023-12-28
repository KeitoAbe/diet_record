import 'package:diet_record/main.dart';
import 'package:diet_record/screens/diet_record.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class DetailPage extends StatefulWidget {
  final DateTime date;

  const DetailPage({Key? key, required this.date}) : super(key: key);

  @override
  DetailPageState createState() => DetailPageState();
}

class DetailPageState extends State<DetailPage> {
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
    var box = await Hive.openBox('dietRecords');
    String dateKey = DateFormat('yyyyMMdd').format(widget.date);
    var record = box.get(dateKey);
    if (record != null) {
      breakfastController.text = record['breakfast'] ?? '';
      lunchController.text = record['lunch'] ?? '';
      dinnerController.text = record['dinner'] ?? '';
      snackController.text = record['snack'] ?? '';
      weightController.text = record['weight'] ?? '';
      bodyFatController.text = record['bodyFat'] ?? '';
    }
  }

  Future<void> saveDataAndReload() async {
    final contextBeforeAsync = context;
    Navigator.pop(contextBeforeAsync);
    var box = await Hive.openBox('dietRecords');
    String dateKey = DateFormat('yyyyMMdd').format(widget.date);
    await box.put(dateKey, {
      'breakfast': breakfastController.text,
      'lunch': lunchController.text,
      'dinner': dinnerController.text,
      'snack': snackController.text,
      'weight': weightController.text,
      'bodyFat': bodyFatController.text,
    });

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
