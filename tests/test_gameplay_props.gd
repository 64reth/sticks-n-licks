extends SceneTree
# Test-only deterministic fixtures followed by a legal seeded CPU match.
var game: Node2D
var now := 0.0
var checks := 0
var failures := 0
var graphical := false
var captured: Dictionary = {}
var bot := RhythmTestPlayer.new()

func _initialize() -> void:
 call_deferred("run")
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func capture(label: String) -> void:
 if not graphical or captured.has(label):return
 captured[label] = true
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/props-"+label+".png")
func hold(seconds: float) -> void:
 if not graphical:return
 for i in range(int(seconds*60)):
  await process_frame
func race_reset() -> void:
 game.game_mode = "pvp"
 game.begin()
 now = game.cue
 game.mode = "race"
 game.sync_ground_sticks()
func action(player: int, name: String, at: float) -> void:
 game.submit_action(player,name,true,at)
 game.submit_action(player,name,false,at)
func fixture(height: int, defense: int, error: float, left: float = 138, right: float = 182, attacker: int = 0) -> void:
 game.bout = Bout.new()
 game.bout.positions.assign([left,right])
 game.bout.initiative = attacker
 game.mode = "combat"
 game.phrase_resolved = false
 game.exchange_phrase = 0
 game.conductor.start(now)
 game.bout.selections.assign([height,defense] if attacker==0 else [defense,height])
 game.bout.errors.assign([0.0,error] if attacker==0 else [error,0.0])
 game.selected.assign(game.bout.selections)
 for p in range(2):
  game.fighters[p].reset_visual()
  game.fighters[p].position = Vector2(game.bout.positions[p],150)
  game.fighters[p].face(game.facing(p))
 game.sync_ground_sticks()
 game.impact_effect.clear()
 game.resolve_exchange()
 game.refresh()

