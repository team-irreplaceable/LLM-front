# 📱 Flutter 기반 뉴스 요약 RAG 서비스 (프론트엔드)

FastAPI + LangChain 기반 뉴스 요약 시스템의 **Flutter 클라이언트**입니다.  
사용자는 검색어를 입력하고, 관련 뉴스를 실시간으로 요약된 형태로 받아볼 수 있습니다.

---

## 🧩 사용 기술

| 구성 요소             | 역할                              |
|----------------------|-----------------------------------|
| **Flutter**           | 검색 UI 및 요약 결과 출력          |


---

## ⚙️ 설정

1. **Flutter 설치**  
   👉 [https://docs.flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install)

2. **의존성 설치**

   ```bash
   flutter pub get
   ```

3. **API 서버 주소 설정**
   lib/config.dart 파일에 다음 내용을 추가하거나 수정하세요:
```const String baseUrl = 'http://localhost:8000'; // 실제 FastAPI 서버 주소로 변경```

4. **실행**
   ```flutter run```

