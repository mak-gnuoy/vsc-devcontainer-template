# AI 코딩 CLI Dev Container

Claude Code, Codex, Gemini, GitHub Copilot CLI와 Superpowers 플러그인이 미리 설치된 개발
컨테이너 설정입니다. 저장소를 열면 팀 누구나 동일한 환경에서 작업하고, 컨테이너를
재빌드해도 다시 로그인할 필요가 없습니다.

## 포함된 것

| 구성 요소 | 설치 방식 |
| --- | --- |
| Claude Code CLI + VS Code 확장 (`anthropic.claude-code`) | `Dockerfile`에서 `scripts/install-claude.sh` (네이티브 릴리스 바이너리) |
| Codex CLI + VS Code 확장 (`openai.chatgpt`) | `Dockerfile`에서 `scripts/install-codex.sh` (GitHub 릴리스 바이너리) |
| Gemini CLI + VS Code 확장 (`google.gemini-cli-vscode-ide-companion`) | `Dockerfile`에서 `scripts/install-gemini.sh` (GitHub 릴리스 JS 번들) |
| GitHub Copilot CLI + VS Code 확장 (`github.copilot`, `github.copilot-chat`) | `Dockerfile`에서 `scripts/install-copilot.sh` (GitHub 릴리스 바이너리) |
| Node.js LTS + npm | `ghcr.io/devcontainers/features/node:1` |
| bun | `Dockerfile`에서 `scripts/install-bun.sh` (GitHub 릴리스 바이너리) |
| GitHub CLI (`gh`) | `ghcr.io/devcontainers/features/github-cli:1` |
| Python 3 (+ venv, pip, 린터/포매터) | `ghcr.io/devcontainers/features/python:1` |
| git, curl, ripgrep, jq, ssh, sudo 등 | `Dockerfile`의 apt |
| Superpowers 플러그인 (CLI 4개 모두) | `postCreateCommand`의 `scripts/install-superpowers.sh` |
| gstack 스킬 (Claude Code, Codex) | `postCreateCommand`의 `scripts/install-gstack.sh` |
| ccusage | `postCreateCommand`의 `scripts/install-ccusage.sh` (npm 전역 설치) |

ccusage는 Node.js feature가 설치된 뒤 `postCreateCommand`에서 자동 설치합니다.
현재 컨테이너에서 수동으로 설치하거나 갱신할 때도 같은 스크립트를 사용합니다.
재실행하면 요청한 버전으로 설치되며, 인자를 생략하면 최신 버전을 설치합니다.

```bash
bash .devcontainer/scripts/install-ccusage.sh
bash .devcontainer/scripts/install-ccusage.sh 20.0.20
# 환경 변수로도 버전 지정 가능: CCUSAGE_VERSION=20.0.20
ccusage daily
ccusage codex daily
```

스크립트는 현재 npm 전역 경로에 설치하고 `ccusage --version`으로 실행을 확인합니다.
설치 실패 시 오류를 반환하므로 컨테이너 생성 로그에서 원인을 확인할 수 있습니다.
`No valid Claude data directories found in CLAUDE_CONFIG_DIR` 오류는 지정한 Claude
설정 폴더에 `projects/` 사용량 데이터가 없을 때 발생합니다. 실제 Claude Code 기록이
저장된 경로인지 확인하거나, Codex 기록을 조회하려면 `ccusage codex daily`를 사용하세요.

네 CLI 모두 컨테이너를 만들 때가 아니라 이미지를 빌드할 때 설치합니다. 다운로드가 레이어에
캐시되고, Gemini를 뺀 셋은 node 툴체인에도 의존하지 않습니다.

