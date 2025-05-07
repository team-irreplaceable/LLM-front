import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';
import '../services/keyword_service.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final List<String> _selectedKeywords = [];
  late KeywordService _keywordService;
  
  // 임시 키워드 목록
  final List<String> _availableKeywords = [
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
  ];

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
      _selectedKeywords.addAll(savedKeywords);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                '환영합니다!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '관심 있는 키워드를 선택해주세요',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _availableKeywords.length,
                  itemBuilder: (context, index) {
                    final keyword = _availableKeywords[index];
                    final isSelected = _selectedKeywords.contains(keyword);
                    
                    return InkWell(
                      onTap: () => _toggleKeyword(keyword),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary 
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? Theme.of(context).colorScheme.primary 
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            keyword,
                            style: TextStyle(
                              color: isSelected 
                                  ? Colors.white 
                                  : Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '시작하기',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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