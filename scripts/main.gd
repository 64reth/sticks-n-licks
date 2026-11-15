extends Node2D
var conductor := RhythmConductor.new()
var bout := Bout.new()
var audio := AudioDirector.new()
var fighters: Array[Fighter] = []
var mode: String = "menu"
var cue: float = 0.0
var race_deadline: float = 0.0
var anticipation_phrases: int = 1
var max_anticipation_phrases: int = 3
var cue_style: String = "snare"
var race_timeout: float = 2.0
var phrase_resolved: bool = false
var debug_visible: bool = false
var help_visible: bool = false
var status: String = ""
var label := Label.new()
var detail := Label.new()
var previous_bpm: int = 120
var settings: Dictionary = {}
var selected: Array[int] = [-1, -1]
var controls: Array[CombatInput] = [CombatInput.new(), CombatInput.new()]
var tie_priority: int = 0
var last_error: Array[float] = [INF, INF]
var pose_until: float = 0.0
var click_player := AudioStreamPlayer.new()
var click_stream: AudioStreamWAV
var metronome_enabled: bool = true

func _ready() -> void:
 Bindings.install()
 var config := FileAccess.open("res://data/combat/settings.json", FileAccess.READ)
 if config:
  settings = JSON.parse_string(config.get_as_text())
 conductor.perfect_ms = float(settings.get("perfect_ms", 70.0))
 conductor.good_ms = float(settings.get("good_ms", 140.0))
 for control in controls:
  control.combination_ms = float(settings.get("combination_ms", 100.0))
 conductor.latency_ms = float(settings.get("latency_ms", 0.0))
 max_anticipation_phrases = int(settings.get("max_anticipation_phrases", 3))
 race_timeout = float(settings.get("race_timeout_seconds", 2.0))
 cue_style = str(settings.get("cue_style", "snare"))
 audio.clock_source = conductor.now
 audio.enabled = not conductor.clock_override.is_valid()
 audio.latency_ms = float(settings.get("audio_latency_ms", 0.0))
 add_child(audio)
 metronome_enabled = not audio.tracks.has("120")
 add_child(click_player)
 click_stream = AudioStreamWAV.new()
 click_stream.format = AudioStreamWAV.FORMAT_16_BITS
 click_stream.mix_rate = 22050
 var samples := PackedByteArray()
 samples.resize(2205 * 2)
 for n in range(2205):
  var value := int(sin(n * TAU * 660.0 / 22050.0) * 7000.0 * (1.0 - n / 2205.0))
  samples.encode_s16(n * 2, value)
 click_stream.data = samples
 click_player.stream = click_stream
 for player in range(2):
  var fighter := Fighter.new()
  fighter.asset_config = "res://data/animations/fighter_0%d.json" % (player + 1)
  fighter.color = Color("f3ba55") if player == 0 else Color("66c9c8")
  add_child(fighter)
  fighter.face(1 if player == 0 else -1)
  fighter.position = Vector2(bout.positions[player], 150)
  fighters.append(fighter)
 label.position = Vector2(8, 5)
 label.add_theme_font_size_override("font_size", 12)
 add_child(label)
 detail.position = Vector2(8, 23)
 detail.add_theme_font_size_override("font_size", 8)
 add_child(detail)
 conductor.beat_changed.connect(on_beat)
 conductor.phrase_changed.connect(on_phrase)
 audio.play_track("menu", conductor.now())
 refresh()

func play_click(force: bool = false) -> void:
 if (force or metronome_enabled) and DisplayServer.get_name() != "headless":
  click_player.play()

func begin() -> void:
 bout = Bout.new()
 bout.escalation_threshold = int(settings.get("escalation_threshold", 3))
 bout.tie_priority = tie_priority
 selected = [-1, -1]
 for control in controls:
  control.reset()
 last_error = [INF, INF]
 conductor.start()
 anticipation_phrases = randi_range(1, max_anticipation_phrases)
 cue = conductor.epoch + anticipation_phrases * 2.0 + 1.5
 race_deadline = cue + race_timeout
 mode = "standoff"
 status = "Wait for GO. Early press forfeits the race."
 previous_bpm = 120
 audio.play_track("standoff", conductor.epoch, true)
 for fighter in fighters:
  fighter.set_pose("standoff_anticipation")

