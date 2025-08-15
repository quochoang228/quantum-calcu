import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import '../ui/style.dart';

class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final lessons = ['qubit', 'superposition', 'entanglement', 'algorithms'];
  String currentLesson = 'qubit';
  String content = '';
  int quizIndex = 0;
  int score = 0;

  final quiz = [
    QuizQuestion(
      question: 'In what form can a qubit exist?',
      answers: ['Only 0', 'Only 1', 'A superposition of 0 and 1'],
      correct: 2,
    ),
    QuizQuestion(
      question: 'What does the H (Hadamard) gate create?',
      answers: ['Bit flip', 'Superposition state', 'Measure a qubit'],
      correct: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    final data = await rootBundle.loadString(
      'assets/lessons/$currentLesson.md',
    );
    setState(() {
      content = data;
    });
  }

  void _nextQuizAnswer(int idx) {
    if (quiz[quizIndex].correct == idx) score++;
    if (quizIndex < quiz.length - 1) {
      setState(() => quizIndex++);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Quiz Done'),
          content: Text('Score: $score/${quiz.length}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  quizIndex = 0;
                  score = 0;
                });
              },
              child: const Text('Restart'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = quiz[quizIndex];
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Hero(
              tag: HeroTags.learning,
              child: Icon(Icons.school_rounded, size: 22),
            ),
            SizedBox(width: 8),
            Text('Learning Mode'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x33FF9F0A), Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: ListView(
              children: [
                Row(
                  children: [
                    const Text('Lesson:'),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: currentLesson,
                      items: lessons
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            currentLesson = v;
                          });
                          _loadLesson();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(content, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text('Quiz: ${q.question}'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    q.answers.length,
                    (i) => ElevatedButton(
                      onPressed: () => _nextQuizAnswer(i),
                      child: Text(q.answers[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> answers;
  final int correct;
  QuizQuestion({
    required this.question,
    required this.answers,
    required this.correct,
  });
}
