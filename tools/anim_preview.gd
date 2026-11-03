extends Node2D
## Podgląd animacji rigów: dla każdego rigu rząd kopii, każda gra inną
## animację, kamera z przybliżeniem. Do oceny ruchu bez wchodzenia do gry:
##   godot --path . res://tools/anim_preview.tscn
## albo klatki do obejrzenia:
##   godot --path . res://tools/anim_preview.tscn --write-movie out/f.png --fixed-fps 20 --quit-after 30

const RIGS: Array[PackedScene] = [
	preload("res://scenes/player/rigs/warrior_rig.tscn"),
	preload("res://scenes/player/rigs/mage_rig.tscn"),
]
const ANIMS: Array[StringName] = [
	&"idle", &"run", &"jump", &"fall", &"attack", &"dodge",
	&"block", &"block_walk", &"hurt", &"knockdown", &"dead",
]
const CELL: Vector2 = Vector2(46, 72)
## Animacje bez pętli startują od nowa co tyle sekund.
const RESTART_EVERY: float = 1.2

var _rigs: Array[PartsRig] = []
var _restart_left: float = RESTART_EVERY
## Komórki "block" przełączają barierę przy każdym restarcie: raz się
## materializuje, raz gaśnie (na przemian wchłonięcie i wygaśnięcie).
var _barrier_on: bool = true
var _barrier_absorbed: bool = false


func _ready() -> void:
	for row: int in RIGS.size():
		for col: int in ANIMS.size():
			var cell: Vector2 = Vector2(float(col), float(row)) * CELL + Vector2(24, 40)
			var rig: PartsRig = RIGS[row].instantiate() as PartsRig
			rig.position = cell
			add_child(rig)
			rig.play(ANIMS[col])
			# Komórka "block" pokazuje też barierę (rig bez bariery to ignoruje).
			if ANIMS[col] == &"block":
				rig.set_barrier(true)
			_rigs.append(rig)
			var label: Label = Label.new()
			label.text = String(ANIMS[col])
			label.add_theme_font_size_override(&"font_size", 5)
			label.position = cell + Vector2(-23, 16)
			label.size = Vector2(46, 8)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			add_child(label)
			var floor_line: ColorRect = ColorRect.new()
			floor_line.position = cell + Vector2(-18, 12)
			floor_line.size = Vector2(36, 1)
			floor_line.color = Color(0.4, 0.4, 0.45, 1)
			add_child(floor_line)
	# Zoom 1.25: kadr 512x288 px mieści 11 kolumn po 46 px i dwa rzędy po 72 px.
	var camera: Camera2D = Camera2D.new()
	camera.zoom = Vector2(1.25, 1.25)
	camera.position = Vector2(ANIMS.size() * CELL.x * 0.5 + 4, CELL.y + 8)
	add_child(camera)


func _process(delta: float) -> void:
	_restart_left -= delta
	if _restart_left > 0.0:
		return
	_restart_left = RESTART_EVERY
	_barrier_on = not _barrier_on
	if not _barrier_on:
		_barrier_absorbed = not _barrier_absorbed
	for i: int in _rigs.size():
		var anim: StringName = ANIMS[i % ANIMS.size()]
		_rigs[i].restart(anim)
		if anim == &"block":
			_rigs[i].set_barrier(_barrier_on, _barrier_absorbed)
