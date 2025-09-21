#!/usr/bin/env python3
"""
Minimal midclt mock used in Molecule scenarios to emulate a subset of the
TrueNAS SCALE middleware API.  It keeps state on disk so that idempotence
checks behave as expected when Ansible replays the same tasks.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, Dict, List

STATE_DIR = Path("/var/tmp/midclt-mock")
STATE_FILE = STATE_DIR / "state.json"

DEFAULT_STATE: Dict[str, Any] = {
    "datasets": {},
    "groups": {},
    "users": {},
    "snapshots": {},
    "apps": {},
    "_counters": {
        "dataset": 0,
        "group": 0,
        "user": 0,
        "snapshot": 0,
    },
}


def load_state() -> Dict[str, Any]:
    if STATE_FILE.exists():
        try:
            with STATE_FILE.open("r", encoding="utf-8") as fh:
                return json.load(fh)
        except json.JSONDecodeError:
            pass
    return json.loads(json.dumps(DEFAULT_STATE))


def save_state(state: Dict[str, Any]) -> None:
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    with STATE_FILE.open("w", encoding="utf-8") as fh:
        json.dump(state, fh, indent=2, sort_keys=True)


def next_id(state: Dict[str, Any], counter: str) -> int:
    counters = state.setdefault("_counters", {})
    counters[counter] = counters.get(counter, 0) + 1
    return counters[counter]


def ensure_entry(container: Dict[str, Any], key: str, payload: Dict[str, Any]) -> Dict[str, Any]:
    entry = container.get(key)
    if entry is None:
        entry = payload
        container[key] = entry
    else:
        entry.update(payload)
    return entry


def filter_rows(rows: List[Dict[str, Any]], filters: List[List[Any]]) -> List[Dict[str, Any]]:
    if not filters:
        return rows

    def matches(row: Dict[str, Any]) -> bool:
        for flt in filters:
            if len(flt) != 3:
                continue
            field, op, value = flt
            if op != "=":
                continue
            row_value = row.get(field) or row.get({"group": "gid"}.get(field, field))
            if row_value != value:
                return False
        return True

    return [r for r in rows if matches(r)]


def handle_dataset(state: Dict[str, Any], method: str, params: List[str]) -> Any:
    datasets: Dict[str, Dict[str, Any]] = state.setdefault("datasets", {})
    if method == "pool.dataset.query":
        filters = json.loads(params[0]) if params else []
        return filter_rows(list(datasets.values()), filters)

    if method == "pool.dataset.create":
        payload = json.loads(params[0]) if params else {}
        name = payload.get("name", "")
        entry = {
            "id": next_id(state, "dataset"),
            "name": name,
            **payload,
        }
        datasets[name] = entry
        return entry

    raise NotImplementedError(method)


def handle_filesystem(method: str) -> Any:
    if method == "filesystem.setperm":
        return {"result": "ok"}
    raise NotImplementedError(method)


def handle_group(state: Dict[str, Any], method: str, params: List[str]) -> Any:
    groups: Dict[str, Dict[str, Any]] = state.setdefault("groups", {})
    if method == "group.query":
        filters = json.loads(params[0]) if params else []
        rows = list(groups.values())
        return filter_rows(rows, filters)

    if method == "group.create":
        payload = json.loads(params[0]) if params else {}
        gid = payload.get("gid")
        entry = ensure_entry(groups, str(gid), {
            "id": next_id(state, "group"),
            "gid": gid,
            "name": payload.get("name", f"group{gid}"),
        })
        return entry

    raise NotImplementedError(method)


def handle_user(state: Dict[str, Any], method: str, params: List[str]) -> Any:
    users: Dict[str, Dict[str, Any]] = state.setdefault("users", {})
    if method == "user.query":
        filters = json.loads(params[0]) if params else []
        return filter_rows(list(users.values()), filters)

    if method == "user.create":
        payload = json.loads(params[0]) if params else {}
        uid = payload.get("uid")
        entry = ensure_entry(users, str(uid), {
            "id": next_id(state, "user"),
            "uid": uid,
            "username": payload.get("username"),
            "group": payload.get("group"),
            "home": payload.get("home"),
            "full_name": payload.get("full_name"),
        })
        return entry

    raise NotImplementedError(method)


def handle_snapshot(state: Dict[str, Any], method: str, params: List[str]) -> Any:
    snaps: Dict[str, Dict[str, Any]] = state.setdefault("snapshots", {})

    if method == "pool.snapshottask.query":
        filters = json.loads(params[0]) if params else []
        rows = []
        for entry in snaps.values():
            row = {
                "id": entry["id"],
                "dataset": entry["dataset"],
            }
            rows.append(row)
        return filter_rows(rows, filters)

    if method == "pool.snapshottask.create":
        payload = json.loads(params[0]) if params else {}
        dataset = payload.get("dataset")
        entry = {
            "id": next_id(state, "snapshot"),
            "dataset": dataset,
            "config": payload,
        }
        snaps[dataset] = entry
        return entry

    if method == "pool.snapshottask.update":
        identifier = params[0]
        payload = json.loads(params[1]) if len(params) > 1 else {}
        for entry in snaps.values():
            if str(entry["id"]) == identifier:
                entry["config"].update(payload)
                return entry
        return {"id": identifier, "config": payload}

    raise NotImplementedError(method)


def handle_core_download(params: List[str]) -> Any:
    if len(params) < 3:
        return None
    dest = Path(params[2])
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text("mock TrueNAS config", encoding="utf-8")
    return {"result": "saved"}


def handle_app(state: Dict[str, Any], method: str, params: List[str]) -> Any:
    apps: Dict[str, Dict[str, Any]] = state.setdefault("apps", {})

    if method == "app.query":
        filters = json.loads(params[0]) if params else []
        rows = []
        for entry in apps.values():
            rows.append({
                "name": entry["name"],
                "state": entry.get("state", "RUNNING"),
            })
        return filter_rows(rows, filters)

    if method == "app.config":
        name = params[0] if params else ""
        entry = apps.get(name)
        if entry is None:
            return {}
        return entry

    if method == "app.create":
        payload = json.loads(params[0]) if params else {}
        name = payload.get("name")
        compose = payload.get("custom_compose_config", {}).get("compose")
        entry = ensure_entry(apps, name, {
            "name": name,
            "compose": compose,
            "environment": {},
            "state": "RUNNING",
        })
        return entry

    if method == "app.update":
        name = params[0]
        payload = json.loads(params[1]) if len(params) > 1 else {}
        entry = ensure_entry(apps, name, {"name": name, "state": "RUNNING"})
        if "custom_compose_config" in payload:
            entry["compose"] = payload["custom_compose_config"].get("compose")
        if "environment" in payload:
            entry["environment"] = payload["environment"]
        return entry

    if method == "app.redeploy":
        name = params[0] if params else "unknown"
        entry = ensure_entry(apps, name, {"name": name, "state": "RUNNING"})
        entry["state"] = "RUNNING"
        entry["redeploy_count"] = entry.get("redeploy_count", 0) + 1
        return entry

    raise NotImplementedError(method)


def main() -> int:
    args = sys.argv[1:]
    json_mode = False

    if args and args[0] == "-j":
        json_mode = True
        args = args[1:]

    if not args or args[0] != "call":
        print("Unsupported invocation", file=sys.stderr)
        return 1

    args = args[1:]
    if not args:
        print("Missing method", file=sys.stderr)
        return 1

    method = args[0]
    params = args[1:]

    state = load_state()

    try:
        if method == "system.info":
            result: Any = {
                "hostname": "molecule-mock",
                "version": "25.04-mock",
            }
        elif method.startswith("pool.dataset"):
            result = handle_dataset(state, method, params)
        elif method.startswith("filesystem"):
            result = handle_filesystem(method)
        elif method.startswith("group"):
            result = handle_group(state, method, params)
        elif method.startswith("user"):
            result = handle_user(state, method, params)
        elif method.startswith("pool.snapshottask"):
            result = handle_snapshot(state, method, params)
        elif method == "core.download":
            result = handle_core_download(params)
        elif method.startswith("app."):
            result = handle_app(state, method, params)
        else:
            raise NotImplementedError(method)
    except NotImplementedError as exc:
        print(f"midclt mock: unsupported method {exc}", file=sys.stderr)
        return 1

    save_state(state)

    if json_mode and result is not None:
        sys.stdout.write(json.dumps(result))
    return 0


if __name__ == "__main__":
    sys.exit(main())
