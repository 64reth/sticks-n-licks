class_name StorySave
extends RefCounted
var path: String="user://story-009.json"
var data: Dictionary={}
func load_progress() -> bool:
 data={}
 if path.is_empty() or not FileAccess.file_exists(path):return false
 var parser:=JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path))!=OK:return false
 var parsed=parser.data
 if not parsed is Dictionary:return false
 if parsed.get("version")!=1 or parsed.get("campaign")!="rent_due" or parsed.get("unlocked_screen")!=1 or parsed.get("opening_complete")!=true or parsed.get("checkpoint") not in ["traversal","screen01_complete"]:return false
 data={"version":1,"campaign":"rent_due","unlocked_screen":1,"checkpoint":parsed.checkpoint,"opening_complete":true}
 return true
func valid() -> bool:return not data.is_empty()
func checkpoint(value: String) -> void:
 data={"version":1,"campaign":"rent_due","unlocked_screen":1,"checkpoint":value,"opening_complete":true}
 if path.is_empty():return
 var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
 if not file:return
 file.store_string(JSON.stringify(data))
 file.close()
 DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
