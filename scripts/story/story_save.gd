class_name StorySave
extends RefCounted
# Same path; version 1 is migrated without losing the owner's opening checkpoint.
var path: String="user://story-009.json"
var data: Dictionary={}
func load_progress() -> bool:
 data={}
 if path.is_empty() or not FileAccess.file_exists(path):return false
 var parser:=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK:return false
 var parsed=parser.data
 if not parsed is Dictionary or parsed.get("campaign")!="rent_due" or parsed.get("opening_complete")!=true:return false
 if parsed.get("version")==1:
  if parsed.get("unlocked_screen")!=1 or parsed.get("checkpoint") not in ["traversal","screen01_complete"]:return false
  data={"version":2,"campaign":"rent_due","unlocked_screen":1,"checkpoint":"traversal","opening_complete":true,"screen":1,"completed":["rent"],"item":"","money":0,"rewards":[]}
  return true
 if parsed.get("version")!=2 or typeof(parsed.get("screen")) not in [TYPE_INT,TYPE_FLOAT] or int(parsed.screen) not in range(1,7):return false
 if not parsed.get("completed") is Array or parsed.get("item") not in ["","crate","stick"] or not parsed.get("rewards") is Array:return false
 if parsed.has("reward_amounts") and not parsed.reward_amounts is Dictionary:return false
 var amounts: Dictionary=parsed.get("reward_amounts",{})
 if not amounts.is_empty() and amounts.size()!=parsed.rewards.size():return false
 for id in amounts:
  if not parsed.rewards.has(id):return false
 var economy:=StoryWallet.new()
 if typeof(parsed.get("money")) not in [TYPE_INT,TYPE_FLOAT] or parsed.money!=economy.total_for(parsed.rewards,amounts):return false
 if parsed.has("rent_target") and parsed.rent_target!=economy.target():parsed.rent_target=economy.target()
 if parsed.has("road_checkpoint") and (typeof(parsed.road_checkpoint) not in [TYPE_INT,TYPE_FLOAT] or float(parsed.road_checkpoint) not in [36.0,68.0,148.0,244.0,292.0]):return false
 if parsed.has("road_section") and float(parsed.road_section) not in [0.0,1.0]:return false
 var log:=QuestLog.new()
 log.restore(parsed.completed)
 if log.completed!=parsed.completed:return false
 var expected_item: String="stick" if log.completed.has("stick") else ("crate" if log.completed.has("crate") and not log.completed.has("handover") else "")
 if parsed.item!=expected_item or parsed.rewards.has("crate_delivery")!=log.completed.has("payment"):return false
 var gates: Array[String]=["rent","village","crate","stick_search","stick_search","cane"]
 if not log.completed.has(gates[int(parsed.screen)-1]):return false
 if parsed.rewards.has("fight_first") and not log.completed.has("fight"):return false
 data=parsed.duplicate(true)
 return true
func valid() -> bool:return not data.is_empty()
func checkpoint(value: String) -> void:
 # Compatibility entry point for Screen 01 tooling, now produces a valid v2 checkpoint.
 data={"version":2,"campaign":"rent_due","unlocked_screen":1,"checkpoint":value,"opening_complete":true,"screen":1,"completed":["rent"],"item":"","money":0,"rewards":[]}
 write()
func write() -> void:
 if path.is_empty():return
 var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if not file:return
 file.store_string(JSON.stringify(data))
 file.close()
 DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
