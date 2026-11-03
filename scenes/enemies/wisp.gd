class_name Wisp
extends Enemy
## Błędny Ognik: wabik (docs/biom-1-przeklety-bor.md). Unosi się nad ziemią,
## cofa się przed graczem, w którego jest zwrócony, zawsze w stronę
## zagrożenia ([member lure_x]), a gdy gracz przestaje go gonić, wraca
## i kusi miganiem. Z daleka rzuca iskrą z podpaleniem.
##
## Gracz podchodzący od drugiej strony zaskakuje go: ognik patrzy tylko
## na jednego gracza naraz i zmienia obiekt uwagi dopiero, gdy ten odejdzie.
## Jedno trafienie gasi ognika; postawy nie ma.

enum State { HOVER, FLEE, TEMPT }

const SPARK_SCENE: PackedScene = preload("res://scenes/enemies/spark.tscn")
const STATE_LABELS: Array[String] = ["unosi się", "cofa się", "kusi"]

## Dokąd wabi (x w pomieszczeniu): rozpadlina, gałąź ze strzygą, wilki.
## Ujemna wartość = tylko ucieka.
@export var lure_x: float = -1.0

var state: State = State.HOVER
## Gracz, na którego ognik patrzy; tylko przed nim ucieka.
var watched: Player = null

var _wstats: WispStats = null
var _base_y: float = 0.0
var _time: float = 0.0
var _still_time: float = 0.0
var _throw_cooldown: float = 0.0

@onready var _glow: ColorRect = $Visual/Glow as ColorRect


func _ready() -> void:
	super()
	_wstats = stats as WispStats
	assert(_wstats != null, "Wisp potrzebuje WispStats")
	_base_y = global_position.y
	_throw_cooldown = _wstats.throw_cooldown * 0.5
	_refresh_label()


func is_critical_window() -> bool:
	return false


func break_posture() -> void:
	pass


func _tick_behaviour(delta: float) -> void:
	_time += delta
	_throw_cooldown = maxf(_throw_cooldown - delta, 0.0)
	_update_watched()
	var vx: float = 0.0
	var new_state: State = State.HOVER
	if watched != null:
		var dx: float = watched.global_position.x - global_position.x
		# Odległość w 2D: gracz na półce wysoko nad ognikiem go nie płoszy.
		var dist: float = global_position.distance_to(watched.global_position)
		face_towards(watched.global_position.x)
		if dist < _wstats.flee_distance:
			new_state = State.FLEE
			_still_time = 0.0
			var away: float = -signf(dx) if dx != 0.0 else 1.0
			vx = away * _wstats.flee_speed
			# Nad celem wabienia zostaje: gracz ma pod niego podejść.
			if lure_x >= 0.0 and absf(lure_x - global_position.x) < 6.0 \
					and signf(lure_x - global_position.x) != away:
				vx = 0.0
		elif dist <= _wstats.notice_distance * 1.5:
			var chasing: bool = absf(watched.velocity.x) > 10.0
			_still_time = 0.0 if chasing else _still_time + delta
			if _still_time >= _wstats.tempt_delay:
				new_state = State.TEMPT
				if dist > _wstats.tempt_hold_distance:
					vx = signf(dx) * _wstats.tempt_speed
			if dist >= _wstats.throw_distance and _throw_cooldown <= 0.0:
				_throw_spark(watched)
	else:
		_still_time = 0.0
	if new_state != state:
		state = new_state
		_refresh_label()
	velocity = Vector2(vx, 0.0)
	global_position.y = _base_y + sin(_time * _wstats.bob_speed) * _wstats.bob_amplitude


func _after_move() -> void:
	clamp_to_room(12.0)


func _update_watched() -> void:
	if watched != null and watched.is_alive() \
			and global_position.distance_to(watched.global_position) <= _wstats.notice_distance * 1.5:
		return
	watched = null
	var best_dist: float = _wstats.notice_distance
	for player: Player in alive_players():
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= best_dist:
			best_dist = dist
			watched = player


func _throw_spark(target: Player) -> void:
	_throw_cooldown = _wstats.throw_cooldown
	var spark: Spark = SPARK_SCENE.instantiate() as Spark
	spark.position = position
	get_parent().add_child(spark)
	var direction: Vector2 = (target.global_position - global_position).normalized()
	spark.throw(direction, _wstats.spark_speed, _wstats.spark_damage,
		_wstats.spark_burn_seconds, _wstats.spark_lifetime, self)
	print("[Ognik] iskra w P%d" % target.player_id)


func _update_visual() -> void:
	super()
	var pulse: float = 0.5 + 0.5 * sin(_time * 10.0)
	match state:
		State.TEMPT:
			_glow.modulate = Color(1.0, 1.0, 1.0, 0.3 + 0.7 * pulse)
			visual.scale = Vector2(1.0, 1.0) * (1.0 + 0.25 * pulse)
		_:
			_glow.modulate = Color(1.0, 1.0, 1.0, 0.8 + 0.2 * pulse)
			visual.scale = Vector2.ONE
	visual.scale.x *= float(facing)


func _refresh_label() -> void:
	if _wstats == null:
		super()
		return
	label.text = "%s · %s" % [display_name, STATE_LABELS[state]]
