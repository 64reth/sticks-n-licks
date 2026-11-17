class_name StoryDialogue
extends RefCounted
signal completed(id: String)
var definitions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/story/dialogue.json"))
var queue: Array[Dictionary]=[]
var held: bool=false
var pending: bool=false
var next_branch: String="" # Reserved data hook; no branching story authored yet.
func active() -> bool:return not queue.is_empty()
func line() -> Dictionary:return queue[0] if active() else {}
func begin(id: String, indices: Array=[]) -> void:
 var lines: Array=definitions[id]
 for i in range(lines.size()):
  if not indices.is_empty() and not indices.has(i):continue
  var entry: Dictionary=lines[i].duplicate()
  entry.id=id
  entry.sequence_index=i
  entry.last=i==(indices.back() if not indices.is_empty() else lines.size()-1)
  queue.append(entry)
func press(pressed: bool) -> void:
 if pressed and not held and active():pending=true
 held=pressed
func on_subdivision() -> void:
 if not pending or not active():return
 pending=false
 var entry: Dictionary=queue.pop_front()
 if entry.last:completed.emit(entry.id)
func clear() -> void:
 queue.clear()
 held=false
 pending=false
