class_name MageRig
extends PartsRig
## Mag z części: kaptur, szata, dwie ręce, dwie nogi, laska z kryształem
## w przedniej dłoni i fokus (świecąca kula) w tylnej (assets/sprites/mage).
##
## Laska stoi w dłoni kryształem do góry (0 stopni = wzdłuż ręki ku barkowi).
## Obrót dłoni dobiera się tak, żeby suma kątów ramienia i dłoni dawała
## 10 do 20 stopni: kryształ wychyla się lekko do przodu i widać, że Mag
## ją trzyma. W ataku dłoń obraca laskę kryształem do przodu. Fokus unosi się nad tylną
## dłonią i rozbłyska przy ataku. Mag nie ma bloku (README, sekcja 4), więc
## block wraca do idle, a unik to krótki doskok, nie fikołek.

const ORB: String = "Body/ShoulderBack/Hand/Orb"
const ORB_IDLE: Color = Color(1.0, 1.0, 1.0, 0.9)
const ORB_FLASH: Color = Color(1.8, 1.8, 1.6, 1.0)

## Liczba poziomych odłamków, na które dzieli się łuk bariery.
const BARRIER_PIECES: int = 10
## Odstęp między kolejnymi parami odłamków przy formowaniu (od końców do środka).
const BARRIER_FORM_STEP: float = 0.045

var _pieces: Array[Sprite2D] = []
var _homes: Array[Vector2] = []
var _pieces_root: Node2D = null
var _barrier_tweens: Array[Tween] = []
var _barrier_visible: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var _barrier: Sprite2D = $Barrier as Sprite2D
@onready var _ring: Sprite2D = $Ring as Sprite2D


func _ready() -> void:
	super()
	_build_barrier_pieces()


## Tnie teksturę łuku na poziome paski, każdy jako osobny Sprite2D z region_rect.
## Szablon $Barrier zostaje niewidoczny; animacje działają na odłamkach.
func _build_barrier_pieces() -> void:
	_barrier.visible = false
	_pieces_root = Node2D.new()
	_pieces_root.name = "BarrierPieces"
	_pieces_root.z_index = _barrier.z_index
	_pieces_root.visible = false
	add_child(_pieces_root)
	var width: int = _barrier.texture.get_width()
	var height: int = _barrier.texture.get_height()
	for i: int in BARRIER_PIECES:
		var y0: int = int(float(height) * float(i) / float(BARRIER_PIECES))
		var y1: int = int(float(height) * float(i + 1) / float(BARRIER_PIECES))
		var piece: Sprite2D = Sprite2D.new()
		piece.texture = _barrier.texture
		piece.centered = false
		piece.region_enabled = true
		piece.region_rect = Rect2(0, y0, width, y1 - y0)
		piece.offset = Vector2.ZERO
		piece.position = _barrier.offset + Vector2(0, float(y0))
		_homes.append(piece.position)
		_pieces_root.add_child(piece)
		_pieces.append(piece)


## Bariera: łuk przed postacią. Formuje się od góry i od dołu jednocześnie,
## odłamki spotykają się na środku z błyskiem; stoi pulsując, a gdy wchłonie
## cios albo minie jej czas, pęka na kawałki (po ciosie wybucha na zewnątrz,
## po czasie kruszy się i opada).
func set_barrier(active: bool, absorbed: bool = false) -> void:
	_kill_barrier_tweens()
	if active:
		_materialize_barrier()
		return
	if not _barrier_visible:
		return
	_shatter_barrier(absorbed)


