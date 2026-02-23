import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/event_model.dart';
import '../data/calendar_repository.dart';
import 'widgets/add_event_sheet.dart';
import '../../todo/presentation/todo_list_widget.dart';
import 'event_detail_screen.dart';
import '../../../core/widgets/ad_banner_widget.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  final String coupleId;
  const CalendarScreen({super.key, required this.coupleId});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<EventModel> _allEvents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _refreshEvents();
  }

  Future<void> _refreshEvents() async {
    setState(() => _isLoading = true);
    final repo = ref.read(calendarRepositoryProvider);
    // 1. 먼저 로컬 데이터 로드
    final localEvents = await repo.getLocalEvents(widget.coupleId);
    setState(() {
      _allEvents = localEvents;
      _isLoading = false;
    });

    // 2. 백그라운드에서 동기화
    await repo.syncEvents(widget.coupleId);
    
    // 3. 업데이트된 로컬 데이터 다시 로드
    final syncedEvents = await repo.getLocalEvents(widget.coupleId);
    if (mounted) {
      setState(() {
        _allEvents = syncedEvents;
      });
    }
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return _allEvents.where((e) => isSameDay(e.date, day)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('우리의 달력'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _refreshEvents,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: const CalendarStyle(
                    markerDecoration: BoxDecoration(
                      color: Color(0xFFFF85A1),
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: Color(0xFFFFB3C1),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Color(0xFFFF85A1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const Divider(height: 1),
                TodoListWidget(coupleId: widget.coupleId),
                const Divider(height: 1),
                Expanded(
                  child: _buildEventList(),
                ),
              ],
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventSheet(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventList() {
    final events = _getEventsForDay(_selectedDay!);
    if (events.isEmpty) {
      return const Center(child: Text('일정이 없습니다.'));
    }
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailScreen(event: event),
              ),
            );
          },
          leading: CircleAvatar(
            backgroundColor: _getColor(event.colorIndex),
          ),
          title: Text(event.title),
          subtitle: Text(event.description ?? ''),
        );
      },
    );
  }

  void _showAddEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return AddEventSheet(
          selectedDay: _selectedDay!,
          coupleId: widget.coupleId,
          onSave: (event) async {
            final repo = ref.read(calendarRepositoryProvider);
            await repo.addEvent(event);
            _refreshEvents();
          },
        );
      },
    );
  }

  Color _getColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}
