from __future__ import annotations

import argparse
import json
from copy import deepcopy
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_PATH = ROOT / "python-ml" / "data" / "chat_choice_training.jsonl"


LABEL_HINTS = {
    "A": ["보컬", "발성", "노래", "음정"],
    "B": ["댄스", "안무", "퍼포먼스", "동선"],
    "C": ["팀워크", "합", "소통", "협업"],
    "D": ["멘탈", "컨디션", "회복", "안정"],
    "SPECIAL": ["스타성", "무대", "임팩트", "연출"],
    "NONE": ["잠깐", "모르겠어", "무난하게", "일단"],
}


PATTERNS = [
    "이번엔 {hint} 쪽으로 가자",
    "{hint} 위주로 해보자",
    "{hint} 중심으로 가자",
    "{base} 쪽으로 가보자",
    "{base} 방향으로 가자",
    "{base} 방향으로 선택",
    "{hint} 쪽으로 바꿔보자",
    "{hint} 포인트를 올리자",
    "{base} 느낌으로 가는 게 좋겠어",
    "{base} 이렇게 해보자",
    "이번 선택은 {base}",
    "지금은 {hint} 쪽이 맞을 것 같아",
    "{hint} 우선으로 가면 어때",
    "{base} 이 선택으로 밀어 봐",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Augment chat-choice training jsonl rows.")
    parser.add_argument("--path", default=str(DEFAULT_PATH), help="Target jsonl path")
    parser.add_argument("--target", type=int, default=2000, help="Desired total row count")
    parser.add_argument(
        "--replace-augmented",
        action="store_true",
        help="Drop existing generated rows before creating fresh augmented samples",
    )
    return parser.parse_args()


def load_rows(path: Path) -> list[dict]:
    rows: list[dict] = []
    if not path.exists():
        return rows
    with path.open("r", encoding="utf-8") as f:
        for line in f:
            raw = line.strip()
            if not raw:
                continue
            try:
                row = json.loads(raw)
            except json.JSONDecodeError:
                continue
            if isinstance(row, dict):
                rows.append(row)
    return rows


def normalize_base_text(text: str) -> str:
    base = " ".join(str(text or "").strip().split())
    if not base:
        return "무난하게 가보자"
    return base.rstrip(".!?, ")


def build_candidates(row: dict) -> Iterable[str]:
    key = str(row.get("resolvedKey", "")).strip().upper()
    base = normalize_base_text(str(row.get("userText", "")))
    hints = LABEL_HINTS.get(key) or ["선택"]
    yielded: set[str] = set()
    for idx, pattern in enumerate(PATTERNS):
        hint = hints[idx % len(hints)]
        text = pattern.format(base=base, hint=hint).strip()
        if not text or text == base or text in yielded:
            continue
        yielded.add(text)
        yield text
    for hint in hints:
        text = f"{hint} 쪽으로 {base}"
        if text not in yielded:
            yielded.add(text)
            yield text
        text = f"{base} 그리고 {hint} 강조"
        if text not in yielded:
            yielded.add(text)
            yield text


def augment_rows(rows: list[dict], target: int) -> list[dict]:
    if len(rows) >= target:
        return []

    generated: list[dict] = []
    seen_texts = {normalize_base_text(str(row.get("userText", ""))) for row in rows}
    cursor = 0
    while len(rows) + len(generated) < target:
        source = rows[cursor % len(rows)]
        cursor += 1
        for candidate in build_candidates(source):
            if candidate in seen_texts:
                continue
            clone = deepcopy(source)
            clone["timestamp"] = datetime.now(timezone.utc).isoformat()
            clone["userText"] = candidate
            clone["resolverType"] = "AUGMENT"
            clone["mlDecisionReason"] = f"AUGMENTED_FROM_{str(source.get('resolvedKey', '')).upper() or 'UNKNOWN'}"
            generated.append(clone)
            seen_texts.add(candidate)
            if len(rows) + len(generated) >= target:
                break
        if cursor > len(rows) * 20 and len(rows) + len(generated) < target:
            raise RuntimeError("Could not generate enough unique augmented samples.")
    return generated


def write_rows(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


def append_rows(path: Path, rows: list[dict]) -> None:
    if not rows:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8", newline="\n") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


def main() -> None:
    args = parse_args()
    path = Path(args.path).resolve()
    rows = load_rows(path)
    if not rows:
        raise SystemExit(f"No rows found: {path}")
    original_count = len(rows)
    if args.replace_augmented:
        rows = [row for row in rows if str(row.get("resolverType", "")).upper() != "AUGMENT"]
    generated = augment_rows(rows, args.target)
    if args.replace_augmented:
        write_rows(path, rows + generated)
    else:
        append_rows(path, generated)
    print(
        json.dumps(
            {
                "path": str(path),
                "originalCount": original_count,
                "baseCount": len(rows),
                "addedCount": len(generated),
                "finalCount": len(rows) + len(generated),
            },
            ensure_ascii=False,
        )
    )


if __name__ == "__main__":
    main()
