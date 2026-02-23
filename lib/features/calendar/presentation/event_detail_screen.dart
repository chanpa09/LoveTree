import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/event_model.dart';
import '../../../core/models/comment_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/auth_repository.dart';

String _formatKoreanDateFull(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final wd = weekdays[date.weekday - 1];
  return '${date.year}년 ${date.month}월 ${date.day}일 ($wd)';
}

String _formatTime(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

/// 특정 일정의 상세 정보를 보여주고, 커플 간의 실시간 댓글(마이크로 채팅)을 지원하는 화면입니다.
class EventDetailScreen extends ConsumerStatefulWidget {
  /// 상세 내용을 표시할 대상 일정 모델
  final EventModel event;
  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  /// 댓글 입력을 위한 텍스트 컨트롤러
  final _commentController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  /// 채팅 리스트의 자동 스크롤을 제어하기 위한 스크롤 컨트롤러
  final _scrollController = ScrollController();

  /// 새로운 댓글을 작성하여 Firestore에 업로드합니다.
  /// 업로드 후에는 최신 메시지가 보이도록 자동으로 스크롤을 하단으로 이동시킵니다.
  void _addComment() async {
    if (_commentController.text.isEmpty) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    final comment = CommentModel(
      id: '', // Firestore 자동 생성을 위해 빈 값 전달
      eventId: widget.event.id,
      authorId: user.uid,
      content: _commentController.text,
      createdAt: DateTime.now(),
    );

    // [Step 1] Firestore의 하위 컬렉션 'comments'에 새 댓글 추가
    await _firestore
        .collection('events')
        .doc(widget.event.id)
        .collection('comments')
        .add(comment.toFirestore());

    _commentController.clear();

    // [Step 2] 새 메시지 작성 후 부드럽게 스크롤 하단으로 이동
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final eventColor = _getColor(widget.event.colorIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // ── 상단: 이벤트 정보 요약 헤더 카드 ──
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  eventColor.withOpacity(0.12),
                  eventColor.withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: eventColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // 일정 색상 아이콘
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: eventColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Icon(
                    Icons.event_rounded,
                    color: eventColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            _formatKoreanDateFull(widget.event.date),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppTheme.darkTextSecondary
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (widget.event.description?.isNotEmpty ??
                          false) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.event.description!,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 중간 섹션: 실시간 댓글 영역 제목 ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '댓글 / 마이크로 채팅',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // ── 하단: 실시간 업데이트되는 댓글 리스트 (StreamBuilder) ──
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('events')
                  .doc(widget.event.id)
                  .collection('comments')
                  .orderBy('created_at', descending: false) // 과거 메시지가 위로
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppTheme.primary,
                    ),
                  );
                }

                final comments = snapshot.data!.docs
                    .map((doc) => CommentModel.fromFirestore(doc))
                    .toList();

                // 댓글이 하나도 없는 경우 안내 위젯 표시
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 56,
                          color: AppTheme.textHint.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '첫 댓글을 남겨보세요! 💬',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '이 일정에 대해 이야기해보세요',
                          style: TextStyle(
                            color: AppTheme.textHint.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 채팅 형식의 리스트 빌더
                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isMe = comment.authorId ==
                        ref
                            .read(authRepositoryProvider)
                            .currentUser
                            ?.uid;

                    return _buildChatBubble(
                        comment, isMe, isDark);
                  },
                );
              },
            ),
          ),

          // ── 최하단: 메시지 입력창 ──
          _buildMessageInput(isDark),
        ],
      ),
    );
  }

  /// 나(Right)와 상대방(Left)을 구분하여 보여주는 말풍선 위젯을 생성합니다.
  Widget _buildChatBubble(
      CommentModel comment, bool isMe, bool isDark) {
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isMe
              ? const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isMe
              ? null
              : (isDark
                  ? AppTheme.darkSurfaceVariant
                  : const Color(0xFFF5F5F8)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft:
                isMe ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight:
                isMe ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: isMe
                  ? AppTheme.primary.withOpacity(0.15)
                  : Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              comment.content,
              style: TextStyle(
                color: isMe
                    ? Colors.white
                    : (isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(comment.createdAt),
              style: TextStyle(
                color: isMe
                    ? Colors.white.withOpacity(0.7)
                    : AppTheme.textHint.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 메시지 입력창 영역 위젯 빌더
  Widget _buildMessageInput(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        left: 16,
        right: 12,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.darkSurfaceVariant
                    : const Color(0xFFF8F8FA),
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusL),
              ),
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  hintStyle: TextStyle(
                    color: AppTheme.textHint,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                onSubmitted: (_) => _addComment(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 전송 버튼
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
              onPressed: _addComment,
            ),
          ),
        ],
      ),
    );
  }

  /// 인덱스에 따른 브랜드 컬러 팔레트를 반환합니다.
  Color _getColor(int index) {
    return AppTheme.eventColors[index % AppTheme.eventColors.length];
  }
}
