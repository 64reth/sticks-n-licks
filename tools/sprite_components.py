from PIL import Image
from pathlib import Path

def components(image,threshold=64):
 a=image.getchannel('A');w,h=image.size
 small=a.resize(((w+3)//4,(h+3)//4),Image.Resampling.NEAREST).point(lambda x:255 if x>=threshold else 0)
 sw,sh=small.size;pixels=bytearray(small.tobytes());result=[]
 for i in range(len(pixels)):
  if not pixels[i]:continue
  pixels[i]=0;stack=[i];left=right=i%sw;top=bottom=i//sw;area=0
  while stack:
   n=stack.pop();x=n%sw;y=n//sw;area+=1
   left=min(left,x);right=max(right,x);top=min(top,y);bottom=max(bottom,y)
   for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
    if 0<=nx<sw and 0<=ny<sh:
     m=ny*sw+nx
     if pixels[m]:pixels[m]=0;stack.append(m)
  if area>=150:result.append((left*4,top*4,min(w,(right+1)*4),min(h,(bottom+1)*4),area*16))
 return sorted(result,key=lambda b:(b[1]//300,b[0]))
if __name__=='__main__':
 for p in sorted(Path('assets/characters').glob('*/spritesheets/*.png')):
  print(p.name,components(Image.open(p)))
