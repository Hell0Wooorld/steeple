import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase 프로젝트 설정값.
///
/// Firebase 콘솔 → 프로젝트 설정 → 내 앱(Android)에서 받은 google-services.json의 값을
/// 채워 넣으세요. 값이 비어 있으면 앱은 Firebase 없이 기기 저장 모드로 동작합니다.
/// 이 값들은 비밀번호가 아니며(앱 안에 그대로 들어감), 데이터 보호는 보안 규칙이 맡습니다.
///
///   apiKey            ← client[0].api_key[0].current_key
///   appId             ← client[0].client_info.mobilesdk_app_id
///   messagingSenderId ← project_info.project_number
///   projectId         ← project_info.project_id
///   storageBucket     ← project_info.storage_bucket
class FirebaseConfig {
  static const android = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    storageBucket: '',
  );

  /// iOS 앱을 Firebase에 등록한 뒤 GoogleService-Info.plist 값으로 채웁니다.
  static const ios = FirebaseOptions(
    apiKey: '',
    appId: '',
    messagingSenderId: '',
    projectId: '',
    storageBucket: '',
    iosBundleId: 'kr.sungong.sungong',
  );

  /// 현재 플랫폼의 설정. 아직 채워지지 않았으면 null.
  static FirebaseOptions? get current {
    if (kIsWeb) return null;
    final options = switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => null,
    };
    if (options == null || options.apiKey.isEmpty || options.appId.isEmpty) return null;
    return options;
  }
}