func run() -> void:
 graphical = DisplayServer.get_name() != "headless"
 game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path = ""
 game.conductor.clock_override = func():return now
 root.add_child(game)
 game.set_process(false)
 await capture("launch")
 game.flow.view.visible = false
 for order in [[0,1],[1,0]]:
  race_reset()
  check(game.ground_sticks.state==GroundSticks.State.BOTH_ON_GROUND,"reset crossed sticks")
  await capture("both")
  await hold(0.6)
  action(order[0],"execute",now+0.1)
  game.sync_ground_sticks()
  check(game.ground_sticks.state==(GroundSticks.State.RIGHT_ONLY if order[0]==0 else GroundSticks.State.LEFT_ONLY),"first pickup removes owned stick")
  await capture("right-only" if order[0]==0 else "left-only")
  await hold(0.6)
  action(order[1],"execute",now+0.2)
  game.sync_ground_sticks()
  check(not game.ground_sticks.visible,"second pickup hides sticks")
  await capture("none")
  await hold(0.6)
 # Missed inputs, near ties, false starts and automatic pickup retain original race rules.
 race_reset()
 game._process(0)
 check(game.ground_sticks.state==GroundSticks.State.BOTH_ON_GROUND,"no input retains both before deadline")
 now = game.race_deadline+0.01
 game._process(0)
 check(game.mode=="standoff" and game.ground_sticks.state==GroundSticks.State.BOTH_ON_GROUND,"no inputs retries with both sticks")
 for offset in [0.0,0.004,0.006]:
  race_reset()
  action(0,"execute",now+0.1)
  action(1,"execute",now+0.1+offset)
  game._process(0)
  check(game.mode=="pickup" and not game.ground_sticks.visible,"tie/near tie collects both")
  check(game.bout.hits==[0,0],"race never damages")
 race_reset()
 action(0,"execute",now+0.1)
 now = game.race_deadline+0.01
 game._process(0)
 check(game.mode=="pickup" and not game.ground_sticks.visible,"missed second input uses existing automatic pickup")
 race_reset()
 action(0,"execute",now-0.1)
 game._process(0)
 check(game.mode=="pickup" and game.bout.initiative==1 and not game.ground_sticks.visible,"false start preserves initiative and automatic pickup")
 game.match_progress.round_wins.assign([1,0])
 game._begin_round()
 check(game.ground_sticks.state==GroundSticks.State.BOTH_ON_GROUND and game.match_progress.round_wins==[1,0],"round reset restores props only")
 game.begin()
 check(game.ground_sticks.state==GroundSticks.State.BOTH_ON_GROUND and game.match_progress.round_wins==[0,0],"rematch restores props and markers")
 for kind in ["HIT","BLOCK","PARRY"]:
  for attacker in range(2):
   for height in range(3):
    fixture(height,-1 if kind=="HIT" else height,100.0 if kind=="BLOCK" else 0.0,138,182,attacker)
    var fx: ImpactEffect = game.impact_effect
    check(game.bout.last_event.kind==kind and fx.kind==kind and fx.visible,"authoritative mapping "+kind)
    var damage: Array = game.bout.hits.duplicate()
    var initiative: int = game.bout.initiative
    var count: int = fx.spawn_count
    game.resolve_exchange()
    check(fx.spawn_count==count and game.bout.hits==damage and game.bout.initiative==initiative,"duplicate resolve has no visual/rule effects")
    check(fx.position==fx.position.round() and fx.position.y==[98,118,138][height],"integer contact follows height")
    if attacker==0 and height==1:
     await capture(kind.to_lower()+"-0")
     for f in range(1,3):
      now += fx.frame_seconds
      fx.advance(now)
      check(fx.frame==f and fx.visible,"three-frame progression")
      await capture(kind.to_lower()+"-"+str(f))
      await hold(fx.frame_seconds)
    else:
     fx.advance(now+fx.frame_seconds)
     check(fx.frame==1,"frame one")
     fx.advance(now+2*fx.frame_seconds)
     check(fx.frame==2,"frame two")
    fx.advance(fx.started+3*fx.frame_seconds)
    check(not fx.visible,"effect cleanup")
    check(game.bout.hits==damage and game.bout.initiative==initiative,"effect playback is visual only")
    await hold(0.15)
 # Clamp the full frame safely even if reusable event geometry is near an edge.
 fixture(1,-1,0)
 var edge_event: Dictionary = game.bout.last_event.duplicate(true)
 for point in [Vector2(0,0),Vector2(319,179)]:
  edge_event.attack_region = Rect2(point,Vector2.ONE)
  edge_event.hurt_region = Rect2(point,Vector2.ONE)
  game.impact_effect.play_resolved(edge_event,str(point),now)
  var bounds := Rect2(game.impact_effect.position-Vector2(16,16),Vector2(32,32))
  check(Rect2(0,0,320,180).encloses(bounds),"full effect frame remains within viewport")
 fixture(0,-1,0)
 game.phrase_resolved = false
 game.exchange_phrase = 1
 game.bout.selections.assign([0,-1])
 game.bout.errors.assign([141.0,INF])
 game.impact_effect.clear()
 game.resolve_exchange()
 check(game.bout.last_event.kind=="WHIFF" and not game.impact_effect.visible,"timing miss has no successful effect")
 fixture(0,-1,0,100,220)
 check(game.bout.last_event.kind=="WHIFF" and not game.impact_effect.visible,"range miss has no effect")
 fixture(-1,-1,0)
 check(not game.impact_effect.visible,"missing attack has no effect")
 fixture(1,1,0)
 var effect: ImpactEffect = game.impact_effect
 var spawn_before := effect.spawn_count
 check(not effect.play_resolved(game.bout.last_event,effect.last_key,now),"duplicate event suppressed")
 var replacement: Dictionary = game.bout.last_event.duplicate(true)
 replacement.kind = "BLOCK"
 check(effect.play_resolved(replacement,"replacement",now) and effect.spawn_count==spawn_before+1,"active effect safely replaced")
 var frozen: int = effect.frame
 game.set_paused(true)
 effect.advance(game.conductor.now())
 check(effect.frame==frozen,"paused conductor freezes effect")
 game.set_paused(false)
 effect.clear()
 # Legal production CPU dispatch, no position/selection overrides after begin.
 game.game_mode = "cpu"
 game.cpu_difficulty = "hard"
 game.cpu_seed = 7000
 game.begin()
 bot.configure("rush_high",107000)
 game.conductor.beat_changed.connect(func(_b: int,_p: int):
  if game.mode=="combat":bot.plan_boundary(game.public_cpu_observation()))
 var seen_cue := -INF
 var seen_exchange := 0
 var cpu_effects := 0
 for tick in range(15000):
  now += 1.0/60.0
  game._process(1.0/60.0)
  if game.mode=="standoff" and seen_cue!=game.cue:
   seen_cue=game.cue
   bot.start_round(game.cue)
  while bot.next_time()<=now:
   var intent: Dictionary = bot.pop_intent()
   if intent.kind=="race" and game.mode not in ["standoff","race"]:continue
   if intent.kind!="race" and game.mode!="combat":continue
   action(0,str(intent.action),now)
   if intent.kind=="combat":action(0,"execute",now)
  if game.completed_exchanges.size()>seen_exchange:
   seen_exchange=game.completed_exchanges.size()
   if game.bout.last_event.kind in ["HIT","BLOCK","PARRY"]:
    check(game.impact_effect.visible and game.impact_effect.kind==game.bout.last_event.kind,"CPU resolved effect")
    cpu_effects+=1
    await capture("cpu-"+str(game.bout.last_event.kind).to_lower())
  if game.mode=="round_win":game.next_round()
  if game.mode=="match_win":break
  if graphical:await process_frame
 check(game.mode=="match_win" and cpu_effects>0,"legal CPU match completes with effects")
 print("GAMEPLAY PROPS: %d checks, %d failures; CPU effects %d" % [checks,failures,cpu_effects])
 game.audio.stop()
 game.impact_effect.clock_source = Callable()
 game.audio.clock_source = Callable()
 game.conductor.clock_override = Callable()
 game.queue_free()
 await process_frame
 quit(0 if failures==0 else 1)
