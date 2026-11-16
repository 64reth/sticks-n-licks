class_name HUDPresenter
extends RefCounted
const NAMES := ["RED", "BLUE"]

static func countdown(at: float, cue: float, duration: float) -> String:
 var start := cue - 3.0 * duration
 if at < start:
  return ""
 if at < cue:
  return str(3 - mini(2, int(floor((at - start + 0.000000001) / duration))))
 return "GO!" if at < cue + 0.35 else ""

static func snapshot(game: Node2D, at: float) -> Dictionary:
 var phase: String = game.mode
 var progress: MatchProgress = game.match_progress
 var number := countdown(at, game.cue, game.conductor.duration()) if phase in ["standoff", "race", "pickup"] else ""
 var major := number
 var instruction := ""
 var footer := ""
 var outcome := ""
 var phases := {"menu":"LOCAL VERSUS","standoff":"GET READY","race":"GRAB STICKS!","pickup":"READY","combat":"FIGHT!","finishing":"ROUND OVER","round_win":"ROUND WON!","match_win":"CHAMPION!"}
 if phase == "menu":
  phases["menu"]="PLAYER VS CPU" if game.game_mode=="cpu" else "LOCAL VERSUS"
  major = "STICKS N LICKS"
  instruction = "M MODE: "+("PLAYER VS CPU" if game.game_mode=="cpu" else "PLAYER VS PLAYER")
  footer = "ENTER START  H HELP  F4 STAGE"
 elif phase == "standoff":
  instruction = "GET READY TO GRAB YOUR STICK!"
 elif number == "GO!":
  instruction = "GRAB YOUR STICK!"
 elif phase == "pickup":
  footer = NAMES[game.bout.initiative] + " HAS INITIATIVE"
 if phase in ["finishing", "round_win", "match_win"]:
  var champion: int = progress.winner
  var who: int = game.bout.winner
  major = NAMES[who] + (" CHAMPION!" if champion >= 0 else " ROUND WON!") if who >= 0 else ""
  if phase == "round_win": footer = "NEXT ROUND SOON  ESC PAUSE"
  elif phase == "match_win": footer = "ENTER REMATCH  ESC MENU"
 if phase == "combat" and at < game.outcome_until and not game.bout.last_event.is_empty():
  var event: Dictionary = game.bout.last_event
  var height: int = event["height"]
  var level: String = ["HIGH","MID","LOW"][height] if height in [0,1,2] else ""
  match str(event["kind"]):
   "HIT": outcome = NAMES[event["attacker"]] + " " + level + " HIT!"
   "BLOCK": outcome = level + " BLOCK!"
   "PARRY": outcome = "PERFECT PARRY!"
   "WHIFF": outcome = "MISS!" if height >= 0 else ""
 var scale := 2
 if number in ["3","2","1"]:
  var beat_start: float = game.cue - float(number.to_int()) * game.conductor.duration()
  scale = 4 if at - beat_start < 0.08 else 3
 elif number == "GO!":
  scale = 3
 return {"energy":[game.bout.energy_remaining(0),game.bout.energy_remaining(1)],
  "round_wins":progress.round_wins.duplicate(),"wins_needed":progress.wins_needed(),
  "round_number":progress.round_number,"bpm":game.conductor.bpm,"phase":phases.get(phase,"READY"),
  "initiative":game.bout.initiative if phase=="combat" else -1,"major":major,"major_scale":scale,
  "instruction":instruction,"footer":footer,"outcome":outcome,"go":number=="GO!",
  "menu_options":("LEFT/RIGHT CPU: "+game.cpu_difficulty.to_upper() if game.game_mode=="cpu" else "P1 RED / P2 BLUE") if phase=="menu" else "",
  "help":game.help_visible,"best_of":progress.best_of}
