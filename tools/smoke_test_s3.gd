extends Node
## Test dymny S3 (Rozstaje):
##   godot --headless --path . res://tools/smoke_test_s3.tscn
##
## Sesja startuje w S3. Sprawdza: ognik czeka w pomieszczeniu, dwa wilki
## wbiegają z przeciwnych krawędzi (kleszcze) po zejściu z półki, ognik
## cofa się przed goniącym go P2 w stronę rozpadliny, P2 spada do rozpadliny
## i dostaje obrażenia od upadku, a wyjście na dnie po odliczaniu przeciąga
## partnera (G1 jeszcze nie istnieje, więc sesja tylko to zgłasza).

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const MAX_TICKS: int = 60 * 120

var _session: LocalSession = null
var _tick: int = 0
var _phase: int = 0
var _phase_started: int = 0
var _failures: int = 0
var _hp_before_fall: int = -1


func _ready() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	var session: LocalSession = main as LocalSession
	session.first_room = &"s3_rozstaje"
	add_child(main)
	_session = session


func _physics_process(_delta: float) -> void:
	_tick += 1
	if _tick > MAX_TICKS:
		_fail("przekroczono limit klatek w fazie %d" % _phase)
		_finish()
		return
	var p1: Player = _session.players[0]
	var p2: Player = _session.players[1]
	var t: int = _tick - _phase_started
	match _phase:
		0:
			_next_phase_if(_tick > 5, "start")
			if _phase == 1:
				_check(_session.current_room.room_id == &"s3_rozstaje", "start w S3")
				_check(_wisp() != null, "ognik czeka w pomieszczeniu")
				_check(_wolves().is_empty(), "wilki nie stoją w pomieszczeniu na starcie")
		1:
			# Oboje schodzą z półki w prawo, w stronę ognika.
			Input.action_press(&"kb_move_right")
			Input.action_press(&"pad_move_right")
			_next_phase_if(p1.global_position.y > 300.0 and p1.is_on_floor(), "zejście z półki")
			if _phase == 2:
				Input.action_release(&"kb_move_right")
		2:
			# P1 odchodzi w lewo poza zasięg ognika, żeby ognik patrzył tylko na P2.
			# Ognik ucieka tylko przed graczem, na którego patrzy (karta: "zaskoczenie").
			_walk_left_until(p1, 400.0)
			var wolves: Array[Werewolf] = _wolves()
			if wolves.size() >= 2:
				var left: bool = false
				var right: bool = false
				for wolf: Werewolf in wolves:
					if wolf.global_position.x < 640.0:
						left = true
					else:
						right = true
				_next_phase_if(true, "dwa wilki wbiegły")
				_check(left and right, "kleszcze: wilki z przeciwnych krawędzi")
			elif t > 60 * 5:
				_fail("drugi wilk nie wbiegł w 5 s")
				_finish()
		3:
			# P2 goni ognika i skacze nad szarżami; P1 trzyma się z dala.
			_walk_left_until(p1, 400.0)
			Input.action_press(&"pad_move_right")
			if t % 24 == 0:
				Input.action_press(&"pad_jump")
			elif t % 24 == 8:
				Input.action_release(&"pad_jump")
			var wisp: Wisp = _wisp()
			if wisp != null and wisp.global_position.x > 940.0:
				_next_phase_if(true, "ognik zwabił P2 nad rozpadlinę (x = %.0f)" % wisp.global_position.x)
				_check(wisp.watched == p2, "ognik patrzy na goniącego go P2")
			elif t > 60 * 15:
				_fail("ognik nie cofnął się nad rozpadlinę w 15 s (x = %.0f)" % (
					wisp.global_position.x if wisp != null else -1.0))
				_finish()
		4:
			# P2 biegnie dalej za światłem i wpada do rozpadliny.
			Input.action_press(&"pad_move_right")
			Input.action_release(&"pad_jump")
			if _hp_before_fall < 0 and p2.global_position.y > 336.0:
				_hp_before_fall = p2.hp
			if p2.global_position.y > 430.0 and _hp_before_fall >= 0 and t > 2:
				Input.action_release(&"pad_move_right")
				await get_tree().physics_frame
				_next_phase_if(true, "P2 spadł do rozpadliny")
				_check(p2.hp <= _hp_before_fall - 20, "upadek zadał obrażenia (%d -> %d)" % [
					_hp_before_fall, p2.hp])
				_check(p1.global_position.y < 340.0, "P1 został na górze")
			elif t > 60 * 12:
				_fail("P2 nie wpadł do rozpadliny (y = %.0f)" % p2.global_position.y)
				_finish()
		5:
			var exit: RoomExit = _crevasse_exit()
			if exit.fired:
				_next_phase_if(true, "wyjście przeciągnęło partnera po odliczaniu")
				_check(WorldStore.count_events(&"player_death", &"fall") == 0, "upadek nie zabił")
			elif t > 60 * 8:
				_fail("wyjście nie przeciągnęło partnera w 8 s")
				_finish()
		6:
			_finish()


func _walk_left_until(player: Player, target_x: float) -> void:
	if player.global_position.x > target_x:
		Input.action_press(&"kb_move_left")
	else:
		Input.action_release(&"kb_move_left")


func _wisp() -> Wisp:
	for child: Node in _enemies().get_children():
		var wisp: Wisp = child as Wisp
		if wisp != null and not wisp.dead:
			return wisp
	return null


func _wolves() -> Array[Werewolf]:
	var result: Array[Werewolf] = []
	for child: Node in _enemies().get_children():
		var wolf: Werewolf = child as Werewolf
		if wolf != null:
			result.append(wolf)
	return result


func _enemies() -> Node:
	return _session.current_room.get_node(^"Enemies")


func _crevasse_exit() -> RoomExit:
	return _session.current_room.get_node(^"Exits/CrevasseDown") as RoomExit


func _next_phase_if(condition: bool, label: String) -> void:
	if condition:
		print("[smoke-s3] faza %d zaliczona: %s (tick %d)" % [_phase, label, _tick])
		_phase += 1
		_phase_started = _tick


func _check(condition: bool, label: String) -> void:
	if condition:
		print("[smoke-s3] OK  %s" % label)
	else:
		_fail(label)


func _fail(label: String) -> void:
	_failures += 1
	printerr("[smoke-s3] BŁĄD  %s" % label)


func _finish() -> void:
	print("[smoke-s3] koniec po %d klatkach fizyki, błędów: %d" % [_tick, _failures])
	set_physics_process(false)
	get_tree().quit(1 if _failures > 0 else 0)