`scripts/install-claude.sh`는 `https://claude.ai/install.sh`가 하는 일을 그대로 하되, 이미지에
맞지 않는 부분만 뺐습니다. 공식 설치 스크립트는 바이너리를 `$HOME` 아래에 두고 사용자
한 명을 위한 런처와 셸 통합까지 구성하는데, 여기서는 `/opt/claude`에 놓고 PATH에 링크해
이미지를 쓰는 모든 사용자가 같은 Claude Code를 쓰도록 합니다. 버전은 릴리스 매니페스트의
SHA-256으로 항상 검증하고, zstd로 압축된 바이너리가 있으면 그쪽을 받습니다(334MB → 74MB).
`ghcr.io/anthropics/devcontainer-features/claude-code` feature를 쓰지 않는 이유이기도 합니다 —
그 feature는 node를 요구하는 `npm install -g @anthropic-ai/claude-code`입니다.

Codex는 devcontainer feature 자체가 없어서 `scripts/install-codex.sh`가 GitHub 릴리스의
`codex-package-<arch>-unknown-linux-musl.tar.gz`를 받아 `/opt/codex`에 풀고
`/usr/local/bin/codex` 심볼릭 링크를 만듭니다. npm(`npm install -g @openai/codex`) 대신
이 방식을 쓰는 이유는 위와 같습니다. 대신 이미지가 커집니다 — `/opt` 기준으로 Claude Code
320MB, Codex 320MB, Copilot 154MB, Gemini 95MB로 합계 약 890MB입니다.

Gemini CLI만 리눅스용 바이너리를 배포하지 않습니다. 릴리스가 Node.js 20+에서 도는 JS
번들이라, `scripts/install-gemini.sh`는 `gemini-cli-bundle.zip`을 `/opt/gemini`에 풀고
`/usr/local/bin/gemini`에 작은 런처를 둡니다. node는 node feature가 넣어주는 것을 실행
시점에 씁니다. feature는 프로필 스크립트로 PATH를 잡아주는데 모든 셸이 그걸 읽지는 않아서,
런처는 nvm의 `current` 심볼릭 링크로 폴백합니다.

Copilot CLI의 npm 패키지(`@github/copilot`)는 같은 바이너리를 감싼 로더일 뿐이라
`scripts/install-copilot.sh`는 릴리스 애셋을 바로 받습니다. 릴리스마다 `SHA256SUMS.txt`가 있어서
다운로드는 항상 검증합니다.

