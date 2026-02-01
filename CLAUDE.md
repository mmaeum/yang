# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

Yang은 SwiftUI 기반의 iOS 앱으로, 일일 비디오 녹화를 위한 "Memory Bank" 역할을 합니다. 사용자는 하루에 하나의 비디오를 녹화할 수 있으며, 이는 사용자 정의 사진 앨범에 저장되고 3D 공간에서 상호작용 가능한 "별"로 시각화됩니다.

## 개발 명령어

### 빌드 및 실행
- Xcode에서 `yang.xcodeproj` 열기
- Xcode의 빌드 명령어 사용 (⌘+B로 빌드, ⌘+R로 실행)
- 배포 대상: iOS 18.4+
- Swift 버전: 5.0

### 테스트
- 단위 테스트: `yangTests/yangTests.swift`
- UI 테스트: `yangUITests/yangUITests.swift` 및 `yangUITestsLaunchTests.swift`
- Xcode의 테스트 네비게이터 또는 ⌘+U로 테스트 실행

### 패키지 의존성
- **RiveRuntime** (v6.10.0): 런치 스크린 애니메이션에 사용
- 의존성은 Swift Package Manager로 관리되며 `Package.resolved`에서 해결됨

## 아키텍처 및 코드 구조

### 핵심 앱 플로우
1. **런치 스크린**: Rive 애니메이션(`launch_animation.riv`)을 4초간 표시
2. **사진 라이브러리 확인**: 사용자가 오늘 "yang" 앨범에 비디오를 녹화했는지 확인
3. **조건부 네비게이션**:
   - 오늘의 비디오가 있으면 → `ContentView` (Memory Bank) 표시
   - 오늘의 비디오가 없으면 → `VideoRecordingView` (녹화 인터페이스) 표시

### 주요 컴포넌트

#### 앱 상태 관리
- `AppState` (`yangApp.swift`에 위치): `@ObservableObject`를 사용한 글로벌 상태
  - `isLaunching`: 런치 스크린 표시 제어
  - `hasTodayVideo`: 사용자가 오늘 비디오를 녹화했는지 추적
  - `isCheckingPhotos`: 사진 라이브러리 확인 로딩 상태

#### 비디오 녹화 시스템
- `VideoRecordingView`: 커스텀 십자선 오버레이가 있는 카메라 인터페이스
- `VideoRecordingViewModel`: AVFoundation 카메라 세션, 3초 녹화 타이머, 사진 앨범 관리 처리
- 비디오는 자동으로 사진 앱의 사용자 정의 "yang" 앨범에 저장됨

#### 메모리 시각화
- `ContentView`: 3D 별 필드가 있는 메인 메모리 뱅크 인터페이스
- `StarListView`: SceneKit 기반의 3D 인터랙티브 뷰
- `Star`: 3D 위치를 가진 비디오 자산을 나타내는 데이터 모델
- 비디오는 시드 기반 랜덤 생성을 사용하여 위치가 지정된 흰색 구체로 표시됨

#### 유틸리티
- `PhotoLibraryChecker`: 사진 라이브러리 권한 및 오늘의 비디오 확인 처리
- 앨범 관리: 사진 앱에서 사용자 정의 "yang" 앨범 생성 및 관리

### UI/UX 패턴
- 전체적으로 검은 배경 테마
- 모노스페이스 폰트 (SF Pro, Share Tech Mono, Press Start 2P)
- 전체 화면 모달 프레젠테이션
- 십자선 오버레이가 있는 커스텀 카메라 프리뷰
- 별 시각화를 위한 3D SceneKit 통합

### 필요한 권한
- 비디오 녹화를 위한 카메라 접근
- 오디오 녹화를 위한 마이크 접근
- 비디오 저장 및 검색을 위한 사진 라이브러리 접근
- 권한은 앱 플로우를 통해 점진적으로 요청됨

### 데이터 플로우
1. 앱 실행 → 사진 라이브러리 권한 확인
2. 사진 라이브러리 확인 → 오늘의 비디오 존재 여부 결정
3. 비디오 녹화 → 사용자 정의 앨범에 저장 → 앱 상태 업데이트
4. 메모리 뱅크 → 앨범에서 비디오 로드 → 3D 별 위치 생성
5. 별 상호작용 → 전체 화면 모달로 비디오 표시

### 주요 파일 구조
- `yang/yangApp.swift`: 메인 앱 진입점 및 상태 관리
- `yang/ContentView.swift`: 기본 메모리 뱅크 인터페이스
- `yang/Features/Camera/`: 비디오 녹화 기능
- `yang/Features/Star/`: 3D 별 시각화 및 상호작용
- `yang/Utils/PhotoLibraryChecker.swift`: 사진 라이브러리 유틸리티