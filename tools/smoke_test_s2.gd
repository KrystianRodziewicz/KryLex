extends Node
## Test dymny S2 (Porzucony wóz):
##   godot --headless --path . res://tools/smoke_test_s2.tscn
##
## Sesja startuje od razu w S2. Sprawdza: wilk wbiega dopiero po wejściu
## w strefę dźwigni, szarża trafia i nakłada krwawienie, blok tarczą odbija
## wilka i ogłusza, ciosy w ogłuszonego są krytyczne i go zabijają,
## zdarzenie enemy_killed trafia do WorldStore, dźwignia na dwóch otwiera
## kratę, a gracz spada do wyjścia w dół.

const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const MAX_TICKS: int = 60 * 120
const LEVER_A_X: float = 240.0
const LEVER_B_X: float = 880.0
const PIT_X: float = 1032.0

var _session: LocalSession = null
var _tick: int = 0
var _phase: int = 0
var _phase_started: int = 0
var _failures: int = 0
var _hit_player: Player = null
var _interact_pressed_at: int = -1


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
	match _phase:
		0:
			_next_phase_if(_tick > 5, "start")
			if _phase == 1:
				_check(_session.current_room.room_id == &"s2_porzucony_woz", "start w S2")
				_check(_wolf() == null, "wilk nie stoi w pomieszczeniu na starcie")
		1:
			# Oboje zbiegają z półki w stronę dźwigni A.
			Input.action_press(&"kb_move_right")
			Input.action_press(&"pad_move_right")
			_next_phase_if(p1.global_position.x > 170.0 and p1.is_on_floor(), "zejście z półki")
			if _phase == 2:
				_release_all()
		2:
			_next_phase_if(_wolf() != null, "wilk wbiegł po ostrzeżeniu")
			if t > 60 * 4:
				_fail("wilk nie wbiegł po wejściu w strefę dźwigni")
				_finish()
		3:
			# Stoją bez ruchu: szarża ma trafić.
			var wolf: Werewolf = _wolf()
			if p1.hp < p1.stats.max_hp or p2.hp < p2.stats.max_hp:
				_hit_player = p1 if p1.hp < p1.stats.max_hp else p2
				_next_phase_if(true, "szarża trafiła P%d" % _hit_player.player_id)
				_check(_hit_player.bleed_left > 0.0 or _hit_player.hp < _hit_player.stats.max_hp - 10,
					"szarża nałożyła krwawienie")
				_check(wolf != null and wolf.target != null and wolf.target.hp <= mini(p1.hp, p2.hp),
					"wilk celuje w gracza z niższym zdrowiem")
			elif t > 60 * 12:
				_fail("szarża nie trafiła nikogo przez 12 s")
				_finish()
		4:
			# P1 odwraca się do lewej krawędzi i trzyma tarczę.
			if t < 4:
				Input.action_press(&"kb_move_left")
			elif t == 4:
				Input.action_release(&"kb_move_left")
			else:
				Input.action_press(&"kb_block")
			var wolf: Werewolf = _wolf()
			if wolf != null and wolf.stunned_left > 0.0:
				_next_phase_if(true, "blok odbił szarżę, wilk ogłuszony")
				Input.action_release(&"kb_block")
			elif t > 60 * 15:
				_fail("wilk nie odbił się od tarczy przez 15 s")
				_finish()
		5:
			# Dobiega do ogłuszonego wilka i tnie: ciosy krytyczne mają go zabić.
			var wolf: Werewolf = _wolf()
			if wolf == null or wolf.dead:
				_release_all()
				_next_phase_if(true, "wilk zabity")
				_check(WorldStore.count_events(&"enemy_killed") == 1, "enemy_killed w WorldStore")
				_check(WorldStore.count_events(&"player_death") == 0, "nikt nie zginął")
				return
			var dx: float = wolf.global_position.x - p1.global_position.x
			if absf(dx) > 22.0:
				Input.action_release(&"kb_attack")
				if dx < 0.0:
					Input.action_press(&"kb_move_left")
					Input.action_release(&"kb_move_right")
				else:
					Input.action_press(&"kb_move_right")
					Input.action_release(&"kb_move_left")
			else:
				Input.action_release(&"kb_move_left")
				Input.action_release(&"kb_move_right")
				if t % 20 == 0:
					Input.action_press(&"kb_attack")
				elif t % 20 == 3:
					Input.action_release(&"kb_attack")
			if t > 60 * 12:
				_fail("wilk żyje po 12 s ataków (hp %d)" % wolf.hp)
				_finish()
		6:
			# Dźwignia na dwóch: P1 do A, P2 do B, potem oboje ciągną w tej samej chwili.
			var a_ready: bool = _walk_to(p1, LEVER_A_X, "kb_")
			var b_ready: bool = _walk_to(p2, LEVER_B_X, "pad_")
			if a_ready and b_ready and _interact_pressed_at < 0:
				_interact_pressed_at = _tick
				Input.action_press(&"kb_interact")
				Input.action_press(&"pad_interact")
			if _interact_pressed_at > 0 and _tick - _interact_pressed_at == 3:
				Input.action_release(&"kb_interact")
				Input.action_release(&"pad_interact")
			if _interact_pressed_at > 0 and _tick - _interact_pressed_at > 30:
				_next_phase_if(true, "obie dźwignie pociągnięte")
				_check(_grate().is_open, "krata otwarta")
				_check(_lever(&"LeverA").latched and _lever(&"LeverB").latched, "dźwignie zablokowane na stałe")
			if t > 60 * 25:
				_fail("gracze nie doszli do dźwigni")
				_finish()
		7:
			# P1 idzie do kraty i spada do wyjścia w dół.
			if p1.global_position.y > 350.0:
				_release_all()
				_next_phase_if(true, "P1 spadł przez otwartą kratę")
				return
			_walk_to(p1, PIT_X, "kb_")
			if t > 60 * 15:
				_fail("P1 nie spadł przez kratę")
				_finish()
		8:
			_finish()


