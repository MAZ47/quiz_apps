import 'package:flutter/material.dart';
import '../models/question.dart';

class QuizManagementPage extends StatefulWidget {
  const QuizManagementPage({super.key});

  @override
  State<QuizManagementPage> createState() => _QuizManagementPageState();
}

class _QuizManagementPageState extends State<QuizManagementPage> {
  final List<Question> questions = [];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _questionController = TextEditingController();

  final List<TextEditingController> _optionControllers = List.generate(
    4,
        (_) => TextEditingController(),
  );

  int _correctOptionIndex = -1;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    FocusScope.of(context).unfocus(); // Close keyboard on submit

    if (_formKey.currentState!.validate()) {
      if (_correctOptionIndex == -1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select the correct option via radio button'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final questionText = _questionController.text.trim();
      final options = _optionControllers.map((c) => c.text.trim()).toList();

      final newQuestion = Question(
        text: questionText,
        options: options,
        correctOptionIndex: _correctOptionIndex,
      );

      setState(() {
        questions.add(newQuestion);

        // Reset question and options form inputs only
        _questionController.clear();
        for (final controller in _optionControllers) {
          controller.clear();
        }
        _correctOptionIndex = -1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Question added successfully!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building QuizManagementPage with ${questions.length} questions');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Management'),
        actions: [
          if (questions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Chip(
                  label: Text(
                    '${questions.length} Qs',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Quiz Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a quiz title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Quiz Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a quiz category';
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 32, thickness: 1.5),
                    const Text(
                      'Add Question',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        labelText: 'Question Text',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.help_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a question';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Options (Select radio for correct answer):',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // RadioGroup ব্যবহার করে Deprecated Warning সমাধান করা হয়েছে
                    RadioGroup<int>(
                      groupValue: _correctOptionIndex,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _correctOptionIndex = value;
                          });
                        }
                      },
                      child: Column(
                        children: List.generate(4, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              children: [
                                Radio<int>(
                                  value: index,
                                ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _optionControllers[index],
                                    decoration: InputDecoration(
                                      labelText: 'Option ${index + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Please enter option ${index + 1}';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _addQuestion,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Add Question to List',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const Divider(height: 32, thickness: 1.5),
                    const Text(
                      'Added Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (questions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No questions added yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: questions.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              '${index + 1}. ${question.text}',
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: List.generate(
                                  question.options.length,
                                      (optionIndex) {
                                    final optionText =
                                    question.options[optionIndex];
                                    final isCorrect = optionIndex ==
                                        question.correctOptionIndex;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        '${isCorrect ? "✓" : "•"} $optionText',
                                        style: TextStyle(
                                          color: isCorrect
                                              ? Colors.green
                                              : Colors.black87,
                                          fontWeight: isCorrect
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  questions.removeAt(index);
                                });
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}