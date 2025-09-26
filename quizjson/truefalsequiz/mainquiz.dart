// https://varanasi-software-junction.github.io/pictures-json/quizjson/truefalsequiz/news.json


// Minimal DartPad single-file Flutter app.
// Replace BASE_URL with your GitHub Pages base URL (must end with slash).

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class QuizUtilities {
  static const String BASE_URL = 'https://varanasi-software-junction.github.io/pictures-json/quizjson/truefalsequiz/';

  static final String NEWS_URL = '${BASE_URL}news.json';
  static final String SUBJECTS_URL = '${BASE_URL}subjects.json';

  static String quizzesUrl(int subjectId) => '${BASE_URL}quizzes_$subjectId.json';
  static String questionsUrl(int quizId) => '${BASE_URL}questions_$quizId.json';

  static int currentsubject = 0;
  static int currentquiz = 0;
  static int currentquestion = 0;
  static int currentscore = 0;

  static List newswidgets = [];
  static List subjectwidgets = [];
  static List quizwidgets = [];
  static List questionswidgets = [];

  static List> questionsdata = [];

  static Future downloadJson(String url) async {
    final r = await http.get(Uri.parse(url));
    if (r.statusCode == 200) return r.body;
    throw Exception('Failed to load $url (${r.statusCode})');
  }

  static Future getNews() async {
    newswidgets = [];
    final js = await downloadJson(NEWS_URL);
    final d = jsonDecode(js);
    final List items = d['news'] ?? [];
    for (var it in items) {
      final title = it['title'] ?? '';
      final body = it['body'] ?? '';
      newswidgets.add(Text('$title - $body'));
    }
    if (newswidgets.isEmpty) newswidgets.add(Text('No news'));
  }

  static Future getSubjects(BuildContext ctx) async {
    subjectwidgets = [];
    final js = await downloadJson(SUBJECTS_URL);
    final d = jsonDecode(js);
    final List items = d['subjects'] ?? [];
    for (var it in items) {
      final int id = it['id'] is int ? it['id'] : int.tryParse('${it['id']}') ?? 0;
      final String name = it['name'] ?? '$id';
      subjectwidgets.add(ElevatedButton(
        child: Text(name),
        onPressed: () async {
          currentsubject = id;
          await getQuizzes(ctx, id);
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => QuizBySubjectPage()));
        },
      ));
    }
    if (subjectwidgets.isEmpty) subjectwidgets.add(Text('No subjects'));
  }

  static Future getQuizzes(BuildContext ctx, int subjectId) async {
    quizwidgets = [];
    final js = await downloadJson(quizzesUrl(subjectId));
    final d = jsonDecode(js);
    final List items = d['quizzes'] ?? [];
    for (var it in items) {
      final int id = it['id'] is int ? it['id'] : int.tryParse('${it['id']}') ?? 0;
      final String title = it['title'] ?? '$id';
      quizwidgets.add(ElevatedButton(
        child: Text(title),
        onPressed: () async {
          currentquiz = id;
          await getQuestions(id);
          Navigator.push(ctx, MaterialPageRoute(builder: (_) => QuizPage()));
        },
      ));
    }
    if (quizwidgets.isEmpty) quizwidgets.add(Text('No quizzes'));
  }

  static Future getQuestions(int quizId) async {
    questionswidgets = [];
    questionsdata = [];
    final js = await downloadJson(questionsUrl(quizId));
    final d = jsonDecode(js);
    final List items = d['questions'] ?? [];
    for (var it in items) {
      final int id = it['id'] is int ? it['id'] : int.tryParse('${it['id']}') ?? 0;
      final String text = it['text'] ?? '';
      final bool answer = it['answer'] == true;
      questionsdata.add({'id': id, 'text': text, 'answer': answer});
      questionswidgets.add(Text(text));
    }
    if (questionswidgets.isEmpty) {
      questionswidgets.add(Text('No questions'));
      questionsdata.add({'id': 0, 'text': 'No questions', 'answer': true});
    }
    currentquestion = 0;
    currentscore = 0;
  }
}

void main() => runApp(MaterialApp(home: FirstPage()));

class FirstPage extends StatefulWidget { @override _FirstPageState createState() => _FirstPageState(); }
class _FirstPageState extends State {
  @override
  void initState() { super.initState(); _load(); }
  void _load() async {
    await QuizUtilities.getNews();
    await QuizUtilities.getSubjects(context);
    setState((){});
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('firstpage')),
      body: Column(children: [ ...QuizUtilities.newswidgets, ElevatedButton(child: Text('Go to Subjects'), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectPage())); }), ]),
    );
  }
}

class SubjectPage extends StatelessWidget { @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: Text('subjectpage')), body: Column(children: [ ...QuizUtilities.subjectwidgets, ElevatedButton(child: Text('Back'), onPressed: () => Navigator.pop(context)), ])); } }

class QuizBySubjectPage extends StatelessWidget { @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: Text('quizbysubject')), body: Column(children: [ ...QuizUtilities.quizwidgets, ElevatedButton(child: Text('Back'), onPressed: () => Navigator.pop(context)), ])); } }

class QuizPage extends StatefulWidget { @override _QuizPageState createState() => _QuizPageState(); }
class _QuizPageState extends State {
  int idx = 0;
  @override
  void initState() { super.initState(); idx = QuizUtilities.currentquestion; }
  void answer(bool val) {
    final correct = QuizUtilities.questionsdata[idx]['answer'] == true;
    if (val == correct) QuizUtilities.currentscore++;
    idx++;
    QuizUtilities.currentquestion = idx;
    if (idx >= QuizUtilities.questionsdata.length) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizResultsPage()));
    } else {
      setState((){});
    }
  }
  @override
  Widget build(BuildContext context) {
    final total = QuizUtilities.questionswidgets.length;
    if (idx >= total) return Scaffold(appBar: AppBar(title: Text('quiz')), body: Text('Finished'));
    return Scaffold(appBar: AppBar(title: Text('quiz')), body: Column(children: [ QuizUtilities.questionswidgets[idx], ElevatedButton(child: Text('True'), onPressed: () => answer(true)), ElevatedButton(child: Text('False'), onPressed: () => answer(false)), ElevatedButton(child: Text('Back'), onPressed: () => Navigator.pop(context)), Text('Score: ${QuizUtilities.currentscore}'), ]));
  }
}

class QuizResultsPage extends StatelessWidget { @override Widget build(BuildContext context) { final total = QuizUtilities.questionsdata.length; final score = QuizUtilities.currentscore; return Scaffold(appBar: AppBar(title: Text('quizresults')), body: Column(children: [ Text('Completed'), Text('Subject: ${QuizUtilities.currentsubject}'), Text('Quiz: ${QuizUtilities.currentquiz}'), Text('Score: $score / $total'), ElevatedButton(child: Text('Back to Home'), onPressed: () => Navigator.popUntil(context, (r) => r.isFirst)), ])); } }
