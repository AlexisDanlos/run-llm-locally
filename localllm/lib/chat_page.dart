import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:llama_cpp/llama_cpp.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, String>> messages = [];
  LlamaCpp? _llama;
  bool _loading = true;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    final data = await rootBundle.load('assets/model.gguf');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/model.gguf');
    await file.writeAsBytes(data.buffer.asUint8List());
    _llama = await LlamaCpp.load(file.path, verbose: false);
    setState(() {
      _loading = false;
    });
  }

  void _send() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty || _llama == null) return;
    setState(() {
      messages.add({'role': 'user', 'text': prompt});
      _controller.clear();
      messages.add({'role': 'assistant', 'text': ''});
    });
    final idx = messages.length - 1;
    await for (final token in _llama!.answer(prompt)) {
      setState(() {
        messages[idx]['text'] = messages[idx]['text']! + token;
      });
    }
  }

  @override
  void dispose() {
    _llama?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Local LLM Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final msg = messages[i];
                final isUser = msg['role'] == 'user';
                return ListTile(
                  title: Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      child: Text(msg['text']!),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller)),
                IconButton(icon: const Icon(Icons.send), onPressed: _send),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
