import hashlib
import json
import unittest
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

class StageAssetTests(unittest.TestCase):
    def test_catalogue_matches_original_pngs(self):
        config = json.loads((ROOT / 'data/stages.json').read_text())
        self.assertIn(config['default'], [item['id'] for item in config['stages']])
        for item in config['stages']:
            for field in ('source', 'path'):
                path = ROOT / item[field]
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), item['sha256'])
                with Image.open(path) as image:
                    self.assertEqual(image.format, 'PNG')
                    self.assertEqual(list(image.size), item['dimensions'])
                    self.assertEqual(image.mode, item['mode'])

    def test_extensionless_stage_two_preserved_exactly(self):
        folder = ROOT / 'assets/environments/backgrounds'
        self.assertEqual((folder / 'background_02').read_bytes(), (folder / 'background_02.png').read_bytes())
