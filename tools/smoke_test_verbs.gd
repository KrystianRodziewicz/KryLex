extends Node
## Test dymny czasowników (README, sekcja 3) na wilku w S2:
##   godot --headless --path . res://tools/smoke_test_verbs.tscn
##
## Podpal: pocisk ognia Maga podpala wilka (obrażenia w czasie).
## Zamroź: zmiana żywiołu na lód, zamrożony wilk nie szarżuje, podchodzi.
## Przerwij (Mag): impuls ogłusza wilka w promieniu.
## Przerwij (Wojownik) + zamrożenie: uderzenie tarczą roztrzaskuje wilka.
## Wilk dostaje na start 150 HP, żeby nie zginął w trakcie testu.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const MAX_TICKS: int = 60 * 120
const WOLF_TEST_HP: int = 150

var _session: LocalSession = null
var _tick: int = 0
var _phase: int = 0
var _phase_started: int = 0
var _failures: int = 0
var _hp_mark: int = -1
var _shot_at: int = -1000


func _ready() -> void:
	var main: Node = MAIN_SCENE.instantiate()
	var session: LocalSession = main as LocalSession
	session.first_room = &"s2_porzucony_woz"
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
	var wolf: Werewolf = _wolf()
	match _phase:
		0:
			_next_phase_if(_tick > 5, "start")
		1:
			Input.action_press(&"kb_move_right")
			Input.action_press(&"pad_move_right")
			_next_phase_if(p1.global_position.x > 170.0 and p1.is_on_floor(), "zejście z półki")
			if _phase == 2:
				_release_all()
		2:
			if wolf != null:
				wolf.hp = WOLF_TEST_HP
				_hp_mark = wolf.hp
				_next_phase_if(true, "wilk wbiegł (HP testowe %d)" % WOLF_TEST_HP)
			elif t > 60 * 4:
				_fail("wilk nie wbiegł")
				_finish()
		3:
			# Podpal: P2 odwraca się do wilka i strzela ogniem, aż wilk zapłonie.
			if wolf == null:
				_fail("wilk zniknął")
				_finish()
				return
			_face_left(p2, "pad_")
			if t > 6 and _tick - _shot_at > 30:
				_shot_at = _tick
				Input.action_press(&"pad_attack")
			if _tick - _shot_at == 3:
				Input.action_release(&"pad_attack")
			if wolf.burn_left > 0.0:
				_next_phase_if(true, "pocisk ognia podpalił wilka")
				_check(wolf.hp < _hp_mark, "pocisk zadał obrażenia (%d -> %d)" % [_hp_mark, wolf.hp])
			elif t > 60 * 15:
				_fail("wilk nie zapłonął w 15 s (hp %d)" % wolf.hp)
				_finish()
		4:
			# Zamroź: zmiana żywiołu na lód.
			if t == 1:
				Input.action_press(&"pad_element")
			if t == 4:
				Input.action_release(&"pad_element")
			if t == 6:
				_check(p2.current_element == Elements.Kind.ICE, "P2 przełączył żywioł na lód")
				_hp_mark = wolf.hp if wolf != null else 0
				_next_phase_if(true, "żywioł zmieniony")
		5:
			# Strzela lodem, aż wilk zamarznie; podpalenie musi minąć, żeby etykieta była jasna.
			if wolf == null:
				_fail("wilk zniknął")
				_finish()
				return
			_face_left(p2, "pad_")
			if _tick - _shot_at > 30:
				_shot_at = _tick
				Input.action_press(&"pad_attack")
			if _tick - _shot_at == 3:
				Input.action_release(&"pad_attack")
			if wolf.is_frozen():
				_next_phase_if(true, "pocisk lodu zamroził wilka")
				_check(wolf.speed_scale() < 1.0, "zamrożony wilk jest spowolniony (x%.1f)" % wolf.speed_scale())
			elif t > 60 * 15:
				_fail("wilk nie zamarzł w 15 s")
				_finish()
		6:
			# Impuls: P2 czeka, aż wilk podejdzie, dolewając lodu, i wypuszcza impuls.
			if wolf == null:
				_fail("wilk zniknął")
				_finish()
				return
			_face_left(p2, "pad_")
			if wolf.frozen_left < 0.4 and _tick - _shot_at > 30:
				_shot_at = _tick
				Input.action_press(&"pad_attack")
			if _tick - _shot_at == 3:
				Input.action_release(&"pad_attack")
			var dist: float = absf(wolf.global_position.x - p2.global_position.x)
			if dist <= 40.0 and wolf.stunned_left <= 0.0 and p2.state != Player.State.ATTACK:
				Input.action_press(&"pad_interrupt")
				_check(wolf.state != Werewolf.State.CHARGE, "zamrożony wilk podszedł zamiast szarżować")
				_next_phase_if(true, "wilk w zasięgu impulsu (%.0f px)" % dist)
			elif t > 60 * 20:
				_fail("wilk nie podszedł do P2 w 20 s (dist %.0f, stan %s)" % [dist, Werewolf.STATE_LABELS[wolf.state]])
				_finish()
		7:
			if t == 3:
				Input.action_release(&"pad_interrupt")
			if wolf != null and wolf.stunned_left > 0.0 and t > 3:
				_hp_mark = wolf.hp
				_next_phase_if(true, "impuls ogłuszył wilka (%.1f s)" % wolf.stunned_left)
			elif t > 60:
				_fail("impuls nie ogłuszył wilka")
				_finish()
		8:
			# Roztrzaskanie: P1 podchodzi do zamrożonego wilka i uderza tarczą.
			if wolf == null:
				_fail("wilk zniknął")
				_finish()
				return
			# P2 pilnuje zamrożenia.
			_face_left(p2, "pad_")
			if wolf.frozen_left < 0.5 and _tick - _shot_at > 30:
				_shot_at = _tick
				Input.action_press(&"pad_attack")
			if _tick - _shot_at == 3:
				Input.action_release(&"pad_attack")
			var dx: float = wolf.global_position.x - p1.global_position.x
			if absf(dx) > 20.0:
				_walk(p1, dx)
			else:
				Input.action_release(&"kb_move_left")
				Input.action_release(&"kb_move_right")
				if wolf.is_frozen() and p1.interrupt_cooldown_left <= 0.0 and p1.state != Player.State.ATTACK:
					_hp_mark = wolf.hp
					Input.action_press(&"kb_interrupt")
					_next_phase_if(true, "P1 uderza tarczą w zamrożonego wilka")
			if t > 60 * 25:
				_fail("P1 nie doszedł do zamrożonego wilka (dx %.0f, frozen %.1f)" % [dx, wolf.frozen_left])
				_finish()
		9:
			if t == 3:
				Input.action_release(&"kb_interrupt")
			if wolf != null and wolf.hp <= _hp_mark - 15 and t > 3:
				_release_all()
				_next_phase_if(true, "roztrzaskanie (%d -> %d)" % [_hp_mark, wolf.hp])
				_check(wolf.stunned_left > 0.0, "roztrzaskany wilk jest ogłuszony")
				_check(not wolf.is_frozen(), "roztrzaskanie zdejmuje zamrożenie")
			elif t > 60 * 2:
				_fail("uderzenie tarczą nie roztrzaskało wilka (hp %d, mark %d)" % [
					wolf.hp if wolf != null else -1, _hp_mark])
				_finish()
		10:
			_finish()


