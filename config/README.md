# Configuration Guide

이 디렉토리는 AI Simulation Game의 설정 파일들을 관리합니다.

## 📁 구조

```
config/
├── agents/                    # 에이전트 팀 설정
│   ├── team_config.json      # 개발 팀 역할 및 책임 정의
│   └── agent_prompts.json    # 각 에이전트별 전용 프롬프트
├── environments/             # 환경별 설정
│   ├── development.json      # 개발 환경 설정
│   ├── production.json       # 배포 환경 설정  
│   ├── testing.json         # 테스트 환경 설정
│   └── local.example.json   # 로컬 설정 템플릿
└── README.md               # 이 파일
```

## 🤖 에이전트 팀

### 팀 구성 (team_config.json)
- **GameDesigner**: 게임 메커니즘 및 밸런싱
- **AIEngineer**: Utility AI 시스템 개발
- **SystemsArchitect**: 아키텍처 설계 및 최적화
- **UIUXDesigner**: 사용자 인터페이스 설계
- **QAAnalyst**: 품질 보증 및 테스트
- **DataScientist**: 데이터 분석 및 인사이트

### 에이전트 활용 방법
```json
// agent_prompts.json에서 각 에이전트별 전용 프롬프트 확인
{
  "GameDesigner": {
    "system_prompt": "게임 디자이너 전용 프롬프트...",
    "context": [...],
    "guidelines": [...]
  }
}
```

## 🌍 환경 설정

### Development Environment (development.json)
- 디버그 모드 활성화
- 상세한 로깅 
- 개발 도구 활성화
- 성능 모니터링

### Production Environment (production.json) 
- 최적화된 성능 설정
- 최소한의 로깅
- 디버그 기능 비활성화
- 메모리 관리 최적화

### Testing Environment (testing.json)
- 작은 규모 시뮬레이션 (10 에이전트)
- 결정적 동작 (고정 시드)
- 빠른 의사결정 간격
- 자동 테스트 도구

### Local Environment (local.json)
⚠️ **보안 주의**: 이 파일은 `.gitignore`에 포함되어 있습니다.

1. `local.example.json`을 `local.json`으로 복사
2. API 키 및 개인 설정 입력
3. 절대 Git에 커밋하지 마세요

```bash
cp config/environments/local.example.json config/environments/local.json
# local.json 파일을 편집하여 개인 설정 추가
```

## 🔒 보안

### 민감한 정보 관리
다음 정보들은 `.gitignore`에 의해 Git 추적에서 제외됩니다:
- API 키 및 토큰
- 데이터베이스 연결 정보  
- 개인 설정 파일 (local.json)
- 인증서 파일 (.key, .pem 등)

### 안전한 설정 방법
1. **절대 하지 말아야 할 것**:
   - API 키를 코드에 직접 입력
   - 개인 설정을 public 레포지토리에 커밋
   - 비밀번호를 평문으로 저장

2. **권장 방법**:
   - `local.example.json`을 템플릿으로 활용
   - 환경 변수 또는 별도 설정 파일 사용
   - 민감한 정보는 암호화하여 저장

## 🚀 사용 방법

### 1. 에이전트 팀 활용
```javascript
// 특정 에이전트로 작업할 때
const gameDesigner = require('./config/agents/agent_prompts.json').agent_prompts.GameDesigner;
// 해당 에이전트의 system_prompt와 guidelines 활용
```

### 2. 환경 설정 적용
```gdscript
# Godot에서 환경 설정 로드 예시
func load_environment_config(env_name: String):
    var file = FileAccess.open("res://config/environments/" + env_name + ".json", FileAccess.READ)
    var config = JSON.parse_string(file.get_as_text())
    apply_config(config)
```

### 3. 개발 워크플로
1. 기능 개발시 해당 에이전트 역할로 작업
2. 환경별 설정에 맞는 테스트 수행  
3. 변경사항을 team_config.json에 반영
4. 보안 검토 후 커밋

## 📝 업데이트 가이드

### 새 에이전트 추가
1. `team_config.json`에 에이전트 정보 추가
2. `agent_prompts.json`에 프롬프트 설정 추가
3. 역할 및 책임 명확히 정의

### 환경 설정 수정
1. 해당 환경 JSON 파일 수정
2. 변경 사항 문서화
3. 다른 환경에 미치는 영향 검토

이 설정 구조를 통해 팀원들이 일관된 개발 환경에서 협업할 수 있습니다.