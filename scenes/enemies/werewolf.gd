class_name Werewolf
extends Enemy
## Wilkołak: rdzeń motywu "Bór patrzy" (docs/biom-1-przeklety-bor.md).
## Wbiega z krawędzi ekranu, trzyma dystans i szarżuje w gracza z niższym
## zdrowiem. Nie staje do wymiany ciosów: po szarży odbiega i powtarza.
##
## Słabości z karty: blok tarczą odbija go i ogłusza (okno krytyczne),
## chybiona szarża kończy się poślizgiem plecami do graczy (też okno
## krytyczne). *Przerwij* i *Zamroź* dochodzą razem z tymi czasownikami.

enum State { ENTER, STALK, WINDUP, CHARGE, POUNCE, SLIDE, RETREAT, BITE_WINDUP, BITE, BITE_RECOVER }

const STATE_LABELS: Array[String] = [
	"wbiega", "czai się", "warczy", "szarża", "gryzie", "poślizg", "odbiega",
	"kłapie", "gryzie", "kłapie",
]

var state: State = State.ENTER
var target: Player = null

var _wstats: WerewolfStats = null
var _state_time: float = 0.0
var _cooldown_left: float = 0.0
var _charge_dir: int = 1
var _charge_start_x: float = 0.0
var _enter_dir: int = 1
var _enter_start_x: float = 0.0


func _ready() -> void:
	super()
	_wstats = stats as WerewolfStats
	assert(_wstats != null, "Werewolf potrzebuje WerewolfStats")
	_refresh_label()


func enter_from(direction: int) -> void:
	_enter_dir = direction
	facing = direction
	_enter_start_x = global_position.x
	_set_state(State.ENTER)


func is_critical_window() -> bool:
	return stunned_left > 0.0 or state == State.SLIDE


func _tick_behaviour(delta: float) -> void:
	_apply_gravity(delta)
	_state_time += delta
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	match state:
		State.ENTER:
			velocity.x = float(_enter_dir) * _wstats.enter_speed
			if absf(global_position.x - _enter_start_x) >= _wstats.enter_distance:
				_cooldown_left = _wstats.stalk_cooldown * 0.5
				_set_state(State.STALK)
		State.STALK:
			_tick_stalk(delta)
		State.WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if target != null:
				face_towards(target.global_position.x)
			if _state_time >= _wstats.charge_windup:
				_start_charge()
		State.CHARGE:
			velocity.x = float(_charge_dir) * _wstats.charge_speed
			var travelled: float = absf(global_position.x - _charge_start_x)
			var edge_ahead: bool = (global_position.x >= room_bounds.end.x - 20.0) if _charge_dir > 0 \
				else (global_position.x <= room_bounds.position.x + 20.0)
			if is_on_wall() or travelled >= _wstats.charge_distance or edge_ahead:
				hitbox.deactivate()
				_set_state(State.SLIDE)
		State.POUNCE:
			velocity.x = move_toward(velocity.x, 0.0, 1200.0 * delta)
			if _state_time >= _wstats.pounce_seconds:
				_set_state(State.RETREAT)
		State.SLIDE:
			# Hamuje przez cały poślizg, plecami do graczy.
			var decel: float = _wstats.charge_speed / maxf(_wstats.slide_seconds, 0.05)
			velocity.x = move_toward(velocity.x, 0.0, decel * delta)
			if _state_time >= _wstats.slide_seconds:
				_set_state(State.RETREAT)
		State.RETREAT:
			_tick_retreat(delta)
		State.BITE_WINDUP:
			velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
			if _state_time >= _wstats.bite_windup:
				hitbox.activate(_wstats.bite_damage, 60.0, self)
				_set_state(State.BITE)
		State.BITE:
			velocity.x = 0.0
			if _state_time >= _wstats.bite_active:
				hitbox.deactivate()
				_set_state(State.BITE_RECOVER)
		State.BITE_RECOVER:
			velocity.x = 0.0
			if _state_time >= _wstats.bite_recovery:
				_cooldown_left = _wstats.stalk_cooldown * 0.5
				_set_state(State.STALK)


