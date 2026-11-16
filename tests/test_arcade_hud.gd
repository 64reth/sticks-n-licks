extends SceneTree
var game: Node2D
var time: float = 0.0
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error(message)

func key(action: String,pressed: bool=true) -> void:
 var event: InputEventKey = InputMap.action_get_events(action)[0].duplicate()
 event.keycode = event.physical_keycode
 event.pressed = pressed
 game._unhandled_input(event)

func enter() -> void:
 var event := InputEventKey.new()
 event.keycode = KEY_ENTER
 event.pressed = true
 game._unhandled_input(event)

func advance(at: float) -> void:
 time = at
 game._process(1.0)

func capture(name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 game.refresh()
 game.queue_redraw()
 game.combat_debug.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://output/hud003_%s.png" % name)

func setup_combat(left: float=140,right: float=180,attacker: int=0,bpm: int=120) -> void:
 time += 10
 game.begin()
 game.mode = "combat"
 game.bout.positions.assign([left,right])
 game.bout.initiative = attacker
 game.conductor.start(time)
 game.conductor.bpm = bpm
 game.conductor.pending_bpm = bpm
 game.previous_bpm = bpm
 advance(time)

func action(attacker: int,height: int=0,block: int=-1,error_ms: float=0) -> void:
 var forward := "right" if game.facing(attacker)>0 else "left"
 key("p%d_%s" % [attacker+1,["high",forward,"low"][height]])
 key("p%d_execute" % (attacker+1))
 if block>=0:
  var defender := 1-attacker
  time += error_ms/1000.0
  var defense_forward := "right" if game.facing(defender)>0 else "left"
  key("p%d_%s" % [defender+1,["high",defense_forward,"low"][block]])
  key("p%d_execute" % (defender+1))
 key("p1_execute",false)
 key("p2_execute",false)

func visible_text(node: Node) -> String:
 var result := ""
 if node is Label and node.is_visible_in_tree():result += node.text+"\n"
 for child in node.get_children():result += visible_text(child)
 return result

func run() -> void:
 # One health source: scored hits reduce the opposing fighter's three segments.
 var bout := Bout.new()
 for player in range(2):
  for damage in range(4):
   bout.hits = [0,0]
   bout.hits[1-player] = damage
   check(bout.energy_remaining(player)==3-damage,"Energy derives from opponent's scored hits")
   check(bout.energy_remaining(1-player)==3,"Attacker's own bar is unchanged")
 var progress := MatchProgress.new()
 progress.reset(3)
 check(progress.wins_needed()==2,"Best of three requires two round wins")
 check(not progress.next_round(),"Cannot skip an unresolved round")
 check(progress.award_round(0),"First round awards Red")
 check(not progress.award_round(0) and progress.round_wins==[1,0],"Round awards are idempotent")
 check(progress.winner==-1 and progress.next_round() and progress.round_number==2,"One win is not a match victory")
 progress.award_round(1)
 check(progress.round_wins==[1,1] and progress.winner==-1,"Split rounds preserve both markers")
 progress.next_round()
 progress.award_round(0)
 check(progress.winner==0 and progress.round_wins==[2,1],"Two wins decide the match")
 check(not progress.next_round() and not progress.award_round(1),"Completed match cannot add rounds or score")
 progress.reset(5)
 check(progress.wins_needed()==3 and progress.round_wins==[0,0],"Best-of format is configurable and resets markers")
 for bpm in [120,140,160]:
  var d := 60.0/float(bpm)
  var cue := d*7
  for index in range(3):
   check(HUDPresenter.countdown(cue-d*(3-index),cue,d)==str(3-index),"Countdown number aligns with musical boundary")
  check(HUDPresenter.countdown(cue-3*d-0.001,cue,d)=="","Anticipation before final count stays unnumbered")
  check(HUDPresenter.countdown(cue,cue,d)=="GO!","GO is exactly the authoritative cue")
  check(HUDPresenter.countdown(cue+0.35,cue,d)=="","GO clears after its short accent")
 game = load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.game_mode="pvp"
 game.conductor.clock_override = func():return time
 root.add_child(game)
 game.set_process(false)
 check(game.hud.visible and not game.label.visible and not game.detail.visible and not game.input_feedback_label.visible,"Default HUD hides all old diagnostics")
 check(game.hud.size==Vector2(320,180),"HUD uses viewport Control layout")
 check(game.hud.red.position==Vector2(5,5) and game.hud.blue.position==Vector2(219,5),"Player cards are symmetrical and anchored")
 check(game.hud.red.energy==3 and game.hud.blue.energy==3,"Both energy bars start full")
 check(game.hud.red.title.text=="RED" and game.hud.blue.title.text=="BLUE","Player identities are readable names")
 var normal := visible_text(game).to_lower()
 for raw in ["latency",".wav","phrase","standoff","combat","whiff","select"]:
  check(not normal.contains(raw),"Default HUD does not expose raw diagnostics: "+raw)
 for player in range(2):
  check(game.fighters[player].scale==Vector2.ONE and not game.fighters[player].sprite.flip_h,"HUD does not change fighter scale/facing")
 await capture("menu")
 # Countdown from the playable scene; false start still forfeits initiative and no energy.
 game.max_anticipation_phrases=1
 game.begin()
 var cue: float = game.cue
 for index in range(3):
  advance(cue-(3-index)*0.5)
  check(game.hud.major_label.text==str(3-index),"Actual scene presents conductor count")
  check(game.hud.instruction_label.text=="GET READY TO GRAB YOUR STICK!","Anticipation instruction")
  await capture("count_%d" % (3-index))
 time=cue-0.001
 key("p1_execute")
 key("p1_execute",false)
 check(game.bout.false_starts[0],"Before-GO race execution remains a false start")
 advance(cue)
 check(game.hud.major_label.text=="GO!" and game.hud.instruction_label.text=="GRAB YOUR STICK!","GO coincides with authoritative race cue")
 check(game.bout.initiative==1 and game.hud.red.energy==3 and game.hud.blue.energy==3,"False-start race loss awards no damage")
 check(game.match_progress.round_wins==[0,0],"Race wins award no round markers")
 await capture("go")
 advance(cue+0.36)
 check(game.hud.major_label.text=="","Centre clears so the race/pickup stays visible")
 # Reach/defence outcomes retain energy except clean hits, for both players.
 for attacker in range(2):
  for kind in ["HIT","BLOCK","PARRY","WHIFF"]:
   setup_combat(30 if kind=="WHIFF" else 140,290 if kind=="WHIFF" else 180,attacker)
   var target: float = game.conductor.action_time()
   advance(target)
   action(attacker,0,-1 if kind=="HIT" else 0,90 if kind=="BLOCK" else 0)
   advance(target+0.241)
   check(game.bout.last_event.get("kind")==kind,"Expected authoritative outcome for HUD")
   var energy: Array[int]=[3,3]
   if kind=="HIT":energy[1-attacker]=2
   check(game.hud.red.energy==energy[0] and game.hud.blue.energy==energy[1],"Only correct victim loses a segment")
   check(game.hud.red.wins==0 and game.hud.blue.wins==0,"An exchange alone never awards a round")
   check(game.hud.outcome_label.text==("PERFECT PARRY!" if kind=="PARRY" else ("MISS!" if kind=="WHIFF" else ("HIGH BLOCK!" if kind=="BLOCK" else ("RED" if attacker==0 else "BLUE")+" HIGH HIT!"))),"Attack result uses player-facing language")
   await capture("%s_p%d" % [kind.to_lower(),attacker+1])
   advance(target+0.9)
   check(game.hud.outcome_label.text=="","Temporary combat messages clear")
 # All four beats: movement first, then post-movement beat-four snapshot.
 for bpm in [120,140,160]:
  setup_combat(100,156,0,bpm)
  var target: float = game.conductor.action_time()
  var original: float = game.bout.positions[0]
  time=target-0.1
  key("p1_right")
  action(0)
  check(game.bout.positions[0]==original,"Early combo never moves immediately")
  advance(target)
  check(game.bout.positions[0]==original+Bout.STEP,"Held forward moves on beat four even with combat combination")
  advance(target+0.161)
  check(game.bout.impact_positions==game.bout.positions,"Range snapshot occurs after both movements and collision limits")
  check(game.bout.in_reach(0,0,game.bout.impact_positions),"Beat-four advance can legitimately establish reach")
  advance(target+0.241)
  check(game.bout.last_event.get("kind")=="HIT","Combat evaluates the frozen post-movement contact")
  setup_combat(100,156,0,bpm)
  target=game.conductor.action_time()
  advance(target)
  advance(target+0.161)
  key("p1_right")
  action(0)
  check(game.bout.positions[0]==100,"Out-of-window movement cannot alter frozen range")
  game.bout.positions.assign([140.0,180.0]) # simulate any later state/render change
  advance(target+0.241)
  check(game.bout.last_event.get("kind")=="WHIFF","Late movement/state cannot exploit already-sampled range")
 # F3 toggles only presentation; normal controls never consume gameplay input.
 var before: Array = game.bout.positions.duplicate()
 var f3 := InputEventKey.new()
 f3.keycode=KEY_F3
 f3.pressed=true
 game._unhandled_input(f3)
 advance(time)
 check(not game.hud.visible and game.detail.visible and game.input_feedback_label.visible and game.combat_debug.visible,"F3 reveals developer-only layer")
 check(game.bout.positions==before,"Debug HUD cannot move fighters")
 await capture("debug")
 game._unhandled_input(f3)
 advance(time)
 check(game.hud.visible and not game.detail.visible,"F3 restores clean arcade HUD")
 game.help_visible=true
 game.refresh()
 check(game.hud.help_panel.visible,"Player-facing help remains available")
 await capture("help")
 game.help_visible=false
 # Complete best-of-three matches for either champion, with proper next-round/rematch resets.
 for champion in range(2):
  time+=10
  game.begin()
  for round_index in range(2):
   var round_cue: float=game.cue
   advance(round_cue+0.08)
   key("p%d_execute" % (champion+1))
   key("p%d_execute" % (champion+1),false)
   time+=0.04
   key("p%d_execute" % (2-champion))
   key("p%d_execute" % (2-champion),false)
   advance(time)
   advance(game.conductor.epoch)
   var start: float=game.conductor.epoch
   time=start+0.1
   key("p1_right")
   key("p2_left")
   for offset in [0.5,1.0]:
    advance(start+offset)
    key("p1_right",false)
    key("p2_left",false)
    key("p1_right")
    key("p2_left")
   for hit in range(3):
    var target: float=game.conductor.action_time()
    advance(target)
    action(champion,0,2)
    advance(target+0.241)
    var victim_energy: int=game.bout.energy_remaining(1-champion)
    check(victim_energy==2-hit,"Clean hit drains one of the three authoritative energy segments")
    check(game.hud.red.energy==(3 if champion==0 else victim_energy) and game.hud.blue.energy==(victim_energy if champion==0 else 3),"Damage appears on correct card immediately")
    if hit<2:
     check(game.match_progress.round_wins[champion]==round_index,"Markers do not update before third clean hit")
     advance(game.conductor.phrase_start+game.conductor.duration()*4)
   check(game.mode=="finishing" and game.match_progress.round_wins[champion]==round_index+1,"Third hit awards one round marker immediately")
   game.resolve_exchange()
   check(game.match_progress.round_wins[champion]==round_index+1,"Repeated resolution never duplicates round markers")
   await create_timer(0.95).timeout
   game.refresh()
   if round_index==0:
    check(game.mode=="round_win" and game.match_progress.winner==-1,"First victory is a round, not a match")
    check(game.hud.major_label.text.contains("ROUND WON!"),"Round victory is clearly announced")
    await capture("round_won_p%d" % (champion+1))
    enter()
    check(game.mode=="standoff" and game.hud.red.energy==3 and game.hud.blue.energy==3,"Next round resets energy")
    check(game.match_progress.round_wins[champion]==1 and game.match_progress.round_number==2,"Next round preserves win markers")
    advance(game.race_deadline+0.01)
    check(game.mode=="standoff" and game.match_progress.round_wins[champion]==1 and game.match_progress.round_number==2,"Unanswered race retries preserve the current match score")
   else:
    check(game.mode=="match_win" and game.match_progress.winner==champion,"Two round victories secure best-of-three")
    check(game.hud.major_label.text.contains("CHAMPION!"),"Match victory differs from round victory")
    await capture("champion_p%d" % (champion+1))
    enter()
    check(game.mode=="standoff" and game.match_progress.round_wins==[0,0] and game.match_progress.round_number==1,"Rematch resets match markers and round number")
 print("ARCADE HUD TESTS: %d checks, %d failures" % [checks,failures])
 game.conductor.clock_override=Callable()
 game.queue_free()
 quit(0 if failures==0 else 1)
