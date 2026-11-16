"""Reviewed Milestone 006 sheets. Non-destructive, no resampling; refuses existing output."""
import hashlib,json
from pathlib import Path
from collections import deque
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]

def clean_red_victory(im):
    # Remove border-connected neutral haze only. Closed outlines preserve interior whites.
    px=im.load(); w,h=im.size; seen=set(); todo=deque()
    def background(x,y):
        r,g,b,a=px[x,y]
        return a<128 or (max(r,g,b)-min(r,g,b)<=24 and max(r,g,b)>40)
    for x in range(w):todo.extend([(x,0),(x,h-1)])
    for y in range(h):todo.extend([(0,y),(w-1,y)])
    while todo:
        x,y=todo.popleft()
        if (x,y) in seen or not (0<=x<w and 0<=y<h) or not background(x,y):continue
        seen.add((x,y));r,g,b,a=px[x,y];px[x,y]=(r,g,b,0)
        todo.extend([(x-1,y),(x+1,y),(x,y-1),(x,y+1)])
    return len(seen)

def main():
 manifest={'version':1,'canvas':[768,768],'ground_pixel':744,'sheets':[]}
 for fighter in [1,2]:
  folder=ROOT/f'assets/characters/fighter_0{fighter}/frames/milestone_006'
  if folder.exists():raise SystemExit(f'Refusing overwrite: {folder}')
  folder.mkdir()
  config_path=ROOT/f'data/animations/fighter_0{fighter}.json';config=json.loads(config_path.read_text())
  for state,count in [('stunned',3),('hurt',2),('victory',4),('defeat',3)]:
   source=ROOT/f'assets/characters/fighter_0{fighter}/spritesheets/fighter_0{fighter}_{state}.png'
   original=Image.open(source).convert('RGBA'); w,h=original.size
   assert w%count==0
   records=[]; images=[]; removed=0
   for i in range(count):
    rect=(i*w//count,0,(i+1)*w//count,h)
    cell=original.crop(rect)
    if fighter==1 and state=='victory':removed+=clean_red_victory(cell)
    alpha=cell.getchannel("A").point(lambda a:0 if a<32 else a)
    cell.putalpha(alpha)
    bbox=cell.getbbox(); assert bbox
    images.append((rect,cell,bbox))
   reference_height=images[-1][2][3]-images[-1][2][1] if state=='stunned' else images[0][2][3]-images[0][2][1]
   scale=64/reference_height
   for i,(rect,cell,bbox) in enumerate(images):
    crop=cell.crop(bbox); assert crop.width<=768 and crop.height<=744
    x=(768-crop.width)//2;y=744-crop.height
    canvas=Image.new('RGBA',(768,768));canvas.paste(crop,(x,y))
    out=folder/f'{state}_{i:03}.png';canvas.save(out)
    records.append({'file':str(out.relative_to(ROOT)),'source_cell':rect,'source_foreground':bbox,'translation':[x-bbox[0],y-bbox[1]],'alpha_extrema':canvas.getchannel('A').getextrema(),'bbox':canvas.getbbox()})
   resource=folder/f'{state}.tres'
   text=[f'[gd_resource type="SpriteFrames" load_steps={count+1} format=3]']
   for i,frame in enumerate(records):text.append(f'[ext_resource type="Texture2D" path="res://{frame["file"]}" id="{i+1}"]')
   text.extend(['[resource]','animations = [{"frames":['+', '.join('{"duration":1.0,"texture":ExtResource("%d")}'%(i+1) for i in range(count))+f'],"loop":false,"name":&"{state}","speed":'+str({'stunned':9,'hurt':10,'victory':5,'defeat':6}[state])+'}]'])
   resource.write_text('\n'.join(text)+'\n')
   entry={'resource':str(resource.relative_to(ROOT)),'frames':count,'scale':scale,'native_facing':'right' if fighter==1 else 'left','ground_pixel':744,'canvas':[768,768],'source_category':state,'frame_indices':list(range(count))}
   config['animations'][state]=entry
   aliases={'hurt':['high_hit','mid_hit','low_hit'],'stunned':['stagger'],'defeat':['defeated']}.get(state,[])
   for alias in aliases:config['animations'][alias]={**entry,'source_animation':state}
   manifest['sheets'].append({'fighter':fighter,'state':state,'source':str(source.relative_to(ROOT)),'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'dimensions':[w,h],'frame_count':count,'cell_width':w//count,'scale':scale,'neutral_border_pixels_removed':removed,'frames':records})
  config_path.write_text(json.dumps(config,indent=2)+'\n')
 (ROOT/'docs/assets/milestone-006-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 catalogue_stages()
 print('Imported',len(manifest['sheets']),'sheets',sum(s['frame_count'] for s in manifest['sheets']),'frames')

def catalogue_stages():
 folder=ROOT/'assets/environments/backgrounds'
 sources={}
 for source in sorted(folder.iterdir()):
  if source.suffix or not source.is_file():continue
  try:
   im=Image.open(source)
   if im.format!='PNG':continue
  except Exception:continue
  destination=source.with_suffix('.png')
  if destination.exists() and destination.read_bytes()!=source.read_bytes():
   destination=folder/(source.name+'_original.png')
  if not destination.exists():destination.write_bytes(source.read_bytes())
  assert destination.read_bytes()==source.read_bytes()
  sources[destination]=source
 names={'01':'Village Street','02':'Beach Courtyard','03':'Crop Over Festival','04':'Fish Fry','05':'Fish Fry Copy','06':'Speightstown','07':'Animal Flower Cave','04_original':'Seafront Street'}
 catalog={'default':'stage_01','stages':[]};hashes={}
 for p in sorted(folder.glob('*.png')):
  im=Image.open(p)
  if im.format!='PNG':continue
  suffix=p.stem.removeprefix('background_');source=sources.get(p,p)
  digest=hashlib.sha256(p.read_bytes()).hexdigest()
  entry={'id':'stage_'+suffix,'name':names.get(suffix,'Stage '+suffix.replace('_',' ')),'path':str(p.relative_to(ROOT)),'source':str(source.relative_to(ROOT)),'sha256':digest,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'dimensions':list(im.size),'format':'PNG','mode':im.mode,'ground_y':150}
  if digest in hashes:entry['duplicate_of']=hashes[digest]
  hashes[digest]=entry['id'];catalog['stages'].append(entry)
 (ROOT/'data/stages.json').write_text(json.dumps(catalog,indent=2)+'\n')
if __name__=='__main__':main()
