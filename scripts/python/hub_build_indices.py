#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Hub machine indexes (JSON). Invoked by build-*-index.sh / .ps1 wrappers.

  python hub_build_indices.py prompts <prompts_root>
  python hub_build_indices.py tech-insight <vault_root>
  python hub_build_indices.py skills <skills_share_root>
  python hub_build_indices.py media-skills <skills_media_root>
  python hub_build_indices.py public-catalog <hub_root>
"""
import argparse
import json
import re
import sys
from pathlib import Path

if sys.version_info < (3, 6):
    sys.stderr.write('hub_build_indices.py requires Python 3.6+\n')
    sys.exit(1)

# Directories that contain canonical assets (asset_type -> directory per asset_taxonomy.md).
# Derivatives (02_interview_bank, 03_resume_bullets), staging (00_inbox),
# templates, indexes, etc. are intentionally excluded.
CANONICAL_DIRS = ('01_case_library', '04_methodology')

# Files to skip even inside canonical dirs.
SKIP_NAMES = frozenset({'README.md'})


def fm_field_yaml(text, key):
    """Parse a field from YAML front matter (--- ... ---).

    Supports plain scalars and simple folded/literal block scalars
    (description: >- / > / |- / | followed by indented lines).
    """
    m = re.search(r'^---\s*\n(.*?)\n---', text, re.S | re.M)
    if not m:
        return ''
    block = m.group(1)
    lines = block.splitlines()
    prefix = key + ':'
    for i, line in enumerate(lines):
        if not line.startswith(prefix):
            continue
        rest = line[len(prefix):].strip()
        if rest in ('>-', '>', '|-', '|'):
            collected = []
            for nxt in lines[i + 1:]:
                if not nxt:
                    if collected:
                        collected.append('')
                    continue
                if nxt[0] in (' ', '\t'):
                    collected.append(nxt.strip())
                    continue
                break
            return ' '.join(x for x in collected if x).strip()
        return rest.strip().strip('"').strip("'")
    return ''


def fm_field_bold(text, key):
    """Parse a field from legacy bold-markdown format: **key**: value"""
    m = re.search(r'^\*\*' + re.escape(key) + r'\*\*:\s*(.+)$', text, re.M)
    return m.group(1).strip() if m else ''


def fm_field(text, key):
    """Try YAML front matter first, then legacy bold format."""
    v = fm_field_yaml(text, key)
    return v if v else fm_field_bold(text, key)


def cmd_prompts(root):
    root = Path(root)
    items = []
    for subname in ('share', 'projects'):
        sub = root / subname
        if not sub.is_dir():
            continue
        for p in sorted(sub.rglob('*.prompt.md')):
            if 'bak' in p.parts:
                continue
            rel = p.relative_to(root).as_posix()
            text = p.read_text(encoding='utf-8')
            items.append({
                'id': fm_field(text, 'id'),
                'path': rel,
                'scope': fm_field(text, 'scope'),
                'project': fm_field(text, 'project'),
                'type': fm_field(text, 'type'),
                'owner_skill': fm_field(text, 'owner_skill'),
                'status': fm_field(text, 'status'),
                'replaced_by': fm_field(text, 'replaced_by'),
            })
    out = root / 'indexes' / 'prompts.index.json'
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(
        json.dumps({'version': 1, 'items': items}, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    sys.stdout.write('PROMPT_INDEX=ok items={} file={}\n'.format(len(items), out))
    return 0


def _build_skill_layer_index(layer_root, path_prefix):
    """Build index.json under a skill layer root from SKILL.md front matter."""
    layer_root = Path(layer_root)
    if not layer_root.is_dir():
        sys.stderr.write('ERROR: skill layer root not found: {}\n'.format(layer_root))
        return 1, None
    items = []
    for d in sorted(layer_root.iterdir()):
        if not d.is_dir():
            continue
        if d.name.startswith('.') or d.name == 'bak':
            continue
        if 'bak' in d.parts:
            continue
        skill_md = d / 'SKILL.md'
        if not skill_md.is_file():
            continue
        text = skill_md.read_text(encoding='utf-8')
        name = fm_field(text, 'name') or d.name
        desc = fm_field(text, 'description')
        items.append({
            'name': name,
            'dir': d.name,
            'path': '{}/{}'.format(path_prefix, d.name),
            'description': desc,
        })
    out = layer_root / 'index.json'
    payload = {
        'version': 1,
        'count': len(items),
        'items': sorted(items, key=lambda x: x['dir']),
    }
    out.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    return 0, (len(items), out)


def cmd_skills(share_root):
    """Build skills/share/index.json from SKILL.md front matter."""
    rc, result = _build_skill_layer_index(share_root, 'skills/share')
    if rc != 0:
        return rc
    count, out = result
    sys.stdout.write('SKILL_INDEX=ok items={} file={}\n'.format(count, out))
    return 0


def cmd_media_skills(media_root):
    """Build skills/media/index.json from SKILL.md front matter."""
    rc, result = _build_skill_layer_index(media_root, 'skills/media')
    if rc != 0:
        return rc
    count, out = result
    sys.stdout.write('MEDIA_SKILL_INDEX=ok items={} file={}\n'.format(count, out))
    return 0


def cmd_public_catalog(hub_root):
    """Check that public docs and filenames match skills/share/index.json."""
    hub_root = Path(hub_root).resolve()
    index_path = hub_root / 'skills' / 'share' / 'index.json'
    if not index_path.is_file():
        sys.stderr.write('ERROR: public catalog index not found: {}\n'.format(index_path))
        return 1

    try:
        payload = json.loads(index_path.read_text(encoding='utf-8'))
    except (OSError, ValueError) as exc:
        sys.stderr.write('ERROR: cannot read public catalog index: {}\n'.format(exc))
        return 1

    items = payload.get('items', [])
    count = payload.get('count')
    errors = []
    if count != len(items):
        errors.append('index count={} but items={}'.format(count, len(items)))
    if not isinstance(count, int):
        errors.append('index count is not an integer')
        count = len(items)

    source_mode = (hub_root / 'README.public.zh-CN.md').is_file()
    mode = 'source' if source_mode else 'public'
    zh_suffix = '.zh-CN.md' if source_mode else '.md'
    root_zh = 'README.public.zh-CN.md' if source_mode else 'README.md'
    root_en = 'README.public.en.md' if source_mode else 'README.en.md'

    expected_markers = {
        root_zh: (
            'Share 技能（{}）'.format(count),
            '**{} 技能介绍 + 整体用法**'.format(count),
        ),
        root_en: (
            'Share skills ({})'.format(count),
            '**{} skills + how to use the hub**'.format(count),
        ),
        'docs/getting-started/SKILLS_GUIDE{}'.format(zh_suffix): (
            '{} 个共享技能'.format(count),
            '## {} 个技能一览'.format(count),
        ),
        'docs/getting-started/SKILLS_GUIDE.en.md': (
            '**{} share skills**'.format(count),
            '## {} skills at a glance'.format(count),
        ),
        'docs/getting-started/VERIFY{}'.format(zh_suffix): (
            'SKILL_INDEX=ok items={}'.format(count),
        ),
        'docs/getting-started/VERIFY.en.md': (
            'SKILL_INDEX=ok items={}'.format(count),
        ),
        'docs/getting-started/SHARE_SKILL_SCORECARD{}'.format(zh_suffix): (
            '当前 **{}** 个 share 技能'.format(count),
            'SKILL_INDEX=ok items={}'.format(count),
            '{}/{}'.format(count, count),
        ),
        'docs/getting-started/SHARE_SKILL_SCORECARD.en.md': (
            'current **{}** share-skill'.format(count),
            'SKILL_INDEX=ok items={}'.format(count),
            '{}/{}'.format(count, count),
        ),
        'docs/getting-started/README.en.md': (
            '**{} skills and how to use the hub**'.format(count),
            'latest {}-skill bundle'.format(count),
        ),
    }

    texts = {}
    for rel, markers in expected_markers.items():
        path = hub_root / rel
        if not path.is_file():
            errors.append('missing {}'.format(rel))
            continue
        text = path.read_text(encoding='utf-8')
        texts[rel] = text
        for marker in markers:
            if marker not in text:
                errors.append('{} missing {!r}'.format(rel, marker))

    guide_paths = (
        'docs/getting-started/SKILLS_GUIDE{}'.format(zh_suffix),
        'docs/getting-started/SKILLS_GUIDE.en.md',
    )
    for rel in guide_paths:
        text = texts.get(rel, '')
        numbered_sections = re.findall(r'^###\s+\d+\.\s+`[^`]+`', text, re.M)
        if len(numbered_sections) != count:
            errors.append('{} sections={} expected={}'.format(rel, len(numbered_sections), count))
        for item in items:
            name = item.get('name') or item.get('dir')
            if name and '`{}`'.format(name) not in text:
                errors.append('{} missing skill {}'.format(rel, name))

    if not source_mode:
        required_public_names = ('README.en.md', 'scripts/README.en.md')
        stale_source_names = ('README.public.en.md', 'scripts/README.public.en.md')
        for rel in required_public_names:
            if not (hub_root / rel).is_file():
                errors.append('missing exported filename {}'.format(rel))
        for rel in stale_source_names:
            if (hub_root / rel).exists():
                errors.append('stale source filename exported {}'.format(rel))

    if errors:
        sys.stderr.write('PUBLIC_CATALOG=fail errors={} mode={}\n'.format(len(errors), mode))
        for error in errors:
            sys.stderr.write('  {}\n'.format(error))
        return 1

    sys.stdout.write('PUBLIC_CATALOG=ok items={} mode={}\n'.format(count, mode))
    return 0


def cmd_tech_insight(vault, allow_missing=False):
    vault = Path(vault)
    items = []
    missing = []  # canonical-dir files that lack canonical_id

    for dir_name in CANONICAL_DIRS:
        sub = vault / dir_name
        if not sub.is_dir():
            continue
        for p in sorted(sub.rglob('*.md')):
            if 'bak' in p.parts:
                continue
            if p.name in SKIP_NAMES:
                continue
            try:
                rel = p.relative_to(vault).as_posix()
            except ValueError:
                continue
            text = p.read_text(encoding='utf-8')
            cid = fm_field(text, 'canonical_id').strip()
            if not cid:
                missing.append(rel)
                continue  # skip — do not fabricate an id
            items.append({
                'canonical_id': cid,
                'path': rel,
                'title': fm_field(text, 'title'),
                'asset_type': fm_field(text, 'asset_type'),
                'domain': fm_field(text, 'domain'),
            })

    # Report missing canonical_id.
    if missing:
        level = 'WARN' if allow_missing else 'ERROR'
        sys.stderr.write(
            '{}: {} file(s) in canonical dirs lack canonical_id (skipped from index):\n'.format(
                level, len(missing),
            ),
        )
        for m in missing:
            sys.stderr.write('  MISSING_CANONICAL_ID: {}\n'.format(m))
        if not allow_missing:
            sys.stdout.write(
                'TECH_INSIGHT_INDEX=fail missing_canonical_id={0}'
                ' (re-run with --allow-missing to skip this check)\n'.format(len(missing)),
            )
            return 1

    # Duplicate canonical_id is always a hard error.
    seen = {}
    for it in items:
        cid = it['canonical_id']
        if cid in seen:
            sys.stderr.write(
                'ERROR: DUPLICATE canonical_id={0}\n  {1}\n  {2}\n'.format(
                    cid, seen[cid], it['path'],
                ),
            )
            return 1
        seen[cid] = it['path']

    out = vault / 'indexes' / 'assets.index.json'
    out.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        'version': 1,
        'items': items,
        'missing_canonical_id_count': len(missing),
    }
    out.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + '\n',
        encoding='utf-8',
    )
    sys.stdout.write(
        'TECH_INSIGHT_INDEX=ok items={0} missing_canonical_id={1} file={2}\n'.format(
            len(items), len(missing), out,
        ),
    )
    return 0


def main():
    ap = argparse.ArgumentParser(description='Build hub machine indexes (JSON).')
    sub = ap.add_subparsers(dest='cmd')

    p1 = sub.add_parser('prompts', help='Build prompts.index.json')
    p1.add_argument('root', type=str, help='Path to hub prompts/')

    p2 = sub.add_parser('tech-insight', help='Build assets.index.json')
    p2.add_argument('root', type=str, help='Path to TechInsightVault/')
    p2.add_argument(
        '--allow-missing', action='store_true',
        help='Exit 0 even when canonical files lack canonical_id (audit/migration mode).',
    )

    p3 = sub.add_parser('skills', help='Build skills/share/index.json')
    p3.add_argument('root', type=str, help='Path to hub skills/share/')

    p4 = sub.add_parser('media-skills', help='Build skills/media/index.json')
    p4.add_argument('root', type=str, help='Path to hub skills/media/')

    p5 = sub.add_parser('public-catalog', help='Check public docs against skills/share/index.json')
    p5.add_argument('root', type=str, help='Path to private source hub or public mirror')

    args = ap.parse_args()
    if not getattr(args, 'cmd', None):
        ap.print_help()
        return 2
    if args.cmd == 'prompts':
        return cmd_prompts(args.root)
    if args.cmd == 'tech-insight':
        return cmd_tech_insight(args.root, allow_missing=getattr(args, 'allow_missing', False))
    if args.cmd == 'skills':
        return cmd_skills(args.root)
    if args.cmd == 'media-skills':
        return cmd_media_skills(args.root)
    if args.cmd == 'public-catalog':
        return cmd_public_catalog(args.root)
    return 2


if __name__ == '__main__':
    sys.exit(main() or 0)
