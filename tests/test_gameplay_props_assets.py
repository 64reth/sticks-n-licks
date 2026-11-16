"""Validate reviewed source sheets; never run the 96px character validator here."""
import hashlib
import json
from pathlib import Path
import unittest
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]

class GameplayPropsAssets(unittest.TestCase):
    def test_reviewed_originals_and_cells(self):
        manifest = json.loads((ROOT / 'docs/assets/gameplay-props.json').read_text())
        self.assertEqual(len(manifest['assets']), 4)
        for entry in manifest['assets']:
            path = ROOT / entry['path']
            with self.subTest(asset=path.name):
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), entry['sha256'])
                with Image.open(path) as image:
                    self.assertEqual(image.mode, 'RGBA')
                    self.assertEqual(image.size, (2172, 724))
                    for cell in entry['cells']:
                        x, y, w, h = cell['rect']
                        alpha = image.getchannel('A').crop((x, y, x+w, y+h))
                        self.assertEqual(list(alpha.getbbox()), cell['alpha_bounds'])
                        self.assertEqual(list(alpha.point(lambda v: 255 if v > 128 else 0).getbbox()), cell['alpha_above_128_bounds'])
                        self.assertGreater(alpha.histogram()[0], 0)
                settings = Path(str(path)+'.import').read_text()
                self.assertIn('mipmaps/generate=false', settings)
                self.assertIn('compress/mode=0', settings)

if __name__ == '__main__':
    unittest.main()
