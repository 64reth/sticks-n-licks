"""Reviewed, non-destructive Milestone 008 excerpt import; no external services.

The source ZIP is preserved. Selected originals remain byte-identical under source/;
short PCM derivatives get explicit rectangles-in-time and fade metadata. Licensing
is unresolved: these are provisional development assets, not cleared for release.
"""
from pathlib import Path
from zipfile import ZipFile
import array
import hashlib
import io
import json
import wave

ROOT=Path(__file__).resolve().parents[1]
ARCHIVE=ROOT/'assets/audio/sfx/FreeSFX.zip'
CHOICES={
 'swing':('Swoosh/Retro Swooosh 02.wav',0.220),
 'hit':('Impact/Retro Impact Punch 07.wav',0.280),
 'block':('Impact/Retro Impact Punch Hurt 01.wav',0.220),
 'parry':('Impact/Retro Impact Metal 36.wav',0.240),
 'pickup':('PickUp/Retro PickUp Coin 04.wav',0.200),
 'menu_navigate':('Alarms Blip Beeps/Retro Beeep 06.wav',0.080),
 'menu_confirm':('Alarms Blip Beeps/Retro Beeep 20.wav',0.097),
 'menu_back':('Events/Wrong/Retro Event Wrong Simple 03.wav',0.180),
}
def main():
 target=ROOT/'assets/audio/sfx/freesfx_008'
 originals=ROOT/'source/audio/freesfx_008'
 if target.exists() or originals.exists():raise SystemExit('Refusing existing output directory')
 target.mkdir(parents=True);originals.mkdir(parents=True)
 (originals/'.gdignore').touch()
 manifest={'archive':'assets/audio/sfx/FreeSFX.zip','archive_sha256':hashlib.sha256(ARCHIVE.read_bytes()).hexdigest(),'license':'UNVERIFIED: no licence/terms/readme found in supplied archive; commercial redistribution not established. Provisional development only.','selection_basis':'Short measured onset/excerpts; audition playlist supplied. Perceptual review required. No FreeSFX music/cinematic/ambience/countdown/result melodies used.','assets':[],'inventory':[]}
 with ZipFile(ARCHIVE) as z:
  for n in z.namelist():
   if not n.lower().endswith('.wav'):continue
   if not any('/'+s+'/' in n for s in ['Impact','Swoosh','PickUp','Events','Alarms Blip Beeps','Music/Success','Cinematic']):continue
   with wave.open(io.BytesIO(z.read(n))) as w:
    manifest['inventory'].append({'archive_path':n,'seconds':w.getnframes()/w.getframerate(),'rate':w.getframerate(),'channels':w.getnchannels()})
  for event,(name,cap) in CHOICES.items():
   member='FreeSFX/GameSFX/'+name
   data=z.read(member)
   original=originals/Path(name).name;original.write_bytes(data)
   with wave.open(io.BytesIO(data)) as w:
    channels=w.getnchannels();rate=w.getframerate();width=w.getsampwidth();count=w.getnframes();pcm=w.readframes(count)
   assert width==2
   values=array.array('h',pcm);peak=max(abs(v) for v in values)
   first=next((i//channels for i,v in enumerate(values) if abs(v)>max(64,peak*0.01)),0)
   start=max(0,first-int(rate*0.001))
   end=min(count,start+round(cap*rate))
   samples=array.array('h',values[start*channels:end*channels])
   fade=min(round(rate*0.012),(end-start)//4)
   for f in range(end-start):
    gain=min(1,(end-start-1-f)/max(1,fade))
    # Preserve the attack; only the selected tail fades to zero to avoid a cut click.
    if gain<1:
     for c in range(channels):samples[f*channels+c]=round(samples[f*channels+c]*gain)
   output=target/(event+'.wav')
   with wave.open(str(output),'wb') as w:
    w.setnchannels(channels);w.setsampwidth(width);w.setframerate(rate);w.writeframes(samples.tobytes())
   manifest['assets'].append({'event':event,'archive_path':member,'original':str(original.relative_to(ROOT)),'original_sha256':hashlib.sha256(data).hexdigest(),'resource':str(output.relative_to(ROOT)),'sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'sample_rate':rate,'channels':channels,'source_frames':count,'source_duration':count/rate,'start_frame':start,'end_frame':end,'fade_out_frames':fade,'duration':(end-start)/rate,'source_peak':peak/32768})
 (ROOT/'docs/assets/milestone-008-sfx.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print('Imported eight provisional excerpts; originals and archive preserved.')
if __name__=='__main__':main()
