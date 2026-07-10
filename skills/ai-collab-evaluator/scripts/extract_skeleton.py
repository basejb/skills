#!/usr/bin/env python3
"""Claude Code 세션 jsonl → 평가용 스켈레톤 추출.

사용법:
    python3 extract_skeleton.py <session.jsonl> [--max-user 600] [--max-asst 250]

출력:
    - 요약 통계 (사용자 발화 수, AI 텍스트 블록 수, 도구별 호출 횟수)
    - 대화 스켈레톤: [USER] 발화 전문(잘림) / [TOOL] 도구+힌트 / [ASST] AI 텍스트 앞부분
    - [FORK] 백그라운드 에이전트 알림 별도 태깅

tool_result·system-reminder·로컬 커맨드 노이즈는 제거. 사용자 발화는 질문 방식
평가의 핵심 증거이므로 길게, AI 텍스트는 맥락 파악용으로 짧게 자른다.
"""
import json
import sys


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        sys.exit(1)
    path = args[0]
    max_user = 600
    max_asst = 250
    if "--max-user" in args:
        max_user = int(args[args.index("--max-user") + 1])
    if "--max-asst" in args:
        max_asst = int(args[args.index("--max-asst") + 1])

    out = []
    tools = {}
    n_user = n_asst = n_fork = 0

    for line in open(path):
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue
        t = d.get("type")
        if t == "user":
            m = d.get("message", {}).get("content", "")
            if isinstance(m, str):
                txt = m
            else:
                # tool_result가 섞인 메시지는 스킵 (도구 결과이지 사용자 발화 아님)
                if any(isinstance(c, dict) and c.get("type") == "tool_result" for c in m):
                    continue
                txt = " ".join(
                    c.get("text", "")
                    for c in m
                    if isinstance(c, dict) and c.get("type") == "text"
                )
            txt = txt.strip()
            if not txt:
                continue
            head = txt[:60]
            if "<system-reminder" in head or txt.startswith("[Request"):
                continue
            if "<local-command" in head or "<command-name>" in head:
                continue
            if "<task-notification" in head:
                n_fork += 1
                # 포크 결과 요약만 추출
                marker = "<result>"
                idx = txt.find(marker)
                summary = txt[idx + len(marker):idx + len(marker) + 200] if idx >= 0 else txt[:200]
                out.append(("FORK", summary))
                continue
            n_user += 1
            out.append(("USER", txt[:max_user]))
        elif t == "assistant":
            m = d.get("message", {}).get("content", [])
            if not isinstance(m, list):
                continue
            for c in m:
                if not isinstance(c, dict):
                    continue
                if c.get("type") == "tool_use":
                    name = c.get("name", "?")
                    tools[name] = tools.get(name, 0) + 1
                    inp = c.get("input", {})
                    hint = str(
                        inp.get("description")
                        or inp.get("skill")
                        or inp.get("prompt")
                        or inp.get("file_path")
                        or ""
                    )[:100]
                    out.append(("TOOL", f"{name}: {hint}"))
                elif c.get("type") == "text":
                    txt = c.get("text", "").strip()
                    if txt:
                        n_asst += 1
                        out.append(("ASST", txt[:max_asst]))

    print(f"user msgs: {n_user}, asst text blocks: {n_asst}, fork notifications: {n_fork}")
    print("tool counts:", tools)
    print("---SKELETON---")
    for role, txt in out:
        print(f"[{role}] {txt.replace(chr(10), ' | ')}")


if __name__ == "__main__":
    main()
