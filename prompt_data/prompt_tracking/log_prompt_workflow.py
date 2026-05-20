#!/usr/bin/env python3
"""
Queue user prompts on submit and append to prompt_data/prompts.txt when the agent loop ends.

Cursor's documented `stop` hook input does not include the raw user prompt, so we store
the prompt on `beforeSubmitPrompt` (keyed by `generation_id`) and flush on `stop`.

`afterFileEdit` records repo-relative edited paths keyed by `generation_id`; those are
consumed when `stop` flushes so each log entry can include edit metadata.

Each **`prompts.txt`** row uses local wall-clock **`Date:`** / **`Time:`**
(`yyyy-MM-dd`, **`HH:mm:ss`**; **`TZ`** / OS local picks the conversion).

**`conversation_id`** in logs is a small integer from **`prompt_data/prompt_tracking/conversation_id_map.json`**
(UUID → number, assigned on first sight). Full UUIDs stay in that map file only.

**`long-term-prompt-tracking.txt`** (under **`prompt_data/`**) appends numbered blocks (`Prompt #N`, …).
Sequence counter: **`prompt_data/prompt_tracking/prompt_counter.json`**.

Hook scripts and pending state live under **`prompt_data/prompt_tracking/`** (not `.cursor/`).
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone

PENDING_NAME = ".pending_prompts_by_generation.json"
EDITS_PENDING_NAME = ".pending_edited_files_by_generation.json"
OUTPUT_REL = "prompt_data/prompts.txt"
LONG_TERM_TRACKING_REL = "prompt_data/long-term-prompt-tracking.txt"
TRACKING_DIR_REL = "prompt_data/prompt_tracking"
CONVERSATION_ID_MAP_REL = "prompt_data/prompt_tracking/conversation_id_map.json"
PROMPT_COUNTER_REL = "prompt_data/prompt_tracking/prompt_counter.json"


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _logged_instant_utc() -> datetime:
    """Single instant captured at flush (UTC, no microseconds)."""
    return datetime.now(timezone.utc).replace(microsecond=0)


def _local_wall_clock_and_tz_line(dt_utc: datetime) -> tuple[str, str, str]:
    """Local yyyy-MM-dd, HH:mm:ss, and short description of TZ used."""
    raw = os.environ.get("TZ")
    if raw is None:
        local = dt_utc.astimezone()
        abbrev = local.tzname() or ""
        label = abbrev if abbrev else type(local.tzinfo).__name__
        return (
            local.strftime("%Y-%m-%d"),
            local.strftime("%H:%M:%S"),
            f"system local ({label})",
        )

    trimmed = raw.strip()
    if trimmed.startswith(":"):
        trimmed = trimmed[1:].strip()
    if trimmed == "":
        local = dt_utc.astimezone(timezone.utc)
        return (
            local.strftime("%Y-%m-%d"),
            local.strftime("%H:%M:%S"),
            "UTC (TZ env empty)",
        )

    try:
        from zoneinfo import ZoneInfo
    except ImportError:
        local = dt_utc.astimezone()
        abbrev = local.tzname() or ""
        return (
            local.strftime("%Y-%m-%d"),
            local.strftime("%H:%M:%S"),
            f"zoneinfo unavailable; system local ({abbrev})",
        )

    try:
        zone = ZoneInfo(trimmed)
    except Exception:
        local = dt_utc.astimezone()
        abbrev = local.tzname() or ""
        return (
            local.strftime("%Y-%m-%d"),
            local.strftime("%H:%M:%S"),
            f'invalid TZ {raw!r}; system local ({abbrev})',
        )

    local = dt_utc.astimezone(zone)
    abbrev = local.tzname() or ""
    tz_line = trimmed
    if abbrev and abbrev.lower() != trimmed.lower():
        tz_line = f"{trimmed} ({abbrev})"
    return local.strftime("%Y-%m-%d"), local.strftime("%H:%M:%S"), tz_line


def _data_path(root: str, rel: str) -> str:
    return os.path.join(root, rel)


def _conversation_id_from_hook(data: dict) -> str | None:
    raw = data.get("conversation_id")
    if raw is None:
        return None
    s = str(raw).strip()
    return s if s else None


def _allocate_conversation_number(root: str, conversation_uuid: str | None) -> str:
    """Map a Cursor conversation UUID to a stable small integer string for logs."""
    if not conversation_uuid:
        return ""
    path = _data_path(root, CONVERSATION_ID_MAP_REL)
    state = _load_json_dict(path)
    mapping = state.get("uuid_to_number")
    if not isinstance(mapping, dict):
        mapping = {}
    if conversation_uuid in mapping:
        return str(mapping[conversation_uuid])
    try:
        next_id = int(state.get("next_id", 1))
    except (TypeError, ValueError):
        next_id = 1
    mapping[conversation_uuid] = next_id
    state["uuid_to_number"] = mapping
    state["next_id"] = next_id + 1
    try:
        _save_json_dict_atomic(path, state)
    except OSError:
        pass
    return str(next_id)


def _next_prompt_number(root: str) -> int:
    path = _data_path(root, PROMPT_COUNTER_REL)
    state = _load_json_dict(path)
    try:
        n = int(state.get("next_prompt_number", 1))
    except (TypeError, ValueError):
        n = 1
    state["next_prompt_number"] = n + 1
    try:
        _save_json_dict_atomic(path, state)
    except OSError:
        pass
    return n


def _workspace_root(data: dict) -> str:
    roots = data.get("workspace_roots") or []
    if isinstance(roots, list) and roots:
        return str(roots[0])
    return os.environ.get("CURSOR_PROJECT_DIR") or os.getcwd()


def _tracking_dir(root: str) -> str:
    return _data_path(root, TRACKING_DIR_REL)


def _prompt_pending_path(root: str) -> str:
    # Path must not contain spaces: Cursor runs `command` without shell quoting.
    return os.path.join(_tracking_dir(root), PENDING_NAME)


def _edits_pending_path(root: str) -> str:
    return os.path.join(_tracking_dir(root), EDITS_PENDING_NAME)


def _load_json_dict(path: str) -> dict:
    if not os.path.isfile(path):
        return {}
    try:
        with open(path, encoding="utf-8") as f:
            raw = json.load(f)
        return raw if isinstance(raw, dict) else {}
    except (OSError, json.JSONDecodeError):
        return {}


def _save_json_dict_atomic(path: str, data: dict) -> None:
    os.makedirs(os.path.dirname(path), mode=0o755, exist_ok=True)
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    os.replace(tmp, path)


def _rel_file_path(workspace_root: str, abs_path: str) -> str:
    try:
        r = os.path.relpath(abs_path, workspace_root)
    except ValueError:
        return os.path.abspath(abs_path)
    r = os.path.normpath(r)
    if r.startswith(f"..{os.sep}") or r == "..":
        return os.path.abspath(abs_path)
    return r.replace(os.sep, "/")


def _emit_before_submit_ok() -> None:
    sys.stdout.write(json.dumps({"continue": True}) + "\n")


def _emit_stop_ok() -> None:
    sys.stdout.write("{}\n")


def _emit_after_file_edit_ok() -> None:
    sys.stdout.write("{}\n")


def _append_prompt_file(
    root: str,
    text: str,
    *,
    conversation_id_number: str,
    logged_instant_utc: datetime,
    files_edited: bool,
    edited_files_relative: list[str],
) -> None:
    out = _data_path(root, OUTPUT_REL)
    os.makedirs(os.path.dirname(out), mode=0o755, exist_ok=True)
    long_term_out = _data_path(root, LONG_TERM_TRACKING_REL)
    ld_loc, lt_loc, _ = _local_wall_clock_and_tz_line(logged_instant_utc)
    prompt_num = _next_prompt_number(root)
    cid_line = (
        f"conversation_id: {conversation_id_number}"
        if conversation_id_number
        else "conversation_id:"
    )
    lines = [
        "",
        "-" * 80,
        f"Date: {ld_loc}",
        f"Time: {lt_loc}",
        cid_line,
        f"files_edited: {'yes' if files_edited else 'no'}",
        "edited_files:",
    ]
    if edited_files_relative:
        for rel in edited_files_relative:
            lines.append(f"  - {rel}")
    lines.extend(["-" * 80, "", text, ""])
    block = "\n".join(lines)
    with open(out, "a", encoding="utf-8") as f:
        f.write(block)

    lt_block = (
        f"Prompt #{prompt_num}\n\n"
        f"Date: {ld_loc} {lt_loc}\n\n"
        f"Prompt:\n{text}\n\n"
    )
    with open(long_term_out, "a", encoding="utf-8") as f:
        f.write(lt_block)


def _queue(data: dict) -> int:
    root = _workspace_root(data)
    gen = data.get("generation_id")
    prompt = data.get("prompt")
    if gen is None or prompt is None:
        _emit_before_submit_ok()
        return 0
    pending_path = _prompt_pending_path(root)
    pending = _load_json_dict(pending_path)
    pending[str(gen)] = {
        "prompt": prompt,
        "queued_at_utc": _now_iso(),
        "conversation_id": _conversation_id_from_hook(data),
    }
    try:
        _save_json_dict_atomic(pending_path, pending)
    except OSError:
        pass
    _emit_before_submit_ok()
    return 0


def _take_edited_files_snapshot(root: str, generation_id: str | None) -> list[str]:
    """Remove and return sorted unique repo-relative paths for this generation."""
    if generation_id is None:
        return []
    edits_path = _edits_pending_path(root)
    data = _load_json_dict(edits_path)
    key = str(generation_id)
    raw_list = data.pop(key, None)
    paths: list[str] = []
    if isinstance(raw_list, list):
        for x in raw_list:
            s = str(x).strip().replace("\\", "/")
            if s:
                paths.append(s)
    paths = sorted(set(paths), key=lambda p: (p.casefold(), p))
    try:
        _save_json_dict_atomic(edits_path, data)
    except OSError:
        pass
    return paths


def _restore_edited_files_hint(root: str, generation_id: str | None, paths: list[str]) -> None:
    if generation_id is None or not paths:
        return
    edits_path = _edits_pending_path(root)
    data = _load_json_dict(edits_path)
    key = str(generation_id)
    existing_raw = data.get(key, [])
    merged: list[str] = []
    seen: set[str] = set()
    for src in paths + (
        existing_raw if isinstance(existing_raw, list) else []
    ):
        if not isinstance(src, str):
            continue
        u = src.strip().replace("\\", "/")
        if not u or u in seen:
            continue
        seen.add(u)
        merged.append(u)
    merged.sort(key=lambda p: (p.casefold(), p))
    data[key] = merged
    try:
        _save_json_dict_atomic(edits_path, data)
    except OSError:
        pass


def _record_edit(data: dict) -> int:
    gen = data.get("generation_id")
    abs_fp = data.get("file_path")
    if gen is None or abs_fp is None or not isinstance(abs_fp, str) or not abs_fp.strip():
        _emit_after_file_edit_ok()
        return 0
    root = _workspace_root(data)
    rel = _rel_file_path(root, abs_fp)
    edits_path = _edits_pending_path(root)
    state = _load_json_dict(edits_path)
    key = str(gen)
    existing = state.get(key, [])
    if not isinstance(existing, list):
        existing = []
    items = [str(x).strip().replace("\\", "/") for x in existing if str(x).strip()]
    items.append(rel)
    items = sorted(set(items), key=lambda p: (p.casefold(), p))
    state[key] = items
    try:
        _save_json_dict_atomic(edits_path, state)
    except OSError:
        pass
    _emit_after_file_edit_ok()
    return 0


def _flush(data: dict) -> int:
    root = _workspace_root(data)
    gen = data.get("generation_id")
    logged_instant = _logged_instant_utc()

    direct = data.get("prompt") or data.get("user_prompt")
    if isinstance(direct, str) and direct.strip():
        paths = _take_edited_files_snapshot(root, gen)
        cid_num = _allocate_conversation_number(
            root, _conversation_id_from_hook(data)
        )
        try:
            _append_prompt_file(
                root,
                direct.strip(),
                conversation_id_number=cid_num,
                logged_instant_utc=logged_instant,
                files_edited=bool(paths),
                edited_files_relative=paths,
            )
        except OSError:
            _restore_edited_files_hint(root, gen, paths)
        _emit_stop_ok()
        return 0

    if gen is None:
        _emit_stop_ok()
        return 0

    pending_path = _prompt_pending_path(root)
    pending = _load_json_dict(pending_path)
    key = str(gen)
    entry = pending.pop(key, None)
    if entry is None:
        _emit_stop_ok()
        return 0

    paths = _take_edited_files_snapshot(root, gen)
    prompt_text = entry.get("prompt")
    cid_uuid = _conversation_id_from_hook(data)
    if cid_uuid is None:
        raw_q = entry.get("conversation_id")
        if isinstance(raw_q, str) and raw_q.strip():
            cid_uuid = raw_q.strip()
    cid_num = _allocate_conversation_number(root, cid_uuid)

    if not isinstance(prompt_text, str):
        _save_json_dict_atomic(pending_path, pending)
        _restore_edited_files_hint(root, gen, paths)
        _emit_stop_ok()
        return 0

    try:
        _append_prompt_file(
            root,
            prompt_text,
            conversation_id_number=cid_num,
            logged_instant_utc=logged_instant,
            files_edited=bool(paths),
            edited_files_relative=paths,
        )
        try:
            _save_json_dict_atomic(pending_path, pending)
        except OSError:
            pending[key] = entry
            try:
                _save_json_dict_atomic(pending_path, pending)
            except OSError:
                pass
    except OSError:
        pending[key] = entry
        try:
            _save_json_dict_atomic(pending_path, pending)
        except OSError:
            pass
        _restore_edited_files_hint(root, gen, paths)

    _emit_stop_ok()
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--queue", action="store_true", help="beforeSubmitPrompt: remember prompt")
    parser.add_argument("--flush", action="store_true", help="stop: append queued prompt to prompt_data/prompts.txt")
    parser.add_argument(
        "--record-edit",
        action="store_true",
        help="afterFileEdit: record edited file path under generation_id",
    )
    args = parser.parse_args()

    raw = sys.stdin.read()
    if not raw.strip():
        if args.queue:
            _emit_before_submit_ok()
        elif args.record_edit:
            _emit_after_file_edit_ok()
        else:
            _emit_stop_ok()
        return 0

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        if args.queue:
            _emit_before_submit_ok()
        elif args.record_edit:
            _emit_after_file_edit_ok()
        else:
            _emit_stop_ok()
        return 0

    if not isinstance(data, dict):
        if args.queue:
            _emit_before_submit_ok()
        elif args.record_edit:
            _emit_after_file_edit_ok()
        else:
            _emit_stop_ok()
        return 0

    if args.queue:
        return _queue(data)
    if args.flush:
        return _flush(data)
    if args.record_edit:
        return _record_edit(data)

    evt = data.get("hook_event_name")
    if evt == "beforeSubmitPrompt":
        return _queue(data)
    if evt == "stop" or evt == "Stop":
        return _flush(data)

    if args.queue or args.record_edit:
        _emit_before_submit_ok() if args.queue else _emit_after_file_edit_ok()
        return 0

    _emit_stop_ok()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