[Superpowers](https://github.com/obra/superpowers)는 Claude 전용이 아닙니다. 저장소에
하네스별 매니페스트(`.claude-plugin`, `.codex-plugin`, `gemini-extension.json` 등)가 들어
있어서, 같은 스킬 묶음을 CLI 4개에 각각 설치합니다.

| CLI | 설치 방식 |
| --- | --- |
| Claude Code | `claude plugin install superpowers@superpowers-marketplace --yes` |
| Codex | `codex plugin add superpowers@superpowers-marketplace` |
| Copilot | `copilot plugin install superpowers@superpowers-marketplace` |
| Gemini | `gemini extensions install https://github.com/obra/superpowers --consent` |

이것만 이미지가 아니라 컨테이너를 만들 때 설치합니다. 플러그인은 각 CLI의 설정
디렉터리(`~/.claude`, `~/.codex`, `~/.copilot`, `~/.gemini`)에 들어가는데 넷 다 named
volume이고, 볼륨은 **비어 있는 상태로 만들어질 때만** 이미지 내용을 물려받습니다. 이미
있는 볼륨에 재빌드하면 이미지에 넣어둔 플러그인은 조용히 무시됩니다. 그래서 마운트가 끝난 뒤
`postCreateCommand`에서 돌립니다. 플러그인 하나 때문에 컨테이너 생성이 실패하는 건 과하므로,
CLI별로 경고만 남기고 계속 진행하며 스크립트는 항상 0으로 끝냅니다.

CLI마다 재실행 동작이 달라서 스크립트가 흡수합니다. 마켓플레이스 등록은 Copilot만 중복
등록을 오류로 보므로 실패해도 넘어가고 실제 설치 결과만 봅니다. Gemini는 확장이 이미 있으면
재설치가 오류라서, 설치되어 있으면 건너뜁니다(`gemini extensions update superpowers`로 갱신).
Gemini는 서드파티 확장 경고 프롬프트도 있어서 `--consent` 없이는 TTY 없는 postCreate에서
그대로 멈춥니다.

[gstack](https://github.com/garrytan/gstack)은 플러그인이 아닙니다. 저장소를 한 번 클론해
두고 저장소의 `setup`이 호스트별 스킬 디렉터리에 심볼릭 링크를 깔아주는 구조라,
`scripts/install-gstack.sh`는 업스트림 기본 위치인 `~/.claude/skills/gstack`에 클론합니다.
그 경로가 named volume이라 42MB 다운로드가 재빌드에도 남고 `git pull`로 갱신도 됩니다.
Codex 쪽 설치는 `~/.codex/skills/` 아래 링크들이 그 클론을 가리키는 구조인데, 두 볼륨 다
유지되므로 링크가 끊기지 않습니다. Superpowers와 같은 이유로 이미지가 아니라
`postCreateCommand`에서 돌리고, 같은 규약으로 경고만 남기고 항상 0으로 끝냅니다.

Claude Code와 Codex에만 설치합니다. gstack은 Cursor·Factory·Kiro·OpenCode도 지원하지만
이 이미지에 없고, Gemini와 Copilot용 설치는 아예 없습니다 — 그 둘은
`agents-digest/gstack-AGENTS.md` 2KB 다이제스트를 프로젝트 규칙 파일에 붙여넣는
"instruction-only" 등급뿐이라 이미지가 대신 해줄 수 있는 일이 아닙니다.

스킬은 `--no-prefix`로 짧은 이름(`/review`, `/ship`, `/qa`)을 씁니다. 같은 디렉터리에
Superpowers가 들어와 있지만 그쪽은 플러그인 네임스페이스(`superpowers:*`)라 겹치지
않습니다. 다만 호스트 내장 명령이나 프로젝트 자체 스킬과는 이름이 겹칠 수 있고, 그런
충돌은 `setup`이 찾아서 경고해 줍니다. `gstack-*` 접두사로 되돌리려면 스크립트의
`--no-prefix`를 `--prefix`로 바꾸면 되고, 모드를 바꿀 때 이전 모드의 링크는 `setup`이
정리합니다. `setup`의 프롬프트들은 `/dev/tty`를 타임아웃과 함께 읽어서 TTY 없는
postCreate를 멈추지는 않지만, 안 물어봐도 되는 것은 플래그로 미리 답해둡니다.

이 플래그는 Claude 쪽에만 먹습니다. Codex는 클론 안에 미리 생성돼 있는
`.agents/skills/gstack-*` 디렉터리에서 링크를 거는데 그 이름에 접두사가 박혀 있어서,
Codex에서는 어느 모드든 `/gstack-review`입니다. Claude 쪽에서도 원래 이름에 이미
`gstack-`이 들어간 둘(gstack 라우터와 `/gstack-upgrade`)은 그대로입니다.

이미 다른 모드로 설치된 컨테이너에서 모드를 바꾸면 옛 이름이 하나씩 남을 수 있습니다.
`setup`의 정리 코드가 심볼릭 링크만 지우는데 일부 스킬은 생성된 파일로 깔리기 때문입니다.
그런 디렉터리에는 `.gstack-owned` 표시가 있으니 `rm -rf ~/.claude/skills/gstack-<이름>`으로
지우면 됩니다. 새로 만든 컨테이너는 한 모드만 설치하므로 해당하지 않습니다.

Chromium은 받지 않습니다(`GSTACK_SKIP_PLAYWRIGHT=1`). Playwright는 브라우저를
`~/.cache/ms-playwright`에 두는데 그 경로는 볼륨이 아니어서 재빌드마다 200MB를 다시 받고,
debian-slim에는 headless Chromium이 필요한 공유 라이브러리도 없습니다. 브라우저 스킬은
호출할 때 에러가 나고 나머지는 정상입니다. 같은 이유로 `GSTACK_SKIP_FONTS=1`도 줍니다 —
`setup`이 `make-pdf`의 이모지 렌더링용으로 `fonts-noto-color-emoji`를 apt로 설치하려
하는데, 그 스킬 자체가 Chromium으로 인쇄하므로 여기서는 돌지 않습니다.

텔레메트리는 업스트림 기본이 on이고 스킬 사용 기록을 gstack의 Supabase로 보냅니다. 팀이
공용으로 쓰는 이미지라 설치 후 `gstack-config set telemetry off`로 끕니다.
`GSTACK_TELEMETRY=on`으로 돌리면 업스트림 기본값을 그대로 씁니다.

`codex-*` 대신 `codex-package-*` 애셋을 쓰는 것이 중요합니다. 실행 파일 옆에 있어야 하는
런타임 파일(`codex-resources/bwrap`, `codex-path/rg` 등)이 여기에만 들어 있고, 그중 bwrap이
없으면 `codex sandbox`가 실행되지 않습니다. 데비안의 `bubblewrap` 패키지로 대체하면
오히려 깨집니다 — PATH의 시스템 bwrap이 우선하는데, 권한 없는 컨테이너 안에서는 `/proc`를
마운트하지 못합니다.

python feature는 기본값이 `version: "os-provided"`라 소스 컴파일 없이 apt로
`python3`, `python3-pip`, `python3-venv`, `python3-dev`를 설치합니다. 더불어 `black`, `mypy`,
`pytest`, `pylint` 등 표준 도구 묶음도 함께 깔립니다. 이게 부담스러우면
`{ "installTools": false }` 옵션으로 끄면 됩니다. 특정 버전(`"3.12"` 등)을 지정하면 그때는
CPython을 소스에서 빌드하므로 첫 빌드가 길어집니다.

베이스는 Docker Hub 공식 `debian:trixie-slim` 이미지입니다. `mcr.microsoft.com`에 의존하지
않기 위한 선택이며, 그 대가로 공식 이미지에 없는 것들(비root 사용자, `sudo`,
`ca-certificates`, `git` 등)을 `Dockerfile`에서 직접 구성합니다. `vscode` 사용자를 feature가
아니라 Dockerfile에서 만드는 이유는, feature가 Dockerfile *이후에* 적용되기 때문입니다 —
볼륨 마운트 지점을 `chown`하려면 그 시점에 사용자가 이미 있어야 합니다.

## 시작하기

필요한 것: [Docker](https://docs.docker.com/get-docker/)와 VS Code
[Dev Containers 확장](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
(또는 GitHub Codespaces, JetBrains 등 Dev Containers 스펙을 지원하는 도구).

1. 저장소를 VS Code로 엽니다.
2. 안내 팝업에서 **Reopen in Container**를 누르거나, 명령 팔레트에서
   **Dev Containers: Reopen in Container**를 실행합니다.
3. 빌드가 끝나면 CLI별로 한 번씩 로그인합니다.
   - `claude` — 실행하면 브라우저 인증이 시작됩니다.
   - `codex login` — ChatGPT 계정. API 키를 쓰려면
     `printenv OPENAI_API_KEY | codex login --with-api-key`.
   - `gemini` — 실행 후 `/auth`에서 Google 계정을 고릅니다. `GEMINI_API_KEY`를 넣어두면
     그대로 씁니다.
   - `copilot login` — GitHub 계정. dev container를 인식해 기본으로 device code 방식을
     쓰므로 포트 포워딩이 필요 없습니다. 자동화에는 `COPILOT_GITHUB_TOKEN`도 됩니다.

첫 빌드는 이미지와 feature를 받느라 몇 분 걸립니다. 이후 컨테이너 생성은 캐시된 레이어를
쓰므로 훨씬 빠릅니다.

> 브라우저 인증은 끝났는데 터미널이 계속 대기한다면, 편집기의 포트 포워딩이 localhost
> 콜백을 전달하지 못한 경우입니다. Claude Code는 브라우저에 표시된 코드를 복사해
> `Paste code here if prompted` 프롬프트에 붙여넣으면 됩니다. Codex는 코드 붙여넣기가
> 없고 콜백(`http://localhost:1455/...`)으로만 로그인이 끝나므로, 해당 포트가 호스트로
> 포워딩되는지 확인하세요.

## 재빌드해도 유지되는 것

Claude Code는 인증 토큰과 설정을 `~/.claude`에 저장하지만, **OAuth 계정 정보와 프로젝트
신뢰 여부는 그 디렉터리 밖의 `~/.claude.json`에 둡니다.** 그래서 `~/.claude`만 볼륨으로
마운트하면 재빌드 후 다시 로그인해야 합니다.

이 설정은 두 가지를 함께 적용해 그 문제를 피합니다.

- `~/.claude`에 named volume 마운트
- `CLAUDE_CONFIG_DIR=/home/vscode/.claude` — `.claude.json`도 볼륨 안에 쓰이도록

나머지 셋은 이런 예외가 없어서 디렉터리 하나씩만 마운트하면 됩니다 — `~/.codex`
(`auth.json`, `config.toml`), `~/.gemini`, `~/.copilot`.

Superpowers도 네 CLI의 설정 디렉터리 안에 들어가므로 같은 볼륨들에 남습니다. 그래서
재빌드 후에는 다시 받지 않고 확인만 합니다.

gstack은 볼륨이 하나 더 필요합니다. 스킬과 소스 클론은 `~/.claude`·`~/.codex` 안에
들어가지만, 설정(`config.yaml`)과 백업, 마지막 setup 버전은 그 밖의 `~/.gstack`에 두기
때문에 그 경로도 named volume으로 마운트합니다.

셸 히스토리도 별도 볼륨(`/commandhistory`)에 남습니다. 여섯 볼륨 모두 이름에
`${devcontainerId}`가 들어가므로 다른 저장소와 섞이지 않습니다.

## 설정이 제대로 됐는지 확인

컨테이너 터미널에서:

```bash
# 도구 설치 확인
claude --version && codex --version && gemini --version && copilot --version \
  && node -v && npm -v && bun --version && gh --version | head -1 && python3 --version

# gstack 스킬이 Claude Code와 Codex에 깔렸는지 (각각 50개 이상)
readlink ~/.claude/skills/*/SKILL.md | grep -c '/skills/gstack/'   # 짧은 이름
readlink ~/.codex/skills/* | grep -c '/skills/gstack/'             # gstack-* 이름
grep -E '^(skill_prefix|telemetry):' ~/.gstack/config.yaml

# 설정 디렉터리 위치와 소유권 (vscode 소유여야 함)
echo "$CLAUDE_CONFIG_DIR"      # -> /home/vscode/.claude
ls -ld /home/vscode/.claude /home/vscode/.codex /home/vscode/.gemini /home/vscode/.copilot
```

**인증 영속성 확인이 핵심입니다.** 로그인한 뒤 **Dev Containers: Rebuild Container**를
한 번 더 실행했을 때, 새 터미널에서 `claude`가 인증 프롬프트 없이 바로 뜨면 정상입니다.
`ls -la "$CLAUDE_CONFIG_DIR"`에 `.credentials.json`과 `.claude.json`이 모두 보이면 됩니다.
Codex도 마찬가지로 `ls -la ~/.codex`에 `auth.json`이 남아 있으면 재로그인이 필요 없습니다.

VS Code 없이 확인하려면 호스트의 저장소 루트(이 파일의 상위 디렉터리)에서:

```bash
npx @devcontainers/cli up --workspace-folder .
npx @devcontainers/cli exec --workspace-folder . claude --version
npx @devcontainers/cli exec --workspace-folder . codex --version
```

## 커스터마이즈

**도구 추가** — 언어 런타임처럼 재사용 가능한 것은 `devcontainer.json`의 `features`에,
단순 apt 패키지는 `Dockerfile`에 추가하는 편이 빌드 캐시를 타기 좋습니다.
[사용 가능한 feature 목록](https://containers.dev/features).

**Claude Code 버전 고정** — 기본은 `ARG CLAUDE_VERSION=stable`입니다. `latest`나 정확한
버전(`2.1.236` 등)을 넣을 수 있고, 체크섬은 매니페스트에서 가져오므로 따로 고정할 해시는
없습니다.

이미지에 root 소유로 설치되므로 Claude Code는 제자리에서 자기 자신을 갱신하지 못합니다.
`claude update`를 실행하면 실패하는 대신 `~/.local/share/claude/versions/<버전>`에 사본을
하나 더 받고 `~/.local/bin/claude`로 링크합니다. 그 경로는 PATH에 없고 볼륨으로 유지되지도
않아서, 조용히 두 벌이 생기고 재빌드하면 사라집니다. 그래서 `containerEnv`에
`DISABLE_AUTOUPDATER=1`을 두었습니다. 버전을 올리려면 `CLAUDE_VERSION`을 바꾸거나
`stable` 상태로 캐시 없이 리빌드하세요.

**Codex 버전 고정** — 기본은 최신 릴리스(`ARG CODEX_VERSION=latest`)입니다. 재현 가능한
빌드가 필요하면 Dockerfile의 기본값을 버전으로 바꾸거나 빌드 인자로 넘기세요.

```jsonc
"build": {
  "dockerfile": "Dockerfile",
  "args": { "CODEX_VERSION": "0.153.4", "CODEX_SHA256": "<sha256>" }
}
```

릴리스에는 체크섬 파일이 없고 sigstore 번들만 있습니다. 다운로드를 검증하려면 애셋의
`sha256sum` 값을 직접 구해 `CODEX_SHA256`으로 넘기면 되고, 비워두면 검증을 건너뜁니다.

이렇게 설치한 Codex는 스스로 업데이트하지 않고, `codex update`도 설치 방식을 감지하지 못해
거부합니다(`Could not detect the Codex installation method`). `latest`로 두더라도 레이어가
캐시되어 있는 동안에는 빌드 시점 버전에 머무릅니다. 버전을 올리려면 `CODEX_VERSION`을
바꾸거나 캐시 없이(**Dev Containers: Rebuild Container Without Cache**) 리빌드하세요.

**Gemini · Copilot 버전 고정** — 둘 다 기본은 최신 릴리스(`GEMINI_VERSION`,
`COPILOT_VERSION`)입니다. 빌드 인자로 버전을 넘기면 고정됩니다. Copilot은
`SHA256SUMS.txt`로 항상 검증하고, Gemini는 체크섬을 배포하지 않으므로 필요하면
`GEMINI_SHA256`에 번들 해시를 넘기세요.

**플러그인 추가·제거** — `scripts/install-superpowers.sh`는 마켓플레이스·플러그인·저장소를
`SUPERPOWERS_MARKETPLACE`, `SUPERPOWERS_PLUGIN`, `SUPERPOWERS_REPO`로 받습니다. CLI를 빼려면
스크립트 마지막 `for` 목록에서 이름을 지우면 되고, 아예 안 쓰려면 `devcontainer.json`의
`postCreateCommand`를 지우세요. 업데이트는 CLI마다
`claude plugin update superpowers@superpowers-marketplace`,
`codex plugin add superpowers@superpowers-marketplace`,
`copilot plugin install superpowers@superpowers-marketplace`,
`gemini extensions update superpowers`입니다.

**gstack 조정** — `scripts/install-gstack.sh`는 저장소·리비전·클론 위치를 `GSTACK_REPO`,
`GSTACK_REF`, `GSTACK_DIR`로 받습니다. 업스트림에 태그가 없어서 버전을 고정하려면
`GSTACK_REF`에 커밋 SHA를 주면 됩니다(스크립트가 클론 후 그 ref를 fetch하므로 브랜치도
SHA도 됩니다). 기본값 `main`은 HEAD를 브랜치에 남겨두므로 `git pull`도 그대로 동작합니다.
호스트를 빼려면 스크립트의 `for` 목록에서 이름을 지우고, 아예 안 쓰려면
`devcontainer.json`의 `postCreateCommand`에서 뒤쪽 명령을 지우세요. 클론은 스크립트가
관리하므로 그 아래 로컬 수정은 다음 실행에서 사라집니다.

업데이트는 컨테이너를 다시 만들 때 자동으로 되고(스크립트가 매번 fetch), 손으로 하려면
`bash .devcontainer/scripts/install-gstack.sh`를 다시 돌리거나 `/gstack-upgrade`를 쓰면
됩니다. 제거는 `~/.claude/skills/gstack/bin/gstack-uninstall`입니다.

**bun 버전 고정** — 기본은 최신 릴리스(`ARG BUN_VERSION=latest`)이고 체크섬은
`SHASUMS256.txt`로 항상 검증합니다. 빌드 머신 CPU에는 AVX2가 있고 실행 머신에는 없다면
`BUN_BASELINE=1`로 이식성 있는 빌드를 받으세요 — 기본 x64 빌드는 AVX2가 없으면 SIGILL로
죽고, 스크립트의 자동 판별은 설치하는 쪽 CPU만 볼 수 있습니다.

**조직 정책 적용** — `/etc/claude-code/managed-settings.json`을 Dockerfile에서 복사하면
사용자 설정보다 우선 적용됩니다. 다만 저장소 쓰기 권한이 있는 사람은 이 단계를 지울 수
있으므로, 우회 불가능한 정책은
[server-managed settings](https://code.claude.com/docs/en/server-managed-settings)나 MDM으로
배포하세요.

**네트워크 egress 제한** — 이 설정에는 없습니다. 필요하면 `runArgs`에
`--cap-add=NET_ADMIN`, `--cap-add=NET_RAW`를 추가하고 방화벽 스크립트를 붙이는 방식으로
확장할 수 있습니다.
[레퍼런스 컨테이너](https://github.com/anthropics/claude-code/tree/main/.devcontainer)에
동작하는 예시가 있습니다.

## 보안 참고

- 인증 볼륨에 Claude Code의 `.credentials.json`과 Codex의 `auth.json`이 남습니다.
  **신뢰할 수 있는 저장소에서만** 사용하세요.
- Copilot CLI는 시스템 자격증명 저장소가 없으면 토큰을 `~/.copilot/` 아래 **평문 설정
  파일**에 둡니다. 컨테이너에는 보통 그 저장소가 없으니 평문이라고 보면 됩니다.
- 호스트의 `~/.ssh`나 클라우드 자격증명 파일은 마운트하지 마세요. 저장소 범위로 한정된
  단기 토큰을 쓰는 편이 낫습니다.
- 세션은 `remoteUser` 설정에 따라 비root(`vscode`)로 연결되므로 `--dangerously-skip-permissions`를 쓸 수는
  있지만, 이 플래그는 도구 호출을 검토할 기회를 없앱니다. Claude는 여전히 호스트에
  그대로 보이는 워크스페이스 파일을 수정할 수 있고 네트워크에도 접근할 수 있습니다.
  프롬프트를 줄이는 것이 목적이라면
  [auto mode](https://code.claude.com/docs/en/permission-modes)를 먼저 고려하세요.
  Codex의 `--dangerously-bypass-approvals-and-sandbox`도 같은 이야기입니다. 승인 없이
  돌리고 싶다면 `--full-auto`(워크스페이스 쓰기 + 네트워크 차단)가 더 나은 선택입니다.

## 문제 해결

**`~/.claude`나 `~/.codex`가 root 소유로 보임** — Dockerfile은 볼륨이 비어 있을 때만
소유권을 물려줍니다. 이미 잘못된 소유권으로 만들어진 볼륨이 있다면 호스트에서 해당
볼륨을 지우고 재빌드하세요 (로그인은 다시 해야 합니다).

```bash
docker volume ls | grep -E 'claude-code-config|codex-config'
docker volume rm <volume-name>
```

**Codex 설치에서 빌드가 실패** — `scripts/install-codex.sh`는 GitHub 릴리스에서 직접 받습니다.
사내 프록시나 egress 제한이 있으면 `github.com`과 `release-assets.githubusercontent.com`을
허용하거나, 스크립트의 `base` URL을 내부 미러로 바꾸세요. 지원 아키텍처는
x86_64와 aarch64뿐입니다.

**`codex sandbox`가 `bwrap`으로 실패** — 컨테이너에 `bubblewrap`을 apt로 설치했는지
확인하세요. 시스템 bwrap이 Codex 번들 bwrap보다 우선하는데, 권한 없는 컨테이너에서는
`Can't mount proc on /proc` 으로 실패합니다. `sudo apt-get remove bubblewrap`으로 해결됩니다.

**Claude Code 설치에서 빌드가 실패** — `scripts/install-claude.sh`는 `downloads.claude.ai`에서
받습니다. egress를 제한한다면 그 호스트를 허용하세요. 지원되지 않는 지역에서는 버전
조회가 HTML 오류 페이지를 돌려주는데, 스크립트가 이를 감지해 실패시킵니다
([지원 국가](https://www.anthropic.com/supported-countries)).

**`gemini`가 `node was not found on PATH`로 실패** — Gemini CLI는 JS 번들이라 실행 시점에
node가 필요합니다. `devcontainer.json`에서 node feature를 빼면 같이 깨집니다.

**gstack이 설치되지 않음** — 같은 로그에서 `install-gstack:` 줄을 보세요. `bun`이 PATH에
없으면 `setup`이 실행 자체를 거부하므로 스크립트가 건너뛰고, GitHub에 접근하지 못하면
클론에서 멈춥니다. 원인을 고친 뒤 `bash .devcontainer/scripts/install-gstack.sh`를 다시
돌리면 됩니다. 현재 상태는 `ls ~/.claude/skills`, `ls ~/.codex/skills`로 볼 수 있습니다.

**gstack 브라우저 스킬이 실패** — 의도된 동작입니다. Chromium을 받지 않으므로
`/browse`, `/scrape`, `/make-pdf`처럼 브라우저가 필요한 스킬은 호출할 때
에러가 납니다. 정말 필요하면 `install-gstack.sh`의 `GSTACK_SKIP_PLAYWRIGHT` 설정을 지우고
Chromium 실행 라이브러리를 `Dockerfile`에 추가하세요. 권한 없는 컨테이너에서는
`GSTACK_CHROMIUM_NO_SANDBOX=1`도 필요할 수 있습니다.

**`bun: command not found`** — `bun`은 `Dockerfile`에서 `/opt/bun`에 설치되고
`/usr/local/bin/bun`으로 링크됩니다. 이미지를 다시 빌드하지 않은 컨테이너라면 없을 수
있으니, **Dev Containers: Rebuild Container**를 한 번 돌리세요.

**Superpowers가 설치되지 않음** — 컨테이너 생성 로그(**Dev Containers: Show Container
Log**)에서 `install-superpowers:` 경고를 확인하세요. 마지막 줄에 실패한 CLI 이름이 모여
있습니다. GitHub에 접근하지 못하면 실패합니다. 원인을 고친 뒤 터미널에서
`bash .devcontainer/scripts/install-superpowers.sh`를 다시 실행하면 됩니다. 현재 상태는
`claude plugin list`, `codex plugin list`, `copilot plugin list`,
`gemini extensions list`로 볼 수 있습니다.

**`pip install`이 `externally-managed-environment` 오류** — Debian trixie는 PEP 668을
적용합니다. 프로젝트마다 가상환경을 쓰세요.

```bash
python3 -m venv .venv && source .venv/bin/activate
```

## 참고 문서

- [Claude Code dev containers](https://code.claude.com/docs/en/devcontainer)
- [Codex CLI](https://developers.openai.com/codex/cli/)
- [Claude Code 설치 방법](https://code.claude.com/docs/en/setup)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/about-copilot-cli)
- [Dev Containers 스펙](https://containers.dev/)
