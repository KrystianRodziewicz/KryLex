class_name Player
extends CharacterBody2D
## Postać gracza: ruch, skok, unik, atak, blok i przyjmowanie obrażeń.
##
## Wejście przychodzi wyłącznie jako [InputFrame] z [PlayerInput], więc
## w kroku 2 M0 host może podstawić klatki odebrane od klienta bez zmian
## w tej klasie. Liczby do strojenia siedzą w [PlayerStats]
## (resources/balance/), nie tutaj.
##
## Co liczy host, a co klient, opisuje docs/technika.md ("Kto Czym Zarządza").

signal health_changed(current: int, maximum: int)
signal died(player: Player)
signal state_changed(new_state: State)
signal ping_requested(player: Player)
signal flask_requested(player: Player)

enum State { IDLE, RUN, AIR, ATTACK, DODGE, HURT, DEAD }

@export var stats: PlayerStats
@export var player_id: int = 1
@export var input_profile: PlayerInput.Profile = PlayerInput.Profile.KEYBOARD

var hp: int = 0
var state: State = State.IDLE
## 1 = w prawo, -1 = w lewo.
var facing: int = 1
var blocking: bool = false
var frame: InputFrame = InputFrame.new()

var _state_time: float = 0.0
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _dodge_cooldown_left: float = 0.0
var _attack_opened: bool = false
var _attack_closed: bool = false

@onready var input: PlayerInput = $PlayerInput as PlayerInput
@onready var visual: Node2D = $Visual as Node2D
@onready var body_rect: ColorRect = $Visual/Body as ColorRect
@onready var shield_rect: ColorRect = $Visual/Shield as ColorRect
@onready var name_label: Label = $NameLabel as Label
@onready var hitbox: Hitbox = $Hitbox as Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D as CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var interact_area: Area2D = $InteractArea as Area2D


func _ready() -> void:
	assert(stats != null, "Player potrzebuje PlayerStats (resources/balance/)")
	add_to_group(&"players")
	input.profile = input_profile
	hp = stats.max_hp
	body_rect.color = stats.color
	shield_rect.visible = false
	name_label.text = "P%d %s" % [player_id, stats.label]
	hurtbox.hit_received.connect(_on_hit_received)
	health_changed.emit(hp, stats.max_hp)


func _physics_process(delta: float) -> void:
	frame = input.poll()
	_tick_timers(delta)
	match state:
		State.DEAD:
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, stats.friction * delta)
		State.HURT:
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, stats.friction * 0.5 * delta)
			if _state_time >= stats.hurt_stun:
				_set_state(State.IDLE)
		State.DODGE:
			_tick_dodge(delta)
		State.ATTACK:
			_tick_attack(delta)
		_:
			_tick_locomotion(delta)
	move_and_slide()
	_state_time += delta
	_update_visual()


# --- Stany -----------------------------------------------------------------


func _tick_locomotion(delta: float) -> void:
	var on_floor: bool = is_on_floor()
	if on_floor:
		_coyote_left = stats.coyote_time
	if frame.jump_pressed:
		_jump_buffer_left = stats.jump_buffer

	blocking = frame.block_held and stats.can_block and on_floor
	var control: float = 1.0 if on_floor else stats.air_control
	var speed: float = stats.move_speed * (stats.block_move_multiplier if blocking else 1.0)
	if is_zero_approx(frame.move.x):
		velocity.x = move_toward(velocity.x, 0.0, stats.friction * control * delta)
	else:
		velocity.x = move_toward(velocity.x, frame.move.x * speed, stats.acceleration * control * delta)
		if not blocking:
			facing = 1 if frame.move.x > 0.0 else -1

	if _jump_buffer_left > 0.0 and _coyote_left > 0.0 and not blocking:
		velocity.y = stats.jump_velocity
		_jump_buffer_left = 0.0
		_coyote_left = 0.0
	if not on_floor and velocity.y < 0.0 and not frame.jump_held:
		velocity.y = maxf(velocity.y, stats.jump_velocity * stats.jump_cut_multiplier)
	_apply_gravity(delta)

	if frame.dodge_pressed and on_floor and _dodge_cooldown_left <= 0.0:
		_start_dodge()
		return
	if frame.attack_pressed and not blocking:
		_start_attack()
		return
	if frame.interact_pressed:
		_try_interact()
	if frame.ping_pressed:
		ping_requested.emit(self)
	if frame.flask_pressed:
		flask_requested.emit(self)

	if not on_floor:
		_set_state(State.AIR)
	elif is_zero_approx(velocity.x):
		_set_state(State.IDLE)
	else:
		_set_state(State.RUN)


func _start_dodge() -> void:
	blocking = false
	velocity.x = float(facing) * stats.dodge_speed
	velocity.y = 0.0
	hurtbox.enabled = false
	_dodge_cooldown_left = stats.dodge_cooldown + stats.dodge_duration
	_set_state(State.DODGE)


