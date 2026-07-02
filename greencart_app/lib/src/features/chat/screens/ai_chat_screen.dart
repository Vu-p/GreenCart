import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/features/chat/data/chat_service.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  static const routePath = '/ai-chat';

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Welcome message
    _messages.add(ChatMessage(
      role: 'model',
      text:
          'Xin chào bạn! 🌿 Mình là **GreenCart Nutritionist** — trợ lý dinh dưỡng & mua sắm thông minh.\n\nMình có thể giúp bạn:\n• 🥗 Tư vấn dinh dưỡng & thực đơn\n• 📋 Lên kế hoạch bữa ăn (Meal Plan)\n• 🔄 Gợi ý thay thế sản phẩm\n• 📦 Hỏi đáp về sản phẩm & đơn hàng\n\nBạn cần hỗ trợ gì nào? 😊',
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(role: 'user', text: text));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final reply = await ref.read(chatServiceProvider).sendMessage(text);
      setState(() {
        _messages.add(ChatMessage(role: 'model', text: reply));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
            role: 'model',
            text: 'Xin lỗi, đã xảy ra lỗi. Vui lòng thử lại! 🔄'));
        _isTyping = false;
      });
    }
    _scrollToBottom();
  }

  void _clearChat() {
    ref.read(chatServiceProvider).clearHistory();
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        role: 'model',
        text: 'Cuộc trò chuyện đã được làm mới! 🌿 Bạn cần mình hỗ trợ gì nào?',
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFE9F5EE),
              child: Text('🌿', style: TextStyle(fontSize: 20)),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GreenCart AI',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                Text('Trợ lý Dinh dưỡng & Mua sắm',
                    style: TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Làm mới cuộc trò chuyện',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick suggestion chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickChip(
                    label: '🥗 Thực đơn giảm cân',
                    onTap: () {
                      _controller.text = 'Gợi ý thực đơn giảm cân 1 ngày';
                      _sendMessage();
                    },
                  ),
                  _QuickChip(
                    label: '🔄 Thay thế sản phẩm',
                    onTap: () {
                      _controller.text =
                          'Sản phẩm nào có thể thay thế nhau trong cửa hàng?';
                      _sendMessage();
                    },
                  ),
                  _QuickChip(
                    label: '🌱 Organic dưới 50k',
                    onTap: () {
                      _controller.text =
                          'Liệt kê sản phẩm organic giá dưới 50.000đ';
                      _sendMessage();
                    },
                  ),
                  _QuickChip(
                    label: '📋 Meal Plan tuần',
                    onTap: () {
                      _controller.text =
                          'Lên kế hoạch bữa ăn 1 tuần cho gia đình 4 người';
                      _sendMessage();
                    },
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return const _TypingIndicator();
                }
                final msg = _messages[index];
                return _ChatBubble(message: msg);
              },
            ),
          ),

          // Input bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Hỏi về dinh dưỡng, sản phẩm, meal plan...',
                        hintStyle: TextStyle(
                            fontSize: 14, color: Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006A38), Color(0xFF00C853)],
                      ),
                      borderRadius: BorderRadius.circular(23),
                      boxShadow: [
                        BoxShadow(
                          color:
                              const Color(0xFF006A38).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isTyping ? Icons.hourglass_top : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE9F5EE),
              child: Text('🌿', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF006A38) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft:
                      isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight:
                      isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SelectableText(
                message.text,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  color: isUser ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF006A38),
              child: Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE9F5EE),
            child: Text('🌿', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF006A38),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Đang suy nghĩ...',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        onPressed: onTap,
        backgroundColor: const Color(0xFFE9F5EE),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      ),
    );
  }
}
