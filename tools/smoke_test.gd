extends Node
## Test dymny kroku 1 M0 bez okna i bez człowieka przy klawiaturze:
##   godot --headless --path . res://tools/smoke_test.tscn
##
## Wciska akcje przez [method Input.action_press], więc sprawdza tę samą
## ścieżkę co prawdziwe urządzenia: obie postacie biegną do bramy Osady,
## brama czeka na oboje, S1 się ładuje, P1 atakuje kukłę, P2 skacze.
## Kod wyjścia 1 przy pierwszej nieudanej asercji. Liczy klatki fizyki,
## więc wynik nie zależy od tempa renderowania.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const MAX_TICKS: int = 60 * 40

var _session: LocalSession = null
var _tick: int = 0
var _phase: int = 0
var _phase_started: int = 0
var _failures: int = 0
var _dummy_hp_before: int = -1
var _p2_min_y: float = INF


func _ready() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	add_child(main)
	_session = main as LocalSession
	_check(_session != null, "scena główna ma skrypt LocalSession")


func _physics_process(_delta: float) -> void:
	_tick += 1
	if _tick > MAX_TICKS:
		_fail("przekroczono limit klatek w fazie %d" % _phase)
		_finish()
		return
	if _session == null:
		_finish()
		return
	var t: int = _tick - _phase_started
	match _phase:
		0:
			_next_phase_if(_tick > 5, "start")
			if _phase == 1:
				_check(_session.players.size() == 2, "dwie postacie w sesji")
				_check(_in_room(&"osada"), "start w Osadzie")
				_check(_session.players[0].input.profile == PlayerInput.Profile.KEYBOARD,
					"P1 na klawiaturze")
				_check(_session.players[1].input.profile == PlayerInput.Profile.JOYPAD,
					"P2 na padzie")
		1:
			# Tylko P1 biegnie do bramy: brama ma czekać na partnera.
			Input.action_press(&"kb_move_right")
			if _in_room(&"s1_za_plotem"):
				_fail("brama przepuściła jednego gracza")
			_next_phase_if(_tick - _phase_started > 60 * 7, "P1 przy bramie")
			if _phase == 2:
				_check(_session.players[0].global_position.x > 560.0, "P1 dobiegł do bramy (x = %.0f)" % _session.players[0].global_position.x)
				_check(_in_room(&"osada"), "brama czeka na P2")
		2:
			Input.action_press(&"kb_move_right")
			Input.action_press(&"pad_move_right")
			_next_phase_if(_in_room(&"s1_za_plotem"), "oboje przeszli do S1")
			if _phase == 3:
				Input.action_release(&"kb_move_right")
				Input.action_release(&"pad_move_right")
		3:
			# Po przeładowaniu pomieszczenia P1 zbiega z półki do kukły.
			if _tick - _phase_started > 10:
				Input.action_press(&"kb_move_right")
			var p1: Player = _session.players[0]
			# Kukła stoi na x = 440; zasięg ataku to 16 px plus pół hitboxa.
			_next_phase_if(p1.global_position.x > 418.0 and p1.is_on_floor(), "P1 przy kukle")
			if _phase == 4:
				Input.action_release(&"kb_move_right")
				_dummy_hp_before = _dummy().hp
		4:
			if t == 10:
				Input.action_press(&"kb_attack")
			if t == 13:
				Input.action_release(&"kb_attack")
			if t == 20:
				Input.action_press(&"pad_jump")
			if t == 35:
				Input.action_release(&"pad_jump")
			_p2_min_y = minf(_p2_min_y, _session.players[1].global_position.y)
			_next_phase_if(t > 90, "atak i skok")
			if _phase == 5:
				_check(_dummy().hp < _dummy_hp_before, "atak P1 trafił kukłę (%d -> %d)" % [
					_dummy_hp_before, _dummy().hp])
				_check(_p2_min_y < 170.0, "P2 skoczył na padzie (min y = %.0f, start 186)" % _p2_min_y)
				_check(WorldStore.count_events(&"player_death") == 0, "nikt nie zginął po drodze")
		5:
			# P2 (Mag) schodzi z półki w zasięg pocisku i strzela w kukłę z dystansu.
			var p2: Player = _session.players[1]
			# Za schodkiem (x > 340) P2 stoi na podłodze, na wysokości kukły.
			if p2.global_position.x < 362.0 or not p2.is_on_floor():
				Input.action_press(&"pad_move_right")
			else:
				Input.action_release(&"pad_move_right")
				_dummy_hp_before = _dummy().hp
				_next_phase_if(true, "P2 w zasięgu pocisku (x = %.0f)" % p2.global_position.x)
			if t > 60 * 8:
				_fail("P2 nie zszedł z półki")
				_finish()
		6:
			if t == 5:
				Input.action_press(&"pad_attack")
			if t == 8:
				Input.action_release(&"pad_attack")
			# Blok dopiero po zakończeniu ataku (0,3 s), inaczej wciśnięcie przepada.
			if t == 40:
				Input.action_press(&"pad_block")
			if t == 43:
				Input.action_release(&"pad_block")
			_next_phase_if(t > 90, "pocisk Maga i bariera")
			if _phase == 7:
				var p2: Player = _session.players[1]
				_check(_dummy().hp < _dummy_hp_before, "pocisk ognia trafił kukłę z dystansu (%d -> %d)" % [
					_dummy_hp_before, _dummy().hp])
				_check(p2.barrier_active, "bariera Maga stoi po wciśnięciu bloku")
		7:
			_finish()


func _in_room(room_id: StringName) -> bool:
	return _session.current_room != null and _session.current_room.room_id == room_id


func _dummy() -> TrainingDummy:
	return _session.current_room.get_node(^"Props/TrainingDummy") as TrainingDummy


func _next_phase_if(condition: bool, label: String) -> void:
	if condition:
		print("[smoke] faza %d zaliczona: %s (tick %d)" % [_phase, label, _tick])
		_phase += 1
		_phase_started = _tick


func _check(condition: bool, label: String) -> void:
	if condition:
		print("[smoke] OK  %s" % label)
	else:
		_fail(label)


func _fail(label: String) -> void:
	_failures += 1
	printerr("[smoke] BŁĄD  %s" % label)


func _finish() -> void:
	print("[smoke] koniec po %d klatkach fizyki, błędów: %d" % [_tick, _failures])
	set_physics_process(false)
	get_tree().quit(1 if _failures > 0 else 0)
