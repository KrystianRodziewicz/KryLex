class_name BlockRig
extends PlayerRig
## Rig z prostokątów (graybox). Domyślny, dopóki klasa nie ma własnego rigu.

var _anim: StringName = &""

@onready var _body: ColorRect = $Body as ColorRect
@onready var _shield: ColorRect = $Shield as ColorRect


func setup(stats: PlayerStats) -> void:
	_body.color = stats.color
	_shield.visible = false


func play(anim: StringName, _duration: float = -1.0) -> void:
	if anim == _anim:
		return
	_anim = anim
	_shield.visible = anim == &"block" or anim == &"block_walk"
	rotation = 0.0
	self_modulate = Color.WHITE
	match anim:
		&"dead":
			rotation = PI * 0.5
			self_modulate = Color(0.4, 0.4, 0.4, 0.8)
		&"knockdown":
			rotation = -PI * 0.5
		&"dodge":
			self_modulate = Color(1.0, 1.0, 1.0, 0.5)
		&"attack":
			self_modulate = Color(1.3, 1.3, 1.1)
