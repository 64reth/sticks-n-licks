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
const MIN_X := 30.0
const MAX_X := 290.0
const GAP := 40.0
const STEP := 16.0

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

func resolve(conductor: RhythmConductor) -> String:
 if winner >= 0:
  return outcome
 var attacker := initiative
 var defender := 1 - attacker
 var attack_grade := conductor.grade(errors[attacker])
 var block_grade := conductor.grade(errors[defender])
 if selections[attacker] < 0 or attack_grade == "miss":
  initiative = defender
  outcome = "Miss: initiative reversed"
  defensive_streak = 0
 elif positions[1] - positions[0] > 140.0:
  initiative = defender
  outcome = "Out of reach: initiative reversed"
  defensive_streak = 0
 elif selections[attacker] == selections[defender] and block_grade != "miss":
  defensive_streak += 1
  if block_grade == "perfect":
   initiative = defender
   outcome = "Perfect parry: initiative reversed"
  else:
   outcome = "Blocked: attacker retains initiative"
 else:
  hits[attacker] += 1
  defensive_streak = 0
  outcome = "Clean hit for P%d" % (attacker + 1)
  if hits[attacker] >= 3:
   winner = attacker
   outcome = "P%d WINS" % (attacker + 1)
 if defensive_streak >= escalation_threshold:
  conductor.schedule_tempo(140 if conductor.bpm == 120 else 160)
  defensive_streak = 0
 selections = [-1, -1]
 errors = [INF, INF]
 return outcome
