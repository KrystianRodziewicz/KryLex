class_name WarriorRig
extends PlayerRig
## Wojownik z części: głowa, tułów, dwie ręce, dwie nogi, miecz i tarcza,
## każda jako Sprite2D z assets/sprites/warrior. Animacje to klatki kluczowe
## na obrotach i pozycjach przegubów, budowane tutaj w kodzie, więc poprawka
## ruchu to zmiana jednej liczby.
##
## Hitboxy nie są kluczowane w animacji: o oknie ataku decyduje PlayerStats,
## a [method play] dostaje czas trwania i dopasowuje do niego tempo.
##
## Dłonie mają własne obroty: miecz leży w dłoni klingą od barku (0 stopni =
## klinga przedłuża rękę), a tarcza dostaje obrót przeciwny do ręki, więc
## zawsze stoi w pionie, niezależnie od tego, co robi ramię.

const BODY: String = "Body"
const HEAD: String = "Body/Neck"
const ARM_B: String = "Body/ShoulderBack"
const ARM_F: String = "Body/ShoulderFront"
const HAND_B: String = "Body/ShoulderBack/Hand"
const HAND_F: String = "Body/ShoulderFront/Hand"
const LEG_B: String = "LegBack"
const LEG_F: String = "LegFront"

## Spoczynkowy obrót dłoni z mieczem: klinga oparta o bark, nie w ziemi.
const SWORD_REST: float = -150.0

var _current: StringName = &""
var _player: AnimationPlayer = null


func _ready() -> void:
	_player = AnimationPlayer.new()
	_player.name = "AnimationPlayer"
	add_child(_player)
	var library: AnimationLibrary = AnimationLibrary.new()
	library.add_animation(&"idle", _anim_idle())
	library.add_animation(&"run", _anim_run())
	library.add_animation(&"jump", _anim_jump())
	library.add_animation(&"fall", _anim_fall())
	library.add_animation(&"attack", _anim_attack())
	library.add_animation(&"dodge", _anim_dodge())
	library.add_animation(&"block", _anim_block(false))
	library.add_animation(&"block_walk", _anim_block(true))
	library.add_animation(&"hurt", _anim_hurt())
	library.add_animation(&"knockdown", _anim_knockdown())
	library.add_animation(&"dead", _anim_dead())
	_player.add_animation_library(&"", library)
	play(&"idle")


func setup(_stats: PlayerStats) -> void:
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


## Tylna ręka z tarczą: ramię obraca się, a dłoń dostaje obrót przeciwny
## (plus [param tilt]), więc tarcza zostaje w pionie.
func _shield_arm(times: PackedFloat32Array, arm_degrees: PackedFloat32Array, tilt: float = 0.0) -> Array[Track]:
	var hand: PackedFloat32Array = PackedFloat32Array()
	for d: float in arm_degrees:
		hand.append(-d + tilt)
	return [_rot(ARM_B, times, arm_degrees), _rot(HAND_B, times, hand)]


## Przednia ręka z mieczem: ramię i osobny obrót dłoni (0 = klinga przedłuża rękę).
func _sword_arm(times: PackedFloat32Array, arm_degrees: PackedFloat32Array,
		hand_degrees: PackedFloat32Array) -> Array[Track]:
	return [_rot(ARM_F, times, arm_degrees), _rot(HAND_F, times, hand_degrees)]


func _anim_idle() -> Animation:
	# Spokojny oddech: tułów opada o piksel raz na 1,6 s, ręce ledwo drgają.
	# Miecz oparty o bark, tarcza wisi z przodu przy biodrze.
	var t: PackedFloat32Array = [0.0, 0.8, 1.6]
	var tracks: Array[Track] = [
		_pos(BODY, t, [Vector2(0, 0), Vector2(0, 1), Vector2(0, 0)]),
		_rot(LEG_B, [0.0], [0.0]),
		_rot(LEG_F, [0.0], [0.0]),
		_rot(HEAD, [0.0], [0.0]),
		_rot(BODY, [0.0], [0.0]),
	]
	tracks.append_array(_sword_arm(t, [22.0, 19.0, 22.0], [SWORD_REST, SWORD_REST - 3.0, SWORD_REST]))
	tracks.append_array(_shield_arm(t, [-28.0, -25.0, -28.0]))
	return _build(1.6, true, tracks)