func _tick_dodge(delta: float) -> void:
	_apply_gravity(delta)
	if _state_time >= stats.dodge_iframes:
		hurtbox.enabled = true
	if _state_time >= stats.dodge_duration:
		_set_state(State.IDLE)


func _start_attack() -> void:
	blocking = false
	_attack_opened = false
	_attack_closed = false
	hitbox_shape.position.x = stats.attack_reach * float(facing)
	_set_state(State.ATTACK)


func _tick_attack(delta: float) -> void:
	_apply_gravity(delta)
	var decel: float = stats.friction * (1.0 if is_on_floor() else stats.air_control) * delta
	velocity.x = move_toward(velocity.x, 0.0, decel)
	var active_from: float = stats.attack_startup
	var active_to: float = active_from + stats.attack_active
	var total: float = active_to + stats.attack_recovery
	if not _attack_opened and _state_time >= active_from:
		_attack_opened = true
		hitbox.activate(stats.attack_damage, stats.attack_knockback, self)
	if not _attack_closed and _state_time >= active_to:
		_attack_closed = true
		hitbox.deactivate()
	if _state_time >= total:
		_set_state(State.IDLE)


func _try_interact() -> void:
	for area: Area2D in interact_area.get_overlapping_areas():
		var target: Interactable = area as Interactable
		if target != null:
			target.interact(self)
			return


# --- Obrażenia ---------------------------------------------------------------


func _on_hit_received(hit: HitInfo) -> void:
	if state == State.DEAD or state == State.DODGE:
		return
	var damage: int = hit.damage
	var from_front: bool = signi(int(hit.direction.x)) == -facing
	if blocking and from_front:
		damage = int(roundf(float(damage) * stats.block_damage_multiplier))
		_flash(Color(0.8, 0.9, 1.0))
		if damage > 0:
			_apply_damage(damage)
		return
	_apply_damage(damage)
	if state == State.DEAD:
		return
	velocity = Vector2(hit.direction.x * hit.knockback, stats.hurt_knockback_up)
	if state == State.ATTACK:
		hitbox.deactivate()
	hurtbox.enabled = true
	_flash(Color(1.0, 0.4, 0.4))
	_set_state(State.HURT)


func _apply_damage(damage: int) -> void:
	hp = maxi(hp - damage, 0)
	health_changed.emit(hp, stats.max_hp)
	if hp == 0:
		_die()


func _die() -> void:
	blocking = false
	hurtbox.enabled = false
	hitbox.deactivate()
	velocity = Vector2.ZERO
	_set_state(State.DEAD)
	died.emit(self)


func heal_full() -> void:
	hp = stats.max_hp
	health_changed.emit(hp, stats.max_hp)
	if state == State.DEAD:
		revive()


func revive() -> void:
	hp = maxi(hp, 1)
	hurtbox.enabled = true
	velocity = Vector2.ZERO
	_set_state(State.IDLE)
	health_changed.emit(hp, stats.max_hp)


## Zeruje ruch po przeniesieniu do nowego pomieszczenia.
func reset_motion() -> void:
	velocity = Vector2.ZERO
	_coyote_left = 0.0
	_jump_buffer_left = 0.0
	if state != State.DEAD:
		hitbox.deactivate()
		hurtbox.enabled = true
		_set_state(State.IDLE)


func is_alive() -> bool:
	return state != State.DEAD


# --- Pomocnicze --------------------------------------------------------------


func _apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + stats.gravity * delta, stats.max_fall_speed)


func _tick_timers(delta: float) -> void:
	_coyote_left = maxf(_coyote_left - delta, 0.0)
	_jump_buffer_left = maxf(_jump_buffer_left - delta, 0.0)
	_dodge_cooldown_left = maxf(_dodge_cooldown_left - delta, 0.0)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	_state_time = 0.0
	state_changed.emit(new_state)


func _update_visual() -> void:
	visual.scale.x = float(facing)
	shield_rect.visible = blocking
	match state:
		State.DEAD:
			visual.modulate = Color(0.4, 0.4, 0.4, 0.8)
			visual.rotation = PI * 0.5
		State.DODGE:
			visual.modulate = Color(1.0, 1.0, 1.0, 0.5)
			visual.rotation = 0.0
		State.ATTACK:
			visual.modulate = Color(1.3, 1.3, 1.1)
			visual.rotation = 0.0
		_:
			if visual.modulate.r >= 1.0 and visual.modulate.g >= 1.0 and visual.modulate.b >= 1.0:
				visual.modulate = Color.WHITE
			visual.rotation = 0.0


func _flash(color: Color) -> void:
	visual.modulate = color
	var tween: Tween = create_tween()
	tween.tween_property(visual, ^"modulate", Color.WHITE, 0.15)
