# Cross-Platform Terminal Setup (WezTerm + Nushell + Starship)

목표: **macOS / Linux** 에서 **동일한 UX**로 동작하는 터미널 환경 구축  
원칙: **OS 색채 최소화**, 설정은 **단일 소스(공유 dotfiles)**, 설치는 **Nix 기반**

---

## 📋 성공 기준 (Definition of Done)

- [ ] WezTerm 실행 시 기본 셸이 **Nushell**로 열린다 (macOS/Linux 모두)
- [ ] 프롬프트가 **Starship**으로 통일된다 (동일한 UI)
- [ ] 설정 파일은 모두 `~/.config/` 하위에서 관리된다
- [ ] 폰트: **JetBrainsMono Nerd Font** 적용되어 아이콘/폭/라인 높이가 동일
- [ ] 탭바: 1개면 숨김, fancy 탭바 끄기, 장식 최소화
- [ ] 키바인딩: 기존 WezTerm 기본값 유지 (leader=CTRL+a, pane/nav/split)
- [ ] Nushell: Starship 프롬프트 정상 작동, 명령 실행/실패 코드 표시 일관성
- [ ] 선택 유틸(zoxide/fzf): 설치 시 정상 동작, 미설치 시도 오류 없음
- [ ] **Nix-first 설치**: `flake.nix` + 스크립트로 WezTerm/Nu/Starship 설치 + dotfiles 링크까지 완료
- [ ] 검증: 새 환경에서 WezTerm→Nu 진입, 프롬프트/폰트/한글/이모지 정상

---

## 🚀 Quick Start (Nix-First)

### 전제 조건
- macOS 또는 Linux (macOS 13+, Ubuntu 22.04+, Fedora 37+)
- Git 설치됨
- Nix 패키지 매니저 설치 (flake 지원)

### 설치 (1단계)

```bash
# 1. 이 리포지토리 clone
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. 심볼릭 링크 생성
mkdir -p ~/.config
ln -sf ~/dotfiles/.config/wezterm ~/.config/wezterm
ln -sf ~/dotfiles/.config/nushell ~/.config/nushell
ln -sf ~/dotfiles/.config/starship.toml ~/.config/starship.toml

# 3. Nix로 설치 (flake 활성화 필수)
nix flake update  # (선택) 잠금 파일 업데이트
nix profile install ./  # WezTerm, Nushell, Starship 등 설치
```

또는 **Home Manager** 사용:
```bash
# Home Manager 설정 (macOS/Linux)
home-manager switch --flake ~/dotfiles
```

### 초기 실행
```bash
# WezTerm 실행 (Nu로 자동 진입해야 함)
wezterm

# 혹은 Nu 직접 실행
nu
```

---

## 📁 Repository 구조

```
dotfiles/
.config/
  wezterm/
    wezterm.lua           # 메인 설정 진입점
    modules/
      appearance.lua      # 색상, 폰트, UI 설정
      keybindings.lua    # 키바인딩 (leader=CTRL+a)
  nushell/
    env.nu               # 공통 환경변수 (STARSHIP_SHELL 등)
    config.nu            # Starship 프롬프트 훅, 선택 유틸 로드
  starship.toml          # OS-중립 프롬프트 설정
scripts/
  install-nix.sh         # Nix 설치 헬퍼 (선택)
flake.nix               # Nix 플레이크 정의
home.nix                # Home Manager 설정 (선택)
README.md               # 이 파일
AGENTS.md               # 프로젝트 계획서
```

---

## ⌨️ 주요 키바인딩

**Leader: `CTRL+A`**

| 키 | 동작 | 설명 |
|----|------|------|
| `[` | Copy Mode | 복사/스크롤 모드 진입 |
| `h/j/k/l` | Pane Nav | Vim 스타일 창 네비게이션 |
| `\` | Split Horiz | 가로 분할 |
| `-` | Split Vert | 세로 분할 |
| `c` | New Tab | 새 탭 생성 |
| `p/n` | Prev/Next Tab | 탭 이동 |
| `w` | New Workspace | 새 워크스페이스 |
| `s` | Workspace Launcher | 워크스페이스 퍼지 검색 |
| `t` | Tab Launcher | 탭 퍼지 검색 |
| `z` | Zoom Pane | 창 줌 토글 |
| `,` | Rename Tab | 탭 이름 변경 |
| `.` | Rename Workspace | 워크스페이스 이름 변경 |

---

## 🛠️ 선택 유틸

설치 시 다음 도구가 자동 포함됩니다. 부재 시에도 오류 없음:
- **zoxide**: 스마트 디렉토리 점프 (`z` 커맨드)
- **fzf**: 퍼지 파인더 (히스토리 검색 등)
- **rg/fd/bat/eza**: 고속 그렙/파인드/캣/엘에스

---

## 🔧 Manual Setup (Nix 없이)

### macOS (Homebrew)
```bash
brew install wezterm nushell starship
brew install --cask jetbrains-mono-nerd-font
brew install zoxide fzf ripgrep fd bat eza
```

### Linux (Ubuntu/Debian)
```bash
# WezTerm, Nushell, Starship PPA/공식 설치
# 자세한 방법은 각 프로젝트 공식 문서 참조
```

그 다음 링크 생성:
```bash
mkdir -p ~/.config
ln -sf ~/dotfiles/.config/* ~/.config/
```

---

## ✅ 검증 체크리스트

새로운 macOS/Linux 환경에서 dotfiles 연결 후:

- [ ] WezTerm 실행 → Nushell 자동 진입
- [ ] `pwd`, `ls`, `cd` 커맨드 동작
- [ ] 프롬프트 표시 일관성 (두 OS에서 동일)
- [ ] 폰트: 아이콘/글자폭/라인 높이 동일하게 보임
- [ ] 긴 출력/한글/이모지 깨짐 없음
- [ ] `z` 커맨드 동작 (zoxide 설치 시)
- [ ] 키바인딩 테스트 (`CTRL+A` 후 `h/j/k/l` 이동)

---

## 🐛 Troubleshooting

### 프롬프트가 두 번 뜬다
→ Nu/Starship 훅 중복 설정 확인 (`config.nu`)

### 아이콘이 깨진다
→ JetBrainsMono Nerd Font 설치 확인, WezTerm 폰트 지정 재확인

### `z` 커맨드 동작 안 함
→ zoxide 설치 여부 확인 (`which zoxide`)

### 경로/환경변수 OS마다 다르다
→ 사용 중인 셸 버전, Nix 버전 통일 확인

---

## 📝 Customization

각 설정 파일을 직접 수정하세요:
- **폰트/색상**: `.config/wezterm/modules/appearance.lua`
- **키바인딩**: `.config/wezterm/modules/keybindings.lua`
- **프롬프트**: `.config/starship.toml`
- **환경변수**: `.config/nushell/env.nu`

---

## 🤝 Next Steps (선택)

- [ ] tmux/zellij 도입: 크로스 플랫폼 세션 유지
- [ ] 회사/개인 프로파일 분리 (`env.nu` overlay)
- [ ] Data Engineer Toolkit (jq/yq 대체, CSV/Parquet 처리)

---

**Happy Terminal-ing!** 🚀
