#!/usr/bin/env python3
"""
Export issues from a beads SQLite database that are missing from issues.jsonl.

With beads 0.5.x and deprecation of sqlite in favor of dolt, my beads instances
got into weird states where I couldn't list issues because they were not accesible,
issues from the database were not synced from sqlite, and I couldn't import into
the new dolt database.

This script exports beads from sqlite and appends to the jsonl file and once there
you can use bd import to import them into dolt. Make sure you `rm -rf .beads/dolt/`
first (assuming you have nothing there) otherwise it'll refuse to import.

The empty dolt database is created when you run any bd command.

Usage:
    python3 sqlite-to-jsonl.py [--beads-dir PATH] [--append] [--output FILE]

Options:
    --beads-dir PATH   Path to .beads directory (default: ./.beads)
    --append           Append missing issues directly to issues.jsonl
    --output FILE      Write missing issues to FILE (default: missing_issues.jsonl)

After exporting, import into dolt with:
    bd import -i .beads/issues.jsonl --force
"""

import argparse
import json
import re
import sqlite3
import sys
from pathlib import Path


def fix_timestamps(obj):
    """Normalize timestamps to RFC3339 format required by beads import."""
    ts_no_t = re.compile(r'^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}(?:\.\d+)?)$')
    ts_no_tz = re.compile(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?$')

    if isinstance(obj, dict):
        return {k: fix_timestamps(v) for k, v in obj.items()}
    elif isinstance(obj, list):
        return [fix_timestamps(v) for v in obj]
    elif isinstance(obj, str):
        # Fix "2026-02-10 08:47:27" -> "2026-02-10T08:47:27"
        m = ts_no_t.match(obj)
        if m:
            obj = f"{m.group(1)}T{m.group(2)}"
        # Fix "2026-02-10T08:47:27" -> "2026-02-10T08:47:27Z"
        if ts_no_tz.match(obj):
            obj = obj + 'Z'
    return obj


def load_jsonl_ids(path: Path) -> set:
    ids = set()
    if not path.exists():
        return ids
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                ids.add(json.loads(line).get('id'))
    return ids


def export_missing(beads_dir: Path, output: Path, append: bool):
    db_path = beads_dir / 'beads.db'
    jsonl_path = beads_dir / 'issues.jsonl'

    if not db_path.exists():
        print(f"Error: {db_path} not found", file=sys.stderr)
        sys.exit(1)

    jsonl_ids = load_jsonl_ids(jsonl_path)
    print(f"JSONL entries: {len(jsonl_ids)}")

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row

    total_db = conn.execute('SELECT COUNT(*) FROM issues').fetchone()[0]
    print(f"SQLite entries: {total_db}")

    cur = conn.execute('SELECT * FROM issues ORDER BY created_at')
    missing_rows = [dict(row) for row in cur if row['id'] not in jsonl_ids]
    print(f"Missing: {len(missing_rows)}")

    if not missing_rows:
        print("Nothing to export.")
        return

    issue_ids = [r['id'] for r in missing_rows]
    placeholders = ','.join('?' * len(issue_ids))

    labels = {}
    for row in conn.execute(f'SELECT * FROM labels WHERE issue_id IN ({placeholders})', issue_ids):
        labels.setdefault(row['issue_id'], []).append(row['label'])

    deps = {}
    for row in conn.execute(f'SELECT * FROM dependencies WHERE issue_id IN ({placeholders})', issue_ids):
        deps.setdefault(row['issue_id'], []).append({
            'issue_id': row['issue_id'],
            'depends_on_id': row['depends_on_id'],
            'type': row['type'],
            'created_at': row['created_at'],
            'created_by': row['created_by'],
        })

    comments = {}
    for row in conn.execute(f'SELECT * FROM comments WHERE issue_id IN ({placeholders})', issue_ids):
        comments.setdefault(row['issue_id'], []).append({
            'id': row['id'],
            'author': row['author'],
            'text': row['text'],
            'created_at': row['created_at'],
        })

    internal_fields = {
        'content_hash', 'compaction_level', 'compacted_at', 'compacted_at_commit',
        'original_size', 'ephemeral', 'pinned', 'is_template', 'crystallizes',
    }

    entries = []
    for row in missing_rows:
        entry = {k: v for k, v in row.items()
                 if v is not None and v != '' and v != '{}' and v != 0
                 and k not in internal_fields}
        if row.get('metadata') and row['metadata'] != '{}':
            try:
                entry['metadata'] = json.loads(row['metadata'])
            except Exception:
                pass
        else:
            entry.pop('metadata', None)
        entry['labels'] = labels.get(row['id'], [])
        entry['dependencies'] = deps.get(row['id'], [])
        if row['id'] in comments:
            entry['comments'] = comments[row['id']]
        entries.append(fix_timestamps(entry))

    conn.close()

    if append:
        # Verify no overlap before appending
        existing_ids = load_jsonl_ids(jsonl_path)
        new_ids = {e['id'] for e in entries}
        overlap = existing_ids & new_ids
        if overlap:
            print(f"Error: {len(overlap)} overlapping IDs would cause duplicates", file=sys.stderr)
            sys.exit(1)
        with open(jsonl_path, 'a') as f:
            for entry in entries:
                f.write(json.dumps(entry, ensure_ascii=False) + '\n')
        print(f"Appended {len(entries)} entries to {jsonl_path}")
    else:
        with open(output, 'w') as f:
            for entry in entries:
                f.write(json.dumps(entry, ensure_ascii=False) + '\n')
        print(f"Written {len(entries)} entries to {output}")


def fix_existing_timestamps(beads_dir: Path):
    """Fix timestamp format in an existing issues.jsonl."""
    jsonl_path = beads_dir / 'issues.jsonl'
    if not jsonl_path.exists():
        print(f"Error: {jsonl_path} not found", file=sys.stderr)
        sys.exit(1)

    with open(jsonl_path) as f:
        lines = f.readlines()

    fixed_count = 0
    out = []
    for line in lines:
        entry = json.loads(line.strip())
        fixed = fix_timestamps(entry)
        if fixed != entry:
            fixed_count += 1
        out.append(json.dumps(fixed, ensure_ascii=False))

    with open(jsonl_path, 'w') as f:
        f.write('\n'.join(out) + '\n')

    print(f"Fixed timestamps in {fixed_count} entries ({len(out)} total)")


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--beads-dir', default='.beads', help='Path to .beads directory')
    parser.add_argument('--append', action='store_true', help='Append missing issues to issues.jsonl')
    parser.add_argument('--output', default='missing_issues.jsonl', help='Output file for missing issues')
    parser.add_argument('--fix-timestamps-only', action='store_true',
                        help='Only fix timestamp format in existing issues.jsonl, do not export from SQLite')
    args = parser.parse_args()

    beads_dir = Path(args.beads_dir)

    if args.fix_timestamps_only:
        fix_existing_timestamps(beads_dir)
    else:
        output = Path(args.output) if not args.append else None
        export_missing(beads_dir, output, args.append)


if __name__ == '__main__':
    main()
