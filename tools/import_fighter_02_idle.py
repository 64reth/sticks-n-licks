"""Incrementally add only the supplied Blue idle, reusing reviewed native-frame extraction."""
import json
from pathlib import Path
from PIL import Image
from import_fighter_art import ROOT,CELL,BASELINE,extract,resource,sha

def run():
 source=ROOT/'assets/characters/fighter_02/spritesheets/fighter_02_idle.png'
 target=ROOT/'assets/characters/fighter_02/frames/idle_002'
 before=sha(source)
 target.mkdir(exist_ok=False)
 frames,scale=extract(source,target)
 if len(frames)!=4:
  raise ValueError('The visually inspected sheet has four poses; re-review any changed source')
 animations={}
 for state in ['idle','combat_idle']:
  out=target/(state+'.tres');resource(out,state,frames,fps=8,loop=True)
  animations[state]={'resource':str(out.relative_to(ROOT)),'frames':len(frames),'scale':scale,'native_facing':'left','ground_pixel':BASELINE,'canvas':[CELL,CELL],'source_category':'idle','frame_indices':list(range(len(frames))),'note':'Supplied Blue idle; source is byte-identical to existing mid-block artwork; no regenerated pixels'}
 config_path=ROOT/'data/animations/fighter_02.json'
 config=json.loads(config_path.read_text());config['animations'].update(animations)
 config_path.write_text(json.dumps(config,indent=2)+'\n')
 sheet={'path':str(source.relative_to(ROOT)),'sha256':before,'dimensions':list(Image.open(source).size),'frame_count':len(frames),'frames':frames,'scale':scale,'native_facing':'left','warnings':['Source duplicates fighter_02_mid_block.png byte-for-byte; accepted as owner-supplied idle. Original soft alpha preserved.']}
 manifest={'fighter':2,'sources':[sheet],'animations':animations,'validation':'passed native pixel, transparency and baseline checks; visual inspection required','originals_unchanged':True}
 (target/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 # Update the Blue section/current aggregate only. Never regenerate or rewrite Red art.
 summary_path=ROOT/'docs/assets/milestone-002-sprites.json'
 summary=json.loads(summary_path.read_text());blue=summary['fighters'][1]
 blue['sources'].append(sheet);blue['animations'].update(animations)
 blue['missing_authored_states']=[s for s in blue['missing_authored_states'] if s not in ['dedicated_idle','dedicated_combat_idle']]
 summary['source_sheets']+=1;summary['individual_frames']+=len(frames)
 summary_path.write_text(json.dumps(summary,indent=2)+'\n')
 assert sha(source)==before
 print('Imported Blue idle:',len(frames),'frames; display scale',scale,'baseline',BASELINE)
if __name__=='__main__':run()
