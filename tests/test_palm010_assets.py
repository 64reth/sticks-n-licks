import hashlib
import unittest
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
class PalmAssets(unittest.TestCase):
    def test_original_source_and_grid(self):
        path=ROOT/'assets/environments/props/coconut_palm.png'
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),'41c4fed20fffbeb4547bc07bb40e9ba526ff7db047e5b943de7982f7b7aa78a9')
        with Image.open(path) as image:
            self.assertEqual(image.size,(1448,1086))
            self.assertEqual(image.mode,'RGBA')
            self.assertEqual(image.getchannel('A').getextrema(),(0,255))
            for i in range(8):
                alpha=image.crop((i%4*362,i//4*543,i%4*362+362,i//4*543+543)).getchannel('A')
                bounds=alpha.point(lambda x:255 if x>=64 else 0).getbbox()
                self.assertIsNotNone(bounds)
                self.assertGreater(bounds[0],0)
                self.assertGreater(bounds[1],0)
                self.assertLess(bounds[2],362)
                self.assertLess(bounds[3],543)
                self.assertGreater(alpha.histogram()[0],362*543//3)
    def test_original_import_is_unfiltered_without_mipmaps(self):
        text=(ROOT/'assets/environments/props/coconut_palm.png.import').read_text()
        self.assertIn('mipmaps/generate=false',text)
        self.assertIn('compress/mode=0',text)
