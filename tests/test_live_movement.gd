extends SceneTree
# Real scene lifecycle and wall/audio clock. Only keyboard events drive gameplay.
# Tempo matrix uses the conductor's supported scheduled-tempo API explicitly.
var game: Node2D
var checks := 0
var failures := 0
var evidence: Array[Dictionary] = []
func _initialize() -> void:call_deferred("run")
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func key(code: int, down: bool=true) -> void:
 var event := InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=down
 if code==KEY_SHIFT:event.location=KEY_LOCATION_RIGHT
 Input.parse_input_event(event)
 await process_frame
func tap(code: int) -> void:
 await key(code)
 await create_timer(0.025).timeout
 await key(code,false)
func boundary() -> void:
 var identity := "%d:%d" % [game.conductor.phrase,game.conductor.beat]
 while identity=="%d:%d" % [game.conductor.phrase,game.conductor.beat]:await process_frame
func race() -> void:
 while game.mode in ["round_win","standoff"]:await process_frame
 check(game.mode=="race","Countdown reaches authoritative GO")
 await tap(KEY_F)
 await create_timer(0.04).timeout
 await tap(KEY_SHIFT)
 while game.mode in ["race","pickup"]:await process_frame
 check(game.mode=="combat","Resolved stick race enters combat")
func capture(label: String) -> void:
 if DisplayServer.get_name()=="headless":return
 await RenderingServer.frame_post_draw
 get_root().get_texture().get_image().save_png("res://output/live-"+label+".png")
func simultaneous_tap(codes: Array, signs: Array, label: String) -> void:
 await boundary()
 var target_time: float=game.conductor.beat_time+game.conductor.duration()
 while game.game_time()<target_time-0.09:await process_frame
 var before: Array=game.bout.positions.duplicate()
 var beat: int=game.conductor.beat
 for code in codes:await key(code)
 await create_timer(0.025).timeout
 for code in codes:await key(code,false)
 if game.game_time()<target_time:
  check(game.bout.positions==before,"Early tap waits for musical boundary "+label)
 else:
  check(game.controls[0].movement_executed,"Crossed boundary consumes tap exactly once "+label)
 while game.game_time()<target_time:await process_frame
 await process_frame
 var after: Array=game.bout.positions.duplicate()
 for player in range(2):check(after[player]==before[player]+signs[player]*Bout.STEP,"Released tap steps "+label+" P%d" % player)
 await capture(label+"-step")
 await create_timer(0.09).timeout
 await capture(label+"-stable")
 await create_timer(0.08).timeout
 for player in range(2):check(abs(game.fighters[player].position.x-after[player])<2.5,"Visible sprite follows "+label)
 print("LIVE sample ",label," ",before," -> ",after)
 evidence.append({"label":label,"input_beat":beat,"resolved_beat":game.conductor.beat,"bpm":game.conductor.bpm,"before":before,"after":after,"rendered":[game.fighters[0].position.x,game.fighters[1].position.x]})
 await capture(label)
func win_round() -> void:
 # Deliberate taps, never held polling, advance into actual reach.
 while game.bout.positions[1]-game.bout.positions[0]>Bout.GAP+0.01:
  await boundary()
  await key(KEY_D)
  await key(KEY_LEFT)
  await key(KEY_D,false)
  await key(KEY_LEFT,false)
 while game.mode=="combat":
  while game.mode=="combat" and game.game_time()<game.conductor.action_time()-0.035:await process_frame
  if game.mode!="combat":break
  var attacker: int=game.bout.initiative
  await key(KEY_W if attacker==0 else KEY_UP)
  await tap(KEY_F if attacker==0 else KEY_SHIFT)
  await key(KEY_W if attacker==0 else KEY_UP,false)
  var phrase: int=game.conductor.phrase
  while game.mode=="combat" and game.conductor.phrase==phrase:await process_frame
 while game.mode=="finishing":await process_frame
 check(game.mode in ["round_win","match_win"],"Real combat reaches three-hit round result")
