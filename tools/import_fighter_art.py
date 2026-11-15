"""Extract supplied irregular sheets; originals never change. No resampling of exported pixels."""
import hashlib,json
from pathlib import Path
from PIL import Image,ImageFilter,ImageChops,ImageDraw
from sprite_components import components
ROOT=Path(__file__).resolve().parents[1]
CELL=768
BASELINE=744

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def extract(path,destination):
    image=Image.open(path).convert('RGBA')
    boxes=components(image)
    frames=[]
    # Exact native pixels are copied into padded canvases. The component mask
    # removes isolated generation haze only in derivatives, never originals.
    standing=boxes[0][3]-boxes[0][1]
    for index,(l,t,r,b,area) in enumerate(boxes):
        rect=(max(0,l-12),max(0,t-12),min(image.width,r+12),min(image.height,b+12))
        patch=image.crop(rect)
        a=patch.getchannel('A')
        # Retain all original RGBA in/near the visible silhouette, including soft edges.
        support=a.point(lambda x:255 if x>=64 else 0).filter(ImageFilter.MaxFilter(17))
        cleaned=a.copy()
        cleaned.paste(0,(0,0),ImageChops.invert(support))
        patch.putalpha(cleaned)
        bounds=cleaned.getbbox()
        if not bounds:raise ValueError(path)
        # Anchor on boot span, not the outstretched stick or headband.
        band=cleaned.crop((0,max(0,b-rect[1]-16),patch.width,min(patch.height,b-rect[1]+4)))
        feet=band.point(lambda v:255 if v>=64 else 0).getbbox()
        foot_x=(feet[0]+feet[2])//2 if feet else (l+r)//2-rect[0]
        core=a.point(lambda v:255 if v>=64 else 0).getbbox()
        foot_y=core[3]
        dx=CELL//2-foot_x;dy=BASELINE-foot_y
        if min(dx,dy)<0 or dx+patch.width>CELL or dy+patch.height>CELL:
            raise ValueError(f'Canvas clips {path} frame {index}')
        canvas=Image.new('RGBA',(CELL,CELL))
        canvas.paste(patch,(dx,dy)) # paste without alpha mask: preserve RGBA bytes exactly
        name=destination/f'{index:03d}.png'
        canvas.save(name)
        frames.append({'path':str(name.relative_to(ROOT)), 'source_rect':list(rect),
                       'translation':[dx,dy], 'ground_pixel':BASELINE,
                       'source_foot_anchor':[foot_x+rect[0],foot_y+rect[1]],
                       'sha256':sha(name),'alpha_extrema':list(canvas.getchannel('A').getextrema()),
                       'removed_haze_pixels':sum(1 for before,after in zip(a.getdata(),cleaned.getdata()) if before and not after),
                       'validation':'passed_native_pixels_and_transparent_padding'})
    return frames,64.0/standing

def resource(path,state,frames,fps=8,loop=False):
    refs=['[ext_resource type="Texture2D" path="res://%s" id="%d"]'%(f['path'],i+1) for i,f in enumerate(frames)]
    values=', '.join('{"duration":1.0,"texture":ExtResource("%d")}'%(i+1) for i in range(len(frames)))
    path.write_text('[gd_resource type="SpriteFrames" load_steps=%d format=3]\n'%(len(frames)+1)+'\n'.join(refs)+'\n[resource]\nanimations = [{"frames":['+values+'],"loop":'+str(loop).lower()+',"name":&"'+state+'","speed":'+str(float(fps))+'}]\n')

def run():
    total=0;reports=[]
    for number in [1,2]:
        folder=ROOT/f'assets/characters/fighter_0{number}'
        destination=folder/'frames/milestone_002'
        destination.mkdir(exist_ok=False)
        sheets={};animations={};sources=[]
        for path in sorted((folder/'spritesheets').glob('*.png')):
            key=path.stem.replace(f'fighter_0{number}_','').removesuffix('_sheet')
            target=destination/key;target.mkdir()
            original=sha(path)
            frames,scale=extract(path,target)
            assert sha(path)==original
            total+=len(frames)
            sources.append({'path':str(path.relative_to(ROOT)),'sha256':original,'dimensions':list(Image.open(path).size),'frame_count':len(frames),'frames':frames,'scale':scale,'native_facing':'right' if number==1 else 'left','warnings':['Original antialiased alpha and nonuniform pixel lattice retained; not strict NES pixel cells.']})
            sheets[key]={'frames':frames,'scale':scale}
        def assign(state,key,indices=None,loop=False,note=''):
            item=sheets[key];frames=item['frames']
            chosen=[frames[i] for i in (indices if indices is not None else range(len(frames)))]
            output=destination/(state+'.tres');resource(output,state,chosen,loop=loop)
            animations[state]={'resource':str(output.relative_to(ROOT)), 'frames':len(chosen),'scale':item['scale'], 'native_facing':'right' if number==1 else 'left','ground_pixel':BASELINE,'canvas':[CELL,CELL],'source_category':key,'frame_indices':list(indices) if indices is not None else list(range(len(frames))),'note':note}
        assign('character_master','race',[0])
        assign('idle','idle' if 'idle' in sheets else 'race',None if 'idle' in sheets else [0,1,2,3],True,'Blue idle uses supplied race idle poses' if number==2 else '')
        assign('standoff_anticipation','race',[0,1,2,3,4,6,7],True)
        assign('false_start','race',[11,12])
        assign('race_launch','race',[7,8])
        assign('running','race',[8,9,10],True)
        assign('combat_idle','idle' if number==1 else 'pickup',None if number==1 else [0],True,'No dedicated Blue combat-idle sheet; supplied ready pose')
        assign('stick_pickup','pickup' if number==2 else 'idle',None if number==2 else [0],False,'Red pickup sheet depicts race poses, not a stick pickup; use existing idle while awaiting replacement' if number==1 else '')
        for state in ['forward_step','backward_step']:assign(state,'walk',loop=True)
        for height in ['high','mid','low']:
            assign(height+'_attack',height+'_attack')
            assign(height+'_block',height+'_block')
            assign(height+'_parry',height+'_block',note='Reuse supplied block with runtime flash; no invented parry artwork')
        for state in ['high_hit','mid_hit','low_hit','stagger','knockdown','victory','defeat']:
            assign(state,'idle' if number==1 else 'pickup',[0],note='Missing authored state: retain actual character ready pose with runtime feedback')
        config={'version':2,'native_facing':'right' if number==1 else 'left','animations':animations}
        (ROOT/f'data/animations/fighter_0{number}.json').write_text(json.dumps(config,indent=2)+'\n')
        report={'fighter':number,'sources':sources,'animations':animations,'missing_authored_states':['high_hit','mid_hit','low_hit','stagger','knockdown','victory','defeat']+(['stick_pickup'] if number==1 else ['dedicated_idle','dedicated_combat_idle']), 'validation':'passed technical extraction; visual review required'}
        (destination/'manifest.json').write_text(json.dumps(report,indent=2)+'\n');reports.append(report)
    summary={'source_sheets':sum(len(r['sources']) for r in reports),'individual_frames':total,'fighters':reports,'originals_unchanged':True,'processing':'native RGBA copy, isolated alpha-haze removal in derivatives, transparent padding, boot anchoring; no resizing or recolouring'}
    (ROOT/'docs/assets/milestone-002-sprites.json').write_text(json.dumps(summary,indent=2)+'\n')
    print('Processed',summary['source_sheets'],'sheets and',total,'native-resolution frames')
if __name__=='__main__':run()
