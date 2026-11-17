class_name StoryOverlay
extends Control
var story: StorySession
const FONT=preload("res://assets/ui/arcade/arcade.fnt")
const DIALOGUE_RECT=Rect2(8,144,304,32)
const INVENTORY_RECT=Rect2(294,18,18,16)
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func text(value: String, at: Vector2, color: Color=Color("ffe2a0")) -> void:
 value=value.to_upper()
 for p in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:draw_string(FONT,at+p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("172235"))
 draw_string(FONT,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,8,color)
func wrapped_lines(value: String, width: float=278) -> Array[String]:return StoryDialogue.wrapped_lines(value,width)
func panel(rect: Rect2) -> void:
 draw_rect(rect,Color("172235"))
 draw_rect(rect,Color("ffe2a0"),false,1)
func currency() -> String:return "BDS $%d" % story.wallet.money
func rent_progress() -> String:return "RENT $%d / $%d" % [story.wallet.money,story.wallet.target()]
func draw_inventory() -> void:
 panel(INVENTORY_RECT)
 var at:=INVENTORY_RECT.position
 match story.inventory.item:
  "crate":
   draw_rect(Rect2(at+Vector2(3,3),Vector2(12,10)),Color("b7834d"))
   draw_line(at+Vector2(3,3),at+Vector2(14,12),Color("553e30"),1)
   draw_line(at+Vector2(14,3),at+Vector2(3,12),Color("553e30"),1)
  "stick":draw_line(at+Vector2(4,12),at+Vector2(14,3),Color("ffe2a0"),2)
  _:draw_rect(Rect2(at+Vector2(7,7),Vector2(4,2)),Color("56646d"))
func draw_beats(at: Vector2, highlight_four: bool=false) -> void:
 for i in range(4):
  var active: bool=story.game.conductor.beat==i+1
  draw_rect(Rect2(at+Vector2(i*14,0),Vector2(10,3)),Color("ffe2a0") if active else Color("526575"))
  if highlight_four and i==3:draw_rect(Rect2(at+Vector2(i*14-1,-1),Vector2(12,5)),Color("ffe2a0"),false,1)
func _draw() -> void:
 if not story:return
 if story.quest.completed.has("rent"):
  var objective:=wrapped_lines(story.campaign_objective(),276)
  for i in range(mini(2,objective.size())):text(objective[i],Vector2(8,34+i*10))
 var money:=rent_progress()
 draw_rect(Rect2(8,17,272,3),Color("172235"))
 draw_rect(Rect2(8,17,roundf(272*minf(1,float(story.wallet.money)/story.wallet.target())),3),Color("ffe2a0"))
 text(money,Vector2(312-FONT.get_string_size(money,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x,11))
 draw_inventory()
 if story.phase=="waiting" and not story.dialogue.active():text("READY ON THE NEXT BEAT",Vector2(8,39))
 if story.phase=="playing" and not story.dialogue.active() and not story.quest_panel:
  ControlPrompt.draw(self,"p1_left","Left",Vector2(8,164))
  ControlPrompt.draw(self,"p1_right","Right",Vector2(72,164))
  ControlPrompt.draw(self,"p1_low","Duck",Vector2(143,164))
  ControlPrompt.draw(self,"ui_focus_next","Quest",Vector2(232,164))
  draw_beats(Vector2(134,177))
  var context:=story.context_interaction()
  if not context.is_empty():
   ControlPrompt.draw(self,str(context.action),str(context.label),Vector2(8,78) if story.screens.screen_id==3 else Vector2(70,52))
   if context.get("beat4",false):draw_beats(Vector2(93,69),true)
  if story.inventory.item=="crate":draw_rect(Rect2(story.actor.position+Vector2(10,-24),Vector2(10,10)),Color("b7834d"))
  if story.absolute_beat()<story.notification_until and not story.quest.notification.is_empty() and not story.quest.notification.begins_with("DONE:") and story.quest.notification!=str(story.quest.definition.objective):
   panel(Rect2(5,85,310,25))
   var lines:=wrapped_lines(story.quest.notification,296)
   for i in range(mini(2,lines.size())):text(lines[i],Vector2(10,95+i*10))
 if story.absolute_beat()<story.reward_until and not story.reward_notice.is_empty():
  panel(Rect2(8,112,304,16))
  text(story.reward_notice,Vector2(14,123))
 if story.dialogue.active():
  panel(DIALOGUE_RECT)
  text(str(story.dialogue.line().speaker),Vector2(16,153))
  var lines:=story.dialogue.visible_text().split("\n")
  for i in range(lines.size()):text(lines[i],Vector2(16,163+i*10))
  ControlPrompt.draw(self,"p1_execute","Next" if story.dialogue.is_revealed() else "Reveal",Vector2(246,145))
 if story.quest_panel:
  panel(Rect2(8,31,304,130))
  text(str(story.quest.definition.quests[0].title),Vector2(16,43))
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
  panel(Rect2(4,112,312,22))
  text("%s B%d:%d X%.0f %s" % [story.player_state(),story.game.conductor.phrase,story.game.conductor.beat,story.target_x,story.control.movement_grade],Vector2(8,122))
  text("F6 REPLAY F7 RESTART F8 SKIP",Vector2(8,132))