func _walk_to(player: Player, target_x: float, prefix: String) -> bool:
	var dx: float = target_x - player.global_position.x
	var left: StringName = StringName(prefix + "move_left")
	var right: StringName = StringName(prefix + "move_right")
	if absf(dx) <= 5.0:
		Input.action_release(left)
		Input.action_release(right)
		return true
	if dx > 0.0:
		Input.action_release(left)
		Input.action_press(right)
	else:
		Input.action_release(right)
		Input.action_press(left)
	return false


func _wolf() -> Werewolf:
	var enemies: Node = _session.current_room.get_node_or_null(^"Enemies")
	if enemies == null:
		return null
	for child: Node in enemies.get_children():
		var wolf: Werewolf = child as Werewolf
		if wolf != null:
			return wolf
	return null


func _grate() -> Grate:
	return _session.current_room.get_node(^"Geometry/Grate") as Grate


func _lever(lever_name: StringName) -> Lever:
	return _session.current_room.get_node(NodePath("Props/" + lever_name)) as Lever


func _release_all() -> void:
	for action: StringName in [&"kb_move_left", &"kb_move_right", &"kb_block", &"kb_attack",
			&"kb_interact", &"pad_move_left", &"pad_move_right", &"pad_interact"]:
		Input.action_release(action)


func _next_phase_if(condition: bool, label: String) -> void:
	if condition:
		print("[smoke-s2] faza %d zaliczona: %s (tick %d)" % [_phase, label, _tick])
		_phase += 1
		_phase_started = _tick


func _check(condition: bool, label: String) -> void:
	if condition:
		print("[smoke-s2] OK  %s" % label)
	else:
		_fail(label)


func _fail(label: String) -> void:
	_failures += 1
	printerr("[smoke-s2] BŁĄD  %s" % label)


func _finish() -> void:
	print("[smoke-s2] koniec po %d klatkach fizyki, błędów: %d" % [_tick, _failures])
	set_physics_process(false)
	get_tree().quit(1 if _failures > 0 else 0)
