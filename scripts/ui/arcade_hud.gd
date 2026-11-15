class_name ArcadeHUD
extends Control
const FONT = preload("res://assets/ui/arcade/arcade.fnt")
const CREAM := Color("f6e3b8")
var red := ArcadePlayerCard.new()
var blue := ArcadePlayerCard.new()
var round_label: Label
var tempo_label: Label
var phase_label: Label
var major_label: Label
var instruction_label: Label
var outcome_label: Label
var footer_label: Label
var help_panel := Panel.new()
var help_label: Label
var state: Dictionary = {}

func text_label(at: Vector2, extent: Vector2) -> Label:
 var node := Label.new()
 node.position = at
 node.size = extent
 node.add_theme_font_override("font",FONT)
 node.add_theme_font_size_override("font_size",8)
 node.add_theme_color_override("font_color",CREAM)
 node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 add_child(node)
 return node

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 red.position = Vector2(5,5)
 red.size = Vector2(96,35)
 red.set_anchors_preset(Control.PRESET_TOP_LEFT)
 add_child(red)
 blue.player_name = "BLUE"
 blue.team_color = Color("315cba")
 blue.mirrored = true
 blue.anchor_left = 1
 blue.anchor_right = 1
 blue.offset_left = -101
 blue.offset_right = -5
 blue.offset_top = 5
 blue.offset_bottom = 40
 add_child(blue)
 round_label = text_label(Vector2(103,5),Vector2(114,8))
 tempo_label = text_label(Vector2(103,17),Vector2(114,8))
 phase_label = text_label(Vector2(103,29),Vector2(114,8))
 major_label = text_label(Vector2(0,50),Vector2(160,10))
 instruction_label = text_label(Vector2(0,79),Vector2(320,8))
 outcome_label = text_label(Vector2(0,153),Vector2(320,8))
 footer_label = text_label(Vector2(0,166),Vector2(320,8))
 var style := StyleBoxFlat.new()
 style.bg_color = Color("202323")
 style.border_color = CREAM
 style.set_border_width_all(1)
 help_panel.position = Vector2(16,46)
 help_panel.size = Vector2(288,106)
 help_panel.add_theme_stylebox_override("panel",style)
 help_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(help_panel)
 help_label = text_label(Vector2(22,53),Vector2(276,94))
 help_label.text = "CONTROLS\n\nRED: A/D MOVE  W HIGH  S LOW  F EXECUTE\nBLUE: ARROWS MOVE/HIGH/LOW\nRIGHT SHIFT EXECUTES\nFORWARD + EXECUTE = MID\nMOVE ON BEATS 1-4 / COMBAT ON BEAT 4\nH CLOSE  F3 DEBUG  ESC MENU"

func present(snapshot: Dictionary) -> void:
 state = snapshot
 red.update_card(state["energy"][0],state["round_wins"][0],state["wins_needed"],state["initiative"]==0)
 blue.update_card(state["energy"][1],state["round_wins"][1],state["wins_needed"],state["initiative"]==1)
 round_label.text = "ROUND %d" % state["round_number"]
 tempo_label.text = "%d BPM" % state["bpm"]
 phase_label.text = state["phase"]
 var factor: int = state["major_scale"]
 major_label.scale = Vector2.ONE*factor
 major_label.size = Vector2(320.0/factor,10)
 major_label.text = state["major"]
 major_label.modulate = Color("eec65e") if state["go"] else CREAM
 instruction_label.text = state["instruction"]
 footer_label.text = state["footer"]
 outcome_label.text = state["outcome"]
 help_panel.visible = state["help"]
 help_label.visible = state["help"]
