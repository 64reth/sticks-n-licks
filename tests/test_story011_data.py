import json
import unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
class StoryData(unittest.TestCase):
    def test_approved_dialogue_is_verbatim(self):
        lines=json.loads((ROOT/'data/story/dialogue.json').read_text())
        self.assertEqual([x['text'] for x in lines['opening']],[
            'Every month is de same foolishness! Where de rent money?',
            'Yuh gine find it outside!',
            'Wuhloss! I better find some money quick!'])
        self.assertEqual([x['text'] for x in lines['vendor']],[
            'Wuh happen to you, boy? Yuh look like yuh had a rough morning!',
            'Man, muh wife call me a wutless vagabond! Tell me carry muh backside and guh find de rent money outside!',
            'Cor blen! She really tell you all dat?',
            'And kick me clean through de door too!',
            'Well, standing up hey en gine pay no rent. Come help me move dis crate. I gine give yuh five dollars.',
            'Five dollars?! Man, I gine be sleeping outside till Christmas!',
            'Then yuh better start moving!'])
        self.assertTrue(all(not x['placeholder'] for key in ['opening','vendor'] for x in lines[key]))
        self.assertTrue(all(x['placeholder'] for key in ['delivery','fight_intro','fight_lost','quest_complete'] for x in lines[key]))
    def test_ordered_nested_delivery_has_explicit_unique_events(self):
        definition=json.loads((ROOT/'data/story/quests.json').read_text())
        self.assertEqual(definition['campaign'],'rent_due')
        self.assertEqual(definition['objective'],'Earn enough money to pay the rent.')
        quest=definition['quests'][0]
        self.assertEqual(quest['id'],'a_stick_to_share')
        self.assertEqual(quest['title'],'A Stick To Share Licks')
        delivery=quest['steps'][4]
        self.assertEqual([c['event'] for c in delivery['children']],['road_crossed','crate_delivered','delivery_paid'])
        entries=quest['steps']+delivery['children']
        self.assertEqual(len({s['id'] for s in entries}),12)
        self.assertTrue(all(s['event'] for s in entries))

    def test_currency_has_a_real_pixel_glyph(self):
        from PIL import Image
        with Image.open(ROOT/'assets/ui/arcade/arcade.png') as atlas:
            def glyph(char):
                index=ord(char)-32
                return atlas.crop((index%16*6,index//16*8,index%16*6+5,index//16*8+7)).tobytes()
            self.assertNotEqual(glyph('$'),glyph('?'))
            self.assertNotEqual(glyph('$'),glyph(' '))
