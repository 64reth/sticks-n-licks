import base64
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch, MagicMock
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from PIL import Image
from assets import ROOT, validate, export, digest
from openai_images import plan, execute

class AssetTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(dir=ROOT / 'output')
        self.directory = Path(self.temp.name)
        self.source = self.directory / 'original.png'
        image = Image.new('RGBA', (192,96))
        for offset in [0,96]:
            for x in range(30+offset,60+offset):
                for y in range(20,80):
                    image.putpixel((x,y),(220,180,80,255))
        image.save(self.source)
        self.config = json.loads((ROOT/'tools/image_config.json').read_text())
    def tearDown(self):
        self.temp.cleanup()
    def test_rgba_and_boundaries(self):
        self.assertEqual(validate(self.source, expected=2)['status'], 'passed')
        self.assertEqual(validate(self.source, expected=3)['status'], 'failed')
        image = Image.open(self.source).convert('RGB')
        image.save(self.directory/'opaque.png')
        self.assertEqual(validate(self.directory/'opaque.png', expected=2)['status'], 'failed')
    def test_grid(self):
        self.assertEqual(validate(self.source, cell=(95,96), expected=2)['status'], 'failed')
    def test_edge_bleed(self):
        image=Image.open(self.source)
        image.putpixel((0,40),(255,255,255,255))
        image.save(self.source)
        self.assertEqual(validate(self.source, expected=2)['status'], 'failed')
    def test_partial_alpha(self):
        image=Image.open(self.source)
        image.putpixel((40,40),(255,255,255,100))
        image.save(self.source)
        self.assertEqual(validate(self.source, expected=2)['status'], 'failed')
    def test_lossless_slicing_no_overwrite(self):
        original=digest(self.source)
        out=self.directory/'frames'
        manifest=export(self.source,out,'idle',2)
        self.assertEqual(original,digest(self.source))
        self.assertEqual(len(manifest['generated_files']),2)
        with Image.open(out/'idle_000.png') as frame:
            self.assertEqual(frame.size,(96,96))
        self.assertEqual(Image.open(out/'idle_001.png').getpixel((30,20)),(220,180,80,255))
        self.assertIn('SpriteFrames',(out/'idle.tres').read_text())
        with self.assertRaises(FileExistsError):
            export(self.source,out,'idle',2)
    def test_reference_approval(self):
        with self.assertRaises(ValueError):
            plan('test',self.config,self.source)
        self.config['approved_references'][self.source.relative_to(ROOT).as_posix()]=digest(self.source)
        proposal=plan('test',self.config,self.source)
        self.assertEqual(proposal['reference']['sha256'],digest(self.source))
    def test_no_live_request_without_approval(self):
        proposal=plan('test',self.config)
        with patch('openai.OpenAI') as client:
            with self.assertRaises(ValueError):
                execute(proposal,self.config,'wrong-approval')
            client.assert_not_called()
    def test_limits(self):
        self.config['budget_usd']=0.001
        with self.assertRaises(ValueError):
            plan('test',self.config)
    def test_prompt_limit(self):
        with self.assertRaises(ValueError):
            plan('x'*3000,self.config)
    def test_adapter_mocked_sdk_and_lifetime_limits(self):
        proposal=plan('test',self.config)
        fake=MagicMock()
        fake.images.generate.return_value.data=[MagicMock(b64_json=base64.b64encode(self.source.read_bytes()).decode())]
        fake.images.generate.return_value.model_dump.return_value={"usage":{"input_tokens_details":{"text_tokens":10,"image_tokens":0},"output_tokens":1000}}
        with patch('openai_images.ROOT', self.directory), patch.dict('os.environ', {'OPENAI_API_KEY':'fake-test-only'}), patch('openai.OpenAI',return_value=fake):
            execute(proposal,self.config,proposal['approval_id'])
            ledger=json.loads((self.directory/'assets/generated/cost_ledger.json').read_text())
            self.assertEqual(ledger[0]['status'],'received_unvalidated')
            self.assertAlmostEqual(ledger[0]['estimated_cost_usd'],0.03205)
            outputs=list((self.directory/'assets/generated').glob('*/original.png'))
            self.assertEqual(len(outputs),1)
            self.assertEqual(outputs[0].read_bytes(), self.source.read_bytes())
            with self.assertRaises(ValueError):
                execute(proposal,self.config,proposal['approval_id'])
            fake.images.generate.assert_called_once()

    def test_reference_edit_mocked_sdk_preserves_source(self):
        fake=MagicMock()
        fake.images.edit.return_value.data=[MagicMock(b64_json=base64.b64encode(self.source.read_bytes()).decode())]
        fake.images.edit.return_value.model_dump.return_value={"usage":None}
        self.config['approved_references']={'original.png':digest(self.source)}
        before=digest(self.source)
        with patch('openai_images.ROOT', self.directory), patch.dict('os.environ', {'OPENAI_API_KEY':'fake-test-only'}), patch('openai.OpenAI',return_value=fake):
            proposal=plan('edit',self.config,self.source)
            execute(proposal,self.config,proposal['approval_id'])
            fake.images.edit.assert_called_once()
            self.assertEqual(fake.images.edit.call_args.kwargs['input_fidelity'],'high')
            self.assertEqual(digest(self.source),before)
            fake.images.generate.assert_not_called()

    def test_cost_and_transparency(self):
        proposal=plan('test',self.config)
        self.assertEqual(proposal['request']['background'],'transparent')
        self.assertEqual(proposal['request']['n'],1)
        self.assertEqual(proposal['output_estimate_usd'],0.034)

if __name__=='__main__':
    unittest.main()
