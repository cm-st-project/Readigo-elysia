import 'package:flutter/material.dart';
import 'package:testapp3/components/xp_bar.dart';
import 'package:testapp3/util/firebase_utils.dart';

import '../util/constants.dart';

class QuizResultPage extends StatefulWidget {
  // questions: [{ "question": "...", "choices": [...], "answer": int }]
  final List<dynamic> questions;
  final List<int> selectedAnswers;
  final int difficulty;

  const QuizResultPage({
    super.key,
    required this.questions,
    required this.selectedAnswers,
    required this.difficulty,
  });

  @override
  State<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends State<QuizResultPage> {
  late int correctCount;
  late int wrongCount;

  late final int currentXp;
  late final int nextXp;
  late final int level;
  late final int tempLevel;
  late final int targetXp;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _calculateResults();
    _calculateXpGain();
  }

  void _calculateResults() {
    int correct = 0;

    for (int i = 0; i < widget.questions.length; i++) {
      final correctAnswerIndex = widget.questions[i]["answer"];
      if (widget.selectedAnswers[i] == correctAnswerIndex) {
        correct++;
      }
    }

    correctCount = correct;
    wrongCount = widget.questions.length - correct;
  }

  Future<void> _calculateXpGain() async {
    int gainedXp = correctCount * widget.difficulty;

    final currUserFriendCode = await FirebaseUtils.getCurrentUserFriendCode();
    final userData = await FirebaseUtils.getUserData(currUserFriendCode!);

    currentXp = userData?["xp"];
    nextXp = userData?["next_level_xp"];
    level = userData?["level"];

    int tempXp = currentXp + gainedXp;
    tempLevel = level;
    int tempNextXp = nextXp;

    // Handle level-ups
    while (tempXp >= tempNextXp) {
      tempXp -= tempNextXp;
      tempLevel++;
      tempNextXp = tempLevel * 100;
    }

    targetXp = tempXp;

    await FirebaseUtils.updateUser(currUserFriendCode, {
      "xp": tempXp,
      "level": tempLevel,
      "next_level_xp": tempNextXp,
    });

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quiz Results"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Your Score",
              style: const TextStyle(
                fontSize: 32,
                fontFamily: "Voltaire",
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$correctCount / ${widget.questions.length}",
              style: const TextStyle(
                fontSize: 24,
                color: Colors.green,
              ),
            ),
            Text(
              "Correct: $correctCount    Wrong: $wrongCount",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: widget.questions.length,
                itemBuilder: (context, index) {
                  final question = widget.questions[index];
                  final correctAnswerIndex = question["answer"];
                  final selected = widget.selectedAnswers[index];

                  // Check if the student got it right
                  final isCorrect = selected == correctAnswerIndex;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect ? Colors.green : Colors.red,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Q${index + 1}. ${question["question"]}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          "Your answer: ${question["choices"][selected]}",
                          style: TextStyle(
                            fontSize: 18,
                            color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),

                        if (!isCorrect)
                          Text(
                            "Correct answer: ${question["choices"][correctAnswerIndex]}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            (_isLoading) ? Container() : XPBar(level: level, xp: currentXp, nextLevelXp: nextXp, targetXp: targetXp, targetLevel: tempLevel,),

            ElevatedButton(
              style: Constants.normalButton,
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Back to Home"),
            ),
          ],
        ),
      ),
    );
  }
}
