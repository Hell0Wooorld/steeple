# 순공 (프로토타입)

순공 시간을 재고 시간에 따라 포인트를 주는 앱의 **첫 안드로이드 프로토타입**입니다.
Flutter로 만들어 같은 코드로 iOS 앱도 만들 수 있습니다.

## 동작 방식

1. **순공 시작**을 누르고 폰을 화면이 바닥을 향하게 뒤집어 둡니다.
2. 가속도 센서로 뒤집힌 상태를 감지하고(1.2초 이상 유지돼야 인정), 뒤집혀 있는 시간만 순공 시간으로 쌓습니다.
3. 뒤집혀 있는 동안은 화면을 완전히 검게 만들고 화면 꺼짐을 막습니다. OLED 화면에서는 꺼진 것과 비슷하게 전력을 거의 쓰지 않습니다.
   - 화면을 실제로 꺼 버리지 않는 이유: 화면이 꺼지면 앱이 멈춰서, 그 사이 다른 앱을 썼는지 확인할 수 없습니다.
4. 폰을 들거나, 다른 앱으로 나가거나, 전원 버튼으로 화면을 끄면 **일시정지**됩니다. 다시 뒤집으면 이어서 기록됩니다.
5. 끝내면 순공 1분당 1P를 적립합니다 (1분 미만은 적립 없음, 하루 한도 600P).
6. 결과 화면에서 **보상형 광고**를 보면 같은 양의 포인트를 한 번 더 받습니다. 지금은 5초짜리 가짜 광고 자리입니다.

포인트 정책은 `lib/logic/rewards.dart`의 `RewardPolicy`에서 바꿉니다. 바꾸면 서버 규칙(`firebase/firestore.rules`의 `pointsPerMinute`, `dailyCap`)도 같이 바꿔야 합니다.

## 로그인과 서버 저장 (Firebase)

- **로그인**: 이메일·비밀번호 회원가입과 로그인, 비밀번호 재설정 메일 (Firebase Authentication)
- **저장**: 순공 기록과 포인트를 서버(Cloud Firestore)에 저장해서, 앱을 지우거나 폰을 바꿔도 남습니다.
- **조작 방지**: 포인트는 앱이 마음대로 쓸 수 없고, 서버 보안 규칙이 서버 시간으로 검사합니다.
  - 순공 시작과 종료 시각을 서버 시간으로 기록하고, 실제로 흐른 시간보다 긴 순공 시간은 거부
  - 포인트 = 순공 분 수 (하루 600P 한도, 한국 시간 기준). 다른 값을 넣으면 거부
  - 광고 보너스는 세션당 한 번, 같은 양만
  - 동시에 여러 세션을 열어 부풀리기 불가 (새로 시작하면 이전 세션은 저장 불가)
  - 다른 사람의 기록은 읽거나 쓸 수 없음
- **한계**: 폰이 실제로 뒤집혀 있었는지는 서버가 확인할 수 없습니다. 하루 한도가 피해를 제한합니다.

`lib/firebase_options.dart`가 비어 있으면 앱은 로그인 없이 **기기 저장 모드**로 동작합니다.

### Firebase 프로젝트 만들기 (무료 Spark 요금제로 충분)

