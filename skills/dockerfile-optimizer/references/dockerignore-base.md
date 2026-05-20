# .dockerignore Recommendations

DFO-SIZE-004 룰이 부재 또는 부족을 감지하면 사용자에게 이 내용을 제시한다. 자동 생성 금지 — 사용자 명시 승인 시에만 Write.

---

## 공통 베이스

```dockerignore
# Version control
.git
.gitignore
.gitattributes

# OS
.DS_Store
Thumbs.db

# IDE
.vscode
.idea
*.swp
*.swo

# Logs
*.log
logs

# Environment files (시크릿 누출 방지)
.env
.env.*
!.env.example

# Test/coverage
coverage
.nyc_output
htmlcov
.coverage
.pytest_cache

# CI/CD config (이미지에 불필요)
.github
.gitlab-ci.yml
.circleci

# Documentation (선택)
README.md
docs
```

---

## Node.js 추가

```dockerignore
node_modules
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*
.pnpm-store

# Build artifacts
dist
build
.next
out
.turbo
.nuxt
.cache

# Test
__snapshots__
*.test.ts
*.test.js
*.spec.ts
*.spec.js
```

---

## Python 추가

```dockerignore
__pycache__
*.py[cod]
*$py.class
*.egg-info
.eggs
dist
build

# Virtualenv
.venv
venv
env
.python-version

# Tools
.mypy_cache
.ruff_cache
.tox
```

---

## Go 추가

```dockerignore
bin
dist
*.exe
*.test
*.prof
vendor
```

---

## 결합 예시 (Node.js + 공통)

`.dockerignore` 단일 파일로 결합:

```dockerignore
.git
.gitignore
.DS_Store
.vscode
.idea
*.log
.env
.env.*
!.env.example
coverage
.github

node_modules
dist
.next
.turbo
__snapshots__
```
