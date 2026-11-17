class_name QuestLog
extends RefCounted
signal progressed(event: String)
var definition: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/story/quests.json"))
var completed: Array[String]=[]
var notification: String=""
func steps(quest_id: String="a_stick_to_share") -> Array:
 for entry in definition.quests:
  if entry.id==quest_id:return entry.steps
 return []
func active(quest_id: String="a_stick_to_share") -> Dictionary:
 for step in steps(quest_id):
  if not completed.has(step.id):return step
 return {}
func current(quest_id: String="a_stick_to_share") -> Dictionary:
 var step:=active(quest_id)
 for child in step.get("children",[]):
  if not completed.has(child.id):return child
 return step
func status(id: String, quest_id: String="a_stick_to_share") -> String:
 if completed.has(id):return "completed"
 return "active" if active(quest_id).get("id")==id or current(quest_id).get("id")==id else "locked"
func emit_event(event: String, quest_id: String="a_stick_to_share") -> bool:
 var step:=current(quest_id)
 if step.is_empty() or step.event!=event:return false
 completed.append(step.id)
 var parent:=active(quest_id)
 if parent.has("children") and parent.event==event:completed.append(parent.id)
 notification="DONE: "+str(step.text)
 progressed.emit(event)
 return true
func restore(ids: Array) -> void:
 completed.clear()
 # Reconstruct the ordered prefix; invalid/out-of-order saves cannot unlock a gate.
 for entry in definition.quests:
  for guard in range(32):
   var step:=current(str(entry.id))
   if step.is_empty() or not ids.has(str(step.id)):break
   emit_event(str(step.event),str(entry.id))
 notification=""
func finished(quest_id: String="a_stick_to_share") -> bool:return active(quest_id).is_empty()

func reward_for(step_id: String, quest_id: String="a_stick_to_share") -> Dictionary:
 for step in steps(quest_id):
  if step.id==step_id:return step.get("reward",{})
 return {}
