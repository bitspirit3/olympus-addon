"""Test the actual packaged GuildLink TOC using upstream's strict Forever client model.

python scripts/test-guildlink.py dist/guildlink [--python-runner /path/to/lua_runner.py]
Only the test model's namespace is translated; production files are not edited.
"""
import argparse
import importlib.util
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location('builder', ROOT / 'scripts/build-guildlink.py')
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('package', type=Path)
parser.add_argument('--python-runner', type=Path)
args = parser.parse_args()
package = args.package.resolve()
assert (package / 'GuildLink/GuildLink.toc').is_file(), 'Build the package first'
for name in ('tests/gamepad.lua', 'tests/fixtures/forever-api.lua', 'scripts/gamepad-audit.lua', 'scripts/gamepad-baseline.txt'):
    text = builder.rename((ROOT / name).read_text(encoding='utf-8-sig'))
    if name == 'tests/gamepad.lua':
        # A test configuration replaces the Settings.lua data, never membership/authority functions.
        text = builder.once(text, 'local ok, err = pcall(chunk, "GuildLink", ns)',
            'local ok, err = pcall(chunk, "GuildLink", ns)\n\t\tif file == "Settings.lua" and opts.federation then ns.FederationConfig = opts.federation end')
    target = package / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding='utf-8')
(package / 'tests/guildlink.lua').write_bytes((ROOT / 'tests/guildlink.lua').read_bytes())
command = [sys.executable, str(args.python_runner.resolve())] if args.python_runner else ['luajit']
subprocess.run(command + ['tests/guildlink.lua'], cwd=package, check=True)