func _face_left(player: Player, prefix: String) -> void:
	var left: StringName = StringName(prefix + "move_left")
	if player.facing != -1:
		Input.action_press(left)
	else:
		Input.action_release(left)


func _walk(_player: Player, dx: float) -> void:
	if dx > 0.0:
		Input.action_release(&"kb_move_left")
		Input.action_press(&"kb_move_right")
	else:
		Input.action_release(&"kb_move_right")
		Input.action_press(&"kb_move_left")


func _wolf() -> Werewolf:
	var enemies: Node = _session.current_room.get_node_or_null(^"Enemies")
	if enemies == null:
		return null
	for child: Node in enemies.get_children():
		var wolf: Werewolf = child as Werewolf
		if wolf != null and not wolf.dead:
			return wolf
	return null


func _release_all() -> void:
	for action: StringName in [&"kb_move_left", &"kb_move_right", &"kb_interrupt", &"kb_attack",
			&"pad_move_left", &"pad_move_right", &"pad_attack", &"pad_interrupt", &"pad_element"]:
		Input.action_release(action)


func _next_phase_if(condition: bool, label: String) -> void:
	if condition:
		print("[smoke-verbs] faza %d zaliczona: %s (tick %d)" % [_phase, label, _tick])
		_phase += 1
		_phase_started = _tick


func _check(condition: bool, label: String) -> void:
	if condition:
		print("[smoke-verbs] OK  %s" % label)
	else:
		_fail(label)


func _fail(label: String) -> void:
	_failures += 1
	printerr("[smoke-verbs] BŁĄD  %s" % label)


func _finish() -> void:
	print("[smoke-verbs] koniec po %d klatkach fizyki, błędów: %d" % [_tick, _failures])
	set_physics_process(false)
	get_tree().quit(1 if _failures > 0 else 0)
