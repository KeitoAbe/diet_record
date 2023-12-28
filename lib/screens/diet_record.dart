import 'package:diet_record/models/daily_record.dart';
import 'package:diet_record/screens/detail_page.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

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
    var box = await Hive.openBox('appData');
    DateTime? firstDate = box.get('firstDate') != null
        ? DateTime.parse(box.get('firstDate'))
        : null;

    if (firstDate == null) {
      firstDate = DateTime.now();
      await box.put('firstDate', firstDate.toIso8601String());
    }

    DateTime currentDate = DateTime.now();
    while (currentDate.isAfter(firstDate)) {
      dates.add(currentDate);
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    setState(() {});
  }

  void loadDietRecords() async {
    var box = await Hive.openBox('dietRecords');
    setState(() {
      for (DateTime date in dates) {
        String dateKey = DateFormat('yyyyMMdd').format(date);
        var record = box.get(dateKey);
        if (record != null) {
          records[dateKey] = DailyRecord(
            breakfast: record['breakfast'] ?? '',
            lunch: record['lunch'] ?? '',
            dinner: record['dinner'] ?? '',
            snack: record['snack'] ?? '',
            weight: record['weight'] ?? '',
            bodyFat: record['bodyFat'] ?? '',
          );
        }
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
