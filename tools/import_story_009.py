"""Non-destructive native-pixel extraction of the supplied eviction artwork."""
from pathlib import Path
from hashlib import sha256
import json
from PIL import Image, ImageFilter
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/story/009'

def extract():
    if OUT.exists(): raise SystemExit('Refusing to overwrite existing derivatives')
    OUT.mkdir(parents=True)
    manifest={'resampled':False,'alpha_policy':'Keep source RGBA within 4 native pixels of alpha >=128; discard isolated soft haze in derivatives only.','sources':[]}
    specs=[('assets/characters/fighter_01/spritesheets/fighter_kicked_sheet.png','fighter',[(i%4*362,i//4*362,(i%4+1)*362,(i//4+1)*362) for i in range(12)],[(175,327),(186,323),(186,323),(228,326),(191,321),(187,323),(178,323),(153,328),(165,325),(166,325),(180,325),(191,325)]),('assets/environments/props/house_wife_kick.png','house',[(0,310,410,690),(410,310,828,690),(828,310,1246,690),(1246,310,1664,690)],[(0,362),(7,362),(7,362),(7,362)])]
    for source,name,rects,anchors in specs:
        im=Image.open(ROOT/source).convert('RGBA'); rows=[]
        for i,(rect,anchor) in enumerate(zip(rects,anchors)):
            crop=im.crop(rect); alpha=crop.getchannel('A'); support=alpha.point(lambda x:255 if x>=128 else 0).filter(ImageFilter.MaxFilter(9)); alpha=Image.composite(alpha,Image.new('L',crop.size),support); crop.putalpha(alpha)
            canvas=Image.new('RGBA',(768,768)); dx,dy=384-anchor[0],744-anchor[1]; canvas.paste(crop,(dx,dy)); path=OUT/f'{name}_{i:02}.png'; canvas.save(path)
            rows.append({'frame':i,'rect':list(rect),'anchor':list(anchor),'translation':[dx,dy],'path':str(path.relative_to(ROOT))})
        manifest['sources'].append({'path':source,'sha256':sha256((ROOT/source).read_bytes()).hexdigest(),'dimensions':list(im.size),'alpha_extrema':im.getchannel('A').getextrema(),'frames':rows})
    dest=ROOT/'docs/assets/milestone-009.json'; dest.parent.mkdir(exist_ok=True,parents=True); dest.write_text(json.dumps(manifest,indent=2)+'\n')
if __name__=='__main__': extract()
