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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
        left: 30,
        right: 30,
        top: 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '새로운 일정 🌸',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: '어떤 일정인가요?',
              labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              hintText: '예: 우리의 첫 캠핑, 맛집 탐방 등',
              hintStyle: TextStyle(color: Colors.grey.shade300, fontWeight: FontWeight.normal),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: '상세를 남겨주세요 (선택)',
              labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            '포인트 색상',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedColorIndex == index;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 15),
                    width: isSelected ? 48 : 40,
                    height: isSelected ? 48 : 40,
                    decoration: BoxDecoration(
                      color: _colors[index],
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: _colors[index].withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                      border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
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
            child: const Text('반영하기'),
          ),
        ],
      ),
    );
  }
}
