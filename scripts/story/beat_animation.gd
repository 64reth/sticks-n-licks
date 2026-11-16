class_name BeatAnimation
extends RefCounted
# Reusable beat-relative environmental timeline; no object clocks or delta timers.
var cues: Array[Dictionary]=[]
var origin: float=0
var length: float=16
var offset: float=0
var looping: bool=false
var running: bool=false
func start(at_beat: float) -> void:
 origin=at_beat
 running=true
func stop() -> void:running=false
func sample(absolute_beat: float) -> Dictionary:
 if not running:return {}
 var phase:=absolute_beat-origin-offset
 if phase<0:return {}
 if looping:phase=fposmod(phase,length)
 var result: Dictionary={}
 for cue in cues:
  if phase<float(cue.beat):break
  result=cue
 return result
