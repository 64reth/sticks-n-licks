class_name UserPreferences
extends RefCounted
const DEFAULTS := {"game_mode":"cpu","difficulty":"normal","best_of":3,"bpm":120,"stage":"stage_01","master":80,"music":80,"sfx":80,"music_on":true,"sfx_on":true,"fullscreen":false,"integer_scale":true,"timing_feedback":true}
var values: Dictionary=DEFAULTS.duplicate(true)
var path: String="user://preferences.cfg"
func validate(candidate: Dictionary, stages: Array) -> Dictionary:
 var clean:=DEFAULTS.duplicate(true)
 for key in DEFAULTS:
  if not candidate.has(key):continue
  var value: Variant=candidate[key]
  if typeof(value)!=typeof(DEFAULTS[key]):continue
  clean[key]=value
 if clean.game_mode not in ["cpu","pvp"]:clean.game_mode="cpu"
 if clean.difficulty not in ["easy","normal","hard"]:clean.difficulty="normal"
 if clean.best_of not in [3,5,7]:clean.best_of=3
 if clean.bpm not in [120,140,160]:clean.bpm=120
 if clean.stage!="random" and clean.stage not in stages:clean.stage="stage_01" if "stage_01" in stages else (stages[0] if not stages.is_empty() else "random")
 for key in ["master","music","sfx"]:clean[key]=clampi(int(clean[key]),0,100)
 return clean
func load_values(stages: Array) -> void:
 var config:=ConfigFile.new()
 if not path.is_empty() and config.load(path)==OK:
  var candidate: Variant=config.get_value("preferences","values",{})
  values=validate(candidate if candidate is Dictionary else {},stages)
 else:values=validate({},stages)
func save_values() -> Error:
 if path.is_empty():return OK
 var config:=ConfigFile.new()
 config.set_value("preferences","version",1)
 config.set_value("preferences","values",values)
 return config.save(path)
