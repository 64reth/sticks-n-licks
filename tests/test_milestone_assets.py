import hashlib,json,sys,unittest,wave
from pathlib import Path
from PIL import Image,ImageChops
ROOT=Path(__file__).resolve().parents[1]

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
class MilestoneAssetTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.sprites=json.loads((ROOT/'docs/assets/milestone-002-sprites.json').read_text())
  cls.audio=json.loads((ROOT/'docs/assets/milestone-002-audio.json').read_text())
 def test_all_supplied_sheets_preserved(self):
  self.assertEqual(self.sprites['source_sheets'],20)
  self.assertEqual(self.sprites['individual_frames'],117)
  for fighter in self.sprites['fighters']:
   for sheet in fighter['sources']:
    self.assertEqual(sha(ROOT/sheet['path']),sheet['sha256'])
    self.assertEqual(len(sheet['frames']),sheet['frame_count'])
 def test_rgba_transparent_padding_and_ground_baseline(self):
  for fighter in self.sprites['fighters']:
   for sheet in fighter['sources']:
    for frame in sheet['frames']:
     with Image.open(ROOT/frame['path']) as image:
      self.assertEqual(image.format,'PNG')
      self.assertEqual(image.mode,'RGBA')
      self.assertEqual(image.size,(768,768))
      alpha=image.getchannel('A')
      self.assertEqual(alpha.getextrema()[0],0)
      self.assertGreaterEqual(alpha.getextrema()[1],240)
      bounds=alpha.getbbox()
      self.assertGreater(bounds[0],0)
      self.assertLess(bounds[2],768)
      self.assertLess(bounds[3],768)
      # The visible opaque-enough boot baseline is exact; soft edge retained below it.
      core=alpha.point(lambda a:255 if a>=64 else 0).getbbox()
      self.assertEqual(core[3],744)
      self.assertEqual(sha(ROOT/frame['path']),frame['sha256'])
 def test_retained_pixels_match_source_without_resampling_or_recolour(self):
  for fighter in self.sprites['fighters']:
   for sheet in fighter['sources']:
    with Image.open(ROOT/sheet['path']) as source:
     for frame in sheet['frames']:
      rect=frame['source_rect'];dx,dy=frame['translation']
      original=source.crop(rect)
      with Image.open(ROOT/frame['path']) as output:
       retained=output.crop((dx,dy,dx+original.width,dy+original.height))
       difference=ImageChops.difference(original,retained)
       mask=retained.getchannel('A').point(lambda a:255 if a else 0)
       for channel in difference.split():
        self.assertIsNone(ImageChops.multiply(channel,mask).getbbox())
 def test_expected_animation_resources_and_matching_counts(self):
  configs=[]
  for i in [1,2]:
   config=json.loads((ROOT/f'data/animations/fighter_0{i}.json').read_text());configs.append(config)
   self.assertEqual(config['native_facing'],'right' if i==1 else 'left')
   for state,entry in config['animations'].items():
    text=(ROOT/entry['resource']).read_text()
    self.assertIn(f'&"{entry.get("source_animation", state)}"',text)
    self.assertEqual(text.count('[ext_resource'),entry['frames'])
  for state in ['high_attack','mid_attack','low_attack','high_block','mid_block','low_block','forward_step','running']:
   self.assertEqual(configs[0]['animations'][state]['frames'],configs[1]['animations'][state]['frames'])
 def test_audio_metadata_and_original_hashes(self):
  self.assertEqual(len(self.audio['files']),8)
  for item in self.audio['files']:
   path=ROOT/item['path'];self.assertEqual(sha(path),item['sha256'])
   with wave.open(str(path)) as audio:
    self.assertEqual(audio.getframerate(),44100)
    self.assertEqual(audio.getnchannels(),2)
    self.assertEqual(audio.getsampwidth(),3)
    self.assertAlmostEqual(audio.getnframes()/audio.getframerate(),item['duration_seconds'])
   self.assertTrue(item['metadata_labels'][0].startswith('Tempo: '))
 def test_no_invented_downbeats_or_missing_references(self):
  config=json.loads((ROOT/'data/audio.json').read_text())
  for key,entry in config.items():
   if entry['path']:
    self.assertTrue((ROOT/entry['path'].removeprefix('res://')).exists())
    if not entry['alignment_confirmed']:
     self.assertIsNone(entry['beat_zero_seconds'])
  for name,bpm in [('120',120),('140',140),('160',160)]:
   self.assertEqual(config[name]['bpm'],bpm)
 def test_supplied_blue_idle(self):
  folder=ROOT/'assets/characters/fighter_02'
  source=folder/'spritesheets/fighter_02_idle.png'
  self.assertEqual(sha(source),sha(folder/'spritesheets/fighter_02_mid_block.png'))
  manifest=json.loads((folder/'frames/idle_002/manifest.json').read_text())
  self.assertEqual(manifest['sources'][0]['dimensions'],[2172,724])
  self.assertEqual(manifest['sources'][0]['frame_count'],4)
  config=json.loads((ROOT/'data/animations/fighter_02.json').read_text())
  for state in ['idle','combat_idle']:
   entry=config['animations'][state]
   self.assertEqual(entry['frame_indices'],[0,1,2,3])
   self.assertEqual(entry['native_facing'],'left')
   self.assertEqual(entry['ground_pixel'],744)
   text=(ROOT/entry['resource']).read_text()
   self.assertIn('"loop":true',text)
   self.assertIn('"speed":8.0',text)
 def test_missing_artwork_explicit(self):
  red,blue=self.sprites['fighters']
  self.assertIn('stick_pickup',red['missing_authored_states'])
  self.assertNotIn('dedicated_idle',blue['missing_authored_states'])
  self.assertEqual(blue['animations']['idle']['source_category'],'idle')
  self.assertEqual(blue['animations']['combat_idle']['source_category'],'idle')
  self.assertIn('victory',red['missing_authored_states'])
if __name__=='__main__':unittest.main()
