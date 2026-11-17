extends SceneTree
var checks:=0
var failures:=0
var raw:=0.0
var game: Node2D
func _initialize() -> void:call_deferred("run")
func check(ok: bool,why: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(why)
func tick(at: float) -> void:
 raw=at+game.conductor.pause_offset
 game._process(0)
func tap(player: int,action: String,at: float) -> void:
 game.submit_action(player,action,true,at)
 game.submit_action(player,action,false,at)
func match_fixture(winner: int) -> void:
 # Two actual three-hit rounds, through the unchanged action/race/range adapters.
 # Explicit PvP fixture isolates match lifecycle from CPU randomness (900 CPU matches run separately).
 game.cpu.queue.clear()
 game.game_mode="pvp"
 var first_round_checked:=false
 for guard in range(500):
  if game.mode=="match_win":break
  if game.mode in ["standoff","race"]:
   tick(game.cue+.01)
   tap(winner,"execute",raw)
   tap(1-winner,"execute",raw+.03)
   tick(raw+.05)
  elif game.mode=="pickup":tick(game.story.fight_due)
  elif game.mode=="combat":
   tick(game.conductor.beat_time+game.conductor.duration())
   if absf(game.bout.positions[1]-game.bout.positions[0])>game.bout.stick_reach:tap(winner,"right" if winner==0 else "left",raw)
   if game.conductor.beat==4:
    game.submit_action(winner,"high",true,raw)
    tap(winner,"execute",raw)
    game.submit_action(winner,"high",false,raw)
    tick(raw+.25)
  elif game.mode=="finishing":tick(game.transition_until+.001)
  elif game.mode=="round_win":
   if not first_round_checked:
    check(game.match_progress.round_wins[winner]==1 and game.match_progress.winner==-1,"One round is not a match win")
    check(game.story.wallet.money==5,"No reward at one round")
    check(not game.story.quest.finished(),"Quest stays active at one round")
    first_round_checked=true
   tick(game.round_transition_at+.001)
 check(game.mode=="match_win" and game.match_progress.round_wins[winner]==2,"Existing best-of-three resolves two round wins")
func run() -> void:
 var wallet:=StoryWallet.new()
 check(wallet.target()==100 and wallet.campaign.provisional,"Data-backed provisional BDS100 target")
 check(wallet.campaign.encounters.first_stick_fight.reward==20,"Encounter data configures reward")
 check(wallet.grant("crate_delivery",5) and wallet.grant("fight_first",20),"Job plus completed fight gives cash")
 check(wallet.money==25 and not wallet.grant("fight_first",20),"Reward idempotency")
 wallet.campaign.rent_target=25
 check(wallet.ready_to_pay(),"Target changes to return-home objective without payment")
 wallet.campaign.rent_target=150
 wallet.campaign.encounters.first_stick_fight.reward=30
 check(wallet.target()==150 and wallet.reward_amount("fight_first")==30,"Economy easily rebalanced through data")
 check(wallet.total_for(wallet.rewards,wallet.amounts)==25,"Rebalancing future rewards preserves historical cash ledger")
 var dialogue:=StoryDialogue.new()
 var speech_count:=0
 for id in dialogue.definitions:
  for line in dialogue.definitions[id]:
   speech_count+=1
   check(line.type=="speech" and not str(line.speaker).is_empty(),"Only typed character speech in resources")
   for forbidden in ["Versus","exchanges","progress and money","[TEMP]","Quest complete","Use the same controls"]:
    check(not str(line.text).contains(forbidden),"No technical/stage/reward notification text in speech")
 check(speech_count==14,"All fourteen spoken lines audited")
 dialogue.definitions["system_fixture"]=[{"type":"notification","speaker":"SYSTEM","text":"Not speech"}]
 dialogue.begin("system_fixture")
 check(not dialogue.active(),"Non-speech channel cannot enter dialogue renderer")
 var obstacles:=StoryObstacles.new()
 obstacles.traffic=JSON.parse_string(FileAccess.get_file_as_string("res://data/story/traffic_013.json"))
 check(obstacles.traffic.vehicle_width==64 and obstacles.traffic.vehicle_length==110,"Vehicle is larger than 64px fighter height")
 check(obstacles.traffic.lane_width==88 and obstacles.traffic.section_width==320,"Broad two-section fixed camera design")
 var patterns: Dictionary={}
 for i in range(4):
  var lane: Dictionary=obstacles.traffic.lanes[i]
  patterns[lane.cycle]=true
  check(int(lane.direction)==(1 if i<2 else -1),"Two lanes in each direction")
 check(patterns.size()==4,"Independent lane cycles")
 for road in range(2):
  var starts:=0
  var collisions:=0
  var worst:=0
  var waiting:=0
  for beat in range(6720):
   if not obstacles.can_start_road(road,beat):
    waiting+=1
    worst=maxi(worst,waiting)
    continue
   waiting=0
   starts+=1
   for step in range(16):
    for sub in range(5):
     var fraction:=float(sub)/4
     var x:=36+step*16+16*clampf(fraction/.32,0,1)
     if obstacles.road_collision(beat+step+fraction,x,road):collisions+=1
  check(starts>0 and worst<120,"Safe starts repeat throughout full 6720-beat traffic cycle")
  check(collisions==0,"Every CROSS invitation permits all sixteen approved 16px steps")
  print("ROAD ",road," safe starts=",starts," worst wait=",worst)
 game=load(ProjectSettings.get_setting("application/run/main_scene")).instantiate()
 game.preferences_path=""
 game.conductor.clock_override=func():return raw
 root.add_child(game)
 game.set_process(false)
 game.open_main_menu()
 var story: StorySession=game.story
 story.start(true)
 story.dialogue.clear()
 story.finish_cinematic()
 tick(.5)
 for event in ["village_entered","vendor_spoken","crate_picked","road_crossed","crate_delivered","delivery_paid","cane_road_entered","cane_cleared","stick_picked"]:story.quest.emit_event(event)
 story.inventory.item="stick"
 story.wallet.grant("crate_delivery",5)
 story.enter_screen(6)
 var epoch: float=game.conductor.epoch
 var restarts: int=game.audio.restart_count
 story.start_fight()
 check(game.match_progress.best_of==3 and game.mode=="standoff","Story enters existing best-of-three countdown")
 check(game.game_mode=="cpu" and game.cpu.difficulty=="easy","Existing production CPU configured from encounter")
 var sampled:=story.match_position(0,Vector2(138,150))
 check(sampled==story.match_position(0,Vector2(138,150)),"Render sampling at one conductor phase is deterministic")
 check(not story.overlay.visible and game.hud.visible,"Exploration HUD yields to full ArcadeHUD")
 check(game.hud.state.energy==[3,3] and game.hud.state.wins_needed==2,"Three energy segments and best-of-three markers")
 story.finish_fight(0)
 check(story.wallet.money==5,"Premature match-result callback cannot award cash")
 match_fixture(1)
 check(story.wallet.money==5 and not story.quest.finished(),"Defeat grants no reward and preserves checkpoint")
 check(game.conductor.epoch==epoch and game.audio.restart_count==restarts,"Defeat and rounds do not restart conductor/music")
 story.return_from_match()
 check(story.phase=="playing" and story.overlay.visible and not game.hud.visible,"Exploration HUD restored on result acknowledgement")
 check(story.dialogue.line().id=="fight_lost","Retry dialogue is spoken character line")
 story.dialogue.clear()
 story.start_fight()
 match_fixture(0)
 check(story.wallet.money==25 and story.wallet.rewards==["crate_delivery","fight_first"],"Only completed match grants BDS20 once")
 check(story.quest.finished() and not story.wallet.ready_to_pay(),"First quest complete while campaign rent remains unpaid")
 story.finish_fight(0)
 check(story.wallet.money==25,"Duplicate resolved callback cannot repay")
 var result_beat: float=story.absolute_beat()
 tick(raw+1.25)
 check(is_equal_approx(story.absolute_beat()-result_beat,2.5),"Conductor continues during victory screen")
 check(game.audio.event_log.size()==2,"Original defeat and victory result presentation each plays once")
 check(game.conductor.epoch==epoch and game.audio.restart_count==restarts,"Full win preserves continuous conductor and music")
 story.return_from_match()
 check(story.phase=="playing" and story.overlay.visible and not game.hud.visible,"Winning restores exploration HUD and active campaign")
 check(story.overlay.rent_progress()=="RENT $25 / $100","Rent HUD reports measured progress")
 story.wallet.money=100
 check(story.campaign_objective()=="Return home and pay the rent. (Upcoming)" and story.phase=="playing","Target reached prompts future payment without artificial game-over")
 story.wallet.money=25
 var disk:=StorySave.new()
 disk.path="res://output/013-save-test.json"
 story.persist()
 disk.data=story.save.data.duplicate(true)
 disk.write()
 check(disk.load_progress() and disk.data.money==25 and disk.data.rent_target==100,"Target/cash/rewards save round trip")
 game.return_to_title()
 story.save.data=disk.data.duplicate(true)
 story.start(false)
 tick(raw+.5)
 check(story.wallet.money==25 and story.wallet.rewards.has("fight_first"),"Continue never grants claimed reward again")
 story.request_exit()
 check(story.phase=="playing" and story.quest.notification.contains("upcoming"),"End-of-slice boundary identifies future content, never an impossible unfinished objective")
 disk.data.money=45
 disk.write()
 check(not disk.load_progress(),"Inconsistent cash ledger rejected")
 DirAccess.remove_absolute(ProjectSettings.globalize_path(disk.path))
 game.queue_free()
 await process_frame
 print("STORY 013: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
