"""Read-only inventory of project PNG originals/exports; writes the catalogue only."""
import json
from pathlib import Path
from PIL import Image
from assets import ROOT, digest, validate

items=[]
for top in ['assets', 'references']:
    if not (ROOT/top).exists():
        continue
    for path in sorted((ROOT/top).rglob('*.png')):
        with Image.open(path) as image:
            alpha = image.getchannel('A') if image.mode == 'RGBA' else None
            item = {'path':str(path.relative_to(ROOT)), 'sha256':digest(path),
                    'bytes':path.stat().st_size, 'dimensions':list(image.size),
                    'mode':image.mode, 'alpha_range':list(alpha.getextrema()) if alpha else None,
                    'approval':'placeholder' if 'placeholder' in str(path) else 'unapproved_reference'}
        if top=='references':
            report=validate(path, expected=13)
            report.pop('frame_bounds',None)
            item['validation']=report
            item['notes']='Visually 13 poses, not an exact 96px cell grid. Original unchanged; no animation mapping inferred.'
        else:
            item['validation']=validate(path,expected=2 if 'source' in path.parts else 1)
        items.append(item)
(ROOT/'docs/assets/catalogue.json').write_text(json.dumps({'originals_policy':'Never overwrite sources or supplied references', 'assets':items},indent=2)+'\n')
print(f'Catalogued {len(items)} PNG files without modifying them')