func _process(delta: float) -> void:
 var at := game_time()
 if mode in ["standoff", "race", "combat"]:
  conductor.update(at)
 if mode == "standoff" and at >= cue:
  mode = "race"
  status = "GO! Grab your stick"
  if cue_style == "snare":
   play_click(true)
  else:
   click_player.stop()
   audio.music.stop()
  audio.sound("race")
  for player in range(2):
   if not bout.false_starts[player]:
    fighters[player].set_pose("race_launch")
 if mode == "race":
  var both := bout.reactions[0] >= 0 and bout.reactions[1] >= 0
  var forfeited := bout.false_starts[0] or bout.false_starts[1]
  if both or forfeited or at >= race_deadline:
   var result := bout.resolve_race()
   tie_priority = bout.tie_priority
   if result < 0:
    begin()
    status = "No valid race: new three-count. Wait for GO."
   else:
    mode = "pickup"
    status = "P%d takes initiative. Both fighters collect sticks." % (result + 1)
    for fighter in fighters:
     fighter.set_pose("stick_pickup")
    var next_boundary: float = conductor.epoch + ceil((at + 0.75 - conductor.epoch) / 2.0) * 2.0
    conductor.start(next_boundary)
    phrase_resolved = false
 if mode == "pickup" and at >= conductor.epoch:
  mode = "combat"
  audio.play_track("120", conductor.epoch)
  conductor.update(at)
 if mode == "combat" and not phrase_resolved and at > conductor.action_time() + (conductor.good_ms + controls[0].combination_ms + maxf(0.0, conductor.latency_ms)) / 1000.0:
  resolve_exchange()
 for player in range(2):
  fighters[player].face(facing(player))
  var target_x := bout.positions[player]
  if mode == "pickup" or (mode == "race" and bout.reactions[player] >= 0):
   target_x = 138.0 if player == 0 else 182.0
   if mode == "race":
    fighters[player].set_pose("running")
  fighters[player].position = fighters[player].position.lerp(Vector2(target_x, 150), minf(1.0, delta * 16))
  if mode == "combat" and at > pose_until:
   fighters[player].set_pose("combat_idle")
 refresh()
 queue_redraw()

func game_time() -> float:
 if mode == "combat" and not conductor.clock_override.is_valid() and audio.tracks.has(audio.active) and audio.music.playing:
  return audio.anchor + maxf(0.0, audio.audio_time())
 return conductor.now()

func on_phrase(_phrase: int) -> void:
 if mode != "combat":
  return
 # Resolve an overdue exchange before clearing it if rendering stalled.
 if not phrase_resolved:
  resolve_exchange()
 phrase_resolved = false
 selected = [-1, -1]
 for control in controls:
  control.pending_execute = -INF
 if previous_bpm != conductor.bpm:
  audio.play_track(str(conductor.bpm), conductor.phrase_start)
  previous_bpm = conductor.bpm

func on_beat(beat: int, _phrase: int) -> void:
 if mode == "standoff":
  # Earlier anticipation phrases continue; only the final fourth beat cuts off.
  if beat <= 3 or conductor.now() < cue - 0.01:
   play_click(true)
 elif mode == "combat":
  click_player.pitch_scale = 1.5 if beat == 4 else 1.0
  play_click()
  if beat <= 3:
   var before := bout.positions.duplicate()
   for player in range(2):
    bout.movements[player] = controls[player].step(beat, _phrase)
    if bout.movements[player] != 0:
     fighters[player].rhythmic_pose("forward_step" if bout.movements[player] == facing(player) else "backward_step", conductor.duration())
   bout.move()
   for player in range(2):
    if not is_equal_approx(before[player], bout.positions[player]):
     controls[player].last_step_time = conductor.beat_time
     controls[player].last_step_processed = game_time()
   pose_until = conductor.now() + conductor.duration() * 0.85
  else:
   bout.movements = [0, 0]
   for player in range(2):
    present_combat(player)

func present_combat(player: int) -> void:
 if bout.selections[player] < 0 or conductor.grade(bout.errors[player]) == "miss":
  return
 var height: String = ["high", "mid", "low"][bout.selections[player]]
 fighters[player].impact(height + ("_attack" if bout.initiative == player else "_block"), conductor.duration() * 0.7)
 pose_until = conductor.now() + conductor.duration() * 0.85

func facing(player: int) -> int:
 return 1 if bout.positions[1 - player] > bout.positions[player] else -1

func _notification(what: int) -> void:
 if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
  for control in controls:
   control.reset()
  bout.movements = [0, 0]

func resolve_exchange() -> void:
 phrase_resolved = true
 var attack := bout.initiative
 var defense := 1 - attack
 var direction := maxi(0, selected[attack])
 var height: String = ["high", "mid", "low"][direction]
 status = bout.resolve(conductor)
 pose_until = conductor.now() + 0.35
 if status.begins_with("Perfect"):
  fighters[defense].parry(height, conductor.duration() * 0.5)
  audio.sound("parry")
 elif status.begins_with("Blocked"):
  audio.sound("block")
 elif status.begins_with("Clean") or bout.winner >= 0:
  fighters[defense].set_pose(height + "_hit")
  fighters[defense].hit_feedback()
  audio.sound("hit")
 if bout.winner >= 0:
  mode = "finishing"
  audio.schedule_track("victory", conductor.phrase_start + conductor.duration() * 4.0)
  finish_victory(bout.winner)

