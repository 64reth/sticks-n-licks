extends SceneTree
var game: Node2D
var raw:=0.0
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func advance(at: float) -> void:
 raw=at+game.conductor.pause_offset
 game._process(0)
func counted(event: String) -> int:
 return game.audio.events.trace.filter(func(row):return row.event==event).size()
func fresh(mode: String="pvp") -> void:
 game.game_mode=mode
 game.begin()
 game.mode="combat"
 game.bout.positions.assign([138.0,182.0])
 game.conductor.start(0)
 raw=1.5+game.conductor.pause_offset
 game.conductor.update(1.5)
 game.cpu.queue.clear()
 game.cpu.parameters.hesitate=1.0
 game.cpu.parameters.retreat=0.0
 game.audio.events.trace.clear()
func fixture(kind: String,height: int,attacker: int) -> void:
 fresh()
 game.bout.initiative=attacker
 var defender:=1-attacker
 game.bout.selections[attacker]=height
 game.bout.selections[defender]=-1 if kind=="HIT" else height
 game.selected.assign(game.bout.selections)
 game.bout.errors[attacker]=0
 game.bout.errors[defender]=100 if kind=="BLOCK" else 0
 raw=1.741+game.conductor.pause_offset
 game.resolve_exchange()
func run() -> void:
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return raw
 root.add_child(game)
 game.set_process(false)
 var events: AudioEvents=game.audio.events
 check(events.voices.size()==4,"Bounded three SFX / one UI pool")
 check(AudioServer.get_bus_send(AudioServer.get_bus_index("UI"))=="SFX","UI respects SFX preferences via bus routing")
 var expected: Array=["menu_navigate","menu_confirm","menu_back","swing","hit","block","parry","pickup","countdown","go","round_victory","round_defeat","match_victory","match_defeat"]
 for name in expected:
  check(events.config.events.has(name),"Configured audio event "+name)
  events.last.clear()
  var before:=events.trace.size()
  var plays:=events.emit_event(name,"unit:"+name)
  check(events.trace.size()==before+1,"Each event records once: "+name)
  check(plays==(name in ["menu_navigate","menu_confirm","menu_back","swing","hit","block","parry","pickup"]),"Only refined-scope effects play: "+name)
  events.emit_event(name,"unit:"+name)
  check(events.trace.size()==before+1,"Duplicate event key suppressed: "+name)
 check(float(events.config.events.menu_back.pitch_end)<float(events.config.events.menu_back.pitch),"Back tone has a configurable descending pitch envelope")
 check(events.streams.hit!=events.streams.block and events.streams.block!=events.streams.parry,"Distinct impact resources")
 for i in range(40):
  events.last.clear()
  events.emit_event("hit","stress:%d" % i)
  check(events.active_voices("SFX")<=3,"SFX polyphony stays bounded")
 events.last.clear()
 events.emit_event("pickup","pickup:a")
 events.emit_event("pickup","pickup:b")
 check(events.trace.back().status=="coalesced","Simultaneous pickups avoid duplicate layering")
 for kind in ["HIT","BLOCK","PARRY"]:
  for attacker in range(2):
   for height in range(3):
    fixture(kind,height,attacker)
    check(game.bout.last_event.kind==kind,"Resolved event fixture")
    check(counted(kind.to_lower())==1 and counted("swing")==1,"One resolved impact + subtle swing")
    var impact: Dictionary=events.trace.filter(func(row):return row.event==kind.to_lower())[0]
    check(is_equal_approx(float(impact.at),game.impact_effect.started),"Sound and visual burst share resolved contact time")
    for other in ["hit","block","parry"]:
     if other!=kind.to_lower():check(counted(other)==0,"No wrong impact sound")
    var damage: Array=game.bout.hits.duplicate()
    var initiative: int=game.bout.initiative
    game.resolve_exchange()
    check(counted(kind.to_lower())==1 and game.bout.hits==damage and game.bout.initiative==initiative,"No duplicate audio, damage or initiative")
 fresh()
 game.submit_action(0,"high",true,1.5)
 game.submit_action(0,"execute",true,1.5)
 check(counted("hit")==0 and counted("swing")==0,"Input alone cannot play speculative combat audio")
 advance(1.741)
 check(counted("hit")==1,"Validated action sounds only on resolution")
 for reason in ["range","timing","missing"]:
  fresh()
  game.bout.selections.assign([0,-1] if reason!="missing" else [-1,-1])
  game.selected.assign(game.bout.selections)
  game.bout.errors.assign([141.0,INF] if reason=="timing" else [0.0,INF])
  if reason=="range":game.bout.positions.assign([100.0,220.0])
  raw=1.741+game.conductor.pause_offset
  game.resolve_exchange()
  check(counted("hit")==0 and counted("block")==0 and counted("parry")==0,"No success sound for "+reason+" miss")
  check(counted("swing")==int(reason=="range"),"Only a valid out-of-range swing gets whoosh")
 # Both pickup orders and automatic pickup use accepted race state, never a press alone.
 for order in [[0,1],[1,0]]:
  game.game_mode="pvp"
  game.begin()
  raw=game.cue+0.1+game.conductor.pause_offset
  game.mode="race"
  events.trace.clear()
  game.submit_action(order[0],"execute",true,game.cue+0.1)
  check(counted("pickup")==1,"First accepted pickup")
  raw+=0.1
  game.submit_action(order[1],"execute",true,game.cue+0.2)
  game._process(0)
  check(counted("pickup")==2,"Both owners collect exactly once")
  game._process(0)
  check(counted("pickup")==2,"Automatic pickup cannot duplicate accepted pickups")
 # Ordinary rounds auto-advance identically in CPU/PvP, with a frozen logical deadline.
 for mode in ["pvp","cpu"]:
  for winner in range(2):
   fresh(mode)
   game.bout.initiative=winner
   game.bout.hits[winner]=2
   game.submit_action(winner,"high",true,1.5,"cpu" if mode=="cpu" and winner==1 else "human")
   game.submit_action(winner,"execute",true,1.5,"cpu" if mode=="cpu" and winner==1 else "human")
   advance(1.741)
   check(game.mode=="finishing" and game.match_progress.round_wins[winner]==1,"Third hit awards one round")
   advance(game.transition_until+0.001)
   check(game.mode=="round_win" and game.match_progress.winner<0,"Ordinary result phase")
   check(game.fighters[winner].pose=="victory" and game.fighters[1-winner].pose=="defeat" and not game.fighters[winner].final_locked,"Non-final winner/loser reactions preserved")
   var deadline: float=game.round_transition_at
   check(is_equal_approx(deadline-game.conductor.now(),2.5),"Configured 2.5 second result display")
   var history: Array=game.cpu.history.duplicate()
   MenuTestInput.key(game,KEY_ENTER)
   check(game.mode=="round_win" and game.round_transition_at==deadline,"Enter neither required nor skips result")
   game.submit_action(0,"execute",true,game.conductor.now())
   game.submit_action(0,"right",true,game.conductor.now())
   advance(deadline-0.001)
   game.set_paused(true)
   var frozen: float=game.conductor.now()
   raw+=40
   game._process(0)
   check(game.mode=="round_win" and game.round_transition_at==deadline and game.conductor.now()==frozen,"Pause freezes auto transition")
   events.last.clear()
   var ui_count:=counted("menu_navigate")
   game.audio.emit_event("menu_navigate")
   check(counted("menu_navigate")==ui_count+1,"Pause menus remain audible")
   game.set_paused(false)
   advance(deadline)
   check(game.mode=="standoff" and game.match_progress.round_number==2,"Automatic next countdown without Enter")
   check(game.match_progress.round_wins[winner]==1 and game.bout.hits==[0,0],"Score persists, energy resets")
   check(game.bout.positions==[100.0,220.0] and game.ground_sticks.state==GroundSticks.State.BOTH_ON_GROUND,"Positions and sticks reset")
   check(game.fighters[0].position==Vector2(100,150) and game.fighters[1].position==Vector2(220,150),"Actors ready before new countdown")
   check(game.cue>game.conductor.now() and is_equal_approx(game.conductor.epoch,deadline),"Fresh musical phrase origin; no countdown/combat overlap")
   check(game.cpu.history==history,"CPU learning survives auto round")
   check(game.controls[0].held.is_empty() and is_inf(game.controls[0].pending_execute),"No held/pending controls leak")
   game._process(0)
   check(game.match_progress.round_number==2,"Only one automatic transition")
   fresh(mode)
   game.match_progress.round_wins[winner]=1
   game.bout.initiative=winner
   game.bout.hits[winner]=2
   game.submit_action(winner,"high",true,1.5,"cpu" if mode=="cpu" and winner==1 else "human")
   game.submit_action(winner,"execute",true,1.5,"cpu" if mode=="cpu" and winner==1 else "human")
   advance(1.741)
   advance(game.transition_until+0.001)
   check(game.mode=="match_win" and game.fighters[winner].final_locked,"Deciding match keeps explicit result screen")
   var result_count: int=game.audio.event_log.size()
   advance(game.conductor.now()+60)
   check(game.mode=="match_win" and game.match_progress.winner==winner and game.audio.event_log.size()==result_count,"Match never auto-rematches or repeats result music")
 fresh()
 game.audio.emit_event("hit","exit-cleanup")
 game.set_paused(true)
 game.round_transition_at=game.conductor.now()+2.5
 game.return_to_title()
 check(game.mode=="menu" and is_inf(game.round_transition_at) and events.active_voices("SFX")==0,"Menu exit cancels pending round and stale combat tails")
 print("MILESTONE 008: %d checks, %d failures" % [checks,failures])
 game.audio.stop()
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)
