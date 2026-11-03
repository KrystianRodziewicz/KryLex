class_name PartsRig
extends PlayerRig
## Wspólna mechanika rigów "z części" (paper doll): AnimationPlayer budowany
## w kodzie, tory na obrotach i pozycjach przegubów, odtwarzanie z blendem.
## Klasa pochodna (WarriorRig, MageRig) tylko rejestruje swoje animacje
## w [method _register_animations].
##
## Hitboxy nie są kluczowane w animacji: o oknie ataku decyduje PlayerStats,
## a [method play] dostaje czas trwania i dopasowuje do niego tempo.

const BODY: String = "Body"
const HEAD: String = "Body/Neck"
const ARM_B: String = "Body/ShoulderBack"
const ARM_F: String = "Body/ShoulderFront"
const HAND_B: String = "Body/ShoulderBack/Hand"
const HAND_F: String = "Body/ShoulderFront/Hand"
const LEG_B: String = "LegBack"
const LEG_F: String = "LegFront"

var _current: StringName = &""
var _player: AnimationPlayer = null


func _ready() -> void:
	_player = AnimationPlayer.new()
	_player.name = "AnimationPlayer"
	add_child(_player)
	var library: AnimationLibrary = AnimationLibrary.new()
	_register_animations(library)
	_player.add_animation_library(&"", library)
	play(&"idle")


## Nadpisz: dodaj animacje do biblioteki (idle, run, jump, fall, attack,
## dodge, block, block_walk, hurt, knockdown, dead; brakujące wracają do idle).
func _register_animations(_library: AnimationLibrary) -> void:
	pass


## Ta sama animacja nie startuje od nowa (skok trzyma ostatnią pozę, aż
## gracz zacznie spadać). Nowa animacja przenika z poprzedniej przez krótki
## blend, więc przejścia bieg → skok → lot nie szarpią.
func play(anim: StringName, duration: float = -1.0) -> void:
	if anim == _current:
		return
	restart(anim, duration)


func restart(anim: StringName, duration: float = -1.0) -> void:
	if not _player.has_animation(anim):
		anim = &"idle"
	var blend: float = 0.03 if anim in [&"attack", &"hurt", &"knockdown", &"dead"] else 0.08
	# Po pełnym obrocie (fikołek) tułów stoi na 360 stopniach; blend cofałby go
	# do zera przez ćwierć obrotu w drugą stronę, więc wtedy bez przenikania.
	if _current == &"dodge":
		blend = 0.0
	_current = anim
	var speed: float = 1.0
	if duration > 0.0:
		var length: float = _player.get_animation(anim).length
		speed = length / duration
	_player.play(anim, blend, speed)


## Nazwa bieżącej animacji (do podglądu i testów).
func current_animation() -> StringName:
	return _current


# --- Budowanie animacji -------------------------------------------------------------


## Jeden tor: ścieżka właściwości i lista par (czas, wartość).
class Track:
	extends RefCounted
	var path: NodePath
	var times: PackedFloat32Array
	var values: Array
	var discrete: bool

	func _init(p_path: NodePath, p_times: PackedFloat32Array, p_values: Array,
			p_discrete: bool = false) -> void:
		path = p_path
		times = p_times
		values = p_values
		discrete = p_discrete


func _build(length: float, loop: bool, tracks: Array[Track]) -> Animation:
	var anim: Animation = Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for track: Track in tracks:
		var idx: int = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(idx, track.path)
		anim.track_set_interpolation_type(idx, Animation.INTERPOLATION_LINEAR)
		anim.value_track_set_update_mode(idx,
			Animation.UPDATE_DISCRETE if track.discrete else Animation.UPDATE_CONTINUOUS)
		for i: int in track.times.size():
			anim.track_insert_key(idx, track.times[i], track.values[i])
	return anim


func _rot(path: String, times: PackedFloat32Array, degrees: PackedFloat32Array) -> Track:
	var values: Array = []
	for d: float in degrees:
		values.append(deg_to_rad(d))
	return Track.new(NodePath(path + ":rotation"), times, values)


func _pos(path: String, times: PackedFloat32Array, points: Array[Vector2], discrete: bool = true) -> Track:
	var values: Array = []
	for p: Vector2 in points:
		values.append(p)
	return Track.new(NodePath(path + ":position"), times, values, discrete)


func _color(path: String, times: PackedFloat32Array, colors: Array[Color]) -> Track:
	var values: Array = []
	for c: Color in colors:
		values.append(c)
	return Track.new(NodePath(path + ":modulate"), times, values)


## Ręka z własnym obrotem dłoni (miecz, laska): ramię i dłoń osobno.
func _arm_with_hand(arm: String, hand: String, times: PackedFloat32Array,
		arm_degrees: PackedFloat32Array, hand_degrees: PackedFloat32Array) -> Array[Track]:
	return [_rot(arm, times, arm_degrees), _rot(hand, times, hand_degrees)]


## Ręka, której dłoń dostaje obrót przeciwny do ramienia (tarcza w pionie,
## fokus zawsze "do góry"), plus stały [param tilt].
func _arm_level_hand(arm: String, hand: String, times: PackedFloat32Array,
		arm_degrees: PackedFloat32Array, tilt: float = 0.0) -> Array[Track]:
	var hand_degrees: PackedFloat32Array = PackedFloat32Array()
	for d: float in arm_degrees:
		hand_degrees.append(-d + tilt)
	return [_rot(arm, times, arm_degrees), _rot(hand, times, hand_degrees)]
