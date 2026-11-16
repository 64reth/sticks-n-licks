class_name CoconutPalm
extends Node2D
# One shared source texture, native regions; no animation player, clock or image copies.
const SHEET=preload("res://assets/environments/props/coconut_palm.png")
const CELL=Vector2i(362,543)
const ANCHORS: Array[Vector2]=[Vector2(139,513),Vector2(134,513),Vector2(131,513),Vector2(128,513),Vector2(139,512),Vector2(134,512),Vector2(131,512),Vector2(128,512)]
# Reviewed row-major: neutral / left onset / left peak / return / neutral / right onset / right peak / return.
const SEQUENCE: Array[int]=[0,1,2,3,4,5,6,7]
@export_range(0.01,2.0,0.01) var display_scale: float=0.24:
 set(value):
  display_scale=maxf(0.01,value)
  queue_redraw()
@export var phase_offset_beats: float=0.0
@export_range(0,7,1) var start_frame: int=0
var conductor: RhythmConductor
var frame: int=0
var sampled_beat: float=0.0
func _ready() -> void:
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 position=position.round()
 set_process(conductor!=null)
 sync_beat(0)
func bind_clock(clock: RhythmConductor) -> void:
 conductor=clock
 set_process(clock!=null)
 sync_clock()
func frame_at(absolute_beat: float) -> int:
 var phase:=fposmod(absolute_beat+phase_offset_beats+start_frame,8.0)
 return SEQUENCE[int(floor(phase+0.000000001))%8]
func sync_beat(absolute_beat: float) -> void:
 sampled_beat=absolute_beat
 var selected:=frame_at(absolute_beat)
 if selected!=frame:
  frame=selected
  queue_redraw()
func sync_clock() -> void:
 if conductor==null or not conductor.started:return
 if conductor.beat==0:
  sync_beat(0)
  return
 # Current boundary + fractional phase also handles phrase-boundary tempo changes.
 var fraction:=clampf((conductor.now()-conductor.beat_time)/conductor.duration(),0,1)
 sync_beat(conductor.phrase*4+conductor.beat-1+fraction)
func _process(_delta: float) -> void:
 if is_visible_in_tree():sync_clock()
func region(index: int) -> Rect2:
 return Rect2(Vector2(index%4*CELL.x,index/4*CELL.y),Vector2(CELL))
func destination(index: int) -> Rect2:
 return Rect2((-ANCHORS[index]*display_scale).round(),(Vector2(CELL)*display_scale).round())
func _draw() -> void:
 draw_texture_rect_region(SHEET,destination(frame),region(frame))
