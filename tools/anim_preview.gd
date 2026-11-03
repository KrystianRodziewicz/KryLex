extends Node2D
## Podgląd animacji rigu: siatka kopii rigu, każda gra inną animację,
## kamera z przybliżeniem. Do oceny ruchu bez wchodzenia do gry:
##   godot --path . res://tools/anim_preview.tscn
## albo klatki do obejrzenia:
##   godot --path . res://tools/anim_preview.tscn --write-movie out/f.png --fixed-fps 10 --quit-after 30

const RIG_SCENE: PackedScene = preload("res://scenes/player/rigs/warrior_rig.tscn")
const ANIMS: Array[StringName] = [
	&"idle", &"run", &"jump", &"fall", &"attack", &"dodge",
	&"block", &"block_walk", &"hurt", &"knockdown", &"dead",
]
const COLUMNS: int = 6
const CELL: Vector2 = Vector2(56, 64)
## Animacje bez pętli startują od nowa co tyle sekund.
const RESTART_EVERY: float = 1.2

var _rigs: Array[WarriorRig] = []
var _restart_left: float = RESTART_EVERY


func _ready() -> void:
	for i: int in ANIMS.size():
		var cell: Vector2 = Vector2(float(i % COLUMNS), float(i / COLUMNS)) * CELL + Vector2(28, 36)
		var rig: WarriorRig = RIG_SCENE.instantiate() as WarriorRig
		rig.position = cell
		add_child(rig)
		rig.play(ANIMS[i])
		_rigs.append(rig)
		var label: Label = Label.new()
		label.text = String(ANIMS[i])
		label.add_theme_font_size_override(&"font_size", 6)
		label.position = cell + Vector2(-28, 16)
		label.size = Vector2(56, 10)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		var floor_line: ColorRect = ColorRect.new()
		floor_line.position = cell + Vector2(-24, 12)
		floor_line.size = Vector2(48, 1)
		floor_line.color = Color(0.4, 0.4, 0.45, 1)
		add_child(floor_line)
	# Przy zoom 2 kadr ma 320x180 px, więc mieści 6 kolumn po 56 px i dwa rzędy.
	var camera: Camera2D = Camera2D.new()
	camera.zoom = Vector2(2.0, 2.0)
	camera.position = Vector2(COLUMNS * CELL.x * 0.5, CELL.y + 4)
	add_child(camera)


func _process(delta: float) -> void:
	_restart_left -= delta
	if _restart_left > 0.0:
		return
	_restart_left = RESTART_EVERY
	for i: int in _rigs.size():
		_rigs[i].restart(ANIMS[i])
