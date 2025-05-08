import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/chat_service.dart';
import '../services/search_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SearchService _searchService = SearchService();
  late ChatService _chatService;
  List<ChatMessage> _messages = [];
  Map<String, dynamic> _folders = {};
  bool _isLoading = false;
  bool _showCurrentChat = true;

  @override
  void initState() {
    super.initState();
    _initChatService();
  }

  Future<void> _initChatService() async {
    final prefs = await SharedPreferences.getInstance();
    _chatService = ChatService(prefs);
    await _loadData();
  }

  Future<void> _loadData() async {
    final messages = await _chatService.getMessages();
    final folders = await _chatService.getFolders();
    setState(() {
      _messages = messages;
      _folders = folders;
    });
  }

  Future<void> _loadFolderMessages(String folderName) async {
    final messages = await _chatService.getFolderMessages(folderName);
    setState(() {
      _messages = messages;
      _showCurrentChat = false;
    });
  }

  Future<void> _deleteFolder(String folderName) async {
    await _chatService.deleteFolder(folderName);
    await _loadData();
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // Add user message
    final userMessage = ChatMessage(
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await _chatService.addMessage(userMessage);

    try {
      // Search news
      final result = await _searchService.searchNews(query: message);
      
      // Add bot response
      final botMessage = ChatMessage(
        content: result['response'],
        isUser: false,
        timestamp: DateTime.now(),
      );
      await _chatService.addMessage(botMessage);
    } catch (e) {
      // Add error message
      final errorMessage = ChatMessage(
        content: '죄송합니다. 검색 중 오류가 발생했습니다.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      await _chatService.addMessage(errorMessage);
    }

    setState(() {
      _isLoading = false;
      _messageController.clear();
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('대화 내역'),
        centerTitle: true,
        actions: [
          if (!_showCurrentChat)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final messages = await _chatService.getMessages();
                setState(() {
                  _messages = messages;
                  _showCurrentChat = true;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          if (_showCurrentChat) ...[
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment: message.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: message.isUser
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        message.content,
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '검색어를 입력하세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isLoading
                        ? null
                        : () => _sendMessage(_messageController.text),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ] else ...[
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _folders.length,
                itemBuilder: (context, index) {
                  final folderName = _folders.keys.elementAt(index);
                  final folder = _folders[folderName];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(folder['name']),
                      subtitle: Text(
                        '생성일: ${DateTime.parse(folder['createdAt']).toString().split('.')[0]}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteFolder(folderName),
                      ),
                      onTap: () => _loadFolderMessages(folderName),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 