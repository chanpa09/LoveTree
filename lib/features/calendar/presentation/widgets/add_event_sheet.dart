import 'package:flutter/material.dart';
import '../../../../core/models/event_model.dart';

class AddEventSheet extends StatefulWidget {
  final DateTime selectedDay;
  final String coupleId;
  final Function(EventModel) onSave;

  const AddEventSheet({
    super.key,
    required this.selectedDay,
    required this.coupleId,
    required this.onSave,
  });

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  int _selectedColorIndex = 0;

  final List<Color> _colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.red,
    Colors.purple,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '새 일정 추가',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '일정 제목',
              hintText: '예: 마트 장보기, 병원 예약 등',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: '상세 설명 (선택)',
            ),
          ),
          const SizedBox(height: 20),
          const Text('색상 선택'),
          const SizedBox(height: 10),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _colors[index],
                      shape: BoxShape.circle,
                      border: _selectedColorIndex == index
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.isEmpty) return;
                
                final event = EventModel(
                  id: '', // 리포지토리에서 생성
                  coupleId: widget.coupleId,
                  title: _titleController.text,
                  description: _descController.text,
                  date: widget.selectedDay,
                  colorIndex: _selectedColorIndex,
                  updatedAt: DateTime.now(),
                );
                widget.onSave(event);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('저장하기'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
