class_name WarriorRig
extends PartsRig
## Wojownik z części: hełm, napierśnik, dwie ręce, dwie nogi (udo + goleń
## z kolanem), miecz w przedniej dłoni i tarcza w tylnej (assets/sprites/warrior).
##
## Miecz leży w dłoni klingą od barku (0 stopni = klinga przedłuża rękę),
## a tarcza dostaje obrót przeciwny do ręki, więc zawsze stoi w pionie.
## Kolana i położenie bioder, o których animacja nie mówi, wracają do
## spoczynku (PartsRig._default_tracks).

## Spoczynkowy obrót dłoni z mieczem: klinga uniesiona przed sobą, nie w ziemi.
const SWORD_REST: float = -150.0


func _register_animations(library: AnimationLibrary) -> void:
	library.add_animation(&"idle", _anim_idle())
	library.add_animation(&"run", _anim_run())
	library.add_animation(&"jump", _anim_jump())
	library.add_animation(&"fall", _anim_fall())
	library.add_animation(&"attack", _anim_attack())
	library.add_animation(&"bash", _anim_bash())
	library.add_animation(&"dodge", _anim_dodge())
	library.add_animation(&"block", _anim_block(false))
	library.add_animation(&"block_walk", _anim_block(true))
	library.add_animation(&"hurt", _anim_hurt())
	library.add_animation(&"knockdown", _anim_knockdown())
	library.add_animation(&"dead", _anim_dead())


func _sword_arm(times: PackedFloat32Array, arm_degrees: PackedFloat32Array,
		hand_degrees: PackedFloat32Array) -> Array[Track]:
	return _arm_with_hand(ARM_F, HAND_F, times, arm_degrees, hand_degrees)


func _shield_arm(times: PackedFloat32Array, arm_degrees: PackedFloat32Array, tilt: float = 0.0) -> Array[Track]:
	return _arm_level_hand(ARM_B, HAND_B, times, arm_degrees, tilt)


