// main.dart
import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ----- CONFIG: update these URLs -----
const String NEWS_JSON_URL =
    'https://varanasi-software-junction.github.io/pictures-json/quizjson/news.json';
const String SUBJECTS_JSON_URL =
    'https://varanasi-software-junction.github.io/pictures-json/quizjson/subjects.json';

/// ------------------------------------

/// Utilities
class Utils {
  /// Downloads JSON from the given [url] and returns it as dynamic.
  static Future<dynamic> download(String url) async {
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception('Failed to load: ${res.statusCode}');
      }
    } catch (e) {
      print('Download error ($url): $e');
      return null;
    }
  }
}

void main() {
  runApp(QuizApp());
}

/// ------------------ Models ------------------
class NewsItem {
  final String id, title, summary, url;
  NewsItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.url,
  });
  factory NewsItem.fromJson(Map<String, dynamic> j) => NewsItem(
    id: j['id'] ?? '',
    title: j['title'] ?? '',
    summary: j['summary'] ?? '',
    url: j['url'] ?? '',
  );
}

class Subject {
  final String id, name, quizzesUrl;
  Subject({required this.id, required this.name, required this.quizzesUrl});
  factory Subject.fromJson(Map<String, dynamic> j) => Subject(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    quizzesUrl: j['quizzes_url'] ?? j['quizzesUrl'] ?? '',
  );
}

class QuizOverview {
  final String id, title, description, questionsUrl;
  QuizOverview({
    required this.id,
    required this.title,
    required this.description,
    required this.questionsUrl,
  });
  factory QuizOverview.fromJson(Map<String, dynamic> j) => QuizOverview(
    id: j['id'] ?? '',
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    questionsUrl: j['questions_url'] ?? j['questionsUrl'] ?? '',
  );
}

class TFQuestion {
  final String id, text;
  final bool answer;
  TFQuestion({required this.id, required this.text, required this.answer});
  factory TFQuestion.fromJson(Map<String, dynamic> j) => TFQuestion(
    id: j['id'] ?? '',
    text: j['text'] ?? '',
    answer: j['answer'] == true,
  );
}

/// ------------------ Storage ------------------
class QuizAttempt {
  final String quizId;
  final String quizTitle;
  final DateTime timestamp;
  final int total;
  final int correct;
  final List<bool> answersCorrect;
  QuizAttempt({
    required this.quizId,
    required this.quizTitle,
    required this.timestamp,
    required this.total,
    required this.correct,
    required this.answersCorrect,
  });

  Map<String, dynamic> toJson() => {
    'quizId': quizId,
    'quizTitle': quizTitle,
    'timestamp': timestamp.toIso8601String(),
    'total': total,
    'correct': correct,
    'answersCorrect': answersCorrect,
  };

  factory QuizAttempt.fromJson(Map<String, dynamic> j) => QuizAttempt(
    quizId: j['quizId'],
    quizTitle: j['quizTitle'],
    timestamp: DateTime.parse(j['timestamp']),
    total: j['total'],
    correct: j['correct'],
    answersCorrect: List<bool>.from(j['answersCorrect'] ?? []),
  );
}

abstract class AttemptStorage {
  Future<void> saveAttempt(QuizAttempt attempt);
  Future<List<QuizAttempt>> getAttempts();
  Future<void> clearAll();
}

class WebLocalStorage implements AttemptStorage {
  static const String key = 'quiz_attempts';
  @override
  Future<void> saveAttempt(QuizAttempt attempt) async {
    final cur = html.window.localStorage[key];
    List items = cur != null ? jsonDecode(cur) as List : [];
    items.add(attempt.toJson());
    html.window.localStorage[key] = jsonEncode(items);
  }

  @override
  Future<List<QuizAttempt>> getAttempts() async {
    final cur = html.window.localStorage[key];
    if (cur == null) return [];
    final List arr = jsonDecode(cur) as List;
    return arr
        .map((e) => QuizAttempt.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> clearAll() async {
    html.window.localStorage.remove(key);
  }
}

/// ------------------ App ------------------
class QuizApp extends StatefulWidget {
  @override
  State<QuizApp> createState() => _QuizAppState();
}

class _QuizAppState extends State<QuizApp> {
  final AttemptStorage storage = WebLocalStorage();

  @override
  Widget build(BuildContext context) {
    print("Quiz App started");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quiz App (TF)',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeShell(storage: storage),
    );
  }
}

class HomeShell extends StatefulWidget {
  final AttemptStorage storage;
  HomeShell({required this.storage});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final pages = [
    NewsPage(),
    SubjectsPage(),
    PlaceholderPage(message: 'Select a subject to see quizzes'),
    PlaceholderPage(message: 'Open a quiz to answer'),
    ResultsPage(storage: widget.storage),
  ];

