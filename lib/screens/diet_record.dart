import 'package:diet_record/models/daily_record.dart';
import 'package:diet_record/screens/detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DietRecord extends StatefulWidget {
  const DietRecord({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<DietRecord> createState() => _DietRecordState();
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
        builder: (context) => DetailPage(date: date),
      ),
    );
    if (result == 'saved') {
      loadDietRecords();
    }
  }

  String getRecordText(String field, String label) {
    return field.isNotEmpty
        ? '$label: ${field.replaceAll('\n', '\n          ')}\n'
        : '';
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
              subtitle: Builder(
                builder: (BuildContext context) {
                  final record = records[dateKey];
                  if (record == null) {
                    return const Text('記録なし');
                  }

                  final text = getRecordText(record.breakfast, '朝食') +
                      getRecordText(record.lunch, '昼食') +
                      getRecordText(record.dinner, '夕食') +
                      getRecordText(record.snack, '間食') +
                      getRecordText(record.weight, '体重') +
                      getRecordText(record.bodyFat, '体脂肪率');

                  return Text(text.isEmpty ? '記録なし' : text.trim());
                },
              ),
              onTap: () => navigateToDetailPage(context, dates[index]),
            ),
          );
        },
      ),
    );
  }
}
