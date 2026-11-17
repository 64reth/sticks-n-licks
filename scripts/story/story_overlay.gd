class_name StoryOverlay
extends Control
var story: StorySession
const FONT=preload("res://assets/ui/arcade/arcade.fnt")
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func text(value: String, at: Vector2, color: Color=Color("ffe2a0")) -> void:
 value=value.to_upper()
 for p in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:draw_string(FONT,at+p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("172235"))
 draw_string(FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,8,color)
func wrapped_lines(value: String, width: float=278) -> Array[String]:
 var lines: Array[String]=[]
 var line: String=""
 for word in value.split(" "):
  var candidate: String=word if line.is_empty() else line+" "+word
  if FONT.get_string_size(candidate.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x>width and not line.is_empty():
   lines.append(line)
   line=word
  else:line=candidate
 if not line.is_empty():lines.append(line)
 return lines
func panel(rect: Rect2) -> void:
 draw_rect(rect,Color("172235"))
 draw_rect(rect,Color("ffe2a0"),false,1)
func _draw() -> void:
 if not story:return
 text("RENT DUE!  BDS $%d  [%s]" % [story.wallet.money,story.inventory.item if not story.inventory.item.is_empty() else "EMPTY"],Vector2(8,12))
 if story.inventory.item=="stick":draw_line(Vector2(287,16),Vector2(299,5),Color("ffe2a0"),2)
 var objective: String=str(story.quest.current().get("text","QUEST COMPLETE"))
 if story.quest.completed.has("rent"):text(objective,Vector2(8,24))
 if story.phase=="waiting" and not story.dialogue.active():text("READY ON THE NEXT BEAT",Vector2(8,36))
 if story.phase=="cinematic" and not story.dialogue.active():text("ENTER: SKIP",Vector2(8,24))
 for i in range(4):draw_rect(Rect2(136+i*12,176,8,3),Color("ffe2a0") if story.game.conductor.beat==i+1 else Color("172235"))
 if story.phase=="playing" and not story.dialogue.active():
  text("A/D STEP  S DUCK  F ACTION  TAB QUEST",Vector2(8,159))
  if story.game.preferences.values.timing_feedback and story.game.game_time()<story.control.movement_feedback_until:text(story.control.movement_grade,Vector2(250,174))
  if story.inventory.item=="crate":
   draw_rect(Rect2(story.actor.position+Vector2(10,-24),Vector2(10,10)),Color("b7834d"))
   draw_rect(Rect2(286,4,12,12),Color("b7834d"))
  if story.absolute_beat()<story.notification_until:
   panel(Rect2(5,32,310,26))
   var lines:=wrapped_lines(story.quest.notification,296)
   for i in range(mini(2,lines.size())):text(lines[i],Vector2(10,43+i*10))
 if story.dialogue.active():
  panel(Rect2(8,28,304,58))
  var line:=story.dialogue.line()
  text(str(line.speaker)+( " [TEMP]" if line.get("placeholder",false) else ""),Vector2(16,40))
  var lines:=wrapped_lines(str(line.text))
  for i in range(lines.size()):text(lines[i],Vector2(16,51+i*10))
  text("F: NEXT",Vector2(255,82))
 if story.quest_panel:
  panel(Rect2(8,31,304,130))
  text("A STICK TO SHARE LICKS",Vector2(16,43))
  var y:=55
  for step in story.quest.steps():
   if story.quest.status(step.id)=="locked":break
   text(("[X] " if story.quest.status(step.id)=="completed" else "[>] ")+str(step.text),Vector2(16,y))
   y+=9
   for child in step.get("children",[]):
    if story.quest.status(child.id)=="locked":break
    text(("  + " if story.quest.completed.has(child.id) else "  > ")+str(child.text),Vector2(16,y))
    y+=9
 if story.game.debug_visible and not story.dialogue.active() and not story.quest_panel:
  panel(Rect2(4,60,312,23))
  text("%s B%d:%d X%.0f %s" % [story.player_state(),story.game.conductor.phrase,story.game.conductor.beat,story.target_x,story.control.movement_grade],Vector2(8,70))
  text("F6 REPLAY F7 RESTART F8 SKIP",Vector2(8,80))