  @override
  Widget build(BuildContext context) {
    print("Building HomeShell with index $_index");
    print("=$pages");
    print("Pages 1 $pages[1]");
    return Scaffold(
      appBar: AppBar(title: Text('Quiz App')),
      body:
        Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.business), label: 'Business'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'School'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String message;
  PlaceholderPage({required this.message});
  @override
  Widget build(BuildContext context) => Center(child: Text(message));
}

/// ------------------ Page 1: News ------------------
class NewsPage extends StatelessWidget {
  Future<List<NewsItem>> fetchNews() async {
    final data = await Utils.download(NEWS_JSON_URL);
    if (data == null) return [];
    return (data as List)
        .map((e) => NewsItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NewsItem>>(
      future: fetchNews(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? [];
        if (items.isEmpty) return Center(child: Text('No news'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, i) {
            final n = items[i];
            return ListTile(
              title: Text(n.title),
              subtitle: Text(n.summary),
              trailing: Icon(Icons.open_in_new),
              onTap: () {
                if (n.url.isNotEmpty) html.window.open(n.url, '_blank');
              },
            );
          },
        );
      },
    );
  }
}

/// ------------------ Page 2: Subjects ------------------
class SubjectsPage extends StatelessWidget {
  Future<List<Subject>> fetchSubjects() async {
    print("Fetching subjects from $SUBJECTS_JSON_URL");
    final data = await Utils.download(SUBJECTS_JSON_URL);
    if (data == null) {
      print("Null data received");
      return [];
    }
    print("Not Null data received");
    var x = (data as List)
        .map((e) => Subject.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    print("Subjects list $x");
    return x;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Subject>>(
      future: fetchSubjects(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator());
        }
        final s = snap.data ?? [];
        if (s.isEmpty) {
          return Center(child: Text('No subjects'));
        }
        return ListView.builder(
          itemCount: s.length,
          itemBuilder: (context, i) {
            final sub = s[i];
            print("Sub Name: $sub.name");
            return Card(
              child: ListTile(
                title: Text(sub.name),
                subtitle: Text(sub.quizzesUrl),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QuizzesPage(subject: sub),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// ------------------ Page 3: Quizzes ------------------
class QuizzesPage extends StatelessWidget {
  final Subject subject;
  QuizzesPage({required this.subject});

  Future<List<QuizOverview>> fetchQuizzes() async {
    final data = await Utils.download(subject.quizzesUrl);
    if (data == null) return [];
    return (data as List)
        .map((e) => QuizOverview.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quizzes — ${subject.name}')),
      body: FutureBuilder<List<QuizOverview>>(
        future: fetchQuizzes(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? [];
          if (list.isEmpty) return Center(child: Text('No quizzes'));
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final q = list[i];
              return Card(
                child: ListTile(
                  title: Text(q.title),
                  subtitle: Text(q.description),
                  trailing: Icon(Icons.play_arrow),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => QuizPage(quiz: q)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// ------------------ Page 4: Quiz ------------------
class QuizPage extends StatefulWidget {
  final QuizOverview quiz;
  QuizPage({required this.quiz});
  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late Future<List<TFQuestion>> _future;
  List<int> _answers = [];
  bool _submitted = false;
  List<bool> _correctness = [];

  @override
  void initState() {
    super.initState();
    _future = fetchQuestions();
  }

  Future<List<TFQuestion>> fetchQuestions() async {
    final data = await Utils.download(widget.quiz.questionsUrl);
    if (data == null) return [];
    final qs = (data['questions'] as List)
        .map((e) => TFQuestion.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return qs;
  }

  void _submit(List<TFQuestion> qs) async {
    int correct = 0;
    List<bool> results = [];
    for (int i = 0; i < qs.length; i++) {
      final isCorrect =
          (_answers[i] == 1 && qs[i].answer) ||
          (_answers[i] == 0 && !qs[i].answer);
      results.add(isCorrect);
      if (isCorrect) correct++;
    }
    setState(() {
      _submitted = true;
      _correctness = results;
    });

    final attempt = QuizAttempt(
      quizId: widget.quiz.id,
      quizTitle: widget.quiz.title,
      timestamp: DateTime.now(),
      total: qs.length,
      correct: correct,
      answersCorrect: results,
    );
    await WebLocalStorage().saveAttempt(attempt);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Result'),
        content: Text('Score: $correct / ${qs.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.quiz.title)),
      body: FutureBuilder<List<TFQuestion>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          final qs = snap.data ?? [];
          if (qs.isEmpty) return Center(child: Text('No questions'));
          if (_answers.length != qs.length) {
            _answers = List.filled(qs.length, -1);
          }

          return ListView.builder(
            itemCount: qs.length + 1,
            itemBuilder: (context, i) {
              if (i == qs.length) {
                return ElevatedButton(
                  onPressed: _answers.contains(-1) ? null : () => _submit(qs),
                  child: Text('Submit Quiz'),
                );
              }
              final q = qs[i];
              return Card(
                child: ListTile(
                  title: Text('Q${i + 1}: ${q.text}'),
                  subtitle: _submitted
                      ? Text(_correctness[i] ? 'Correct' : 'Incorrect')
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ChoiceChip(
                        label: Text('True'),
                        selected: _answers[i] == 1,
                        onSelected: _submitted
                            ? null
                            : (sel) =>
                                  setState(() => _answers[i] = sel ? 1 : -1),
                      ),
                      SizedBox(width: 8),
                      ChoiceChip(
                        label: Text('False'),
                        selected: _answers[i] == 0,
                        onSelected: _submitted
                            ? null
                            : (sel) =>
                                  setState(() => _answers[i] = sel ? 0 : -1),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// ------------------ Page 5: Results ------------------
class ResultsPage extends StatefulWidget {
  final AttemptStorage storage;
  ResultsPage({required this.storage});
  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  late Future<List<QuizAttempt>> _future;
  @override
  void initState() {
    super.initState();
    _future = widget.storage.getAttempts();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuizAttempt>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator());
        }
        final attempts = snap.data ?? [];
        if (attempts.isEmpty) return Center(child: Text('No attempts yet'));
        return ListView.builder(
          itemCount: attempts.length,
          itemBuilder: (context, i) {
            final a = attempts[attempts.length - 1 - i];
            return ListTile(
              title: Text('${a.quizTitle} — ${a.correct}/${a.total}'),
              subtitle: Text('${a.timestamp.toLocal()}'),
            );
          },
        );
      },
    );
  }
}
