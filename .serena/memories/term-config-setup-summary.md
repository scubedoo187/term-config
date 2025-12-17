# Term-Config 프로젝트 구현 요약

## 프로젝트 개요
**목표**: macOS/Linux에서 동일한 UX로 동작하는 Nix 기반 크로스플랫폼 터미널 환경 구축
**저장소**: `~/term-config`
**상태**: ✅ 완료 및 적용됨

---

## 핵심 구성 요소

### 1. WezTerm
- 기본 셸: Nushell (`~/.nix-profile/bin/nu`)
- 색상: Seoul256 (Gogh)
- 폰트: JetBrainsMono Nerd Font Mono Bold 14pt
- Leader 키: `CTRL+A`
- 탭바: 1개일 때 숨김, fancy 탭바 끔

### 2. Nushell
- Starship 프롬프트 통합
- fzf 히스토리 검색 (`Ctrl+R`)
- fzf 파일 검색 (`Ctrl+T`)
- zoxide 통합 (`z` 명령)
- 모던 CLI alias (bat, eza, fd, rg)

### 3. Starship
- OS-중립 프롬프트
- git branch/status, docker context
- nodejs/python/rust/golang 언어 감지
- command_timeout = 1000 (pyenv 대응)

### 4. Nix
- `flake.nix`: 패키지 정의 (wezterm, nu, starship, zoxide, fzf, rg, fd, bat, eza)
- `home.nix`: Home Manager 설정
- `scripts/install-nix.sh`: 자동 설치 스크립트

---

## 파일 구조

```
~/term-config/
├── .config/
│   ├── wezterm/
│   │   ├── wezterm.lua           # 메인 설정
│   │   └── modules/
│   │       ├── appearance.lua    # 폰트/색상
│   │       └── keybindings.lua   # 키바인딩
│   ├── nushell/
│   │   ├── env.nu               # 환경변수 + Starship 초기화
│   │   └── config.nu            # 설정 + fzf/zoxide
│   └── starship.toml            # 프롬프트 설정
├── flake.nix                    # Nix 플레이크
├── home.nix                     # Home Manager
├── scripts/install-nix.sh       # 설치 스크립트
└── README.md
```

---

## 심볼릭 링크 (현재 적용됨)

```
~/.wezterm.lua                        → ~/term-config/.config/wezterm/wezterm.lua
~/.config/wezterm                     → ~/term-config/.config/wezterm
~/.config/nushell                     → ~/term-config/.config/nushell
~/.config/starship.toml               → ~/term-config/.config/starship.toml
~/Library/Application Support/nushell → ~/term-config/.config/nushell (macOS)
```

---

## 주요 키바인딩

| 키 | 동작 |
|----|------|
| `Ctrl+A` | Leader 키 |
| `Leader + h/j/k/l` | Pane 이동 |
| `Leader + \` | 가로 분할 |
| `Leader + -` | 세로 분할 |
| `Leader + c` | 새 탭 |
| `Leader + p/n` | 이전/다음 탭 |
| `Leader + z` | Pane 줌 |
| `Leader + [` | Copy 모드 |
| `Ctrl+R` | fzf 히스토리 검색 |
| `Ctrl+T` | fzf 파일 검색 |

---

## 실행 방법

```bash
# WezTerm 실행 (Nix 버전)
~/.nix-profile/bin/wezterm

# 또는 PATH에 Nix 추가 후
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
wezterm
```

---

## 수정 이력

1. **초기 구현**: 구조 스캐폴딩, WezTerm/Nushell/Starship 설정
2. **버그 수정**: 
   - `hide_tab_bar_when_only_one_tab` → `hide_tab_bar_if_only_one_tab`
   - Nu 경로를 절대 경로로 (`~/.nix-profile/bin/nu`)
   - macOS Nu config 경로 (`~/Library/Application Support/nushell`)
3. **Starship 수정**:
   - deprecated 키 제거 (guix, pipefail, nushell)
   - `command_timeout = 1000` 추가
   - `stashed` 포맷 escape 수정
4. **fzf 통합**: `Ctrl+R` 히스토리, `Ctrl+T` 파일 검색
5. **2차 검증**:
   - zoxide 경로 `$env.HOME` 사용
   - `def --env` 추가 (fzf-cd, mkcd)
   - home.nix 문법 수정

---

## 트러블슈팅

### Workspace rename (Leader + .) 안됨
→ 소켓 경로 수정: `sock` → `default-org.wezfurlong.wezterm`
- `sock`: mux 서버용 소켓 (GUI와 연결 안됨)
- `default-org.wezfurlong.wezterm`: GUI 소켓 심볼릭 링크 (활성 GUI와 연결)


### WezTerm이 Nu를 못 찾음
→ `~/.nix-profile/bin/nu` 절대 경로 사용 (wezterm.lua에 구현됨)

### Starship 경고
→ `command_timeout = 1000` 설정 (pyenv 느린 응답 대응)

### fzf Ctrl+R이 기본 Nu 검색으로 뜸
→ config.nu 문법 오류 확인: `nu -c 'source ~/.config/nushell/config.nu'`

### 설정 변경이 반영 안됨
→ WezTerm 완전히 새로 열기 (모든 창 닫고)

---

## Git 커밋 히스토리

```
f03a8c3 fix: 2차 검증 - 전체 설정 파일 수정
09e2239 fix: Simplify starship.toml, remove deprecated keys
b366e81 fix: Escape $ in starship git_status.stashed format
20c8df2 fix: Simplify config.nu for Nu 0.108 compatibility
69a19b5 feat: Add fzf integration for history search
1da5683 fix: Use official Starship init method for Nushell
704bd9e fix: WezTerm config corrections
c5e6a93 Initial dotfiles setup
```
