import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const BaesuJinApp());
}

String _two(int n) => n.toString().padLeft(2, '0');

String _hm(int minutes) => '${minutes ~/ 60}시간 ${minutes % 60}분';

String _hms(Duration d) {
  final total = d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  return '${_two(h)}:${_two(m)}:${_two(s)}';
}

String _formatDate(DateTime d) {
  return '${d.year}-${_two(d.month)}-${_two(d.day)} ${_two(d.hour)}:${_two(d.minute)}';
}

class SavedInput {
  final DateTime deadline;
  final int lifeMinutes;
  final int studyMinutes;
  final String grade;
  final DateTime savedAt;

  const SavedInput({
    required this.deadline,
    required this.lifeMinutes,
    required this.studyMinutes,
    required this.grade,
    required this.savedAt,
  });
}

class BaesuJinApp extends StatelessWidget {
  const BaesuJinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '배수의 진',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const InputScreen(),
    );
  }
}

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  DateTime? _deadline;
  String? _grade;
  final _lifeHourController = TextEditingController();
  final _lifeMinuteController = TextEditingController();
  final _studyHourController = TextEditingController();
  final _studyMinuteController = TextEditingController();

  static const List<String> _grades = [
    'A+', 'A', 'B+', 'B', 'C+', 'C', 'D+', 'D', 'F',
  ];

  @override
  void dispose() {
    _lifeHourController.dispose();
    _lifeMinuteController.dispose();
    _studyHourController.dispose();
    _studyMinuteController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !mounted) return;
    setState(() {
      _deadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  int? _toInt(String text) {
    final t = text.trim();
    if (t.isEmpty) return 0;
    return int.tryParse(t);
  }

  bool _bothEmpty(TextEditingController a, TextEditingController b) {
    return a.text.trim().isEmpty && b.text.trim().isEmpty;
  }

  void _save() {
    final now = DateTime.now();
    final deadline = _deadline;

    if (deadline == null) {
      _showMessage('마감 시각을 선택하세요.');
      return;
    }
    if (!deadline.isAfter(now)) {
      _showMessage('마감 시각은 지금보다 뒤여야 합니다.');
      return;
    }

    final lifeHour = _toInt(_lifeHourController.text);
    final lifeMinute = _toInt(_lifeMinuteController.text);
    final studyHour = _toInt(_studyHourController.text);
    final studyMinute = _toInt(_studyMinuteController.text);
    if (lifeHour == null || lifeMinute == null || studyHour == null || studyMinute == null) {
      _showMessage('시간과 분에는 숫자만 입력하세요.');
      return;
    }

    if (_bothEmpty(_lifeHourController, _lifeMinuteController)) {
      _showMessage('필수 생활 시간을 입력하세요.');
      return;
    }
    if (lifeHour < 0 || lifeMinute < 0) {
      _showMessage('필수 생활 시간은 음수일 수 없습니다.');
      return;
    }
    final lifeTotal = lifeHour * 60 + lifeMinute;

    final studyTotal = studyHour * 60 + studyMinute;
    if (studyHour < 0 || studyMinute < 0 || studyTotal <= 0) {
      _showMessage('필요한 공부 시간은 0보다 커야 합니다.');
      return;
    }

    final grade = _grade;
    if (grade == null) {
      _showMessage('마감 성적 기준을 선택하세요.');
      return;
    }

    final saved = SavedInput(
      deadline: deadline,
      lifeMinutes: lifeTotal,
      studyMinutes: studyTotal,
      grade: grade,
      savedAt: now,
    );
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TimerScreen(data: saved)),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _numberField(TextEditingController controller, String unit) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(signed: true),
      decoration: InputDecoration(
        labelText: unit,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _hourMinuteRow(
    TextEditingController hourController,
    TextEditingController minuteController,
  ) {
    return Row(
      children: [
        Expanded(child: _numberField(hourController, '시간')),
        const SizedBox(width: 12),
        Expanded(child: _minuteField(minuteController)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('배수의 진 · 입력')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('마감 시각'),
            OutlinedButton(
              onPressed: _pickDeadline,
              child: Text(
                _deadline == null ? '날짜·시각 선택' : _formatDate(_deadline!),
              ),
            ),
            _label('필수 생활 시간'),
            _hourMinuteRow(_lifeHourController, _lifeMinuteController),
            _label('필요한 공부 시간'),
            _hourMinuteRow(_studyHourController, _studyMinuteController),
            _label('마감 성적 기준'),
            DropdownButton<String>(
              isExpanded: true,
              value: _grade,
              hint: const Text('선택하세요'),
              items: _grades
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _grade = value;
                });
              },
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('저장')),
          ],
        ),
      ),
    );
  }
}

class TimerScreen extends StatelessWidget {
  final SavedInput data;

  const TimerScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final untilDeadline = data.deadline.difference(data.savedAt);
    final remainingPlay = untilDeadline -
        Duration(minutes: data.lifeMinutes) -
        Duration(minutes: data.studyMinutes);
    final noPlay = remainingPlay <= Duration.zero;
    final saved = data.savedAt;
    final savedTime =
        '${_two(saved.hour)}:${_two(saved.minute)}:${_two(saved.second)}';

    return Scaffold(
      appBar: AppBar(title: const Text('배수의 진 · 타이머')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('남은 놀 시간', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              _hms(noPlay ? Duration.zero : remainingPlay),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
            if (noPlay) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade100,
                child: Text(
                  '놀 시간이 없습니다. 학점 ${data.grade}를 지키려면 지금 공부해야 합니다.',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('저장한 시각: $savedTime'),
            Text('마감 시각: ${_formatDate(data.deadline)}'),
            Text('마감까지(저장 시점): ${_hms(untilDeadline)}'),
            Text('필수 생활 시간: ${_hm(data.lifeMinutes)}'),
            Text('필요한 공부 시간: ${_hm(data.studyMinutes)}'),
            Text('마감 성적 기준: ${data.grade}'),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('다시 입력'),
            ),
          ],
        ),
      ),
    );
  }
}

class MinuteRangeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text);
    if (n == null || n > 59) return oldValue;
    return newValue;
  }
}

Widget _minuteField(TextEditingController controller) {
  return TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(2),
      MinuteRangeFormatter(),
    ],
    decoration: const InputDecoration(
      labelText: '분 (0~59)',
      border: OutlineInputBorder(),
    ),
  );
}