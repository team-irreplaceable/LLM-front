import 'package:flutter/material.dart';
import '../services/search_service.dart';
import '../services/chat_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html_unescape/html_unescape.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _searchService = SearchService();
  late ChatService _chatService;
  String? _selectedPublisher;
  bool _isLoading = false;

  // 애니메이션 관련
  late AnimationController _animationController;
  bool _searchStarted = false;

  List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();

  // 언론사 목록 (29개)
  final List<String> _publishers = [
    '전체',
    // 가나다/알파벳 순 정렬
    'BROTER', 'Korea JoongAng Daily', 'MBN 뉴스', 'YTN', '기독교일보', '경향신문',
    '노컷뉴스', '뉴시스', '디지털 데일리', '디지털타임스', '머니투데이', '문화일보', '세계일보',
    '서울경제', '서울신문', '스포츠동아', '스포츠서울', '스포츠조선', '연합뉴스', '연합뉴스TV',
    '이데일리', '전자신문', '조선일보', '중앙일보', '파이넨셜뉴스', '한겨레', '한국경제신문',
    '헤럴드경제', '뉴스1'
  ];

  Map<String, String?> _thumbnailCache = {};
  final HtmlUnescape _unescape = HtmlUnescape();

  final GlobalKey _inputKey = GlobalKey();
  double _inputHeight = 90;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initChatService();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncSearchState();
    }
  }

  void _syncSearchState() {
    setState(() {
      _searchStarted = _messages.isNotEmpty;
    });
    if (_searchStarted) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Future<void> _initChatService() async {
    final prefs = await SharedPreferences.getInstance();
    _chatService = ChatService(prefs);
    final messages = await _chatService.getMessages();
    setState(() {
      _messages = messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 홈 탭 build 시 대화 상태 동기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final shouldBeStarted = _messages.isNotEmpty;
        if (_searchStarted != shouldBeStarted) {
          setState(() {
            _searchStarted = shouldBeStarted;
          });
          if (shouldBeStarted) {
            _animationController.forward();
          } else {
            _animationController.reverse();
          }
        }
      }
    });
    Widget inputWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: '검색어를 입력하세요',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _performSearch,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final selected = await showDialog<String>(
                    context: context,
                    builder: (context) => _PublisherSelectDialog(
                      publishers: _publishers,
                      selected: _selectedPublisher,
                    ),
                  );
                  if (selected != null) {
                    setState(() {
                      _selectedPublisher = selected;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedPublisher ?? '언론사 선택',
                        style: TextStyle(
                          color: _selectedPublisher == null
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '뉴스 검색',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              final messages = await _chatService.getMessages();
              if (messages.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('저장할 대화 내용이 없습니다.')),
                );
                return;
              }
              final folderName = DateTime.now().toString().split('.')[0];
              await _chatService.saveChatToFolder(folderName, messages);
              await _chatService.clearMessages();
              setState(() {
                _messages.clear();
                _searchStarted = false;
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('대화가 저장되었습니다.')),
                );
              }
            },
            tooltip: '대화 저장',
          ),
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatHistoryScreen(
                    chatService: _chatService,
                    onChatSelected: (messages) {
                      setState(() {
                        _messages = messages;
                        _searchStarted = true;
                      });
                      _animationController.forward();
                    },
                  ),
                ),
              );
            },
            tooltip: '저장된 대화',
          ),
        ],
      ),
      body: _searchStarted
          ? Padding(
              padding: EdgeInsets.zero,
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
                            : Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: message.isUser
                          ? Text(
                              message.content,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            )
                          : _buildBotMessageWidget(message.content, context),
                    ),
                  );
                },
              ),
            )
          : Center(child: inputWidget),
      bottomNavigationBar: _searchStarted ? inputWidget : null,
    );
  }

  TextSpan _buildReferenceTextSpan(String content, BuildContext context) {
    // answer와 references를 구분해서 파싱
    final lines = content.split('\n');
    List<TextSpan> spans = [];
    bool inReferences = false;
    for (final line in lines) {
      if (line.trim() == '[관련 기사]') {
        inReferences = true;
        spans.add(const TextSpan(
          text: '\n[관련 기사]\n',
          style: TextStyle(fontWeight: FontWeight.bold),
        ));
        continue;
      }
      if (!inReferences) {
        spans.add(TextSpan(text: '$line\n'));
      } else {
        if (line.trim().startsWith('•')) {
          // 기사 제목
          spans.add(TextSpan(
              text: '$line\n',
              style: const TextStyle(fontWeight: FontWeight.bold)));
        } else if (line.trim().startsWith('http')) {
          // URL
          spans.add(TextSpan(
            text: '${line.trim()}\n',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ));
        } else {
          // 요약
          spans.add(TextSpan(text: '$line\n'));
        }
      }
    }
    return TextSpan(children: spans);
  }

  Widget _buildBotMessageWidget(String content, BuildContext context) {
    // answer와 references 분리
    final split = content.split('\n\n[관련 기사]\n');
    final answer = split[0];
    final refsBlock = split.length > 1 ? split[1] : null;
    List<Map<String, dynamic>> refs = [];
    if (refsBlock != null) {
      // 각 기사 블록 파싱
      final refLines =
          refsBlock.split('\n').where((l) => l.trim().isNotEmpty).toList();
      for (int i = 0; i < refLines.length; i += 3) {
        if (i + 2 < refLines.length) {
          final titleLine = refLines[i];
          final summaryLine = refLines[i + 1];
          final urlLine = refLines[i + 2];
          final title = titleLine.replaceAll(RegExp(r'^• <b>|</b>\$'), '');
          final summary = summaryLine.trim();
          final url =
              RegExp(r'<a href=\"(.*?)\"').firstMatch(urlLine)?.group(1) ??
                  urlLine.trim();
          final cleanUrl = url.replaceAll(RegExp(r'<[^>]*>'), '');
          refs.add({'title': title, 'summary': summary, 'url': cleanUrl});
        }
      }
      // 썸네일 비동기 로딩
      _loadThumbnails(refs);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(answer,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        if (refs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('[관련 기사]', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: refs.length,
            separatorBuilder: (context, idx) => Divider(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1)),
            itemBuilder: (context, idx) {
              final ref = refs[idx];
              final thumb = _thumbnailCache[ref['url']];
              // HTML 태그 제거 및 제목만 굵게 표시
              String cleanTitle =
                  ref['title'].replaceAll(RegExp(r'<[^>]*>'), '');
              String cleanSummary =
                  ref['summary'].replaceAll(RegExp(r'<[^>]*>'), '');
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: thumb != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            thumb,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                          ),
                        )
                      : const Icon(Icons.article, size: 32),
                  title: Text(_unescape.convert(cleanTitle),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(_unescape.convert(cleanSummary),
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final url = ref['url'];
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          ref['url'],
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Future<String?> fetchOgImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final metaTags = document.getElementsByTagName('meta');
        for (final e in metaTags) {
          if (e.attributes['property'] == 'og:image') {
            return e.attributes['content'];
          }
        }
      }
    } catch (e) {
      // ignore error
    }
    return null;
  }

  Future<void> _loadThumbnails(List refs) async {
    for (final ref in refs) {
      final url = ref['url'];
      if (!_thumbnailCache.containsKey(url)) {
        final thumb = await fetchOgImage(url);
        if (mounted) {
          setState(() {
            _thumbnailCache[url] = thumb;
          });
        }
      }
    }
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    if (!_searchStarted) {
      setState(() {
        _searchStarted = true;
      });
      _animationController.forward();
    }

    setState(() {
      _isLoading = true;
    });

    // Add user message
    final userMessage = ChatMessage(
      content: query,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await _chatService.addMessage(userMessage);
    setState(() {
      _messages.add(userMessage);
    });

    try {
      final result = await _searchService.searchNews(
        query: query,
        publisher: _selectedPublisher == '전체' ? null : _selectedPublisher,
      );
      final answer = result['answer'] ?? '';
      final references = result['references'] as List? ?? [];
      String botContent = answer;
      if (references.isNotEmpty) {
        botContent += '\n\n[관련 기사]\n';
        for (final ref in references) {
          botContent +=
              '• <b>${ref['title']}</b>\n  ${ref['summary']}\n  <a href="${ref['url']}">${ref['url']}</a>\n';
        }
      }
      final botMessage = ChatMessage(
        content: botContent,
        isUser: false,
        timestamp: DateTime.now(),
      );
      await _chatService.addMessage(botMessage);
      setState(() {
        _messages.add(botMessage);
      });
    } catch (e) {
      final errorMessage = ChatMessage(
        content: '검색 중 오류가 발생했습니다.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      await _chatService.addMessage(errorMessage);
      setState(() {
        _messages.add(errorMessage);
      });
    }

    setState(() {
      _isLoading = false;
      _searchController.clear();
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
}

class ChatHistoryScreen extends StatefulWidget {
  final ChatService chatService;
  final void Function(List<ChatMessage>) onChatSelected;
  const ChatHistoryScreen(
      {super.key, required this.chatService, required this.onChatSelected});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  Map<String, dynamic> _folders = {};

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final folders = await widget.chatService.getFolders();
    setState(() {
      _folders = folders;
    });
  }

  Future<void> _deleteFolder(String folderName) async {
    await widget.chatService.deleteFolder(folderName);
    await _loadFolders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('저장된 대화'), centerTitle: true),
      body: ListView.builder(
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
                  '생성일: \\${DateTime.parse(folder['createdAt']).toString().split('.')[0]}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteFolder(folderName),
              ),
              onTap: () async {
                final messages =
                    await widget.chatService.getFolderMessages(folderName);
                widget.onChatSelected(messages);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PublisherSelectDialog extends StatefulWidget {
  final List<String> publishers;
  final String? selected;
  const _PublisherSelectDialog({required this.publishers, this.selected});

  @override
  State<_PublisherSelectDialog> createState() => _PublisherSelectDialogState();
}

class _PublisherSelectDialogState extends State<_PublisherSelectDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.publishers
        .where((p) => p.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 350,
        height: 500,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '언론사 검색',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none),
                  filled: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (context, idx) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final pub = filtered[idx];
                  return ListTile(
                    title: Text(pub),
                    selected: pub == widget.selected,
                    onTap: () => Navigator.pop(context, pub),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
