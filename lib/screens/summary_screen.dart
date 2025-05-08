import 'package:flutter/material.dart';
import '../services/search_service.dart';
import '../services/keyword_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final SearchService _searchService = SearchService();
  late KeywordService _keywordService;
  Map<String, dynamic> _summaries = {};
  bool _isLoading = true;
  final HtmlUnescape _unescape = HtmlUnescape();
  final Map<String, String?> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    _keywordService = KeywordService(prefs);
    await _loadSummaries();
  }

  Future<void> _loadSummaries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final keywords = await _keywordService.getSelectedKeywords();
      final summaryResponse =
          await _searchService.getMultipleKeywordSummaries(keywords);

      // 응답 구조: { results: [ {keyword: ..., articles: [...]}, ... ] }
      final summaries = <String, dynamic>{};
      for (final item in summaryResponse['results']) {
        summaries[item['keyword']] = item;
      }

      setState(() {
        _summaries = summaries;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('요약을 불러오는 중 오류가 발생했습니다.')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
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

  Future<void> _loadThumbnails(List results) async {
    for (final result in results) {
      final url = result['url'];
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

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('키워드 요약'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummaries,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _summaries.length,
        itemBuilder: (context, index) {
          final keyword = _summaries.keys.elementAt(index);
          final summary = _summaries[keyword];
          final results = summary['articles'] as List;

          _loadThumbnails(results);

          return Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            margin: const EdgeInsets.only(bottom: 24),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.label_important,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28),
                      const SizedBox(width: 10),
                      Text(
                        keyword,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2)),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: results.length,
                    separatorBuilder: (context, idx) => Divider(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1)),
                    itemBuilder: (context, resultIndex) {
                      final result = results[resultIndex];
                      final url = result['url'];
                      final thumbnail = _thumbnailCache[url];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 0),
                        leading: thumbnail != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  thumbnail,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.broken_image),
                                ),
                              )
                            : Icon(Icons.article,
                                color: Theme.of(context).colorScheme.secondary,
                                size: 28),
                        title: Text(
                          _unescape.convert(result['title']),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              _unescape.convert(result['summary']),
                              style: const TextStyle(fontSize: 14, height: 1.5),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.link,
                                    size: 14,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () => _launchUrl(result['url']),
                                    child: Text(
                                      result['url'],
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
