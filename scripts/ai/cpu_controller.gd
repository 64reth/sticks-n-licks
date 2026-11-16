class_name CpuController
extends RefCounted
# Public observations in, timed input intents out. No scene, Bout or Input state access.
var rng := RandomNumberGenerator.new()
var parameters: Dictionary = {}
var difficulty := "normal"
var random_seed: int = 5005
var player: int = 1
var state := "STANDOFF"
var distance := 120.0
var selected_action := "wait"
var intended_beat := "-"
var timing_offset := 0.0
var result := "READY"
var commitment: Dictionary = {}
var attack_weights: Array = []
var defense_weights: Array = [1.0,1.0,1.0]
var history: Array[int] = [0,0,0]
var queue: Array[Dictionary] = []
var decisions: Array[Dictionary] = []
var last_height := -1
var repeated := 0
var retreat_streak := 0
var committed_phrase := -1
var observed_exchange := ""
var serial := 0

func configure(level: String, seed_value: int, index: int=1) -> void:
 var config: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/cpu.json"))
 difficulty = level if config.has(level) else str(config.default_difficulty)
 parameters = config[difficulty].duplicate(true)
 random_seed = seed_value
 player = index
 rng.seed = random_seed
 history.assign([0,0,0])
 last_height=-1
 repeated=0
 decisions.clear()
 serial=0
 reset_round()

func reset_round() -> void:
 queue.clear()
 commitment.clear()
 state="STANDOFF"
 result="READY"
 selected_action="wait"
 intended_beat="-"
 committed_phrase=-1
 observed_exchange=""
 retreat_streak=0

func start_round(cue: float) -> void:
 reset_round()
 var reaction := rng.randf_range(float(parameters.race_min),float(parameters.race_max))
 if rng.randf()<float(parameters.false_start):reaction=-rng.randf_range(0.035,0.12)
 elif rng.randf()<0.08:reaction+=rng.randf_range(0.35,0.75)
 add_intent({"at":cue+reaction,"kind":"race","action":"execute","beat":"GO","offset_ms":reaction*1000.0,"role":"race","height":-1})

func weighted(weights: Array) -> int:
 var total := 0.0
 for weight in weights:total+=float(weight)
 var value := rng.randf()*total
 for index in range(weights.size()):
  value-=float(weights[index])
  if value<=0:return index
 return weights.size()-1

func sample_offset(kind: String) -> float:
 # Miss movement stays inside half a 160-BPM beat, so it cannot alias a neighbour.
 var sign_value := -1.0 if rng.randf()<0.5 else 1.0
 if rng.randf()>clampf(float(parameters.rhythm_success),0.05,0.98):
  return sign_value*rng.randf_range(172.0,184.0)
 if rng.randf()<float(parameters.perfect_share):return sign_value*rng.randf_range(18.0,58.0)
 return sign_value*rng.randf_range(105.0,145.0) if kind=="move" else sign_value*rng.randf_range(82.0,126.0)

func add_intent(intent: Dictionary) -> void:
 serial+=1
 intent.id=serial
 queue.append(intent)
 queue.sort_custom(func(a: Dictionary,b: Dictionary):return float(a.at)<float(b.at) if a.at!=b.at else int(a.id)<int(b.id))
 decisions.append(intent.duplicate(true))
 if decisions.size()>4096:decisions.pop_front()

func observe_result(event: Dictionary, exchange_id: String) -> void:
 if exchange_id==observed_exchange or event.is_empty():return
 observed_exchange=exchange_id
 if int(event.attacker)!=player and int(event.height)>=0:
  history[int(event.height)]+=1