func _materialize_barrier() -> void:
	_barrier_visible = true
	_pieces_root.visible = true
	_pieces_root.modulate = Color.WHITE
	var n: int = _pieces.size()
	var middle: float = float(n - 1) * 0.5
	var last_delay: float = 0.0
	for i: int in n:
		var piece: Sprite2D = _pieces[i]
		var home: Vector2 = _homes[i]
		var from_top: bool = float(i) < middle
		# Odległość od bliższego końca: pary odłamków wchodzą w tej samej chwili.
		var order: int = mini(i, n - 1 - i)
		var delay: float = float(order) * BARRIER_FORM_STEP
		last_delay = maxf(last_delay, delay)
		piece.rotation = 0.0
		piece.scale = Vector2.ONE
		piece.position = home + Vector2(0.0, -10.0 if from_top else 10.0)
		piece.modulate = Color(2.0, 2.0, 2.0, 0.0)
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(piece, ^"position", home, 0.09).set_delay(delay) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(piece, ^"modulate", Color(1.6, 1.6, 1.6, 1.0), 0.09).set_delay(delay)
		_barrier_tweens.append(tween)
	# Spotkanie na środku: błysk całości, potem pulsowanie.
	var flash: Tween = create_tween()
	flash.tween_interval(last_delay + 0.09)
	flash.tween_property(_pieces_root, ^"modulate", Color(2.4, 2.4, 2.4, 1.0), 0.05)
	flash.tween_property(_pieces_root, ^"modulate", Color(1.0, 1.0, 1.0, 0.85), 0.12)
	flash.tween_callback(_start_barrier_pulse)
	_barrier_tweens.append(flash)


func _shatter_barrier(absorbed: bool) -> void:
	_barrier_visible = false
	_rng.seed = 7 if absorbed else 11
	var n: int = _pieces.size()
	var middle: float = float(n - 1) * 0.5
	var duration: float = 0.35 if absorbed else 0.5
	_pieces_root.modulate = Color(2.2, 2.2, 2.2, 1.0) if absorbed else Color.WHITE
	for i: int in n:
		var piece: Sprite2D = _pieces[i]
		var home: Vector2 = _homes[i]
		var spread: float = (float(i) - middle) / middle
		var target: Vector2
		var spin: float
		if absorbed:
			# Wybuch na zewnątrz: w przód i w górę albo w dół, zależnie od położenia odłamka.
			target = home + Vector2(_rng.randf_range(8.0, 18.0), spread * 14.0 + _rng.randf_range(-3.0, 3.0))
			spin = _rng.randf_range(-2.5, 2.5)
		else:
			# Kruszenie: odłamki lekko się rozsuwają i opadają pod własnym ciężarem.
			target = home + Vector2(_rng.randf_range(-2.0, 6.0), 14.0 + _rng.randf_range(0.0, 8.0))
			spin = _rng.randf_range(-1.0, 1.0)
		var delay: float = 0.0 if absorbed else _rng.randf_range(0.0, 0.12)
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(piece, ^"position", target, duration).set_delay(delay) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if absorbed else Tween.EASE_IN)
		tween.tween_property(piece, ^"rotation", spin, duration).set_delay(delay)
		tween.tween_property(piece, ^"modulate:a", 0.0, duration).set_delay(delay) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_barrier_tweens.append(tween)
	var finish: Tween = create_tween()
	finish.tween_interval(duration + 0.15)
	finish.tween_callback(_hide_barrier)
	_barrier_tweens.append(finish)


func _start_barrier_pulse() -> void:
	var pulse: Tween = create_tween().set_loops()
	pulse.tween_property(_pieces_root, ^"modulate:a", 1.0, 0.4)
	pulse.tween_property(_pieces_root, ^"modulate:a", 0.65, 0.4)
	_barrier_tweens.append(pulse)


func _hide_barrier() -> void:
	_pieces_root.visible = false
	for i: int in _pieces.size():
		var piece: Sprite2D = _pieces[i]
		piece.position = _homes[i]
		piece.rotation = 0.0
		piece.modulate = Color.WHITE


func _kill_barrier_tweens() -> void:
	for tween: Tween in _barrier_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_barrier_tweens.clear()


func _register_animations(library: AnimationLibrary) -> void:
	library.add_animation(&"idle", _anim_idle())
	library.add_animation(&"run", _anim_run())
	library.add_animation(&"jump", _anim_jump())
	library.add_animation(&"fall", _anim_fall())
	library.add_animation(&"attack", _anim_attack())
	library.add_animation(&"impulse", _anim_impulse())
	library.add_animation(&"dodge", _anim_dodge())
	library.add_animation(&"hurt", _anim_hurt())
	library.add_animation(&"knockdown", _anim_knockdown())
	library.add_animation(&"dead", _anim_dead())


