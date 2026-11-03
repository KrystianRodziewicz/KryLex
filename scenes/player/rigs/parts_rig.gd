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
const KNEE_B: String = "LegBack/Knee"
const KNEE_F: String = "LegFront/Knee"
## Położenie bioder w spoczynku (obie nogi wiszą pod tułowiem).
const LEG_B_HOME: Vector2 = Vector2(-2, 4)
const LEG_F_HOME: Vector2 = Vector2(2, 4)

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


## Zatrzymuje rig w chwili [param time] animacji [param anim], bez blendu
## (narzędzia podglądu klatek, np. tools/anim_strip.tscn).
func pose(anim: StringName, time: float) -> void:
	if not _player.has_animation(anim):
		anim = &"idle"
	_current = anim
	_player.play(anim, 0.0)
	_player.seek(time, true)
	_player.pause()


## Długość animacji w sekundach (0, gdy jej nie ma).
func animation_length(anim: StringName) -> float:
	if not _player.has_animation(anim):
		return 0.0
	return _player.get_animation(anim).length


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
	# Animacja, która nie mówi o kolanach albo położeniu bioder, dostaje je
	# w spoczynku: inaczej kolano zgięte w skoku zostałoby zgięte w idle.
	var all_tracks: Array[Track] = []
	all_tracks.assign(tracks)
	for fallback: Track in _default_tracks():
		if not _has_track(all_tracks, fallback.path):
			all_tracks.append(fallback)
	for track: Track in all_tracks:
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


func _default_tracks() -> Array[Track]:
	return [
		_rot(KNEE_B, [0.0], [0.0]),
		_rot(KNEE_F, [0.0], [0.0]),
		_pos(LEG_B, [0.0], [LEG_B_HOME]),
		_pos(LEG_F, [0.0], [LEG_F_HOME]),
	]


func _has_track(tracks: Array[Track], path: NodePath) -> bool:
	for track: Track in tracks:
		if track.path == path:
			return true
	return false


## Noga z kolanem: obrót w biodrze (ujemny = stopa do przodu) i zgięcie
## goleni (dodatnie = stopa w tył, jak zgina się prawdziwe kolano).
func _leg(leg: String, knee: String, times: PackedFloat32Array,
		hip_degrees: PackedFloat32Array, knee_degrees: PackedFloat32Array) -> Array[Track]:
	return [_rot(leg, times, hip_degrees), _rot(knee, times, knee_degrees)]


## Biodra: obie nogi i tułów przesuwają się razem (wykrok, przysiad), więc
## tułów nie odjeżdża od nóg. [param body_extra] dokłada tułowiowi własne
## przesunięcie, np. wyrównanie pochylenia, które obraca go wokół środka.
func _hips(times: PackedFloat32Array, offsets: Array[Vector2],
		body_extra: Array[Vector2] = []) -> Array[Track]:
	var back: Array[Vector2] = []
	var front: Array[Vector2] = []
	var body: Array[Vector2] = []
	for i: int in offsets.size():
		back.append(LEG_B_HOME + offsets[i])
		front.append(LEG_F_HOME + offsets[i])
		var extra: Vector2 = body_extra[i] if i < body_extra.size() else Vector2.ZERO
		body.append(offsets[i] + extra)
	return [_pos(LEG_B, times, back), _pos(LEG_F, times, front), _pos(BODY, times, body)]


## Bujanie bioder w cyklu chodu: opadają o 2 px dwa razy na cykl, gdy nogi
## są rozstawione, żeby stopa w podporze stała na podłodze zamiast nad nią.
func _gait_bob(cycle: float) -> Array[Track]:
	var drops: Array[int] = [2, 1, 0, 1, 2, 1, 0, 1, 2]
	var times: PackedFloat32Array = PackedFloat32Array()
	var offsets: Array[Vector2] = []
	for i: int in drops.size():
		times.append(cycle * float(i) / 8.0)
		offsets.append(Vector2(0.0, float(drops[i])))
	return _hips(times, offsets)


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
