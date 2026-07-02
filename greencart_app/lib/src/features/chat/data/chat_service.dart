import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greencart_app/src/core/services/api_client.dart';
import 'package:greencart_app/src/features/catalog/data/product_repository.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref);
});

class ChatMessage {
  ChatMessage({required this.role, required this.text, this.isLoading = false});

  final String role; // 'user' or 'model'
  final String text;
  final bool isLoading;
}

class ChatService {
  ChatService(this._ref);

  final Ref _ref;
  final List<Map<String, dynamic>> _history = [];

  Future<String> _buildProductContext() async {
    try {
      final products =
          await _ref.read(productRepositoryProvider).getProducts();
      if (products.isEmpty) return '';

      final buffer = StringBuffer();
      buffer.writeln(
          'Danh sách sản phẩm hiện có trong cửa hàng GreenCart (dùng VNĐ):');
      for (final p in products) {
        final price =
            '${p.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} đ';
        final tags = <String>[];
        if (p.isOrganic) tags.add('Hữu cơ');
        if (p.isDeal) tags.add('Đang giảm giá');
        if (p.stock <= 0) tags.add('Hết hàng');
        buffer.writeln(
            '- ${p.name}: $price | Danh mục: ${p.categoryName} | Tồn kho: ${p.stock} ${tags.isNotEmpty ? "| ${tags.join(", ")}" : ""}');
      }
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  Future<String> sendMessage(String userMessage) async {
    // Build product context on first message
    if (_history.isEmpty) {
      final productContext = await _buildProductContext();
      final systemPrompt = '''
Bạn là **GreenCart Nutritionist** 🌿 — chuyên gia dinh dưỡng thực vật thông minh kiêm trợ lý mua sắm của cửa hàng thực phẩm xanh GreenCart.

Nhiệm vụ chính:
1. **Tư vấn dinh dưỡng**: Gợi ý thực đơn ăn uống lành mạnh, giải đáp thắc mắc dinh dưỡng bằng **tiếng Việt** thân thiện.
2. **Gợi ý Meal Plan (Kế hoạch bữa ăn)**: Khi khách muốn lên thực đơn tuần/ngày, hãy đề xuất các bữa ăn cụ thể kèm sản phẩm có trong cửa hàng, phù hợp mục tiêu (giảm cân, tăng cơ, ăn chay, v.v.).
3. **Tư vấn Thay thế Sản phẩm (Substitution)**: Khi khách hỏi thay thế một sản phẩm, hãy gợi ý sản phẩm cùng loại hoặc tương tự trong cửa hàng, ưu tiên giá rẻ hơn hoặc sản phẩm hữu cơ.
4. **Hỗ trợ Hỏi đáp Sản phẩm & Đơn hàng**: Giải đáp câu hỏi về sản phẩm (giá, tồn kho, hữu cơ hay không), cách đặt hàng, thanh toán, giao hàng. Nếu vấn đề phức tạp, hướng dẫn liên hệ hotline.
5. Khi gợi ý sản phẩm, **chỉ gợi ý các sản phẩm có trong danh sách dưới đây** và kèm giá.
6. Trả lời ngắn gọn, dễ hiểu, có emoji cho sinh động. Dùng bullet points khi liệt kê.
7. Nếu không biết hoặc không chắc, hãy nói rõ thay vì bịa đặt.

$productContext
''';
      _history.add({
        'role': 'user',
        'parts': [
          {'text': '[SYSTEM CONTEXT]\n$systemPrompt\n[END SYSTEM CONTEXT]\n\nXin chào!'}
        ]
      });
      _history.add({
        'role': 'model',
        'parts': [
          {
            'text':
                'Xin chào bạn! 🌿 Mình là GreenCart Nutritionist — trợ lý dinh dưỡng của cửa hàng GreenCart. Bạn cần tư vấn gì về dinh dưỡng, thực đơn hay sản phẩm tươi sạch nào không ạ? 😊'
          }
        ]
      });
    }

    _history.add({
      'role': 'user',
      'parts': [
        {'text': userMessage}
      ]
    });

    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/chat',
        data: {
          'contents': _history,
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          },
          'safetySettings': [
            {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_NONE'},
            {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_NONE'},
          ]
        },
      );

      final candidates = response.data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']['parts'] as List<dynamic>;
        final reply = parts.map((p) => p['text'] as String).join();

        _history.add({
          'role': 'model',
          'parts': [
            {'text': reply}
          ]
        });

        return reply;
      }

      return 'Xin lỗi, mình không thể trả lời lúc này. Vui lòng thử lại sau! 🙏';
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (e.response?.statusCode == 400 &&
          responseData != null &&
          responseData.toString().contains('Chưa cấu hình API Key')) {
        return '⚠️ Chưa cấu hình API Key Gemini trên máy chủ Backend.';
      }
      return 'Lỗi kết nối: ${e.message ?? "Không thể kết nối tới máy chủ AI"}. Vui lòng kiểm tra mạng và thử lại! 📡';
    } catch (e) {
      return 'Đã xảy ra lỗi: $e. Vui lòng thử lại! 🔄';
    }
  }

  void clearHistory() {
    _history.clear();
  }
}