1. [Firebase 콘솔](https://console.firebase.google.com)에서 **프로젝트 추가**를 누릅니다. Google 애널리틱스는 꺼도 됩니다.
2. **Authentication → 시작하기 → 로그인 방법**에서 **이메일/비밀번호**를 사용 설정합니다.
3. **Firestore Database → 데이터베이스 만들기**를 누르고, 위치는 `asia-northeast3 (서울)`, 모드는 **프로덕션 모드**로 고릅니다.
4. Firestore의 **규칙** 탭에 `firebase/firestore.rules` 내용을 모두 붙여 넣고 **게시**합니다.
5. **프로젝트 설정(톱니바퀴) → 내 앱 → Android 앱 추가**에서 패키지 이름을 `kr.sungong.sungong`으로 등록하고 `google-services.json`을 내려받습니다.
6. 그 파일의 값을 `lib/firebase_options.dart`에 채웁니다 (어느 값이 어디로 가는지 파일 안에 적혀 있음).

### 보안 규칙 테스트

Node.js 22와 Java 21이 필요합니다. Firebase 에뮬레이터에서 규칙을 검사합니다 (실제 프로젝트 불필요).

```bash
cd sungong/firebase
npm ci
npm test
```

## APK 받기

`sungong/` 폴더가 바뀌어 푸시될 때마다 GitHub Actions(`.github/workflows/sungong-android.yml`)가 앱 테스트와 보안 규칙 테스트를 돌리고 APK를 빌드합니다.

1. GitHub 저장소의 **Actions** 탭에서 `순공 Android APK` 실행을 엽니다.
2. 맨 아래 **Artifacts**의 `sungong-apk`를 내려받아 압축을 풉니다.
3. 안드로이드 폰에 `app-release.apk`를 옮겨 설치합니다. 처음이면 "출처를 알 수 없는 앱 설치"를 허용해야 합니다.

현재 APK는 개발용 디버그 키로 서명돼 있습니다. Play 스토어에 올리려면 업로드 키를 따로 만들어야 합니다.

## 직접 실행하기

[Flutter SDK](https://docs.flutter.dev/get-started/install)와 Android Studio(안드로이드 SDK)가 필요합니다.

```bash
cd sungong
flutter pub get
flutter test          # 로직 테스트
flutter run           # 연결된 폰이나 에뮬레이터에서 실행
```

에뮬레이터에서는 폰을 뒤집을 수 없으니, 디버그 실행일 때만 보이는 **테스트: 뒤집기 시뮬레이션** 버튼을 쓰세요.
검은 화면을 두 번 탭하면 폰을 든 것으로 처리됩니다. 이 두 기능은 릴리스 APK에는 없습니다.

## 코드 구조

| 파일 | 역할 |
|---|---|
| `lib/logic/flip_detector.dart` | 가속도 센서 값으로 뒤집힘 판정 |
| `lib/logic/study_session.dart` | 세션 상태와 순공 시간 계산 |
| `lib/logic/rewards.dart` | 포인트 정책 (분당 포인트, 하루 한도) |
| `lib/data/study_repository.dart` | 저장소 인터페이스와 기록 모델 |
| `lib/data/firestore_repository.dart` | Firebase 서버 저장 |
| `lib/data/local_repository.dart` | 기기 저장 (Firebase 설정 전) |
| `lib/firebase_options.dart` | Firebase 프로젝트 설정값 |
| `firebase/firestore.rules` | 서버 보안 규칙 (포인트 검증) |
| `firebase/tests/` | 보안 규칙 테스트 |
| `lib/ads/reward_ad.dart` | 보상형 광고 자리 (지금은 가짜) |
| `lib/screens/` | 로그인, 홈, 순공 중, 결과 화면 |

## 실제 서비스 전에 해야 할 일

- **광고**: `lib/ads/reward_ad.dart`를 AdMob 보상형 광고(`google_mobile_ads`)로 바꿉니다. 광고는 사용자가 화면을 보고 있을 때만 보여 줘야 합니다. 지금은 광고 보너스를 앱이 요청하면 서버가 주므로, 실제 광고 시청을 서버에서 확인하려면 AdMob 서버 측 확인(SSV)과 Cloud Functions(유료 Blaze 요금제)가 필요합니다.
- **소셜 로그인**: Google·카카오 로그인은 고정된 앱 서명 키가 필요해서, 플레이 스토어 출시 준비 때 붙이는 것이 좋습니다.
- **보상 지급**: 포인트를 기프티콘 등으로 교환하는 기능, 1P의 가치 결정.
- **부정 사용 방지**: 무작위 확인 알림, 기기·계정 중복 제한 등.
- **iOS**: 같은 코드로 빌드할 수 있지만, Mac과 Xcode가 필요하고 실제 기기에서 따로 확인해야 합니다.
