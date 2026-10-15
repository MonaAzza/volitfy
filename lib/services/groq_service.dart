import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  static const String apiKey = "YOUR_GROQ_API_KEY_HERE";
  static const String endpoint = "https://api.groq.com/openai/v1/chat/completions";

  static Future<String> getSolarAnalysis({
    required double batteryPercentage,
    required double solarGenerationWatts,
    required double currentLoadWatts,
    required String weatherCondition,
    String? userQuery,
  }) async {
    final String actualQuery = userQuery ?? "أعطني تحليلاً وتوصية ذكية ومختصرة للمستخدم حول وضع النظام الحالي.";

    if (apiKey.isEmpty || apiKey == "YOUR_GROQ_API_KEY_HERE") {
      return "يرجى وضع مفتاح Groq API الخاص بك في ملف groq_service.dart";
    }

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "openai/gpt-oss-120b",
          "messages": [
            {
              "role": "system",
              "content": "أنت 'حارس الطاقة الشمسية' (Voltify)، المساعد الذكي للتطبيق . أنت مستشار ذكي، لطيف للغاية، مؤدب وودود و لطييف جدا، متخصص في مساعدة أهالي قطاع غزة في إدارة أنظمة الطاقة الشمسية والبطاريات والترشيد الكهربائي.\n\nإذا سألك أحد عن المطور، اذكر  أنه تم تطوير هذا التطبيق بواسطة منى .\n\nتعليمات صارمة لإجاباتك:\n1. كن لطيفاً وبشوشاً ومحترماً وداعماً للمستخدم دائماً.\n2. أجب مباشرة وبدقة على السؤال المحدد الذي يطرحه المستخدم بدون الخروج عن الموضوع أو التحدث عن أشياء لا علاقة لها بالسؤال.\n3. اجعل الإجابة مختصرة وواضحة وسهلة الفهم بعيداً عن المصطلحات المعقدة، مع مراعاة قراءات النظام المرفقة لك."
            },
            {
              "role": "user",
              "content": "معلومات النظام الحالية للرجوع إليها إن لزم الأمر:\n- نسبة البطارية: $batteryPercentage%\n- توليد الألواح: $solarGenerationWatts واط\n- الاستهلاك الحالي: $currentLoadWatts واط\n- حالة الطقس: $weatherCondition\n\nسؤال المستخدم المحدد الذي يجب الإجابة عليه فقط:\n$actualQuery"
            }
          ],
          "temperature": 0.5,
          "max_tokens": 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        try {
          final data = jsonDecode(response.body);
          final String groqError = data['error']?['message'] ?? response.body;
          return "خطأ من سيرفر Groq (رمز ${response.statusCode}): $groqError";
        } catch (_) {
          return "استجابة سيرفر Groq (رمز ${response.statusCode}): ${response.body}";
        }
      }
    } catch (e) {
      return "حدث خطأ أثناء الاتصال بالشبكة: $e";
    }
  }
}
