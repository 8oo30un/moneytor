# Moneytor - 개인 맞춤형 지출 관리 앱

Flutter와 Firebase 기반의 지출 관리 앱 **Moneytor**는 사용자의 **카테고리별 지출 습관**을 분석하여, 월별 예산 설정, 실시간 소비 현황 추적, 과소비 경고 등 **개인 맞춤형 피드백**을 제공합니다.

---

## 📱 주요 기능

- ✅ **카테고리별 지출 카드 등록**
- 📊 **파이차트를 통한 비율 시각화**
- 🎯 **카테고리/전체 목표 지출 설정 및 상태 분석**
- 📅 **캘린더 기반 지출 조회**
- ☁️ **Firebase 연동으로 사용자별 데이터 저장 및 관리**
- 🔄 **매월 1일 자동 데이터 초기화**
- 👤 **Google 로그인 / 익명 로그인 지원**

---

## 🛠️ 기술 스택

| 구분     | 사용 기술                                  |
| -------- | ------------------------------------------ |
| UI       | Flutter, Dart, Material Design, Lottie     |
| 상태관리 | `provider` 패키지                          |
| Backend  | Firebase Auth, Firestore, Firebase Storage |
| 시각화   | `pie_chart`, `table_calendar` 패키지       |

---

## 🧩 주요 패키지

| 패키지명         | 설명               | URL                                                       |
| ---------------- | ------------------ | --------------------------------------------------------- |
| `provider`       | 상태 관리          | [provider](https://pub.dev/packages/provider)             |
| `table_calendar` | 달력 UI 위젯       | [table_calendar](https://pub.dev/packages/table_calendar) |
| `pie_chart`      | 원형 차트 시각화   | [pie_chart](https://pub.dev/packages/pie_chart)           |
| `lottie`         | 애니메이션 로딩 등 | [lottie](https://pub.dev/packages/lottie)                 |

---

## 🚀 실행 방법

1. 이 저장소를 클론합니다.

   ```bash
   git clone https://github.com/your-username/moneytor.git
   cd moneytor
   ```

2. 패키지를 설치합니다.

   ```bash
   flutter pub get
   ```

3. Firebase 연동을 위해 `google-services.json` (Android) 및 `GoogleService-Info.plist` (iOS)를 프로젝트에 추가합니다.

4. 실행
   ```bash
   flutter run
   ```

---

## 🖼️ 주요 스크린샷

| 홈 페이지                             | 로그인 페이지                            | 그래프 페이지                            | 캘린더 페이지                                  |
| ------------------------------------- | ---------------------------------------- | ---------------------------------------- | ---------------------------------------------- |
| ![home](/assets/screenshots/home.png) | ![login](/assets/screenshots/login.png)) | ![graph](/assets/screenshots/graph.png)) | ![calendar](/assets/screenshots/calendar.png)) |

---

## 🧠 프로젝트 설계

### ✅ 상태 관리 구조 (Provider 기반)

- `AppState` 클래스에서 사용자 상태, 카드 정보, 지출 데이터, 목표 설정 상태를 통합 관리
- `ChangeNotifier`로 UI와 비동기 연동
- `reloadAllData()` 메서드를 통해 Firestore에서 데이터를 불러와 자동 상태 재계산

### 🗂️ Firebase 구조

```
users (collection)
 └── {userId} (document)
      ├── monthlyGoal
      ├── totalSpending
      ├── lastCalculatedSpending
      └── register_cards (subcollection)
           └── {cardId} (document)
                ├── name
                ├── spendingGoal
                ├── totalAmount
                └── expenses (List)
```

---

## 🔧 향후 계획 (v1.5, 2.0…)

- ✅ 다크 모드 지원
- 📈 지출 통계 차트 추가
- 🔔 목표 초과 알림 기능
- 📦 내보내기 및 백업 기능 (CSV, PDF)
- 👥 가족 또는 그룹 지출 공유 기능

---

## 👤 팀원 및 담당 역할

| 이름   | 역할                                                                 |
| ------ | -------------------------------------------------------------------- |
| 김우현 | 전체 개발, UI/UX 설계, 상태관리 구조 설계, Firebase 연동 및 유지보수 |

> 실시간 상태 변화 처리와 사용자 경험에 중점을 두어 실무적인 앱 구조를 경험했습니다.  
> 향후 다른 앱에도 적용할 수 있는 템플릿으로 발전시키고 싶습니다.

---

## 🤝 기여 및 문의

기여를 환영합니다!  
버그 제보나 기능 제안은 Issues로 남겨주시고, PR은 언제든 환영입니다.

---

## 🔗 참고 링크

- [Flutter 공식 문서](https://flutter.dev/)
- [Firebase 문서](https://firebase.google.com/docs)