func plan_boundary(public: Dictionary) -> void:
 # The adapter supplies only this whitelist. Current selections/errors never cross it.
 var phrase: int=public.phrase
 var beat: int=public.beat
 var at: float=public.beat_time
 var duration: float=public.duration
 distance=absf(float(public.positions[1])-float(public.positions[0]))
 var forward: String="right" if float(public.positions[1-player])>float(public.positions[player]) else "left"
 var backward: String="left" if forward=="right" else "right"
 var reach: float=public.reach
 if beat==1 and committed_phrase!=phrase:
  committed_phrase=phrase
  attack_weights=parameters.attack_weights.duplicate()
  if repeated>=2 and last_height>=0:attack_weights[last_height]=0.0
  var total_history: int=history[0]+history[1]+history[2]
  defense_weights=[]
  for height in range(3):
   defense_weights.append(1.0+float(parameters.learning)*float(history[height])*3.0/maxf(1,total_history))
  var attacking: bool=int(public.initiative)==player
  var height:=weighted(attack_weights if attacking else defense_weights)
  if attacking:
   repeated=repeated+1 if height==last_height else 1
   last_height=height
  var attempt: bool=(distance<=reach+32.0 or rng.randf()<(0.18 if difficulty=="easy" else 0.06)) if attacking else rng.randf()<float(parameters.defend)
  var role: String="attack" if attacking else "block"
  var offset:=sample_offset("combat")
  commitment={"phrase":phrase,"height":height,"role":role,"made_at":at,"locked_until":at+float(parameters.decision_delay),"attempt":attempt}
  if attempt:
   add_intent({"at":at+duration*3.0+(offset+float(public.latency_ms))/1000.0,"kind":"combat","action":["high",forward,"low"][height],"height":height,"role":role,"offset_ms":offset,"beat":"%d:4" % phrase})
  else:state="RECOVER"
 # Plan one boundary ahead; first combat beat deliberately has no pre-race movement.
 var target_beat:=1 if beat==4 else beat+1
 var target_phrase:=phrase+1 if beat==4 else phrase
 var direction: String=""
 if distance>reach:
  state="APPROACH"
  direction=forward
  retreat_streak=0
 elif retreat_streak<1 and rng.randf()<float(parameters.retreat):
  state="RETREAT"
  direction=backward
  retreat_streak+=1
 else:
  state="ENGAGE" if int(public.initiative)==player else "DEFEND"
  retreat_streak=0
 if direction.is_empty():return
 if rng.randf()<float(parameters.hesitate):
  state="RECOVER"
  return
 # A MID chord already submits a forward tap at beat four through the shared input path.
 if target_beat==4 and commitment.get("attempt",false) and commitment.get("height",-1)==1:return
 var offset:=sample_offset("move")
 if duration+offset/1000.0<float(parameters.decision_delay):offset=absf(offset)
 add_intent({"at":at+duration+(offset+float(public.latency_ms))/1000.0,"kind":"move","action":direction,"height":-1,"role":"step","offset_ms":offset,"beat":"%d:%d" % [target_phrase,target_beat]})

func next_time() -> float:
 return INF if queue.is_empty() else float(queue[0].at)

func pop_intent() -> Dictionary:
 var intent: Dictionary=queue.pop_front()
 selected_action=str(intent.kind)+" "+str(intent.action)
 intended_beat=str(intent.beat)
 timing_offset=float(intent.offset_ms)
 return intent

func diagnostic(actual_distance: float=-1.0) -> String:
 var shown_distance := distance if actual_distance<0 else actual_distance
 var locked := "none"
 if not commitment.is_empty():locked="%s h%d p%d @%.2f" % [commitment.role,int(commitment.height),int(commitment.phrase),float(commitment.locked_until)]
 return "CPU %s seed%d %s dist%.0f\n%s beat%s off%+.0fms %s\nCommit %s\nA%s D%s" % [difficulty.to_upper(),random_seed,state,shown_distance,selected_action,intended_beat,timing_offset,result,locked,format_weights(attack_weights),format_weights(defense_weights)]

func format_weights(weights: Array) -> String:
 var values: Array[String]=[]
 for value in weights:values.append("%.2f" % float(value))
 return ",".join(values)