func _anim_idle() -> Animation:
	# Spokojny oddech: tułów opada o piksel raz na 1,6 s, ręce ledwo drgają.
	# Miecz uniesiony przed sobą, tarcza wisi z przodu przy biodrze.
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
	# Bieg, cykl 0,4 s. Noga w podporze idzie wyprostowana pod ciałem i odpycha
	# się za plecy; w wymachu zgina kolano, podciąga stopę i prostuje się do
	# przodu. Biodra z tułowiem opadają o 2 px, gdy nogi są rozstawione, więc
	# stopa w podporze stoi na podłodze. Ręce w przeciwfazie do nóg, tarcza
	# cały czas z przodu.
	var t: PackedFloat32Array = [0.0, 0.1, 0.2, 0.3, 0.4]
	var tracks: Array[Track] = [
		_rot(BODY, [0.0], [10.0]),
		_rot(HEAD, [0.0], [-4.0]),
	]
	tracks.append_array(_gait_bob(0.4))
	tracks.append_array(_leg(LEG_F, KNEE_F, t, [-40.0, -5.0, 35.0, 0.0, -40.0], [10.0, 0.0, 5.0, 70.0, 10.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, t, [35.0, 0.0, -40.0, -5.0, 35.0], [5.0, 70.0, 10.0, 0.0, 5.0]))
	tracks.append_array(_sword_arm(t, [25.0, 0.0, -30.0, 0.0, 25.0],
		[SWORD_REST, SWORD_REST, SWORD_REST, SWORD_REST, SWORD_REST]))
	tracks.append_array(_shield_arm(t, [-50.0, -30.0, -15.0, -30.0, -50.0]))
	return _build(0.4, true, tracks)


func _anim_jump() -> Animation:
	# Odbicie: nogi podciągają się z ugiętymi kolanami, ręce idą w górę;
	# poza trzyma się do szczytu lotu.
	var t: PackedFloat32Array = [0.0, 0.25, 0.5]
	var tracks: Array[Track] = [
		_pos(BODY, [0.0], [Vector2(0, 0)]),
		_rot(BODY, [0.0, 0.25], [0.0, -5.0]),
		_rot(HEAD, [0.0], [0.0]),
	]
	tracks.append_array(_leg(LEG_F, KNEE_F, [0.0, 0.2, 0.5], [10.0, 30.0, 25.0], [10.0, 45.0, 35.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, [0.0, 0.2, 0.5], [-10.0, -35.0, -30.0], [10.0, 40.0, 30.0]))
	tracks.append_array(_sword_arm(t, [-20.0, -70.0, -80.0], [SWORD_REST, -120.0, -110.0]))
	tracks.append_array(_shield_arm(t, [-50.0, -95.0, -105.0]))
	return _build(0.5, false, tracks)


func _anim_fall() -> Animation:
	# Zaczyna z pozy skoku, prostuje nogi i rozkłada ręce do lądowania.
	var t: PackedFloat32Array = [0.0, 0.5]
	var tracks: Array[Track] = [
		_pos(BODY, [0.0], [Vector2(0, 0)]),
		_rot(BODY, t, [-5.0, 6.0]),
		_rot(HEAD, [0.0], [0.0]),
	]
	tracks.append_array(_leg(LEG_F, KNEE_F, t, [25.0, 15.0], [35.0, 10.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, t, [-30.0, -15.0], [30.0, 10.0]))
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
		_rot(HEAD, [0.0, 0.2, 0.42], [0.0, 8.0, 0.0]),
	]
	tracks.append_array(_leg(LEG_F, KNEE_F, [0.0, 0.2, 0.42], [0.0, 20.0, 0.0], [0.0, 10.0, 0.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, [0.0, 0.2, 0.42], [0.0, -15.0, 0.0], [0.0, 5.0, 0.0]))
	tracks.append_array(_sword_arm(t, [22.0, -165.0, 60.0, 75.0, 22.0],
		[SWORD_REST, 0.0, -30.0, -40.0, SWORD_REST]))
	tracks.append_array(_shield_arm([0.0, 0.1, 0.2, 0.42], [-28.0, 15.0, -60.0, -28.0]))
	return _build(0.42, false, tracks)


func _anim_bash() -> Animation:
	# Przerwij: uderzenie tarczą, 0,52 s jak w balansie. Zamach: tarcza
	# cofa się do boku, biodra lekko w tył. Cios: wykrok przednią nogą,
	# biodra idą 3 px do przodu razem z tułowiem (tułów nie odjeżdża od nóg),
	# tarcza wystrzela z barku poziomo przed pierś. Powrót do postawy.
	var t: PackedFloat32Array = [0.0, 0.12, 0.2, 0.52]
	var hips_t: PackedFloat32Array = [0.0, 0.12, 0.16, 0.2, 0.36, 0.52]
	var tracks: Array[Track] = [
		_rot(BODY, t, [0.0, -8.0, 10.0, 0.0]),
		_rot(HEAD, [0.0, 0.2, 0.52], [0.0, 4.0, 0.0]),
	]
	tracks.append_array(_hips(hips_t,
		[Vector2(0, 0), Vector2(-1, 0), Vector2(1, 0), Vector2(3, 1), Vector2(1, 0), Vector2(0, 0)],
		[Vector2(0, 0), Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(0, 0), Vector2(0, 0)]))
	tracks.append_array(_leg(LEG_F, KNEE_F, t, [0.0, 10.0, -35.0, 0.0], [0.0, 10.0, 15.0, 0.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, t, [0.0, -10.0, 25.0, 0.0], [0.0, 0.0, 0.0, 0.0]))
	tracks.append_array(_sword_arm(t, [22.0, 40.0, 50.0, 22.0], [SWORD_REST, SWORD_REST, SWORD_REST, SWORD_REST]))
	tracks.append_array(_shield_arm(t, [-28.0, -40.0, -95.0, -28.0], -6.0))
	return _build(0.52, false, tracks)


func _anim_dodge() -> Animation:
	# Fikołek: przysiad, obrót o 360 stopni z rozpędem w środku, wstanie.
	# Nogi zwinięte w kłębek (kolana zgięte) przez cały obrót.
	# Czas trwania narzuca PlayerStats.dodge_duration (0,45 s u Wojownika).
	var t: PackedFloat32Array = [0.0, 0.1, 0.45]
	var leg_t: PackedFloat32Array = [0.0, 0.1, 0.4, 0.45]
	var tracks: Array[Track] = [
		_rot(BODY, [0.0, 0.08, 0.3, 0.45], [0.0, 40.0, 300.0, 360.0]),
		_pos(BODY, [0.0, 0.1, 0.3, 0.45], [Vector2(0, 2), Vector2(0, 6), Vector2(0, 6), Vector2(0, 0)]),
		_rot(HEAD, t, [0.0, 20.0, 0.0]),
	]
	tracks.append_array(_leg(LEG_F, KNEE_F, leg_t, [20.0, 70.0, 70.0, 0.0], [20.0, 80.0, 80.0, 0.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, leg_t, [-20.0, -70.0, -70.0, 0.0], [20.0, 80.0, 80.0, 0.0]))
	tracks.append_array(_sword_arm(t, [-20.0, -60.0, 22.0], [SWORD_REST, -100.0, SWORD_REST]))
	# W fikołku tarcza przylega do ciała, więc obraca się razem z nim.
	tracks.append_array([_rot(ARM_B, t, [-40.0, -90.0, -28.0]), _rot(HAND_B, t, [40.0, 90.0, 28.0])])
	return _build(0.45, false, tracks)


func _anim_block(walking: bool) -> Animation:
	# Tarcza z tylnej ręki idzie do przodu i w górę, w pionie; lekki przysiad
	# na ugiętych kolanach.
	var tracks: Array[Track] = [
		_rot(BODY, [0.0], [8.0]),
		_pos(BODY, [0.0], [Vector2(0, 1)]),
		_rot(HEAD, [0.0], [0.0]),
	]
	tracks.append_array(_sword_arm([0.0], [35.0], [SWORD_REST]))
	tracks.append_array(_shield_arm([0.0], [-100.0], -8.0))
	if walking:
		# Powolne kroki zza tarczy: noga w wymachu (idzie do przodu) ugina kolano.
		var t: PackedFloat32Array = [0.0, 0.25, 0.5, 0.75, 1.0]
		tracks.append_array(_leg(LEG_F, KNEE_F, t, [15.0, 0.0, -15.0, 0.0, 15.0], [5.0, 25.0, 5.0, 5.0, 5.0]))
		tracks.append_array(_leg(LEG_B, KNEE_B, t, [-15.0, 0.0, 15.0, 0.0, -15.0], [5.0, 5.0, 5.0, 25.0, 5.0]))
	else:
		tracks.append_array(_leg(LEG_F, KNEE_F, [0.0], [12.0], [12.0]))
		tracks.append_array(_leg(LEG_B, KNEE_B, [0.0], [-12.0], [8.0]))
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
	# Pada na plecy i leży do końca ogłuszenia, nogi ugięte.
	var t: PackedFloat32Array = [0.0, 0.15]
	var tracks: Array[Track] = [
		_rot(BODY, [0.0, 0.15, 0.7], [-20.0, -80.0, -80.0]),
		_pos(BODY, t, [Vector2(0, 0), Vector2(-4, 6)]),
		_rot(HEAD, t, [-10.0, -20.0]),
	]
	tracks.append_array(_leg(LEG_F, KNEE_F, t, [20.0, -60.0], [10.0, 30.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, t, [-10.0, -70.0], [10.0, 40.0]))
	tracks.append_array(_sword_arm(t, [-60.0, -110.0], [-120.0, -60.0]))
	tracks.append_array([_rot(ARM_B, t, [60.0, 100.0]), _rot(HAND_B, t, [-40.0, -20.0])])
	return _build(0.7, false, tracks)


func _anim_dead() -> Animation:
	var t: PackedFloat32Array = [0.0, 0.3]
	var tracks: Array[Track] = [
		_rot(BODY, [0.0, 0.3, 0.6], [-20.0, -90.0, -90.0]),
		_pos(BODY, t, [Vector2(0, 0), Vector2(-5, 7)]),
		_rot(HEAD, t, [-10.0, -30.0]),
	]
	tracks.append_array(_leg(LEG_F, KNEE_F, t, [10.0, -80.0], [10.0, 20.0]))
	tracks.append_array(_leg(LEG_B, KNEE_B, t, [-10.0, -85.0], [10.0, 25.0]))
	tracks.append_array(_sword_arm(t, [-40.0, -100.0], [-120.0, -30.0]))
	tracks.append_array([_rot(ARM_B, t, [40.0, 95.0]), _rot(HAND_B, t, [-30.0, -5.0])])
	return _build(0.6, false, tracks)
