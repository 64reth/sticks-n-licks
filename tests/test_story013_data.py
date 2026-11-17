import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

class Story013DataTests(unittest.TestCase):
    def test_exhaustive_dialogue_classification(self):
        resource = json.loads((ROOT / 'data/story/dialogue.json').read_text())
        audit = json.loads((ROOT / 'docs/assets/milestone-013-dialogue-audit.json').read_text())
        expected = {(row['branch'], row['index']): row for row in audit['spoken_lines']}
        actual = {(branch, i): line for branch, lines in resource.items() for i, line in enumerate(lines)}
        self.assertEqual(set(actual), set(expected))
        for key, line in actual.items():
            self.assertEqual(line['type'], 'speech')
            self.assertEqual(line['text'], expected[key]['text'])
            self.assertEqual(line['speaker'], expected[key]['speaker'])
            self.assertEqual(expected[key]['classification'], 'spoken dialogue')
        self.assertEqual(resource['quest_complete'], [])

    def test_campaign_rewards_have_unique_configured_ids(self):
        campaign = json.loads((ROOT / 'data/story/campaign_013.json').read_text())
        self.assertTrue(campaign['provisional'])
        self.assertGreater(campaign['rent_target'], 0)
        ids = [entry['reward_id'] for entry in campaign['encounters'].values()]
        self.assertEqual(len(set(ids)), len(ids))
        for entry in campaign['encounters'].values():
            self.assertGreaterEqual(entry['reward'], 0)
            self.assertEqual(entry['best_of'], 3)

    def test_approved_bajan_text_unchanged(self):
        # Exact owner-approved strings; type metadata may be added without rewriting speech.
        import hashlib
        resource = json.loads((ROOT / 'data/story/dialogue.json').read_text())
        audit = json.loads((ROOT / 'docs/assets/milestone-013-dialogue-audit.json').read_text())
        approved = {key: [line['text'] for line in resource[key]] for key in ['opening', 'vendor']}
        self.assertEqual(hashlib.sha256(json.dumps(approved, sort_keys=True).encode()).hexdigest(),
                         audit['approved_bajan_sha256'])
