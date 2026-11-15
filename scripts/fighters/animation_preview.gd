extends Node2D
var fighters: Array[Fighter] = []
var names: Array[String] = []
var index: int = 0
var paused: bool = false
var rate: float = 1.0
var label := Label.new()
var capture_counter: int = 0
var capture_elapsed: float = 0.0

func _ready() -> void:
 for player in range(2):
  var fighter := Fighter.new()
  fighter.asset_config = "res://data/animations/fighter_0%d.json" % (player+1)
  add_child(fighter)
  fighter.position = Vector2(85+150*player,150)
  fighter.face(1 if player==0 else -1)
  fighters.append(fighter)
 names.assign(fighters[0].animation_meta.keys())
 label.position = Vector2(5,5)
 label.add_theme_font_size_override("font_size",8)
 add_child(label)
 select(0)

func select(value: int) -> void:
 index = wrapi(value,0,names.size())
 for fighter in fighters:
  fighter.set_pose(names[index])
  fighter.sprite.frame = 0
  fighter.sprite.speed_scale = rate
  if paused:
   fighter.sprite.pause()

func _unhandled_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo:
  return
 match event.keycode:
  KEY_LEFT: select(index-1)
  KEY_RIGHT: select(index+1)
  KEY_SPACE:
   paused = not paused
   for fighter in fighters:
    if paused: fighter.sprite.pause()
    else: fighter.sprite.play()
  KEY_COMMA, KEY_PERIOD:
   paused = true
   for fighter in fighters:
    fighter.sprite.pause()
    var count := fighter.sprite.sprite_frames.get_frame_count(names[index])
    fighter.sprite.frame = wrapi(fighter.sprite.frame + (-1 if event.keycode==KEY_COMMA else 1),0,count)
  KEY_BRACKETLEFT: rate = maxf(0.25,rate-0.25)
  KEY_BRACKETRIGHT: rate = minf(3,rate+0.25)
 for fighter in fighters:
  fighter.sprite.speed_scale = rate

func _process(delta: float) -> void:
 var line := ""
 for player in range(2):
  var fighter := fighters[player]
  line += "P%d frame %d/%d  %s\\n" % [player+1,fighter.sprite.frame+1,fighter.sprite.sprite_frames.get_frame_count(names[index]),str(fighter.animation_meta[names[index]].get("note", "")).left(42)]
 label.text = "%s · %.2fx · %s\n←/→ state  Space pause  ,/. frame  [/] speed\n%s" % [names[index],rate,"PAUSED" if paused else "PLAY",line.replace("\\n","\n")]
 if OS.get_cmdline_user_args().has("--capture-preview"):
  capture_elapsed += delta
  if capture_elapsed >= 0.5:
   capture_elapsed = 0
   capture_state.call_deferred()

func capture_state() -> void:
 if capture_counter >= names.size():
  get_tree().quit()
  return
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://output/preview_%02d_%s.png" % [index,names[index]])
 print("PREVIEW inspected-render ",names[index]," frames ",fighters[0].sprite.frame,"/",fighters[1].sprite.frame)
 capture_counter += 1
 if capture_counter < names.size(): select(capture_counter)
 else: get_tree().quit()

func _draw() -> void:
 for y in range(0,180,10):
  for x in range(0,320,10):
   draw_rect(Rect2(x,y,10,10),Color("48515c") if (x/10+y/10)%2==0 else Color("313b45"))
 draw_line(Vector2(0,150),Vector2(320,150),Color("a8e5b9"),1)
 for x in [85,235]:
  draw_line(Vector2(x,78),Vector2(x,155),Color(1,1,1,0.2),1)
