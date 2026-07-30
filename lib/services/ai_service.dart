import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import '../models/question.dart';

class AiService {
  AiService({String? apiKey}) {
    // OpenRouter API Key এবং Base URL সেটআপ
    OpenAI.apiKey = apiKey ?? 'YOUR_OPENROUTER_API_KEY';
    OpenAI.baseUrl = "https://openrouter.ai/api/v1";
  }

  /// সাধারণ এআই চ্যাটের জন্য মেসেজ পাঠানো
  Stream<String> sendMessageStream(String text) async* {
    final completion = await OpenAI.instance.chat.create(
      model: "google/gemma-4-26b-a4b-it:free", // আপডেট করা ফ্রি মডেল
      messages: [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(text),
          ],
          role: OpenAIChatMessageRole.user,
        ),
      ],
    );

    yield completion.choices.first.message.content?.first.text ?? '';
  }

  /// কুইজের ভুল উত্তরের ব্যাচ ব্যাখ্যার জন্য JSON রেসপন্স
  Future<Map<int, String>?> generateExplanationsBatch(
      List<Map<String, dynamic>> wrongAnswers,
      ) async {
    if (wrongAnswers.isEmpty) return {};

    final prompt = '''
You are an AI assistant for a quiz app. I will provide a list of wrong answers submitted by a user.
For each item, explain briefly (in 1-2 sentences) why the user's answer is wrong and why the correct one is correct.
Return the result strictly as a JSON object where the keys are the "questionIndex" and the values are the "explanation".

Here is the data:
${wrongAnswers.map((w) => "questionIndex: ${w['index']}, Question: ${w['question']}, User Answer: ${w['selectedAnswer']}, Correct Answer: ${w['correctAnswer']}").join('\n')}
''';

    try {
      final completion = await OpenAI.instance.chat.create(
        model: "google/gemma-4-26b-a4b-it:free", // আপডেট করা ফ্রি মডেল
        responseFormat: {"type": "json_object"},
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      final text = completion.choices.first.message.content?.first.text;
      if (text != null) {
        final decoded = jsonDecode(text) as Map<String, dynamic>;
        return decoded.map(
              (key, value) => MapEntry(int.parse(key), value.toString()),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// ইউজারের প্রম্পট বা টপিক অনুযায়ী ১০টি প্রশ্নের কাস্টম কুইজ তৈরি করা
  Future<List<Question>?> generateQuiz(String promptText) async {
    final instructions = '''
You are a quiz generator. Generate a 10-question multiple-choice quiz about: $promptText.
Return the result strictly as a JSON array of objects inside an object or a direct array, where each object represents a question.
Each object must have the following keys:
- "question": The question text (string)
- "correct_answer": The correct answer (string)
- "incorrect_answers": An array of exactly 3 incorrect answers (array of strings)
- "difficulty": "easy", "medium", or "hard" (string)
''';

    try {
      final completion = await OpenAI.instance.chat.create(
        model: "google/gemma-4-26b-a4b-it:free", // আপডেট করা ফ্রি মডেল
        responseFormat: {"type": "json_object"},
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(instructions),
            ],
            role: OpenAIChatMessageRole.user,
          ),
        ],
      );

      final text = completion.choices.first.message.content?.first.text;
      if (text != null) {
        final decoded = jsonDecode(text);
        List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded.containsKey('questions')) {
          list = decoded['questions'];
        } else {
          list = decoded.values.firstWhere((v) => v is List, orElse: () => []) as List;
        }

        return list
            .map((q) => Question.fromJson(q as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}