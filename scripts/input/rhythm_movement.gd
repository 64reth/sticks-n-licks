class_name RhythmMovement
extends RefCounted
# Shared adapter: CombatInput remains the sole movement acceptance/consumption state.
static func feed(control: CombatInput, action: String, pressed: bool, at: float, facing: int, enabled: bool, clock: RhythmConductor, perfect: float, good: float) -> Dictionary:
 var rising := pressed and not bool(control.held.get(action,false))
 var combination := control.feed(action,pressed,at,facing,enabled)
 var requested := rising and action in ["left","right"] and enabled
 if requested:control.request_movement(action,at,clock,perfect,good)
 return {"combination":combination,"requested":requested}
static func pose(direction: int, facing: int) -> String:
 return "forward_step" if direction==facing else "backward_step"
static func position_at(origin: float, target: float, started: float, at: float, seconds: float) -> float:
 return lerpf(origin,target,clampf((at-started)/seconds,0,1))
