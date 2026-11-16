import hashlib
import json
from pathlib import Path
import unittest
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
class Milestone007Assets(unittest.TestCase):
    def test_approved_originals(self):
        data=json.loads((ROOT/'docs/assets/milestone-007.json').read_text())
        for entry in data['assets']:
            with self.subTest(asset=entry['path']):
                path=ROOT/entry['path']
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),entry['sha256'])
                with Image.open(path) as image:
                    self.assertEqual(list(image.size),entry['size'])
                    self.assertEqual(image.mode,entry['mode'])
                    if image.mode=='RGBA':
                        self.assertEqual(list(image.getchannel('A').getextrema()),[0,255])
        self.assertEqual(data['audio']['duration_seconds'],8)

    def test_reviewed_sheet_regions(self):
        data=json.loads((ROOT/'docs/assets/milestone-007.json').read_text())
        self.assertEqual(len(data['logo_layout']['regions']),6)
        speaker=data['speaker']
        self.assertEqual(len(speaker['rects']),6)
        with Image.open(ROOT/speaker['texture'].removeprefix('res://')) as image:
            for r,a in zip(speaker['rects'],speaker['anchors']):
                x,y,w,h=r
                self.assertTrue(0<=x<x+w<=image.width and 0<=y<y+h<=image.height)
                self.assertTrue(x<=a[0]<=x+w and y<=a[1]<=y+h)
                alpha=image.getchannel('A').crop((x,y,x+w,y+h))
                self.assertIsNotNone(alpha.point(lambda v:255 if v>=128 else 0).getbbox())

if __name__=='__main__':unittest.main()
