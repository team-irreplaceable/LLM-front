import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'isUser': isUser,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    content: json['content'],
    isUser: json['isUser'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class ChatService {
  static const String _messagesKey = 'chat_messages';
  static const String _foldersKey = 'chat_folders';
  final SharedPreferences _prefs;

  ChatService(this._prefs);

  Future<List<ChatMessage>> getMessages() async {
    final messagesJson = _prefs.getStringList(_messagesKey) ?? [];
    return messagesJson
        .map((json) => ChatMessage.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> addMessage(ChatMessage message) async {
    final messages = await getMessages();
    messages.add(message);
    await _saveMessages(messages);
  }

  Future<void> clearMessages() async {
    await _prefs.remove(_messagesKey);
  }

  Future<void> _saveMessages(List<ChatMessage> messages) async {
    final messagesJson = messages
        .map((message) => jsonEncode(message.toJson()))
        .toList();
    await _prefs.setStringList(_messagesKey, messagesJson);
  }

  Future<void> saveChatToFolder(String folderName, List<ChatMessage> messages) async {
    final folders = await getFolders();
    final folderData = {
      'name': folderName,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    folders[folderName] = folderData;
    await _prefs.setString(_foldersKey, jsonEncode(folders));
  }

  Future<Map<String, dynamic>> getFolders() async {
    final foldersJson = _prefs.getString(_foldersKey);
    if (foldersJson == null) return {};
    return jsonDecode(foldersJson) as Map<String, dynamic>;
  }

  Future<List<ChatMessage>> getFolderMessages(String folderName) async {
    final folders = await getFolders();
    final folder = folders[folderName];
    if (folder == null) return [];
    
    final messages = (folder['messages'] as List)
        .map((m) => ChatMessage.fromJson(m))
        .toList();
    return messages;
  }

  Future<void> deleteFolder(String folderName) async {
    final folders = await getFolders();
    folders.remove(folderName);
    await _prefs.setString(_foldersKey, jsonEncode(folders));
  }
} 