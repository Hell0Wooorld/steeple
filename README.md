# 스티플 (Steeple)

> 방황하는 발걸음에, 건강한 교회로 가는 이정표

멀리서도 보이는 첨탑처럼, 교회를 찾는 사람에게 건강한 교회를 안내하는 웹 서비스의 **첫 프로토타입**입니다.
이사 온 사람, 초신자, 교회를 옮기려는 사람을 주 사용자로 생각하고 모바일 화면을 먼저 설계했습니다.

> ⚠️ 이 저장소의 교회 정보는 모두 **가상의 예시 데이터**(부산 25곳)입니다. 실제 교회와 무관합니다.

## 주요 기능

- **지도 + 목록**: OpenStreetMap 지도에 교회 핀을 표시하고 목록과 함께 보여 줍니다. (API 키 불필요)
- **검색과 필터**: 지역(구/동), 교단, 주일 예배 시간대, 교회 규모
- **내 주변 교회**: 브라우저 위치 권한으로 가까운 교회 순 정렬 (위치 정보는 서버로 전송되지 않고 브라우저 안에서만 사용)
- **교회 상세**: 교단, 주소, 예배 시간, 담임목사, 규모, 부서, 연락처, 소개
- **교단 안내**: 주요 교단 소개
- **이단 바로 알기**: 교단 총회의 공식 결의를 출처와 함께 싣기 위한 구조만 마련 (현재 "자료 준비 중"). 개별 교회에 이단 표시를 붙이는 기능은 없습니다.

## 기술 스택

Vite + React + TypeScript, Leaflet + OpenStreetMap, React Router(HashRouter). 서버 없는 정적 사이트이며 데이터는 JSON 파일로 관리합니다.

## 실행 방법

Node.js 22 이상이 필요합니다.

```bash
npm install
npm run dev      # 개발 서버 (http://localhost:5173)
npm run build    # 타입 검사 + 프로덕션 빌드 (dist/)
npm run preview  # 빌드 결과 미리보기
```

## 배포 방법 (GitHub Pages)

`.github/workflows/deploy.yml`이 `main` 브랜치에 push될 때마다 빌드해서 GitHub Pages에 배포합니다.

1. GitHub 저장소의 **Settings → Pages**로 이동합니다.
2. **Build and deployment → Source**를 **GitHub Actions**로 선택합니다.
3. `main`에 병합(push)하면 Actions 탭에서 배포가 진행되고, 완료 후 `https://<아이디>.github.io/Steeple/`에서 볼 수 있습니다.

정적 호스팅에서 새로고침 시 404가 나지 않도록 `HashRouter`(주소가 `#/경로` 형태)를 쓰고, Vite의 `base`는 `./`로 두었습니다. 그래서 저장소 이름이 바뀌어도 설정을 고칠 필요가 없습니다.

## 폴더 구조

```
src/
  data/
    churches.json            교회 데이터
    denominations.json       교단 소개
    heresy-resolutions.json  이단 결의 자료(현재 비어 있음)
  lib/                       데이터 로드, 필터, 거리 계산
  components/                지도, 카드, 필터, 레이아웃, 로고
  pages/                     홈, 교회 찾기, 상세, 교단 안내, 이단 바로 알기
```

## 데이터 형식

### `src/data/churches.json` — 교회 배열

| 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `id` | string | ✅ | 고유 ID. 주소(`#/church/<id>`)에 쓰이므로 영문·숫자 권장 (예: `c01`) |
| `name` | string | ✅ | 교회 이름 |
| `denomination` | string | ✅ | `denominations.json`의 `id` (예: `tonghap`) |
| `address` | string | ✅ | 도로명 주소 전체 |
| `district` | string | ✅ | 구/군 (예: `북구`). 필터에 쓰입니다 |
| `dong` | string | ✅ | 동 (예: `화명동`). 필터에 쓰입니다 |
| `lat`, `lng` | number | ✅ | 위도, 경도 (지도 핀과 거리 계산에 사용) |
| `pastor` | string | ✅ | 담임목사 이름 (직함 "목사"는 화면에서 붙입니다) |
| `size` | `"small"` \| `"medium"` \| `"large"` | ✅ | 규모. 소형 100명 미만, 중형 100~499명, 대형 500명 이상 (주일 출석 기준) |
| `attendance` | number | ✅ | 주일 출석 인원(대략) |
| `services` | 배열 | ✅ | 예배 목록. 아래 참고 |
| `departments` | string[] | ✅ | 부서 (예: `영유아부`, `청소년부`, `청년부`) |
| `website` | string | | 홈페이지 주소 (https:// 포함) |
| `phone` | string | | 대표 연락처 |
| `intro` | string | ✅ | 1~2문장 소개 |

`services` 항목:

| 필드 | 설명 |
| --- | --- |
| `name` | 예배 이름 (예: `주일 1부 예배`) |
| `day` | 요일 (`주일`, `수요일`, `금요일`, `매일`, `평일` 등). **`주일`로 적힌 예배만** 시간대 필터에 사용됩니다 |
| `time` | `"HH:MM"` 24시간 형식 |

주일 예배 시간대 필터는 시작 시각 기준으로 오전(12시 이전), 오후(12~18시), 저녁(18시 이후)으로 나눕니다.

### `src/data/denominations.json` — 교단 배열

`id`, `name`(약칭), `fullName`(정식 명칭), `tradition`, `summary`(소개), `features`(특징 목록). 새 교단을 추가하면 교회 필터와 교단 안내 페이지에 자동으로 나타납니다.

### `src/data/heresy-resolutions.json` — 이단 결의 자료

교단별로 `denominationId`, `status`(`"preparing"` 또는 `"published"`), `entries` 배열을 둡니다. `status`가 `"published"`이고 `entries`가 있으면 표로 표시되고, 아니면 "자료 준비 중"으로 보입니다. `entries` 항목은 다음 필드를 가집니다.

| 필드 | 설명 |
| --- | --- |
| `year` | 결의 연도 |
| `target` | 결의 대상 단체명 |
| `summary` | 결의 내용 요약 |
| `sourceName` | 총회명과 문서명 (필수) |
| `sourceUrl` | 확인 가능한 출처 링크 (선택) |

**게재 원칙**: 총회가 공식 절차로 결의한 내용만, 확인 가능한 출처와 함께 싣습니다. 이 구조는 단체·가르침에 대한 교단 결의를 보여 주기 위한 것이며, 개별 교회에 이단 표시를 붙이는 기능은 의도적으로 만들지 않았습니다.

## 다음 단계

1. **실제 데이터 수집**: 예시 데이터를 실제 교회 정보로 교체합니다. 교회 본인 확인(승인)을 받은 정보만 싣고, 정보 기준일을 함께 표시하는 것을 권장합니다.
2. **교회 등록 신청 기능**: 교회가 직접 정보를 신청·수정할 수 있는 폼과 관리자 검수 흐름을 추가합니다. (정적 사이트이므로 폼 서비스나 GitHub 이슈 연동부터 시작하는 방법이 있습니다.)
3. **이단 바로 알기 자료**: 각 교단 총회의 공식 결의와 출처를 확인해 채웁니다.
4. **Pews와의 연결**: 교회 상세 화면에서 Pews로 이어지는 연결 방식을 설계합니다.

## 라이선스와 출처

지도 타일과 지도 데이터 © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors. OpenStreetMap 공식 타일 서버는 가벼운 사용을 위한 것이므로, 이용자가 늘면 별도 타일 제공 서비스를 검토해야 합니다.