func finish_victory(player: int) -> void:
 await get_tree().create_timer(0.45).timeout
 fighters[1 - player].set_pose("knockdown")
 await get_tree().create_timer(0.45).timeout
 fighters[player].set_pose("victory")
 fighters[1 - player].set_pose("defeat")
 mode = "victory"

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.echo:
  return
 if event is InputEventKey and event.pressed:
  if event.keycode == KEY_F3:
   debug_visible = not debug_visible
  if event.keycode == KEY_H:
   help_visible = not help_visible
  if event.keycode == KEY_ESCAPE:
   if mode != "finishing":
    mode = "menu"
    conductor.started = false
    audio.play_track("menu", conductor.now())
   return
  if event.keycode == KEY_C and mode == "menu":
   cue_style = "cutoff" if cue_style == "snare" else "snare"
  if event.keycode == KEY_ENTER and mode in ["menu", "victory"]:
   begin()
   return
 for player in range(2):
  var prefix := "p%d_" % (player + 1)
  if mode in ["standoff", "race"] and event.is_action_pressed(prefix + "execute"):
   bout.race_press(player, conductor.now(), cue)
   if bout.false_starts[player]:
    fighters[player].set_pose("false_start")
    status = "P%d false start: forfeits initiative" % (player + 1)
  if mode != "combat":
   continue
  # Advance old held state through crossed beats BEFORE applying this event.
  # A press between frames cannot be applied retroactively to an earlier beat.
  var at := game_time()
  conductor.update(at)
  if mode != "combat":
   continue
  for action in ["left", "right", "high", "low", "execute"]:
   if not event.is_action(prefix + action):
    continue
   var combination := controls[player].feed(action, event.is_action_pressed(prefix + action), at, facing(player))
   if combination.is_empty() or phrase_resolved or not is_inf(bout.errors[player]):
    continue
   var error := (conductor.timestamp(combination["execute_at"]) - conductor.action_time()) * 1000.0
   bout.errors[player] = error
   bout.selections[player] = combination["height"]
   selected[player] = combination["height"]
   last_error[player] = error
   if conductor.grade(error) != "miss":
    controls[player].suppress_movement()
    bout.movements[player] = 0
    if at >= conductor.action_time():
     present_combat(player)
    else:
     var height: String = ["high", "mid", "low"][bout.selections[player]]
     fighters[player].prepare(height + ("_attack" if bout.initiative == player else "_block"), conductor.action_time() - at)
     pose_until = conductor.now() + conductor.duration()

func refresh() -> void:
 label.text = "STICKS N LICKS     %d BPM" % conductor.bpm
 if help_visible:
  detail.text = "P1: A/D move · W high · S low · F execute\nP2: arrows move/high/low · RShift execute\nForward + execute = MID (facing-relative)\nHold to step on beats 1-3; beat 4 = combat\nPerfect ±70ms · valid ±140ms · combo 100ms\nH help · F3 debug · Esc menu"
 elif mode == "menu":
  detail.text = "LOCAL VERSUS · Enter to start · H controls
C cue style: %s · F3 rhythm overlay" % cue_style
 else:
  detail.text = "%s · Beat %d · P%d attacks
P1 %d/3 hits   P2 %d/3 hits
%s" % [mode.to_upper(), conductor.beat, bout.initiative + 1, bout.hits[0], bout.hits[1], status]
  if mode == "victory":
   detail.text += "
Enter rematch · Esc menu"
 if debug_visible:
  detail.text += "\nPhrase %d err %s sel %s" % [conductor.phrase, "[%+.0f,%+.0f]" % last_error, str(selected)]
  detail.text += "\nQueue %s beat %d · step grid/actual:" % [str([controls[0].movement(), controls[1].movement()]), conductor.beat]
  for player in range(2):
   var control := controls[player]
   var stamp := "--/--" if is_inf(control.last_step_time) else "%.3f/%.3fs" % [control.last_step_time, control.last_step_processed]
   detail.text += "\nP%d %s" % [player + 1, stamp]
  detail.text += "\n%s\nBeat %d phase %s · next BPM %d" % [audio.diagnostic(), conductor.beat, mode, conductor.pending_bpm]

func _draw() -> void:
 draw_rect(Rect2(0, 0, 320, 180), Color("151e29"))
 draw_rect(Rect2(0, 150, 320, 30), Color("343b39"))
 draw_line(Vector2(16, 150), Vector2(304, 150), Color("aeaa7a"), 1)
 for player in range(2):
  for hit in range(3):
   var x := 27 + player * 238 + hit * 9
   draw_rect(Rect2(x, 80, 5, 5), Color("f3ba55") if hit < bout.hits[player] else Color("596066"))
 for n in range(4):
  draw_circle(Vector2(139 + n * 14, 172), 3, Color("f3ba55") if conductor.beat == n + 1 else Color("596066"))
 if mode in ["standoff", "race", "menu"]:
  draw_line(Vector2(145, 144), Vector2(175, 126), Color("d9bc85"), 2)
  draw_line(Vector2(145, 126), Vector2(175, 144), Color("d9bc85"), 2)