func _staff_arm(times: PackedFloat32Array, arm_degrees: PackedFloat32Array,
		hand_degrees: PackedFloat32Array) -> Array[Track]:
	return _arm_with_hand(ARM_F, HAND_F, times, arm_degrees, hand_degrees)


func _orb_arm(times: PackedFloat32Array, arm_degrees: PackedFloat32Array) -> Array[Track]:
	return _arm_level_hand(ARM_B, HAND_B, times, arm_degrees)


func _anim_idle() -> Animation:
	# Laska oparta o ziemię przed sobą, fokus unosi się przy biodrze i pulsuje.
	var t: PackedFloat32Array = [0.0, 0.9, 1.8]
	var tracks: Array[Track] = [
		_pos(BODY, t, [Vector2(0, 0), Vector2(0, 1), Vector2(0, 0)]),
		_rot(LEG_B, [0.0], [0.0]),
		_rot(LEG_F, [0.0], [0.0]),
		_rot(HEAD, [0.0], [0.0]),
		_rot(BODY, [0.0], [0.0]),
		_pos(ORB, t, [Vector2(0, -2), Vector2(0, -4), Vector2(0, -2)], false),
		_color(ORB, t, [ORB_IDLE, Color(1.3, 1.3, 1.2, 1.0), ORB_IDLE]),
	]
	tracks.append_array(_staff_arm(t, [-12.0, -10.0, -12.0], [24.0, 22.0, 24.0]))
	tracks.append_array(_orb_arm(t, [-35.0, -32.0, -35.0]))
	return _build(1.8, true, tracks)


