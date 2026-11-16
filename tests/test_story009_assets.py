"""Native-pixel provenance checks; visual identity remains a rendered review."""
import hashlib
import json
import unittest
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]

class StoryArtwork(unittest.TestCase):
    def test_sources_and_layout(self):
        manifest=json.loads((ROOT/'docs/assets/milestone-009.json').read_text())
        self.assertFalse(manifest['resampled'])
        self.assertEqual([len(s['frames']) for s in manifest['sources']],[12,4])
        for source in manifest['sources']:
            path=ROOT/source['path']
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),source['sha256'])
            with Image.open(path) as image:
                self.assertEqual(list(image.size),source['dimensions'])
                self.assertEqual(image.mode,'RGBA')
                self.assertEqual(image.getchannel('A').getextrema(),(0,255))

    def test_native_pixels_and_padding(self):
        manifest=json.loads((ROOT/'docs/assets/milestone-009.json').read_text())
        for source in manifest['sources']:
            original=Image.open(ROOT/source['path']).convert('RGBA')
            for frame in source['frames']:
                derived=Image.open(ROOT/frame['path']).convert('RGBA')
                self.assertEqual(derived.size,(768,768))
                self.assertEqual(derived.getpixel((0,0))[3],0)
                dx,dy=frame['translation']; left,top,_,_=frame['rect']
                for y in range(derived.height):
                    for x in range(derived.width):
                        pixel=derived.getpixel((x,y))
                        if pixel[3]:
                            self.assertEqual(pixel,original.getpixel((left+x-dx,top+y-dy)))
                imported=(ROOT/(frame['path']+'.import')).read_text()
                self.assertIn('mipmaps/generate=false',imported)