func _tick_stalk(delta: float) -> void:
	_pick_target()
	if target == null:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		return
	var target_x: float = target.global_position.x
	face_towards(target_x)
	var dist: float = absf(target_x - global_position.x)
	if dist <= _wstats.bite_range and _cooldown_left <= 0.0:
		_set_state(State.BITE_WINDUP)
		return
	var cornered: bool = is_on_wall() or near_room_edge(24.0)
	if _cooldown_left <= 0.0 and (dist >= _wstats.min_charge_distance or cornered):
		_set_state(State.WINDUP)
		return
	# Trzyma dystans: odchodzi, gdy gracz podchodzi, podchodzi, gdy ucieka.
	var desired_x: float = target_x - float(facing) * _wstats.stalk_distance
	var dx: float = desired_x - global_position.x
	if absf(dx) > 6.0:
		velocity.x = signf(dx) * _wstats.move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)


func _tick_retreat(delta: float) -> void:
	_pick_target()
	if target == null:
		_set_state(State.STALK)
		return
	var target_x: float = target.global_position.x
	var away: float = -1.0 if target_x > global_position.x else 1.0
	var desired_x: float = clampf(target_x + away * _wstats.stalk_distance,
		room_bounds.position.x + 20.0, room_bounds.end.x - 20.0)
	var dx: float = desired_x - global_position.x
	if absf(dx) <= 8.0 or is_on_wall() or near_room_edge(20.0):
		velocity.x = 0.0
		_cooldown_left = maxf(_cooldown_left, _wstats.stalk_cooldown)
		_set_state(State.STALK)
		return
	velocity.x = signf(dx) * _wstats.retreat_speed
	facing = 1 if velocity.x > 0.0 else -1


## Krwiożerczy: zawsze gracz z niższym zdrowiem. Przy równym zdrowiu ten
## dalej od wilka, żeby bliższy partner miał co osłaniać.
func _pick_target() -> void:
	var best: Player = null
	var best_hp: int = 0
	var best_dist: float = 0.0
	for player: Player in alive_players():
		var dist: float = absf(player.global_position.x - global_position.x)
		if best == null or player.hp < best_hp or (player.hp == best_hp and dist > best_dist):
			best = player
			best_hp = player.hp
			best_dist = dist
	target = best


func _start_charge() -> void:
	if target == null:
		_set_state(State.STALK)
		return
	_charge_dir = 1 if target.global_position.x >= global_position.x else -1
	facing = _charge_dir
	_charge_start_x = global_position.x
	hitbox.activate(_wstats.charge_damage, _wstats.charge_knockback, self, true,
		_wstats.charge_bleed_seconds)
	_set_state(State.CHARGE)


func _on_hit_landed(hit: HitInfo) -> void:
	if state != State.CHARGE:
		return
	hitbox.deactivate()
	if hit.absorbed:
		# Bariera Maga wchłania szarżę bez ogłuszenia: wilk biegnie dalej do poślizgu.
		print("[Wilkołak] szarżę wchłonęła bariera")
		return
	if hit.blocked:
		# Odbicie od tarczy: nagroda dla Wojownika.
		velocity.x = float(-_charge_dir) * _wstats.blocked_bounce
		print("[Wilkołak] odbija się od tarczy")
		stun(_wstats.blocked_stun_seconds)
		return
	_set_state(State.POUNCE)


func _on_stun_ended() -> void:
	_cooldown_left = _wstats.stalk_cooldown
	_set_state(State.RETREAT)


func _after_move() -> void:
	# Spoza ekranu wbiega tylko przy wejściu; potem zostaje w pomieszczeniu.
	if state != State.ENTER:
		clamp_to_room(16.0)


func _set_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0
	_refresh_label()


func _update_visual() -> void:
	super()
	match state:
		State.WINDUP:
			visual.scale.y = 0.72
		State.CHARGE:
			visual.scale.y = 0.9
		State.SLIDE:
			visual.scale.y = 0.85
		_:
			visual.scale.y = 1.0
	# Poślizg: wilk nadal "patrzy" w stronę biegu, czyli plecami do graczy.
	if stunned_left > 0.0:
		visual.rotation = 0.35
	else:
		visual.rotation = 0.0


func _refresh_label() -> void:
	if _wstats == null:
		super()
		return
	var status: String = "ogłuszony" if stunned_left > 0.0 else STATE_LABELS[state]
	label.text = "%s %d/%d · %s" % [display_name, hp, stats.max_hp, status]
