"""Inventory WAV metadata and candidate alignment; never infer confirmed downbeats."""
import hashlib,json,struct,wave
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def inventory():
 records=[]
 config=json.loads((ROOT/'data/audio.json').read_text())
 confirmed={v.get('path','').removeprefix('res://'):v for v in config.values() if v.get('alignment_confirmed')}
 for p in sorted((ROOT/'assets/audio/music').rglob('*.wav')):
  data=p.read_bytes();markers=[];offset=12
  while offset+8<=len(data):
   name=data[offset:offset+4];length=struct.unpack_from('<I',data,offset+4)[0];content=data[offset+8:offset+8+length]
   if name==b'LIST' and content[:4]==b'adtl':
    pos=4
    while pos+8<=len(content):
     size=struct.unpack_from('<I',content,pos+4)[0]
     if content[pos:pos+4]==b'labl':markers.append(content[pos+12:pos+8+size].rstrip(b'\0').decode(errors='replace'))
     pos+=8+size+(size%2)
   offset+=8+length+(length%2)
  with wave.open(str(p)) as w:
   rate=w.getframerate();channels=w.getnchannels();width=w.getsampwidth();count=w.getnframes();samples=w.readframes(count)
  bpm=int(p.parent.name.replace('bpm',''));duration=count/rate
  # First appreciable signal is a waveform observation, not a musical downbeat.
  first=None
  for frame in range(count):
   i=frame*channels*width
   value=int.from_bytes(samples[i:i+width],'little',signed=True)
   if abs(value)>2**(width*8-1)*0.005:first=frame/rate;break
  confirmation=confirmed.get(str(p.relative_to(ROOT)),{})
  records.append({'path':str(p.relative_to(ROOT)),'sha256':hashlib.sha256(data).hexdigest(),'format':'PCM WAV','duration_seconds':duration,'sample_rate_hz':rate,'channels':channels,'bits_per_sample':width*8,'frames':count,'bpm_from_folder':bpm,'metadata_labels':markers,'duration_in_beats':duration*bpm/60,'first_signal_above_minus46dB_seconds':first,'beat_zero_seconds':confirmation.get('beat_zero_seconds'),'loop_region':[confirmation['loop_start_seconds'],confirmation['loop_end_seconds']] if confirmation else None,'alignment_status':'owner_confirmed: beat 1 at sample zero; whole-file boundaries' if confirmation else 'manual_confirmation_required; duration does not establish musical downbeats'})
 (ROOT/'docs/assets/milestone-002-audio.json').write_text(json.dumps({'files':records},indent=2)+'\n')
 return records
if __name__=='__main__':
 for r in inventory():print(r['path'],r['duration_seconds'],r['metadata_labels'])
