extends SceneTree
var checks: int = 0
var failures: int = 0

func check(condition: bool, message: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error(message)

func close_bout() -> Bout:
 var bout := Bout.new()
 bout.positions = [140.0, 180.0]
 return bout

func next_exchange(bout: Bout, clock: RhythmConductor) -> String:
 clock.phrase += 1
 return bout.resolve(clock)

func _initialize() -> void:
 for bpm in [120, 140, 160]:
  var clock := RhythmConductor.new()
  clock.start(10.0)
  clock.bpm = bpm
  clock.pending_bpm = bpm
  var d: float = 60.0 / bpm
  clock.update(10.0 + d * 2.0 + 0.001)
  check(clock.beat == 3, "Third beat at %d" % bpm)
  clock.update(10.0 + d * 4.0 + 0.001)
  check(clock.phrase == 1 and clock.beat == 1, "Phrase boundary at %d" % bpm)
  check(is_equal_approx(clock.action_time(), clock.phrase_start + d * 3), "Action target")
 var c := RhythmConductor.new()
 c.start(0.0)
 c.schedule_tempo(140)
 c.update(1.99)
 check(c.bpm == 120, "No mid-phrase tempo change")
 c.update(2.0)
 check(c.bpm == 140 and c.phrase == 1, "Scheduled tempo at boundary")
 c.schedule_tempo(160)
 c.update(2.0 + 240.0/140.0)
 check(c.bpm == 160 and c.phrase == 2, "Frenzy boundary")
 var count := [0]
 c = RhythmConductor.new()
 c.beat_changed.connect(func(_b, _p): count[0] += 1)
 c.start(0.0)
 c.update(4.0)
 check(count[0] == 9, "Catch up all nine boundaries after stalled frame")
 for error in [-70.0, 0.0, 70.0]:
  check(c.grade(error) == "perfect", "Perfect window inclusive")
 for error in [-140.0, -71.0, 71.0, 140.0]:
  check(c.grade(error) == "good", "Good window inclusive")
 check(c.grade(140.1) == "miss", "Miss outside window")
 c.latency_ms = 45
 check(is_equal_approx(c.timestamp(1.0), 0.955), "Input latency compensation")
 var b := close_bout()
 b.race_press(0, 0.9, 1.0)
 b.race_press(1, 1.2, 1.0)
 check(b.false_starts[0] and b.resolve_race() == 1, "False start forfeits initiative")
 check(b.hits == [0, 0], "Race never scores")
 b = close_bout()
 b.race_press(0, 1.15, 1.0)
 b.race_press(1, 1.10, 1.0)
 check(b.resolve_race() == 1, "Fastest valid reaction wins")
 b = close_bout()
 b.reactions = [0.100, 0.104]
 check(b.resolve_race() == 0 and b.tie_priority == 1, "First tie priority")
 check(b.resolve_race() == 1 and b.tie_priority == 0, "Tie priority alternates")
 b.false_starts = [true, true]
 check(b.resolve_race() == -1, "Double false start reruns race")
 b = close_bout()
 check(b.resolve_race() == -1, "No reactions reruns race")
 for height in range(3):
  b = close_bout()
  b.selections = [height, height]
  b.errors = [0.0, 90.0]
  check(next_exchange(b, c).begins_with("Blocked") and b.initiative == 0 and b.hits == [0,0], "Directional good block")
  b.selections = [height, height]
  b.errors = [0.0, 60.0]
  check(next_exchange(b, c).begins_with("Perfect") and b.initiative == 1 and b.hits == [0,0], "Perfect reverses without hit")
 b = close_bout()
 b.selections = [0, 2]
 b.errors = [0.0, 0.0]
 next_exchange(b, c)
 check(b.hits == [1,0], "Incorrect block scores")
 b.selections = [0, 0]
 b.errors = [141.0, 0.0]
 next_exchange(b, c)
 check(b.hits == [1,0] and b.initiative == 1, "Missed attack passes initiative")
 b = close_bout()
 for hit in range(3):
  b.selections = [1, -1]
  b.errors = [0.0, INF]
  next_exchange(b, c)
 check(b.winner == 0 and b.hits[0] == 3, "Three-hit victory")
 b.resolve(c)
 check(b.hits[0] == 3, "No post-victory hits")
 b = close_bout()
 for i in range(40):
  b.movements = [-1,1]
  b.move()
 check(b.positions == [30.0,290.0], "Outer arena boundaries")
 for i in range(40):
  b.movements = [1,-1]
  b.move()
 check(b.positions[1] - b.positions[0] >= Bout.GAP, "No overlap or crossing")
 b = close_bout()
 c.start(0.0)
 for i in range(3):
  b.selections = [0,0]
  b.errors = [0.0,90.0]
  next_exchange(b, c)
 check(c.pending_bpm == 140 and c.bpm == 120, "Defensive streak schedules escalation")
 Bindings.install()
 var low = InputMap.action_get_events("p2_execute")[0]
 check(low.location == KEY_LOCATION_RIGHT, "Only right Shift executes")
 b.positions = [30.0,70.0]
 b.movements = [-1,-1]
 b.move()
 check(b.positions[0] >= 30.0 and b.positions[1] - b.positions[0] >= Bout.GAP, "Coupled movement at left wall")
 b.positions = [250.0,290.0]
 b.movements = [1,1]
 b.move()
 check(b.positions[1] <= 290.0 and b.positions[1] - b.positions[0] >= Bout.GAP, "Coupled movement at right wall")
 b = close_bout()
 b.selections = [1,1]
 b.errors = [0.0,141.0]
 next_exchange(b, c)
 check(b.hits == [1,0], "Mistimed matching block permits hit")
 check(b.defensive_streak == 0, "Hit does not add defensive streak")
 b = close_bout()
 b.selections = [-1,1]
 b.errors = [INF,0.0]
 next_exchange(b, c)
 check(b.initiative == 1 and b.hits == [0,0], "No attack passes initiative without hit")
 b = close_bout()
 b.positions = [30.0,290.0]
 b.selections = [0,-1]
 b.errors = [0.0,INF]
 next_exchange(b, c)
 check(b.initiative == 1 and b.hits == [0,0], "Out of range passes initiative")
 c.start(0.0)
 c.bpm = 140
 c.pending_bpm = 140
 b = close_bout()
 for i in range(3):
  b.selections = [0,0]
  b.errors = [0.0,90.0]
  next_exchange(b, c)
 check(c.pending_bpm == 160 and c.bpm == 140, "Defence schedules 160 without mid-phrase change")
 var frames := load("res://assets/characters/fighter_01/frames/placeholder_idle/idle.tres") as SpriteFrames
 check(frames != null and frames.get_frame_count("idle") == 2, "Exported SpriteFrames imports")
 print("RULE TESTS: %d checks, %d failures" % [checks, failures])
 quit(0 if failures == 0 else 1)
