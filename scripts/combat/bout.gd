class_name Bout
extends RefCounted
var initiative: int = 0
var hits: Array[int] = [0, 0]
var winner: int = -1
var defensive_streak: int = 0
var escalation_threshold: int = 3
var tie_priority: int = 0
var false_starts: Array[bool] = [false, false]
var reactions: Array[float] = [-1.0, -1.0]
var selections: Array[int] = [-1, -1]
var errors: Array[float] = [INF, INF]
var positions: Array[float] = [100.0, 220.0]
var movements: Array[int] = [0, 0]
var outcome: String = ""
# Reach measures logical pixels from the fighter anchor to the stick tip.
var stick_reach: float = 44.0
var impact_phrase: int = -1
var impact_positions: Array[float] = []
var impact_time: float = 0.0
var resolved_phrase: int = -1
var last_event: Dictionary = {}
const ENERGY_SEGMENTS := 3
const GROUND_Y := 150.0
const HURTBOX := Rect2(-9, -64, 18, 64)
const ATTACK_BAND := 12.0
const MIN_X := 30.0
const MAX_X := 290.0
const GAP := 40.0
const STEP := 16.0

func energy_remaining(player: int) -> int:
 # Hits belong to the scoring attacker; the opposite player's energy is reduced.
 return clampi(ENERGY_SEGMENTS - hits[1-player], 0, ENERGY_SEGMENTS)

func race_press(player: int, at: float, cue: float) -> void:
 if reactions[player] >= 0 or false_starts[player]:
  return
 if at < cue:
  false_starts[player] = true
 else:
  reactions[player] = at - cue

func resolve_race() -> int:
 var a := reactions[0]
 var b := reactions[1]
 if false_starts[0] and false_starts[1]:
  return -1
 if false_starts[0]:
  initiative = 1
 elif false_starts[1]:
  initiative = 0
 elif a < 0 and b < 0:
  return -1
 elif a < 0:
  initiative = 1
 elif b < 0:
  initiative = 0
 elif abs(a - b) <= 0.005:
  initiative = tie_priority
  tie_priority = 1 - tie_priority
 else:
  initiative = 0 if a < b else 1
 return initiative

func move() -> void:
 var left := clampf(positions[0] + movements[0] * STEP, MIN_X, MAX_X - GAP)
 var right := clampf(positions[1] + movements[1] * STEP, MIN_X + GAP, MAX_X)
 if right - left < GAP:
  var middle := clampf((left + right) / 2.0, MIN_X + GAP / 2.0, MAX_X - GAP / 2.0)
  left = middle - GAP / 2.0
  right = middle + GAP / 2.0
 positions = [left, right]
 movements = [0, 0]

func hurt_region(player: int, at_positions: Array[float] = []) -> Rect2:
 var points := positions if at_positions.is_empty() else at_positions
 return Rect2(Vector2(points[player], GROUND_Y) + HURTBOX.position, HURTBOX.size)

func attack_region(player: int, height: int, at_positions: Array[float] = []) -> Rect2:
 if height < 0 or height > 2 or stick_reach <= HURTBOX.size.x / 2.0:
  return Rect2()
 var points := positions if at_positions.is_empty() else at_positions
 var direction := 1 if points[1 - player] > points[player] else -1
 var front := HURTBOX.size.x / 2.0
 var left := points[player] + (front if direction > 0 else -stick_reach)
 var y: float = [-52.0, -32.0, -12.0][height]
 return Rect2(left, GROUND_Y + y - ATTACK_BAND / 2.0, stick_reach - front, ATTACK_BAND)

func capture_impact(phrase: int, at: float) -> void:
 if impact_phrase == phrase:
  return
 impact_phrase = phrase
 impact_positions = positions.duplicate()
 impact_time = at

func in_reach(player: int, height: int, at_positions: Array[float] = []) -> bool:
 var region := attack_region(player, height, at_positions)
 return region.has_area() and region.intersects(hurt_region(1 - player, at_positions), true)

func resolve(conductor: RhythmConductor, phrase_id: int = -1) -> String:
 var exchange := conductor.phrase if phrase_id < 0 else phrase_id
 if winner >= 0 or resolved_phrase == exchange:
  return outcome
 resolved_phrase = exchange
 if impact_phrase != exchange:
  capture_impact(exchange, conductor.action_time())
 var attacker := initiative
 var defender := 1 - attacker
 var attack_grade := conductor.grade(errors[attacker])
 var block_grade := conductor.grade(errors[defender])
 var height := selections[attacker]
 var region := attack_region(attacker, height, impact_positions)
 var overlap := in_reach(attacker, height, impact_positions)
 last_event = {"kind": "WHIFF", "reason": "", "phrase": exchange,
  "attacker": attacker, "defender": defender, "height": height,
  "attack_region": region, "hurt_region": hurt_region(defender, impact_positions),
  "overlap": overlap, "distance": abs(impact_positions[1] - impact_positions[0]),
  "stick_reach": stick_reach, "impact_time": impact_time}
 if height < 0 or attack_grade == "miss":
  initiative = defender
  outcome = "Miss: initiative reversed"
  last_event["reason"] = "no action" if height < 0 else "timing"
  defensive_streak = 0
 elif not overlap:
  initiative = defender
  outcome = "WHIFF: out of stick reach; initiative reversed"
  last_event["reason"] = "out of range"
  defensive_streak = 0
 elif height == selections[defender] and block_grade != "miss":
  defensive_streak += 1
  if block_grade == "perfect":
   initiative = defender
   outcome = "Perfect parry: initiative reversed"
   last_event["kind"] = "PARRY"
  else:
   outcome = "Blocked: attacker retains initiative"
   last_event["kind"] = "BLOCK"
 else:
  hits[attacker] += 1
  defensive_streak = 0
  outcome = "Clean hit for P%d" % (attacker + 1)
  last_event["kind"] = "HIT"
  if hits[attacker] >= ENERGY_SEGMENTS:
   winner = attacker
   outcome = "P%d WINS" % (attacker + 1)
 if defensive_streak >= escalation_threshold:
  conductor.schedule_tempo(140 if conductor.bpm == 120 else 160)
  defensive_streak = 0
 selections = [-1, -1]
 errors = [INF, INF]
 return outcome
