# basejb/skills

자주 쓰는 Claude Code 스킬 모음. 여러 환경에서 스킬을 동기화하려고 만든 개인 marketplace.

## 설치

```
/plugin marketplace add basejb/skills
/plugin install basejb@skills
```

설치 후 모든 스킬은 `/basejb:<이름>` 형태로 호출됩니다.

## 업데이트

```
/plugin marketplace update skills
/plugin update basejb@skills
```

## 스킬

| 이름 | 호출 | 용도 | 출처 |
|------|------|------|------|
| producthunt | `/basejb:producthunt` | Product Hunt GraphQL API (글·토픽·유저·컬렉션 조회) | [ReScienceLab/opc-skills](https://github.com/ReScienceLab/opc-skills), MIT |
| codex-image | `/basejb:codex-image` | Codex CLI `image_gen`(gpt-image-2) 이미지 생성. OAuth 인증, API 키 불필요 | [wjb127/codex-image](https://github.com/wjb127/codex-image), MIT (수정) |
| seo-optimizer | `/basejb:seo-optimizer` | SEO 콘텐츠 전략 · 기술 SEO · 키워드 리서치 가이드 | [davila7/claude-code-templates](https://github.com/davila7/claude-code-templates), MIT |
| image-optimizer | `/basejb:image-optimizer` | `cwebp`로 이미지를 WebP로 변환 (단일 / 일괄, 화질 유지) | 직접 작성 |

---

## 개발 (저장소 관리자용)

> 아래는 저장소를 직접 유지보수하는 관리자 — 또는 fork해서 본인 사본을 만든 사람 — 전용 메모입니다. `/plugin install`로 설치만 한 사용자는 무시해도 됩니다.

### 로컬 개발

마켓플레이스를 거치지 않고 이 repo 그대로 로드:

```
claude --plugin-dir ~/Repositories/skills
```

스킬 수정 후 `/reload-plugins`로 즉시 반영.

### 스킬 추가 규칙

1. `skills/<이름>/SKILL.md` 작성 (frontmatter `description:` 필수, 이름은 kebab-case)
2. 외부 코드를 가져온 경우 SKILL.md 상단에 출처 코멘트 + 원본 `LICENSE` 파일 함께 포함
3. `.claude-plugin/plugin.json`의 `version` bump
4. commit / push
5. 다른 머신: `/plugin marketplace update skills && /plugin update basejb@skills`
