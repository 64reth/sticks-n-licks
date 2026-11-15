"""Read-only PNG inventory; distinguish supplied native art from strict 96px AI sheets."""
import json
from PIL import Image
from assets import ROOT,digest,validate
known={}
media=ROOT/'docs/assets/milestone-002-sprites.json'
if media.exists():
 for fighter in json.loads(media.read_text())['fighters']:
  for sheet in fighter['sources']:
   known[sheet['path']]={'status':'supplied_source_preserved','manifest':'docs/assets/milestone-002-sprites.json','frames':sheet['frame_count']}
   for frame in sheet['frames']:
    known[frame['path']]={'status':frame['validation'],'manifest':'docs/assets/milestone-002-sprites.json'}
items=[]
for top in ['assets','references']:
 if not (ROOT/top).exists():continue
 for path in sorted((ROOT/top).rglob('*.png')):
  relative=path.relative_to(ROOT).as_posix()
  with Image.open(path) as image:
   alpha=image.getchannel('A') if image.mode=='RGBA' else None
   item={'path':relative,'sha256':digest(path),'bytes':path.stat().st_size,'dimensions':list(image.size),'mode':image.mode,'alpha_range':list(alpha.getextrema()) if alpha else None}
  if relative in known:item['validation']=known[relative]
  elif 'placeholder' in relative:item['validation']=validate(path,expected=2 if 'source' in path.parts else 1)
  else:item['validation']={'status':'unreviewed'}
  items.append(item)
(ROOT/'docs/assets/catalogue.json').write_text(json.dumps({'originals_policy':'Never overwrite supplied originals. Derived native frames retain source RGBA with explicit alpha-haze removal and padding.','assets':items},indent=2)+'\n')
print('Catalogued',len(items),'PNGs')
