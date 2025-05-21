import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma/flutter_gemma_interface.dart';
import 'package:flutter_gemma/core/chat.dart';
import 'package:flutter_gemma/core/message.dart';
import 'package:flutter_gemma/core/model.dart';
import 'package:flutter_gemma/pigeon.g.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_Message> _messages = [];
  late InferenceModel _inferenceModel;
  InferenceChat? _chat;
  bool _isLoading = false;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      final gemma = FlutterGemmaPlugin.instance;
      final modelManager = gemma.modelManager;

      // Installer le modèle depuis les assets (en mode debug uniquement)
      await modelManager.installModelFromAsset('model.bin');

      // Créer l'instance du modèle
      _inferenceModel = await gemma.createModel(
        modelType: ModelType.gemmaIt,
        preferredBackend: PreferredBackend.cpu,
        maxTokens: 512,
      );

      // Créer une instance de chat
      _chat = await _inferenceModel.createChat(
        temperature: 0.8,
        randomSeed: 1,
        topK: 1,
      );

      setState(() {
        _modelReady = true;
      });
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du modèle : $e');
    }
  }

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty || !_modelReady) {
      // Si le modèle n'est pas prêt ou si le message est vide, ne rien faire
      print('Le modèle n\'est pas prêt ou le message est vide.');
      return;
    }

    setState(() {
      _messages.add(_Message(role: 'user', content: input));
      _isLoading = true;
      _controller.clear();
    });

    try {
      await _chat?.addQueryChunk(Message(text: input));
      final response = await _chat?.generateChatResponse();
      if (response != null) {
        setState(() {
          _messages.add(_Message(role: 'assistant', content: response));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_Message(role: 'assistant', content: 'Erreur : $e'));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessage(_Message message) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          message.content,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    // _chat?.close(); // Close chat instance if possible
    _inferenceModel.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat LLM Local'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Entrez votre message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String role;
  final String content;

  _Message({required this.role, required this.content});
}
