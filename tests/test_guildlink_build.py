"""Package-level regression checks for the GuildLink build profile."""
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
import zipfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('guildlink_builder', ROOT / 'scripts/build-guildlink.py')
B = importlib.util.module_from_spec(spec)
spec.loader.exec_module(B)

class GuildLinkBuildTests(unittest.TestCase):
    def test_installable_archive_is_complete_and_reproducible(self):
        with tempfile.TemporaryDirectory() as tmp:
            a = B.build(Path(tmp) / 'a')
            b = B.build(Path(tmp) / 'b')
            archive = 'GuildLink-' + B.VERSION + '.zip'
            self.assertEqual((a / archive).read_bytes(), (b / archive).read_bytes())
            manifest = json.loads((a / 'manifest.json').read_text())
            with zipfile.ZipFile(a / archive) as z:
                self.assertEqual(set(z.namelist()), set(manifest['files']))
                for name in z.namelist():
                    self.assertEqual(hashlib.sha256(z.read(name)).hexdigest(), manifest['files'][name])
                for excluded in ('GuildLink/Markets.lua', 'GuildLink/MarketBank.lua', 'GuildLink_Arena/Games/Bicho.lua'):
                    self.assertNotIn(excluded, z.namelist())
                self.assertFalse(any('CompanionBridge/' in n for n in z.namelist()))
                for folder in ('GuildLink', 'GuildLink_Arena'):
                    toc = z.read(folder + '/' + folder + '.toc').decode()
                    self.assertNotIn('X-Curse-Project-ID', toc)
                    for line in toc.splitlines():
                        if line and not line.startswith('#'):
                            self.assertIn(folder + '/' + line.replace('\\', '/'), z.namelist())
                self.assertEqual(z.read('GuildLink/LICENSE.txt'), (ROOT / 'LICENSE').read_bytes())
                self.assertNotIn(b'OlympusDB', z.read('GuildLink/Core.lua'))
                self.assertNotIn(b'BNGetInfo', z.read('GuildLink/Accord.lua'))

    def test_settings_are_exact_user_data_even_with_upstream_name(self):
        with tempfile.TemporaryDirectory() as tmp:
            profile = Path(tmp) / 'profile'
            shutil.copytree(B.PROFILE, profile)
            settings = (profile / 'Settings.lua').read_text()
            settings = settings.replace('Alliance = {}, Horde = {}', 'Alliance = { "Olympus Friends" }, Horde = {}')
            (profile / 'Settings.lua').write_text(settings, encoding='utf-8')
            original = B.PROFILE
            try:
                B.PROFILE = profile
                output = B.build(Path(tmp) / 'output')
            finally:
                B.PROFILE = original
            self.assertEqual((output / 'GuildLink/Settings.lua').read_text(), settings)
            self.assertNotIn('GuildLink Friends', (output / 'GuildLink/Settings.lua').read_text())

    def test_existing_output_is_preserved(self):
        with tempfile.TemporaryDirectory() as tmp:
            marker = Path(tmp) / 'keep.txt'
            marker.write_text('user data')
            with self.assertRaisesRegex(ValueError, 'new output directory'):
                B.build(Path(tmp))
            self.assertEqual(marker.read_text(), 'user data')
            self.assertEqual(list(Path(tmp).iterdir()), [marker])

if __name__ == '__main__':
    unittest.main()
