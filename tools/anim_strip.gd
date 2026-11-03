extends Node2D
## Taśma klatek jednej animacji: rząd na rig, w nim kopie zatrzymane
## w kolejnych chwilach animacji (pętla: równe kroki przez cały cykl,
## bez pętli: od początku do końca). Pozioma kreska to poziom stóp,
## pionowa to oś postaci (pozycja gracza), więc widać, czy tułów ucieka nogom.
##   godot --headless --path . res://tools/anim_strip.tscn --write-movie out/strip.png --fixed-fps 10 --quit-after 2 -- run 8
## Argumenty po "--": nazwa animacji (domyślnie run) i liczba klatek (domyślnie 8).

const RIGS: Array[PackedScene] = [
	preload("res://scenes/player/rigs/warrior_rig.tscn"),
	preload("res://scenes/player/rigs/mage_rig.tscn"),
]
const CELL: Vector2 = Vector2(24, 40)
const VIEW: Vector2 = Vector2(640, 360)


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var anim: StringName = StringName(args[0]) if args.size() > 0 else &"run"
	var frames: int = maxi(int(args[1]), 2) if args.size() > 1 else 8
	for row: int in RIGS.size():
		var rig_scene: PackedScene = RIGS[row]
		for col: int in frames:
			var cell: Vector2 = Vector2(float(col), float(row)) * CELL + Vector2(12, 26)
			var rig: PartsRig = rig_scene.instantiate() as PartsRig
			rig.position = cell
			add_child(rig)
			var length: float = rig.animation_length(anim)
			var animation_player: AnimationPlayer = rig.get_node(^"AnimationPlayer") as AnimationPlayer
			var looped: bool = length > 0.0 \
				and animation_player.get_animation(anim).loop_mode != Animation.LOOP_NONE
			var steps: int = frames if looped else frames - 1
			var time: float = length * float(col) / float(steps)
			rig.pose(anim, time)
			if row == 0:
				var body: Node2D = rig.get_node(^"Body") as Node2D
				var leg_f: Node2D = rig.get_node(^"LegFront") as Node2D
				var leg_b: Node2D = rig.get_node(^"LegBack") as Node2D
				print("[anim-strip] kolumna %d: t = %.3f s, tułów %.0f° %s, noga przednia %.0f°, tylna %.0f°" % [
					col, time, rad_to_deg(body.rotation), body.position,
					rad_to_deg(leg_f.rotation), rad_to_deg(leg_b.rotation)])
			var floor_line: ColorRect = ColorRect.new()
			floor_line.position = cell + Vector2(-11, 12)
			floor_line.size = Vector2(22, 1)
			floor_line.color = Color(0.4, 0.4, 0.45, 1)
			add_child(floor_line)
			var axis: ColorRect = ColorRect.new()
			axis.position = cell + Vector2(0, -22)
			axis.size = Vector2(1, 36)
			axis.color = Color(0.3, 0.2, 0.2, 0.6)
			axis.z_index = -1
			add_child(axis)
	var grid: Vector2 = Vector2(float(frames), float(RIGS.size())) * CELL
	var zoom: float = floorf(minf(VIEW.x / grid.x, VIEW.y / grid.y))
	var camera: Camera2D = Camera2D.new()
	camera.zoom = Vector2(zoom, zoom)
	camera.position = grid * 0.5
	add_child(camera)
	print("[anim-strip] animacja %s, %d klatek, zoom x%d" % [anim, frames, int(zoom)])
