class_name BeatWorld
extends RefCounted
# All Story world animation reads this view of the existing conductor; never advances a clock.
var conductor: RhythmConductor
func _init(clock: RhythmConductor=null) -> void:conductor=clock
func beat() -> float:
 if conductor==null or not conductor.started or conductor.beat==0:return 0
 return conductor.phrase*4+conductor.beat-1+clampf((conductor.now()-conductor.beat_time)/conductor.duration(),0,1)
func phase(length: float, offset: float=0) -> float:return fposmod(beat()+offset,length)/length
func interpolate(start: float, finish: float, length: float, offset: float=0) -> float:return lerpf(start,finish,phase(length,offset))
func pose(count: int, cycle: float, offset: float=0) -> int:return mini(count-1,int(phase(cycle,offset)*count))
