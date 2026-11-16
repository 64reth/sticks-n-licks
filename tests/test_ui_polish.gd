extends SceneTree
var game: Node2D
var time:=0.0
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func run() -> void:
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return time
 root.add_child(game)
 game.set_process(false)
 game.intro.set_process(false)
 game.intro.update_at(3.6)
 await process_frame
 await process_frame
 var panel: PanelContainer=game.intro.prompt_panel
 var label: Label=game.intro.prompt
 var style: StyleBoxFlat=panel.get_theme_stylebox("panel")
 check(style.content_margin_left==style.content_margin_right and style.content_margin_top==style.content_margin_bottom,"Symmetric CTA content margins")
 check(style.content_margin_left>=7 and style.content_margin_top>=5,"CTA reserves border and intentional padding")
 check(label.vertical_alignment==VERTICAL_ALIGNMENT_CENTER and label.horizontal_alignment==HORIZONTAL_ALIGNMENT_CENTER,"Both text alignments centred")
 check(label.get_theme_font("font")==game.intro.FONT and label.get_theme_font_size("font_size")==16,"Preserve approved font and hierarchy")
 var usable:=Rect2(Vector2(style.content_margin_left,style.content_margin_top),panel.size-Vector2(style.content_margin_left+style.content_margin_right,style.content_margin_top+style.content_margin_bottom))
 check(label.get_parent()==panel and label.get_rect()==usable,"Container owns actual label content bounds")
 var width: float=label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
 var height: float=label.get_theme_font("font").get_height(16)
 var line_box:=Rect2(label.position+(label.size-Vector2(width,height))/2.0,Vector2(width,height))
 check(usable.encloses(line_box) and line_box.get_center().is_equal_approx(usable.get_center()),"Measured line box fits and centres within usable area")
 var rect: Rect2=panel.get_rect()
 for extent in [Vector2i(640,360),Vector2i(960,540),Vector2i(1280,720)]:
  root.size=extent
  await process_frame
  check(panel.get_rect()==rect and Rect2(0,0,320,180).encloses(rect),"CTA remains inside native viewport at window size "+str(extent))
 for at in [0.0,1.6,3.0,3.5,3.9,4.2]:
  game.intro.update_at(at)
  check(panel.get_rect()==rect,"CTA geometry stable throughout intro animation")
  check(panel.visible==(at>=3.0),"CTA visibility retains cue timing")
 check(game.hud_layer.layer>0 and game.hud.get_parent()==game.hud_layer,"Announcements render above scenery/fighters/prop")
 for node in [game.hud.round_label,game.hud.tempo_label,game.hud.phase_label,game.hud.major_label,game.hud.instruction_label,game.hud.footer_label]:
  check(node is PixelAnnouncement and node.outline_pixels==2,"Consistent 2 logical pixel stroke")
  check(node.outline_color==Color("172235") and node.shadow_color==Color("080f1b"),"Arcade contrast palette")
  check(not node.clip_text and not node.clip_contents,"Outline is not clipped to glyph/control box")
 game.intro.visible=false
 game.game_mode="pvp"
 game.begin()
 game.cue=4.0
 game.conductor.start(0)
 for index in range(game.stage.entries.size()):
  game.stage.select_stage(index)
  for at in [2.5,2.6,3.0,3.5,4.0]:
   time=at
   game.mode="race" if at>=4 else "standoff"
   game.refresh()
   var major: PixelAnnouncement=game.hud.major_label
   check(major.text==("GO!" if at>=4 else str(3-mini(2,int((at-2.5)/0.5)))) ,"Conductor countdown unchanged on every stage")
   check(major.scale.x==(3 if at==2.6 or at==4 else 4),"Countdown pulse scales unchanged")
   check((major.ink_origin()*major.scale).is_equal_approx((major.ink_origin()*major.scale).round()),"Scaled text origin lands on native grid")
   var ink_bottom: float=major.position.y+major.get_theme_font("font").get_ascent(8)*major.scale.y+major.outline_pixels
   check(ink_bottom<=game.hud.instruction_label.position.y-2,"Countdown stroke leaves a clear instruction gap")
 var metrics:=FileAccess.open("res://output/ui-polish-metrics.json",FileAccess.WRITE)
 metrics.store_string(JSON.stringify({"panel_rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"content_rect":[usable.position.x,usable.position.y,usable.size.x,usable.size.y],"font_size":16,"line_width":width,"line_height":height,"outline_pixels":2,"checks":checks,"failures":failures},"  "))
 print("UI POLISH: %d checks, %d failures" % [checks,failures])
 game.audio.stop()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)