func run() -> void:
 create_timer(180.0).timeout.connect(func():
  push_error("Live movement E2E timed out in "+game.mode)
  quit(1))
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.game_mode="pvp"
 root.add_child(game)
 game.preferences.values.game_mode=game.game_mode
 check(game.mode=="menu" and not game.conductor.clock_override.is_valid(),"Actual entrypoint, normal clock")
 await tap(KEY_A)
 check(game.bout.positions==[100.0,220.0],"Menu rejects displacement")
 await tap(KEY_ENTER) # Skip intro
 await tap(KEY_ENTER) # Open main menu
 await tap(KEY_ENTER) # Match setup
 for i in range(5):await tap(KEY_DOWN)
 await tap(KEY_ENTER)
 await tap(KEY_D)
 check(game.bout.positions==[100.0,220.0],"Countdown rejects displacement")
 await race()
 await create_timer(0.4).timeout
 await capture("stage01-idle")
 await key(KEY_F4)
 await key(KEY_F4,false)
 check(game.stage.selected==0,"F4 cannot change a live match stage")
 await capture("stage02-idle")
 await boundary()
 await create_timer(game.conductor.duration()/2.0).timeout
 var miss_before: Array=game.bout.positions.duplicate()
 await tap(KEY_A)
 check(game.controls[0].movement_grade=="miss" and game.bout.positions==miss_before,"Midpoint tap misses without movement")
 await capture("miss")
 for pair in [[KEY_D,KEY_LEFT],[KEY_A,KEY_RIGHT]]:
  await boundary()
  await create_timer(0.12).timeout
  for code in pair:await key(code)
  for code in pair:await key(code,false)
  check(game.controls[0].movement_grade=="good" and game.controls[1].movement_grade=="good","Late GOOD movement confirmed")
  await capture("good"+str(pair[0]))
  await create_timer(0.18).timeout
 for bpm in [120,140,160]:
  game.conductor.schedule_tempo(bpm)
  while game.conductor.bpm!=bpm:await process_frame
  for n in range(4):
   if n==2:await boundary()
   await simultaneous_tap([KEY_A,KEY_RIGHT],[-1,1],"%d-retreat-%d" % [bpm,n])
   await simultaneous_tap([KEY_D,KEY_LEFT],[1,-1],"%d-advance-%d" % [bpm,n])
  await boundary()
  await key(KEY_D)
  await key(KEY_LEFT)
  var before: Array=game.bout.positions.duplicate()
  for n in range(2):await boundary()
  await key(KEY_D,false)
  await key(KEY_LEFT,false)
  check(game.bout.positions==before,"Holding cannot repeat at %d" % bpm)
  await simultaneous_tap([KEY_A,KEY_RIGHT],[-1,1],"%d-restore" % bpm)
 await win_round()
 await race()
 await simultaneous_tap([KEY_A,KEY_RIGHT],[-1,1],"round-reset")
 await win_round()
 if game.mode=="round_win":
  await race()
  await win_round()
 check(game.mode=="match_win","Complete match via keyboard events")
 await tap(KEY_ENTER)
 await race()
 await simultaneous_tap([KEY_A,KEY_RIGHT],[-1,1],"rematch")
 var raw_gameplay:=0
 var routed_gameplay:=0
 for row in game.movement_trace:
  if row.phase!="combat":continue
  if row.stage=="raw":raw_gameplay+=1
  if row.stage=="unhandled":routed_gameplay+=1
 check(raw_gameplay==routed_gameplay,"Combat directional events reach validation; menus intentionally consume navigation")
 for bpm in [120,140,160]:
  var seen := {}
  for sample in evidence:
   if sample.bpm==bpm:seen[sample.resolved_beat]=true
  check(seen.size()==4,"Live movement executed on all four beats at %d" % bpm)
 var file := FileAccess.open("res://output/live-movement-evidence.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":evidence,"trace":game.movement_trace,"limitation":"Engine-injected keys; physical keyboard/focus awaiting human verification. Tempo matrix scheduled via public conductor API."},"  "))
 print("LIVE MOVEMENT: %d checks, %d failures" % [checks,failures])
 game.audio.stop()
 quit(1 if failures else 0)
