# Cross-Platform Terminal Setup (WezTerm + Nushell) — Step-by-Step Tasks
목표: **macOS / Windows / Linux** 어디서든 **동일한 UX**로 동작하는 터미널 환경 구축  
원칙: **OS 색채 최소화**, 설정은 **단일 소스(공유 dotfiles)**, OS별 차이는 **설치/경로만 얇게 분기**

---

## 0. 성공 기준 (Definition of Done)
- [ ] WezTerm 실행 시 기본 셸이 **Nushell**로 열린다
- [ ] 프롬프트가 **Starship**으로 통일된다 (OS별 차이 없음)
- [ ] 설정 파일은 모두 `~/.config/` 하위에서 관리된다
- [ ] (선택) zoxide / fzf 등 유틸이 **Nu에서 동일하게 동작**한다
- [ ] OS별 차이는 설치 스크립트만 존재하고, 설정은 100% 공유된다

---

## 1. 작업 준비: Dotfiles 저장소 구조 만들기
- [ ] Git repo 생성 (예: `dotfiles`)
- [ ] 아래 구조 생성
```
dotfiles/
.config/
wezterm/
wezterm.lua
nushell/
config.nu
env.nu
starship.toml
scripts/
install-macos.sh
install-linux.sh
install-windows.ps1
README.md
```
- [ ] 각 OS에서 repo를 clone하고, 심볼릭 링크로 `~/.config/`에 연결
  - macOS/Linux: `ln -s ~/dotfiles/.config/* ~/.config/`
  - Windows(권장): PowerShell로 junction/symlink 연결

---

## 2. OS별 설치 (설치만 다르게, 설정은 동일)
### 2.1 macOS (Homebrew)
- [ ] Homebrew 설치
- [ ] 설치
  - [ ] wezterm
  - [ ] nushell (`nu`)
  - [ ] starship
  - [ ] (선택) zoxide, fzf, ripgrep, fd, bat, eza, git

### 2.2 Linux (apt/dnf/pacman)
- [ ] 패키지 매니저로 설치
  - [ ] wezterm
  - [ ] nushell
  - [ ] starship
  - [ ] (선택) zoxide, fzf, ripgrep, fd, bat, eza, git

### 2.3 Windows (Scoop 권장)
- [ ] Scoop 설치
- [ ] 설치
  - [ ] wezterm
  - [ ] nushell
  - [ ] starship
  - [ ] (선택) zoxide, fzf, ripgrep, fd, git

> **Tip:** Windows에서도 `XDG_CONFIG_HOME=%USERPROFILE%\.config`로 맞추면 `~/.config`와 같은 구조로 운용 가능

---

## 3. 폰트 통일 (OS 색채 제거의 핵심)
- [ ] 모든 OS에 동일 폰트 설치 (권장: **JetBrainsMono Nerd Font**)
- [ ] 설치 후 WezTerm에서 폰트 지정
- [ ] DoD: 3개 OS에서 **글자폭/아이콘/라인 높이**가 동일하게 보인다

---

## 4. WezTerm 설정 적용
파일: `~/.config/wezterm/wezterm.lua`

### 4.1 기본 목표: 탭/장식 최소화 + Nu를 기본 셸로
- [ ] 탭바 1개면 숨기기
- [ ] fancy 탭바 끄기
- [ ] OS 장식 최소화(`RESIZE`)
- [ ] 기본 실행 프로그램을 Nu로 지정 (Windows만 `nu.exe` 분기)

✅ 체크리스트
- [ ] macOS에서 WezTerm 열면 Nu로 바로 진입
- [ ] Windows에서 WezTerm 열면 Nu로 바로 진입
- [ ] Linux에서 WezTerm 열면 Nu로 바로 진입

---

## 5. Nushell 설정 적용
경로:
- `~/.config/nushell/env.nu`
- `~/.config/nushell/config.nu`

### 5.1 env.nu — 공통 환경변수 최소 세팅
- [ ] `$env.STARSHIP_SHELL = "nu"` 설정

### 5.2 config.nu — 프롬프트/UX 통일
- [ ] Starship을 프롬프트로 사용하도록 PROMPT 훅 구성
- [ ] 오른쪽 프롬프트 비활성화(원하면 나중에 활성화)
- [ ] 기본 indicator 제거(중복 방지)

✅ DoD
- [ ] 세 OS에서 프롬프트가 동일하게 나온다
- [ ] 명령 실행/실패 코드 표시가 일관된다

---

## 6. Starship 설정 통일
파일: `~/.config/starship.toml`

- [ ] OS/호스트/경로 표시 규칙을 통일 (너무 OS 느낌 나는 정보는 숨김 처리)
- [ ] 개발 언어 모듈(예: node/python/rust/go) 표시를 필요한 것만 사용

✅ DoD
- [ ] OS가 달라도 “프롬프트 생김새/정보 밀도”가 동일하다

---

## 7. (선택) 생산성 유틸 추가 — Nu에서 동일 UX로
### 7.1 zoxide
- [ ] `zoxide init nushell` 결과를 파일로 저장
- [ ] `config.nu`에서 `source`로 로드
- [ ] `z`로 디렉토리 점프 동작 확인

### 7.2 fzf
- [ ] fzf 설치
- [ ] Nu에서 히스토리/파일 검색에 fzf를 연결하는 alias/functions 추가 (원하면 단계 확장)

✅ DoD
- [ ] `z <pattern>`이 3OS에서 동일하게 동작
- [ ] fzf 호출이 3OS에서 동일하게 동작

---

## 8. OS별 차이 “얇게” 처리하는 규칙 정리
- [ ] **설정 파일에는 OS 분기를 최소화**한다
- [ ] 불가피한 분기는 “경로/실행 파일명” 정도만 허용
  - 예: Windows `nu.exe` vs Unix `nu`
- [ ] 나머지는 `scripts/` 아래 설치 스크립트에서 해결

✅ DoD
- [ ] 설정 파일(diff)은 OS별로 거의 없다(0~몇 줄 수준)

---

## 9. 최종 검증 시나리오 (반드시 수행)
- [ ] 새 머신/새 사용자에서 dotfiles만 연결 후, 아래 테스트 수행
  - [ ] WezTerm 실행 → Nu 진입
  - [ ] `pwd` / `ls` / `cd` / `z`(선택) 동작
  - [ ] git repo 들어가서 프롬프트 표시 확인
  - [ ] 긴 출력/한글/이모지/폰트 아이콘 깨짐 여부 확인

---

## 10. 다음 확장 Task (원할 때만)
- [ ] tmux/zellij 도입해서 “세션 유지”까지 크로스플랫폼 통일
- [ ] wezterm keybinding 통일(탭 이동/분할/복사/붙여넣기)
- [ ] Nu에서 “data engineer toolkit” (jq/yq 대체, parquet/csv 처리 alias)
- [ ] 회사/개인 프로파일 분리(`env.nu`를 private overlay로 분리)

---

## 빠른 Troubleshooting 체크
- [ ] 프롬프트가 두 번 뜬다 → Nu/Starship 훅 중복 설정 여부 확인
- [ ] Windows만 경로가 다르게 보인다 → `XDG_CONFIG_HOME`/HOME 환경변수 확인
- [ ] 아이콘이 깨진다 → Nerd Font 설치/WezTerm 폰트 지정 확인
- [ ] 특정 유틸이 OS마다 동작이 다르다 → 해당 유틸의 설치 버전 통일(가능하면 동일 major)

---
