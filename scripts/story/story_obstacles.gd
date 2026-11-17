class_name StoryObstacles
extends RefCounted
# Pure beat-domain obstacle rules, independent of rendering and input polling.
const ROAD_LEFT=112.0
const ROAD_RIGHT=208.0
const CROSS_STEPS=7 # Safe X=100 -> X=212: seven 16px taps; twelve safe beats.
var origin: float=0
var last_collision_cycle: int=-1
var dodges: Array[int]=[]
func road_phase(beat: float) -> float:return fposmod(maxf(0,beat-origin),16)
func can_start_crossing(beat: float) -> bool:return road_phase(beat)<5
func traffic_warning(beat: float) -> bool:return road_phase(beat)>=12 and road_phase(beat)<14
func traffic_active(beat: float) -> bool:return road_phase(beat)>=14
func vehicle_y(beat: float) -> float:return lerpf(40,200,clampf((road_phase(beat)-14)/2,0,1))
func road_collision(beat: float,x: float) -> bool:
 return traffic_active(beat) and x>ROAD_LEFT and x<ROAD_RIGHT and absf(160-x)<33 and vehicle_y(beat)>=86 and vehicle_y(beat)<=180
func reset_safe(beat: float) -> void:origin=ceil(beat)
func cane_warning(beat: float) -> bool:return fposmod(maxf(0,beat-origin),8)>=4 and fposmod(maxf(0,beat-origin),8)<6
func cane_active(beat: float) -> bool:return fposmod(maxf(0,beat-origin),8)>=6 and fposmod(maxf(0,beat-origin),8)<7
