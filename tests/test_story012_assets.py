from pathlib import Path
import hashlib,json,unittest
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
class RevisionArt(unittest.TestCase):
    def test_every_frame_audited_originals_preserved(self):
        manifest=json.loads((ROOT/'docs/assets/milestone-012-animation-audit.json').read_text())
        self.assertEqual([len(x['frames']) for x in manifest['sources']],[13,12])
        for source in manifest['sources']:
            path=ROOT/source['path']
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),source['sha256'])
            with Image.open(path) as im:
                self.assertEqual(list(im.size),source['dimensions'])
                self.assertEqual(im.mode,'RGBA')
                self.assertEqual(im.getchannel('A').getextrema(),(0,255))
            for entry in source['frames']:
                self.assertTrue(entry['role'])
                with Image.open(ROOT/entry['path']) as frame:
                    self.assertEqual(frame.size,(768,768))
                    self.assertEqual(frame.getchannel('A').point(lambda v:255 if v>=128 else 0).getbbox(),tuple(entry['native_alpha128_bounds']))
    def test_selected_sources_have_planted_native_baseline(self):
        manifest=json.loads((ROOT/'docs/assets/milestone-012-animation-audit.json').read_text())
        self.assertFalse(manifest['source_art_modified'])
        self.assertFalse(manifest['new_fighter_images_generated'])
        self.assertEqual(manifest['selection']['duck']['frame'],0)
        self.assertEqual(manifest['selection']['idle']['frame'],1)
        self.assertEqual(manifest['selection']['unarmed_reaction']['frames'],[1,8,11])
        for source in manifest['sources']:
            for frame in source['frames']:
                self.assertLessEqual(frame['native_alpha128_bounds'][3],748)
