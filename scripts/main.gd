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
var selected: Array[int] = [1, 1]
var tie_priority: int = 0
var last_error: Array[float] = [INF, INF]
var pose_until: float = 0.0
var click_player := AudioStreamPlayer.new()
var click_stream: AudioStreamWAV

func _ready() -> void:
 Bindings.install()
 var config := FileAccess.open("res://data/combat/settings.json", FileAccess.READ)
 if config:
  settings = JSON.parse_string(config.get_as_text())
 conductor.perfect_ms = float(settings.get("perfect_ms", 60.0))
 conductor.good_ms = float(settings.get("good_ms", 130.0))
 conductor.latency_ms = float(settings.get("latency_ms", 0.0))
 max_anticipation_phrases = int(settings.get("max_anticipation_phrases", 3))
 race_timeout = float(settings.get("race_timeout_seconds", 2.0))
 cue_style = str(settings.get("cue_style", "snare"))
 add_child(audio)
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
  fighter.sprite.flip_h = player == 1
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

func play_click() -> void:
 if DisplayServer.get_name() != "headless":
  click_player.play()

func begin() -> void:
 bout = Bout.new()
 bout.escalation_threshold = int(settings.get("escalation_threshold", 3))
 bout.tie_priority = tie_priority
 selected = [1, 1]
 last_error = [INF, INF]
 conductor.start()
 anticipation_phrases = randi_range(1, max_anticipation_phrases)
 cue = conductor.epoch + anticipation_phrases * 2.0 + 1.5
 race_deadline = cue + race_timeout
 mode = "standoff"
 status = "Wait for GO. Early press forfeits the race."
 previous_bpm = 120
 audio.play_track("standoff", conductor.epoch)
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
   play_click()
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
    conductor.start(at + 0.75)
    phrase_resolved = false
 if mode == "pickup" and at >= conductor.epoch:
  mode = "combat"
  audio.play_track("120", conductor.epoch)
  conductor.update(at)
 if mode == "combat" and not phrase_resolved and at > conductor.action_time() + conductor.good_ms / 1000.0:
  resolve_exchange()
 for player in range(2):
  var target_x := bout.positions[player]
  if mode == "pickup" or (mode == "race" and bout.reactions[player] >= 0):
   target_x = 138.0 if player == 0 else 182.0
   if mode == "race":
    fighters[player].set_pose("running")
  fighters[player].position = fighters[player].position.lerp(Vector2(target_x, 120), minf(1.0, delta * 16))
  if mode == "combat" and at > pose_until:
   fighters[player].set_pose("combat_idle")
 refresh()
 queue_redraw()

func game_time() -> float:
 if mode == "combat" and audio.tracks.has(audio.active) and audio.music.playing:
  return audio.anchor + maxf(0.0, audio.audio_time())
 return conductor.now()

func on_phrase(_phrase: int) -> void:
 if mode != "combat":
  return
 # Resolve an overdue exchange before clearing it if rendering stalled.
 if not phrase_resolved:
  resolve_exchange()
 phrase_resolved = false
 if previous_bpm != conductor.bpm:
  audio.play_track(str(conductor.bpm), conductor.phrase_start)
  previous_bpm = conductor.bpm

func on_beat(beat: int, _phrase: int) -> void:
 if mode == "standoff":
  # Earlier anticipation phrases continue; only the final fourth beat cuts off.
  if beat <= 3 or conductor.now() < cue - 0.01:
   play_click()
 elif mode == "combat":
  click_player.pitch_scale = 1.5 if beat == 4 else 1.0
  play_click()
  if beat <= 3:
   for player in range(2):
    if bout.movements[player] != 0:
     fighters[player].set_pose("forward_step" if bout.movements[player] == (1 if player == 0 else -1) else "backward_step")
   bout.move()
   pose_until = conductor.now() + 0.16

func resolve_exchange() -> void:
 phrase_resolved = true
 var attack := bout.initiative
 var defense := 1 - attack
 var direction := selected[attack]
 var height: String = ["high", "mid", "low"][direction]
 status = bout.resolve(conductor)
 pose_until = conductor.now() + 0.35
 fighters[attack].set_pose(height + "_attack")
 if status.begins_with("Perfect"):
  fighters[defense].set_pose(height + "_parry")
  audio.sound("parry")
 elif status.begins_with("Blocked"):
  fighters[defense].set_pose(height + "_block")
  audio.sound("block")
 elif status.begins_with("Clean") or bout.winner >= 0:
  fighters[defense].set_pose(height + "_hit")
  audio.sound("hit")
 if bout.winner >= 0:
  mode = "finishing"
  finish_victory(bout.winner)

func finish_victory(player: int) -> void:
 await get_tree().create_timer(0.45).timeout
 fighters[1 - player].set_pose("knockdown")
 await get_tree().create_timer(0.45).timeout
 fighters[player].set_pose("victory")
 fighters[1 - player].set_pose("defeat")
 audio.sound("victory")
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
  for height in range(3):
   if conductor.beat <= 3 and event.is_action_pressed(prefix + ["high", "mid", "low"][height]):
    selected[player] = height
  if conductor.beat <= 3:
   if event.is_action_pressed(prefix + "left"):
    bout.movements[player] = -1
   if event.is_action_pressed(prefix + "right"):
    bout.movements[player] = 1
  if event.is_action_pressed(prefix + "execute") and not phrase_resolved and is_inf(bout.errors[player]):
   var error := (conductor.timestamp(game_time()) - conductor.action_time()) * 1000.0
   bout.errors[player] = error
   bout.selections[player] = selected[player]
   last_error[player] = error

func refresh() -> void:
 label.text = "STICKS N LICKS     %d BPM" % conductor.bpm
 if help_visible:
  detail.text = "P1: A/D move  W/S/X high/mid/low  F execute
P2: arrows move/high/mid  RShift low  Enter execute
Beats 1-3: move/select. Beat 4: execute.
Perfect ±60ms parries; good ±130ms blocks.
First to 3 hits. H help · F3 debug · Esc menu"
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
  detail.text += "
Phrase %d · errors %s · select %s
Audio offset %sms · FPS %d · %s" % [conductor.phrase, "[%+.0f,%+.0f]" % last_error, str(selected), str(audio.offsets.get(audio.active, 0)), Engine.get_frames_per_second(), bout.outcome]

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