func _anim_run() -> Animation:
	# Nogi na przemian, ręce w przeciwfazie, tułów podskakuje dwa razy na cykl.
	var t: PackedFloat32Array = [0.0, 0.15, 0.3, 0.45, 0.6]
	var tracks: Array[Track] = [
		_rot(LEG_F, t, [35.0, 0.0, -35.0, 0.0, 35.0]),
		_rot(LEG_B, t, [-35.0, 0.0, 35.0, 0.0, -35.0]),
		_pos(BODY, t, [Vector2(0, 0), Vector2(0, -1), Vector2(0, 0), Vector2(0, -1), Vector2(0, 0)]),
		_rot(BODY, [0.0], [6.0]),
		_rot(HEAD, [0.0], [0.0]),
	]
	tracks.append_array(_sword_arm(t, [-20.0, 5.0, 30.0, 5.0, -20.0],
		[SWORD_REST, SWORD_REST, SWORD_REST, SWORD_REST, SWORD_REST]))
	tracks.append_array(_shield_arm(t, [-45.0, -25.0, -5.0, -25.0, -45.0]))
	return _build(0.6, true, tracks)


func _anim_jump() -> Animation:
	# Odbicie: nogi podciągają się, ręce idą w górę; poza trzyma się do szczytu lotu.
	var t: PackedFloat32Array = [0.0, 0.25, 0.5]
	var tracks: Array[Track] = [
		_rot(LEG_F, [0.0, 0.2, 0.5], [10.0, 30.0, 25.0]),
		_rot(LEG_B, [0.0, 0.2, 0.5], [-10.0, -35.0, -30.0]),
		_pos(BODY, [0.0], [Vector2(0, 0)]),
		_rot(BODY, [0.0, 0.25], [0.0, -5.0]),
		_rot(HEAD, [0.0], [0.0]),
	]
	tracks.append_array(_sword_arm(t, [-20.0, -70.0, -80.0], [SWORD_REST, -120.0, -110.0]))
	tracks.append_array(_shield_arm(t, [-50.0, -95.0, -105.0]))
	return _build(0.5, false, tracks)


func _anim_fall() -> Animation:
	# Zaczyna z pozy skoku i powoli rozkłada ręce do lądowania.
	var t: PackedFloat32Array = [0.0, 0.5]
	var tracks: Array[Track] = [
		_rot(LEG_F, t, [25.0, 15.0]),
		_rot(LEG_B, t, [-30.0, -15.0]),
		_pos(BODY, [0.0], [Vector2(0, 0)]),
		_rot(BODY, t, [-5.0, 6.0]),
		_rot(HEAD, [0.0], [0.0]),
	]
	tracks.append_array(_sword_arm(t, [-80.0, -110.0], [-110.0, -100.0]))
	tracks.append_array(_shield_arm(t, [-105.0, -125.0]))
	return _build(0.5, false, tracks)


func _anim_attack() -> Animation:
	# 0,42 s jak w player_warrior.tres: zamach nad głowę (zapowiedź), cięcie
	# klingą do przodu, powrót. Dłoń prostuje miecz w linię ręki w zamachu
	# i lekko go kładzie przy cięciu, żeby ostrze szło poziomo.
	var t: PackedFloat32Array = [0.0, 0.1, 0.17, 0.2, 0.42]
	var tracks: Array[Track] = [
		_rot(BODY, [0.0, 0.1, 0.2, 0.42], [0.0, -10.0, 14.0, 0.0]),
		_pos(BODY, [0.0, 0.1, 0.2, 0.42], [Vector2(0, 0), Vector2(-1, 0), Vector2(2, 0), Vector2(0, 0)]),
		_rot(LEG_F, [0.0, 0.2, 0.42], [0.0, 20.0, 0.0]),
		_rot(LEG_B, [0.0, 0.2, 0.42], [0.0, -15.0, 0.0]),
		_rot(HEAD, [0.0, 0.2, 0.42], [0.0, 8.0, 0.0]),
	]
	tracks.append_array(_sword_arm(t, [22.0, -165.0, 60.0, 75.0, 22.0],
		[SWORD_REST, 0.0, -30.0, -40.0, SWORD_REST]))
	tracks.append_array(_shield_arm([0.0, 0.1, 0.2, 0.42], [-28.0, 15.0, -60.0, -28.0]))
	return _build(0.42, false, tracks)


