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
