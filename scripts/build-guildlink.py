"""Build the independent GuildLink addon, preserving upstream source for updates/tests.

python scripts/build-guildlink.py --output dist/guildlink
The output directory must not already exist; no user files are deleted or overwritten.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
PROFILE = ROOT / 'profiles' / 'guildlink'
VERSION = '0.1.0-alpha1'
TEXT = {'.lua', '.toc', '.xml', '.txt', '.md'}

def rename(text):
    for old, new in [('Olympus', 'GuildLink'), ('OLYMPUS', 'GUILDLINK'), ('olympus', 'guildlink')]:
        text = text.replace(old, new)
    # Both executable slash aliases and displayed instructions; token boundaries avoid /old etc.
    text = re.sub(r'/oly(?=[^a-zA-Z]|$)', '/gl', text)
    for old, new in [('olc', 'glc'), ('oll', 'gll'), ('ola', 'gla'), ('ol', 'gchat')]:
        text = re.sub(r'/' + old + r'(?=[^a-zA-Z]|$)', '/' + new, text)
    text = text.replace('https://github.com/dnl-gentile/guildlink-addon', 'https://github.com/bitspirit3/olympus-addon')
    return text

def once(text, old, new):
    if text.count(old) != 1:
        raise ValueError('Upstream changed: expected exactly one patch anchor: ' + old[:100])
    return text.replace(old, new, 1)

def transform(path, text, excluded):
    if path.name == 'Core.lua':
        text = once(text, '\t\tcmd = (cmd or ""):lower()\n', '\t\tcmd = (cmd or ""):lower()\n\t\tif cmd == "setup" then ns.Print(ns.Federation.Status()); return end\n')
        text = once(text, 'ns.VERSION = "1.3.2"', 'ns.VERSION = "' + VERSION + '"')
    if path.name == 'Who.lua':
        text = once(text, 'function Who.Search(quiet, guild, name)\n', 'function Who.Search(quiet, guild, name)\n\tif #ns.Federation.Guilds() == 0 then return false end\n')
    if path.name == 'Comm.lua':
        text = once(text, '(horde and "OlyH" or "Oly") .. Hash36(key)', '(horde and ns.CHANNEL_HORDE or ns.CHANNEL) .. Hash36(key)')
    if path.name == 'Sign.lua':
        begin = text.index('function Sign.Verify(text, sigHex)\n')
        end = text.index('\nend', begin) + len('\nend')
        text = text[:begin] + 'function Sign.Verify(text, sigHex)\n\t-- GuildLink does not accept upstream signed administrator lists.\n\treturn false\nend' + text[end:]
    if path.name == 'Link.lua':
        for field, value in [('LINK_BACKEND_KEYS', '{}'), ('LINK_CA_KEYS', '{}'), ('LINK_SITE', '""')]:
            text, count = re.subn(r'^ns\.' + field + r' = .*$', 'ns.' + field + ' = ' + value, text, flags=re.M)
            if count != 1: raise ValueError('Missing link configuration: ' + field)
        text = once(text, 'function Link.Slash(rest)\n', 'function Link.Slash(rest)\n\tdo ns.Print("Discord linking is not included in GuildLink."); return end\n')
    if path.suffix == '.toc':
        lines = []
        for line in text.splitlines():
            entry = line.strip().replace('\\', '/')
            if str(path.parent / entry).replace('\\', '/') in excluded: continue
            if line.startswith(('## X-Curse-Project-ID:', '## X-Wago-ID:')): continue
            if line.startswith('## Version:'): line = '## Version: ' + VERSION
            lines.append(line)
            if line == 'Core.lua': lines.extend(['Settings.lua', 'Federation.lua'])
            if line == 'Who.lua': lines.append('FederationSearch.lua')
        if path.parent.name == 'Olympus': lines.append('FederationFinish.lua')
        text = '\n'.join(lines) + '\n'
    return rename(text)

def build(output):
    output = Path(output).resolve()
    if output.exists(): raise ValueError('Choose a new output directory: ' + str(output))
    excluded = {line.strip() for line in (ROOT / 'scripts/bets-only.txt').read_text().splitlines() if line.strip() and not line.startswith('#')}
    files = {}
    for folder in ('Olympus', 'Olympus_Arena'):
        tracked = subprocess.check_output(['git', 'ls-files', '-z', '--', folder], cwd=ROOT).decode().split('\0')
        for name in filter(None, tracked):
            if name in excluded: continue
            path = ROOT / name
            if path.suffix.lower() in TEXT:
                data = transform(Path(name), path.read_text(encoding='utf-8-sig'), excluded).encode()
            else: data = path.read_bytes()
            files[rename(name)] = data
    for src, dest in [('Settings.lua', 'Settings.lua'), ('Federation.lua', 'Federation.lua'), ('Search.lua', 'FederationSearch.lua'), ('Finish.lua', 'FederationFinish.lua'), ('Privacy.lua', 'Accord.lua')]:
        profile_text = (PROFILE / src).read_text(encoding='utf-8-sig')
        # Settings are user data: a guild name containing Olympus must remain exact.
        files['GuildLink/' + dest] = (profile_text if src == 'Settings.lua' else rename(profile_text)).encode()
    files['GuildLink/LICENSE.txt'] = (ROOT / 'LICENSE').read_bytes()
    files['GuildLink/README.txt'] = (PROFILE / 'README.md').read_bytes()
    for folder in ('GuildLink', 'GuildLink_Arena'):
        toc = files[folder + '/' + folder + '.toc'].decode()
        for line in toc.splitlines():
            line = line.strip()
            if line and not line.startswith('#'):
                if folder + '/' + line.replace('\\', '/') not in files:
                    raise ValueError('Missing packaged TOC entry: ' + folder + '/' + line)
    commit = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    hashes = {p: hashlib.sha256(data).hexdigest() for p, data in sorted(files.items())}
    manifest = {'version': VERSION, 'source_commit': commit, 'files': hashes,
                'note': 'Profile source and tests are versioned in profiles/guildlink and scripts/build-guildlink.py.'}
    output.mkdir(parents=True)
    for name, data in files.items():
        target = output / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    archive = output / ('GuildLink-' + VERSION + '.zip')
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as z:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, data)
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    (output / (archive.name + '.sha256')).write_text(hashlib.sha256(archive.read_bytes()).hexdigest() + '  ' + archive.name + '\n')
    print(archive)
    return output

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/guildlink')
    build(parser.parse_args().output)
