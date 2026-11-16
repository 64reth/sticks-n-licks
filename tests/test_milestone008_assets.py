import array
import hashlib
import json
from pathlib import Path
import unittest
import wave

ROOT=Path(__file__).resolve().parents[1]
class Milestone008Assets(unittest.TestCase):
    def test_provisional_sources_and_excerpts(self):
        manifest=json.loads((ROOT/'docs/assets/milestone-008-sfx.json').read_text())
        self.assertIn('UNVERIFIED',manifest['license'])
        self.assertEqual(len(manifest['assets']),8)
        archive=ROOT/manifest['archive']
        if archive.exists():
            self.assertEqual(hashlib.sha256(archive.read_bytes()).hexdigest(),manifest['archive_sha256'])
        for row in manifest['assets']:
            with self.subTest(event=row['event']):
                self.assertEqual(hashlib.sha256((ROOT/row['original']).read_bytes()).hexdigest(),row['original_sha256'])
                path=ROOT/row['resource']
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),row['sha256'])
                with wave.open(str(path)) as w:
                    self.assertEqual(w.getframerate(),row['sample_rate'])
                    self.assertEqual(w.getnchannels(),row['channels'])
                    self.assertEqual(w.getsampwidth(),2)
                    self.assertEqual(w.getnframes(),row['end_frame']-row['start_frame'])
                    pcm=array.array('h',w.readframes(w.getnframes()))
                    self.assertTrue(all(v==0 for v in pcm[-row['channels']:]))
                    self.assertGreaterEqual(min(pcm),-32768)
                    self.assertLessEqual(max(pcm),32767)
                    self.assertLessEqual(row['duration'],0.28)
                self.assertNotIn('/Music/',row['archive_path'])
                self.assertNotIn('/Cinematic/',row['archive_path'])

    def test_only_refined_scope_uses_pack(self):
        config=json.loads((ROOT/'data/sfx.json').read_text())
        enabled={key for key,row in config['events'].items() if row.get('resource')}
        self.assertEqual(enabled,{'swing','hit','block','parry','pickup','menu_navigate','menu_confirm','menu_back'})
        self.assertEqual(sum(config['voices'].values()),4)
        catalog=json.loads((ROOT/'data/audio.json').read_text())
        for event in enabled:
            resource=catalog[config['events'][event]['resource']]
            self.assertEqual(resource['category'],'sfx')
            self.assertIsNone(resource['beat_zero_seconds'])
            self.assertFalse(resource['alignment_confirmed'])
            self.assertTrue((ROOT/resource['path'].removeprefix('res://')).exists())

if __name__=='__main__':unittest.main()
