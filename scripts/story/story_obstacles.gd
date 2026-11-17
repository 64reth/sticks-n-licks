class_name StoryObstacles
extends RefCounted
const ROAD_LEFT=80.0
const ROAD_RIGHT=224.0
const CROSS_STEPS=11
var traffic: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/story/traffic_012.json"))
var origin: float=0
var last_collision_cycle: int=-1
var dodges: Array[int]=[]
func lane_phase(index: int,beat: float) -> float:
 var lane: Dictionary=traffic.lanes[index]
 return fposmod(maxf(0,beat-origin)+float(lane.offset),float(lane.cycle))
func lane_warning(index: int,beat: float) -> bool:
 var lane: Dictionary=traffic.lanes[index]
 var phase:=lane_phase(index,beat)
 return phase>=float(lane.cycle)-float(lane.travel)-float(lane.warning) and phase<float(lane.cycle)-float(lane.travel)
func lane_active(index: int,beat: float) -> bool:
 var lane: Dictionary=traffic.lanes[index]
 return lane_phase(index,beat)>=float(lane.cycle)-float(lane.travel)
func lane_vehicle_y(index: int,beat: float) -> float:
 var lane: Dictionary=traffic.lanes[index]
 var t:=clampf((lane_phase(index,beat)-(float(lane.cycle)-float(lane.travel)))/float(lane.travel),0,1)
 if not traffic.has("section_width"):return lerpf(40,200,t) if int(lane.direction)>0 else lerpf(200,40,t)
 var margin: float=float(traffic.vehicle_length)
 return lerpf(-margin,180+margin,t) if int(lane.direction)>0 else lerpf(180+margin,-margin,t)
func can_start_road(road: int,beat: float) -> bool:
 # Reserve every step plus a beat for the 160ms visual completion. No impossible green invitation.
 var needed: int=int(traffic.roads[road].steps)+1
 for step in range(needed+1):
  for index in range(traffic.lanes.size()):
   if int(traffic.lanes[index].road)==road and (lane_active(index,beat+step) or lane_warning(index,beat+step)):return false
 return true
func safe_waiting_area(x: float) -> bool:
 if traffic.has("section_width"):return x<=36 or x>=292
 return x<=68 or (x>=140 and x<=168) or x>=244
func checkpoint_reached(x: float, previous: float) -> float:
 if traffic.has("section_width"):return 292 if x>=292 else previous
 return maxf(previous,148 if x>=148 and x<=168 else (244 if x>=244 else 68))
func road_collision(beat: float,x: float,section: int=-1) -> bool:
 for index in range(traffic.lanes.size()):
  if section>=0 and int(traffic.lanes[index].road)!=section:continue
  if lane_active(index,beat) and absf(x-float(traffic.lanes[index].x))<(float(traffic.get("vehicle_width",20))/2+9):
   var y:=lane_vehicle_y(index,beat)
   if y>=86 and y<=150+float(traffic.get("vehicle_length",30)):return true
 return false
# Existing cane interfaces retain their timing; compatibility views refer to lane one only.
func road_phase(beat: float) -> float:return fposmod(maxf(0,beat-origin),16)
func can_start_crossing(beat: float) -> bool:return can_start_road(0,beat)
func traffic_warning(beat: float) -> bool:return lane_warning(0,beat)
func traffic_active(beat: float) -> bool:return lane_active(0,beat)
func vehicle_y(beat: float) -> float:return lane_vehicle_y(0,beat)
func reset_safe(beat: float) -> void:origin=ceil(beat)
func cane_warning(beat: float) -> bool:return fposmod(maxf(0,beat-origin),8)>=4 and fposmod(maxf(0,beat-origin),8)<6
func cane_active(beat: float) -> bool:return fposmod(maxf(0,beat-origin),8)>=6 and fposmod(maxf(0,beat-origin),8)<7
