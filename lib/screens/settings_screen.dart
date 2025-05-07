import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/keyword_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late KeywordService _keywordService;
  List<String> _selectedKeywords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initKeywordService();
  }

  Future<void> _initKeywordService() async {
    final prefs = await SharedPreferences.getInstance();
    _keywordService = KeywordService(prefs);
    final savedKeywords = await _keywordService.getSelectedKeywords();
    setState(() {
      _selectedKeywords = savedKeywords;
      _isLoading = false;
    });
  }

  Future<void> _toggleKeyword(String keyword) async {
    setState(() {
      if (_selectedKeywords.contains(keyword)) {
        _selectedKeywords.remove(keyword);
        _keywordService.removeKeyword(keyword);
      } else {
        _selectedKeywords.add(keyword);
        _keywordService.addKeyword(keyword);
      }
    });
  }

  Future<void> _clearAllKeywords() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('키워드 초기화'),
        content: const Text('선택한 모든 키워드가 삭제됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '초기화',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _keywordService.clearKeywords();
      setState(() {
        _selectedKeywords.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 키워드 관리 섹션
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tag,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '관심 키워드 관리',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '선택한 키워드에 관련된 뉴스를 추천해드립니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedKeywords.isNotEmpty) ...[
                        Text(
                          '선택된 키워드 (${_selectedKeywords.length}개)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedKeywords.map((keyword) {
                            return Chip(
                              label: Text(keyword),
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () => _toggleKeyword(keyword),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                      ],
                      const Text(
                        '추가할 키워드',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          '정치',
                          '경제',
                          '사회',
                          '국제',
                          '문화',
                          '스포츠',
                          'IT',
                          '과학',
                          '환경',
                          '교육',
                        ].map((keyword) {
                          final isSelected = _selectedKeywords.contains(keyword);
                          return FilterChip(
                            label: Text(keyword),
                            selected: isSelected,
                            onSelected: (selected) => _toggleKeyword(keyword),
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            selectedColor: Theme.of(context).colorScheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                            ),
                            showCheckmark: false,
                          );
                        }).toList(),
                      ),
                      if (_selectedKeywords.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: _clearAllKeywords,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text(
                              '모든 키워드 초기화',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 