func _anim_dodge() -> Animation:
	# Fikołek: przysiad, obrót o 360 stopni z rozpędem w środku, wstanie.
	# Czas trwania narzuca PlayerStats.dodge_duration (0,45 s u Wojownika).
	var t: PackedFloat32Array = [0.0, 0.1, 0.45]
	var tracks: Array[Track] = [
		_rot(BODY, [0.0, 0.08, 0.3, 0.45], [0.0, 40.0, 300.0, 360.0]),
		_pos(BODY, [0.0, 0.1, 0.3, 0.45], [Vector2(0, 2), Vector2(0, 6), Vector2(0, 6), Vector2(0, 0)]),
		_rot(LEG_F, [0.0, 0.1, 0.4, 0.45], [20.0, 70.0, 70.0, 0.0]),
		_rot(LEG_B, [0.0, 0.1, 0.4, 0.45], [-20.0, -70.0, -70.0, 0.0]),
		_rot(HEAD, t, [0.0, 20.0, 0.0]),
	]
	tracks.append_array(_sword_arm(t, [-20.0, -60.0, 22.0], [SWORD_REST, -100.0, SWORD_REST]))
	# W fikołku tarcza przylega do ciała, więc obraca się razem z nim (tilt = obrót ręki).
	tracks.append_array([_rot(ARM_B, t, [-40.0, -90.0, -28.0]), _rot(HAND_B, t, [40.0, 90.0, 28.0])])
	return _build(0.45, false, tracks)


func _anim_block(walking: bool) -> Animation:
	# Tarcza z tylnej ręki idzie do przodu i w górę, w pionie; lekki przysiad.
	var tracks: Array[Track] = [
		_rot(BODY, [0.0], [8.0]),
		_pos(BODY, [0.0], [Vector2(0, 1)]),
		_rot(HEAD, [0.0], [0.0]),
	]
	tracks.append_array(_sword_arm([0.0], [35.0], [SWORD_REST]))
	tracks.append_array(_shield_arm([0.0], [-100.0], -8.0))
	if walking:
		var t: PackedFloat32Array = [0.0, 0.25, 0.5, 0.75, 1.0]
		tracks.append(_rot(LEG_F, t, [15.0, 0.0, -15.0, 0.0, 15.0]))
		tracks.append(_rot(LEG_B, t, [-15.0, 0.0, 15.0, 0.0, -15.0]))
	else:
		tracks.append(_rot(LEG_F, [0.0], [12.0]))
		tracks.append(_rot(LEG_B, [0.0], [-12.0]))
	return _build(1.0, true, tracks)


func _anim_hurt() -> Animation:
	var t: PackedFloat32Array = [0.0, 0.08, 0.25]
	var tracks: Array[Track] = [
		_rot(BODY, t, [0.0, -22.0, 0.0]),
		_pos(BODY, t, [Vector2(0, 0), Vector2(-2, 0), Vector2(0, 0)]),
		_rot(HEAD, t, [0.0, -15.0, 0.0]),
		_rot(LEG_F, [0.0], [0.0]),
		_rot(LEG_B, [0.0], [0.0]),
	]
	tracks.append_array(_sword_arm(t, [22.0, -60.0, 22.0], [SWORD_REST, -120.0, SWORD_REST]))
	tracks.append_array(_shield_arm(t, [-28.0, 40.0, -28.0]))
	return _build(0.25, false, tracks)


func _anim_knockdown() -> Animation:
	# Pada na plecy i leży do końca ogłuszenia.
	var t: PackedFloat32Array = [0.0, 0.15]
	var tracks: Array[Track] = [
		_rot(BODY, [0.0, 0.15, 0.7], [-20.0, -80.0, -80.0]),
		_pos(BODY, t, [Vector2(0, 0), Vector2(-4, 6)]),
		_rot(LEG_F, t, [20.0, -60.0]),
		_rot(LEG_B, t, [-10.0, -70.0]),
		_rot(HEAD, t, [-10.0, -20.0]),
	]
	tracks.append_array(_sword_arm(t, [-60.0, -110.0], [-120.0, -60.0]))
	tracks.append_array([_rot(ARM_B, t, [60.0, 100.0]), _rot(HAND_B, t, [-40.0, -20.0])])
	return _build(0.7, false, tracks)


func _anim_dead() -> Animation:
	var t: PackedFloat32Array = [0.0, 0.3]
	var tracks: Array[Track] = [
		_rot(BODY, [0.0, 0.3, 0.6], [-20.0, -90.0, -90.0]),
		_pos(BODY, t, [Vector2(0, 0), Vector2(-5, 7)]),
		_rot(LEG_F, t, [10.0, -80.0]),
		_rot(LEG_B, t, [-10.0, -85.0]),
		_rot(HEAD, t, [-10.0, -30.0]),
	]
	tracks.append_array(_sword_arm(t, [-40.0, -100.0], [-120.0, -30.0]))
	tracks.append_array([_rot(ARM_B, t, [40.0, 95.0]), _rot(HAND_B, t, [-30.0, -5.0])])
	return _build(0.6, false, tracks)