func _anim_run() -> Animation:
	# Bieg, cykl 0,4 s, ten sam krok co u Wojownika: noga w podporze prosta
	# pod ciałem, w wymachu zgięte kolano, biodra opadają o 2 px przy
	# rozstawionych nogach. Laska uniesiona nad ziemię, fokus przed sobą.
	var t: PackedFloat32Array = [0.0, 0.1, 0.2, 0.3, 0.4]
	var tracks: Array[Track] = [
		_rot(BODY, [0.0], [10.0]),
		_rot(HEAD, [0.0], [-4.0]),
		_pos(ORB, [0.0], [Vector2(0, -2)], false),
		_color(ORB, [0.0], [ORB_IDLE]),
	]
	tracks.append_array(_gait_bob(0.4))
	tracks.append_array(_leg(LEG_F, KNEE_F, t, [-40.0, -5.0, 35.0, 0.0, -40.0], [10.0, 0.0, 5.0, 70.0, 10.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, t, [35.0, 0.0, -40.0, -5.0, 35.0], [5.0, 70.0, 10.0, 0.0, 5.0]))
	tracks.append_array(_staff_arm(t, [-20.0, -30.0, -40.0, -30.0, -20.0], [38.0, 45.0, 55.0, 45.0, 38.0]))
	tracks.append_array(_orb_arm(t, [-60.0, -50.0, -40.0, -50.0, -60.0]))
	return _build(0.4, true, tracks)


func _anim_jump() -> Animation:
	var t: PackedFloat32Array = [0.0, 0.25, 0.5]
	var tracks: Array[Track] = [
		_pos(BODY, [0.0], [Vector2(0, 0)]),
		_rot(BODY, [0.0, 0.25], [0.0, -5.0]),
		_rot(HEAD, [0.0], [0.0]),
		_pos(ORB, [0.0], [Vector2(0, -2)], false),
		_color(ORB, [0.0], [ORB_IDLE]),
	]
	tracks.append_array(_leg(LEG_F, KNEE_F, [0.0, 0.2, 0.5], [10.0, 30.0, 25.0], [10.0, 45.0, 35.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, [0.0, 0.2, 0.5], [-10.0, -35.0, -30.0], [10.0, 40.0, 30.0]))
	tracks.append_array(_staff_arm(t, [-30.0, -70.0, -80.0], [45.0, 90.0, 100.0]))
	tracks.append_array(_orb_arm(t, [-60.0, -100.0, -110.0]))
	return _build(0.5, false, tracks)


func _anim_fall() -> Animation:
	var t: PackedFloat32Array = [0.0, 0.5]
	var tracks: Array[Track] = [
		_pos(BODY, [0.0], [Vector2(0, 0)]),
		_rot(BODY, t, [-5.0, 6.0]),
		_rot(HEAD, [0.0], [0.0]),
		_pos(ORB, [0.0], [Vector2(0, -2)], false),
		_color(ORB, [0.0], [ORB_IDLE]),
	]
	tracks.append_array(_leg(LEG_F, KNEE_F, t, [25.0, 15.0], [35.0, 10.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, t, [-30.0, -15.0], [30.0, 10.0]))
	tracks.append_array(_staff_arm(t, [-80.0, -110.0], [100.0, 125.0]))
	tracks.append_array(_orb_arm(t, [-110.0, -130.0]))
	return _build(0.5, false, tracks)


func _anim_attack() -> Animation:
	# 0,3 s jak w player_mage.tres: laska odchyla się w tył, pchnięcie
	# kryształem do przodu z rozbłyskiem fokusu, powrót.
	var t: PackedFloat32Array = [0.0, 0.06, 0.12, 0.3]
	var tracks: Array[Track] = [
		_rot(BODY, t, [0.0, -8.0, 12.0, 0.0]),
		_pos(BODY, t, [Vector2(0, 0), Vector2(-1, 0), Vector2(2, 0), Vector2(0, 0)]),
		_rot(LEG_F, [0.0, 0.12, 0.3], [0.0, 25.0, 0.0]),
		_rot(LEG_B, [0.0, 0.12, 0.3], [0.0, -15.0, 0.0]),
		_rot(HEAD, [0.0, 0.12, 0.3], [0.0, 6.0, 0.0]),
		_pos(ORB, [0.0, 0.12, 0.3], [Vector2(0, -2), Vector2(2, -4), Vector2(0, -2)], false),
		_color(ORB, [0.0, 0.1, 0.14, 0.3], [ORB_IDLE, ORB_FLASH, ORB_FLASH, ORB_IDLE]),
	]
	tracks.append_array(_staff_arm(t, [-12.0, 30.0, -95.0, -12.0], [24.0, 10.0, 175.0, 24.0]))
	tracks.append_array(_orb_arm(t, [-35.0, -20.0, -120.0, -35.0]))
	return _build(0.3, false, tracks)


func _anim_impulse() -> Animation:
	# Przerwij: impuls. 0,55 s jak w balansie: laska w górę, uderzenie w ziemię,
	# fokus rozbłyska, pierścień rozchodzi się z rigu (impulse_burst).
	# Przy uderzeniu biodra opadają o piksel razem z tułowiem (przysiad).
	var t: PackedFloat32Array = [0.0, 0.15, 0.25, 0.55]
	var tracks: Array[Track] = [
		_rot(BODY, t, [0.0, -10.0, 14.0, 0.0]),
		_rot(HEAD, t, [0.0, -8.0, 10.0, 0.0]),
		_pos(ORB, [0.0, 0.25, 0.55], [Vector2(0, -2), Vector2(0, -6), Vector2(0, -2)], false),
		_color(ORB, [0.0, 0.2, 0.3, 0.55], [ORB_IDLE, ORB_FLASH, ORB_FLASH, ORB_IDLE]),
	]
	tracks.append_array(_hips(t,
		[Vector2(0, 0), Vector2(0, 0), Vector2(0, 1), Vector2(0, 0)],
		[Vector2(0, 0), Vector2(0, -1), Vector2(0, 1), Vector2(0, 0)]))
	tracks.append_array(_leg(LEG_F, KNEE_F, t, [0.0, 10.0, 30.0, 0.0], [0.0, 5.0, 15.0, 0.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, t, [0.0, -10.0, -25.0, 0.0], [0.0, 5.0, 10.0, 0.0]))
	tracks.append_array(_staff_arm(t, [-12.0, -150.0, 25.0, -12.0], [24.0, 160.0, -10.0, 24.0]))
	tracks.append_array(_orb_arm(t, [-35.0, -120.0, -60.0, -35.0]))
	return _build(0.55, false, tracks)


## Pierścień impulsu: rozchodzi się od stóp Maga i gaśnie.
func impulse_burst() -> void:
	_ring.visible = true
	_ring.scale = Vector2(0.4, 0.3)
	_ring.modulate = Color(1.8, 1.8, 1.8, 1.0)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_ring, ^"scale", Vector2(5.5, 4.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_ring, ^"modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(_hide_ring)


func _hide_ring() -> void:
	_ring.visible = false


func _anim_dodge() -> Animation:
	# Doskok: pochylenie do przodu, laska w tył, szata za plecami. 0,28 s.
	var t: PackedFloat32Array = [0.0, 0.1, 0.28]
	var tracks: Array[Track] = [
		_rot(BODY, t, [10.0, 32.0, 0.0]),
		_pos(BODY, t, [Vector2(0, 1), Vector2(2, 3), Vector2(0, 0)]),
		_rot(HEAD, t, [0.0, -10.0, 0.0]),
		_pos(ORB, [0.0], [Vector2(0, -2)], false),
		_color(ORB, [0.0], [ORB_IDLE]),
	]
	tracks.append_array(_leg(LEG_F, KNEE_F, t, [30.0, 55.0, 0.0], [20.0, 45.0, 0.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, t, [-30.0, -55.0, 0.0], [10.0, 30.0, 0.0]))
	tracks.append_array(_staff_arm(t, [40.0, 70.0, -12.0], [-20.0, -40.0, 24.0]))
	tracks.append_array(_orb_arm(t, [10.0, 40.0, -35.0]))
	return _build(0.28, false, tracks)


func _anim_hurt() -> Animation:
	var t: PackedFloat32Array = [0.0, 0.08, 0.3]
	var tracks: Array[Track] = [
		_rot(BODY, t, [0.0, -22.0, 0.0]),
		_pos(BODY, t, [Vector2(0, 0), Vector2(-2, 0), Vector2(0, 0)]),
		_rot(HEAD, t, [0.0, -15.0, 0.0]),
		_rot(LEG_F, [0.0], [0.0]),
		_rot(LEG_B, [0.0], [0.0]),
		_pos(ORB, [0.0], [Vector2(0, -2)], false),
		_color(ORB, t, [ORB_IDLE, Color(0.6, 0.6, 0.7, 0.6), ORB_IDLE]),
	]
	tracks.append_array(_staff_arm(t, [-12.0, -70.0, -12.0], [24.0, 85.0, 24.0]))
	tracks.append_array(_orb_arm(t, [-35.0, 40.0, -35.0]))
	return _build(0.3, false, tracks)


func _anim_knockdown() -> Animation:
	var t: PackedFloat32Array = [0.0, 0.15]
	var tracks: Array[Track] = [
		_rot(BODY, [0.0, 0.15, 0.7], [-20.0, -80.0, -80.0]),
		_pos(BODY, t, [Vector2(0, 0), Vector2(-4, 6)]),
		_rot(LEG_F, t, [20.0, -60.0]),
		_rot(LEG_B, t, [-10.0, -70.0]),
		_rot(HEAD, t, [-10.0, -20.0]),
		_pos(ORB, [0.0], [Vector2(0, -2)], false),
		_color(ORB, t, [ORB_IDLE, Color(0.6, 0.6, 0.7, 0.6)]),
	]
	tracks.append_array(_staff_arm(t, [-60.0, -110.0], [50.0, 60.0]))
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
		_pos(ORB, t, [Vector2(0, -2), Vector2(0, 2)], false),
		_color(ORB, [0.0, 0.6], [ORB_IDLE, Color(0.3, 0.3, 0.35, 0.3)]),
	]
	tracks.append_array(_staff_arm(t, [-40.0, -100.0], [50.0, 60.0]))
	tracks.append_array([_rot(ARM_B, t, [40.0, 95.0]), _rot(HAND_B, t, [-30.0, -5.0])])
	return _build(0.6, false, tracks)
