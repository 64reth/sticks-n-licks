import hashlib,json,unittest
from pathlib import Path
from PIL import Image, ImageChops
ROOT=Path(__file__).resolve().parents[1]
class ReactionAssets(unittest.TestCase):
 def test_all_sources_and_native_derivatives(self):
  manifest=json.loads((ROOT/'docs/assets/milestone-006-manifest.json').read_text())
  self.assertEqual(len(manifest['sheets']),8)
  self.assertEqual(sum(s['frame_count'] for s in manifest['sheets']),24)
  for sheet in manifest['sheets']:
   source=ROOT/sheet['source'];self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(),sheet['sha256'])
   original=Image.open(source).convert('RGBA')
   for frame in sheet['frames']:
    image=Image.open(ROOT/frame['file']);self.assertEqual(image.size,(768,768));self.assertEqual(image.mode,'RGBA')
    self.assertEqual(image.getchannel('A').getextrema()[0],0)
    self.assertEqual(image.getbbox()[3],744)
    cell=original.crop(frame['source_cell']);tx,ty=frame['translation']
    expected=Image.new('RGBA',(768,768))
    expected.paste(cell,(tx,ty))
    channels=ImageChops.difference(image,expected).split()
    difference=channels[0]
    for channel in channels[1:]:difference=ImageChops.lighter(difference,channel)
    retained=image.getchannel('A').point(lambda alpha:255 if alpha else 0)
    self.assertIsNone(ImageChops.multiply(difference,retained).getbbox())

 def test_red_victory_background_is_removed_only_in_derivatives(self):
  m=json.loads((ROOT/'docs/assets/milestone-006-manifest.json').read_text())
  sheet=next(s for s in m['sheets'] if s['fighter']==1 and s['state']=='victory')
  self.assertGreater(sheet['neutral_border_pixels_removed'],0)
  self.assertGreater(Image.open(ROOT/sheet['source']).getchannel('A').getextrema()[0],0)
  for f in sheet['frames']:self.assertEqual(Image.open(ROOT/f['file']).getpixel((0,0))[3],0)
