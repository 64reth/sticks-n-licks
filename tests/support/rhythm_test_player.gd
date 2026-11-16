class_name RhythmTestPlayer
extends RefCounted
# Defined test strategies, not production AI. Never inspect CPU commitments/current selections.
var style := "balanced"
var rng := RandomNumberGenerator.new()
var queue: Array[Dictionary] = []
var last_phrase := -1
func configure(strategy: String, seed_value: int) -> void:
 style=strategy
 rng.seed=seed_value
 reset_round()
func reset_round() -> void:
 queue.clear()
 last_phrase=-1
func start_round(cue: float) -> void:
 reset_round()
 queue.append({"at":cue+0.23,"kind":"race","action":"execute"})
func plan_boundary(public: Dictionary) -> void:
 var beat: int=public.beat
 var phrase: int=public.phrase
 var at: float=public.beat_time
 var d: float=public.duration
 if beat==1 and phrase!=last_phrase:
  last_phrase=phrase
  var attacking: bool=int(public.initiative)==0
  var height: int=0 if style in ["rush_high","guard_high"] else phrase%3
  if not attacking and style=="rush_high":height=2
  var offset: float=(0.04 if style=="guard_high" else 0.10)*(1.0 if rng.randf()<0.5 else -1.0)
  if rng.randf()<0.12:offset=0.178
  var forward: String="right" if public.positions[1]>public.positions[0] else "left"
  queue.append({"at":at+3*d+offset,"kind":"combat","action":["high",forward,"low"][height]})
 var gap: float=absf(float(public.positions[1])-float(public.positions[0]))
 var advance: bool=gap>float(public.reach)
 var retreat: bool=style=="balanced" and gap<=float(public.reach) and rng.randf()<0.08
 if advance or retreat:
  queue.append({"at":at+d-0.045,"kind":"move","action":"right" if advance else "left"})
 queue.sort_custom(func(a: Dictionary,b: Dictionary):return a.at<b.at)
func next_time() -> float:
 return INF if queue.is_empty() else float(queue[0].at)
func pop_intent() -> Dictionary:return queue.pop_front()
