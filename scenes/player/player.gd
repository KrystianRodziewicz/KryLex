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

## Grafika zastępcza, gdy klasa nie ma własnego rigu w PlayerStats.rig_scene.
const BLOCK_RIG: PackedScene = preload("res://scenes/player/rigs/block_rig.tscn")

@export var stats: PlayerStats
@export var player_id: int = 1
@export var input_profile: PlayerInput.Profile = PlayerInput.Profile.KEYBOARD

var hp: int = 0
var state: State = State.IDLE
## 1 = w prawo, -1 = w lewo.
var facing: int = 1
var blocking: bool = false
var frame: InputFrame = InputFrame.new()
## Kto trafił ostatni; przy śmierci sesja czyta stąd zabójcę do zdarzenia player_death.
var last_hit_by: Node2D = null
## Pozostały czas krwawienia w sekundach.
var bleed_left: float = 0.0
## Pozostały czas podpalenia w sekundach.
var burn_left: float = 0.0
## Bariera Maga: wchłania jeden atak (Osłoń w wersji słabej).
var barrier_active: bool = false
var barrier_left: float = 0.0
var barrier_cooldown_left: float = 0.0
## Żywioł pocisku (klasy dystansowe): zmieniany klawiszem R / prawą gałką.
var current_element: Elements.Kind = Elements.Kind.FIRE
## Przerwij: odnowienie uderzenia tarczą albo impulsu.
var interrupt_cooldown_left: float = 0.0
## Zamrożenie gracza: spowolnienie w sekundach.
var slow_left: float = 0.0

var _state_time: float = 0.0
var _hurt_stun: float = 0.0
var _bleed_tick: float = 0.0
var _burn_tick: float = 0.0
var _rig: PlayerRig = null
var _coyote_left: float = 0.0
var _jump_buffer_left: float = 0.0
var _dodge_cooldown_left: float = 0.0
var _attack_opened: bool = false
var _attack_closed: bool = false
## Profil bieżącego ataku: zwykły cios, pocisk albo Przerwij.
var _atk_startup: float = 0.0
var _atk_active: float = 0.0
var _atk_recovery: float = 0.0
var _atk_hit: HitInfo = HitInfo.new()
var _atk_hitbox: Hitbox = null
var _atk_anim: StringName = &"attack"
var _atk_projectile: bool = false
var _atk_burst: bool = false

@onready var input: PlayerInput = $PlayerInput as PlayerInput
@onready var visual: Node2D = $Visual as Node2D
@onready var name_label: Label = $NameLabel as Label
@onready var hitbox: Hitbox = $Hitbox as Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D as CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var interact_area: Area2D = $InteractArea as Area2D
@onready var impulse_hitbox: Hitbox = $ImpulseHitbox as Hitbox


func _ready() -> void:
	assert(stats != null, "Player potrzebuje PlayerStats (resources/balance/)")
	add_to_group(&"players")
	input.profile = input_profile
	hp = stats.max_hp
	var rig_scene: PackedScene = stats.rig_scene if stats.rig_scene != null else BLOCK_RIG
	_rig = rig_scene.instantiate() as PlayerRig
	assert(_rig != null, "rig_scene musi dziedziczyć po PlayerRig")
	visual.add_child(_rig)
	_rig.setup(stats)
	name_label.text = "P%d %s" % [player_id, stats.label]
	hurtbox.hit_received.connect(_on_hit_received)
	health_changed.emit(hp, stats.max_hp)


func _physics_process(delta: float) -> void:
	frame = input.poll()
	_tick_timers(delta)
	_tick_bleed(delta)
	# Zmiana żywiołu nie jest akcją z oknem czasu, więc działa w każdym stanie.
	if frame.element_pressed and stats.projectile_scene != null and state != State.DEAD:
		current_element = Elements.next(current_element)
		health_changed.emit(hp, stats.max_hp)
		print("[P%d] żywioł: %s" % [player_id, Elements.label(current_element)])
	match state:
		State.DEAD:
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, stats.friction * delta)
		State.HURT:
			_apply_gravity(delta)
			velocity.x = move_toward(velocity.x, 0.0, stats.friction * 0.5 * delta)
			if _state_time >= _hurt_stun:
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
	if frame.block_pressed and stats.has_barrier and barrier_cooldown_left <= 0.0 and not barrier_active:
		_raise_barrier()
	var control: float = 1.0 if on_floor else stats.air_control
	var speed: float = stats.move_speed * (stats.block_move_multiplier if blocking else 1.0)
	if slow_left > 0.0:
		speed *= 0.5
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
	if frame.interrupt_pressed and on_floor and interrupt_cooldown_left <= 0.0:
		_start_interrupt()
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
	var hit: HitInfo = HitInfo.new()
	hit.damage = stats.attack_damage
	hit.knockback = stats.attack_knockback
	hit.source = self
	_begin_swing(&"attack", stats.attack_startup, stats.attack_active, stats.attack_recovery, hit,
		hitbox, stats.projectile_scene != null, false)


## Przerwij (README, sekcja 3): Wojownik uderza tarczą, Mag wypuszcza impuls wokół siebie.
func _start_interrupt() -> void:
	interrupt_cooldown_left = stats.interrupt_cooldown
	var hit: HitInfo = HitInfo.new()
	hit.damage = stats.interrupt_damage
	hit.knockback = stats.interrupt_knockback
	hit.posture_damage = stats.interrupt_posture
	hit.interrupt = true
	hit.stun_seconds = stats.interrupt_stun
	hit.source = self
	var impulse: bool = stats.interrupt_kind == 1
	print("[P%d] %s" % [player_id, "impuls" if impulse else "uderzenie tarczą"])
	_begin_swing(&"impulse" if impulse else &"bash", stats.interrupt_startup, stats.interrupt_active,
		stats.interrupt_recovery, hit, impulse_hitbox if impulse else hitbox, false, impulse)


func _begin_swing(anim: StringName, startup: float, active: float, recovery: float, hit: HitInfo,
		p_hitbox: Hitbox, projectile: bool, burst: bool) -> void:
	blocking = false
	_attack_opened = false
	_attack_closed = false
	_atk_anim = anim
	_atk_startup = startup
	_atk_active = active
	_atk_recovery = recovery
	_atk_hit = hit
	_atk_hitbox = p_hitbox
	_atk_projectile = projectile
	_atk_burst = burst
	hitbox_shape.position.x = stats.attack_reach * float(facing)
	_set_state(State.ATTACK)


func _tick_attack(delta: float) -> void:
	_apply_gravity(delta)
	var decel: float = stats.friction * (1.0 if is_on_floor() else stats.air_control) * delta
	velocity.x = move_toward(velocity.x, 0.0, decel)
	var active_from: float = _atk_startup
	var active_to: float = active_from + _atk_active
	var total: float = active_to + _atk_recovery
	if not _attack_opened and _state_time >= active_from:
		_attack_opened = true
		if _atk_projectile:
			_fire_projectile()
		else:
			_atk_hitbox.activate_hit(_atk_hit)
		if _atk_burst:
			_rig.impulse_burst()
	if not _attack_closed and _state_time >= active_to:
		_attack_closed = true
		_atk_hitbox.deactivate()
	if _state_time >= total:
		_set_state(State.IDLE)


## Atak dystansowy: pocisk z PlayerStats.projectile_scene leci w kierunku patrzenia.
func _fire_projectile() -> void:
	var projectile: Projectile = stats.projectile_scene.instantiate() as Projectile
	if projectile == null:
		push_warning("projectile_scene musi mieć skrypt Projectile")
		return
	var origin: Vector2 = Vector2(stats.projectile_origin.x * float(facing), stats.projectile_origin.y)
	projectile.position = global_position + origin
	get_parent().add_child(projectile)
	var life: float = stats.projectile_range / maxf(stats.projectile_speed, 1.0)
	projectile.launch(Vector2(float(facing), 0.0), stats.projectile_speed, stats.attack_damage,
		stats.attack_knockback, self, current_element, stats.projectile_element_seconds, life)
	projectile.hitbox.template.posture_damage = stats.projectile_posture_damage


func _raise_barrier() -> void:
	barrier_active = true
	barrier_left = stats.barrier_duration
	_rig.set_barrier(true)
	health_changed.emit(hp, stats.max_hp)
	print("[P%d] bariera" % player_id)


func _drop_barrier(absorbed: bool) -> void:
	barrier_active = false
	barrier_left = 0.0
	barrier_cooldown_left = stats.barrier_cooldown
	_rig.set_barrier(false, absorbed)
	health_changed.emit(hp, stats.max_hp)
	print("[P%d] bariera %s" % [player_id, "wchłonęła cios" if absorbed else "zgasła"])


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
	last_hit_by = hit.source
	var damage: int = hit.damage
	var from_front: bool = signi(int(hit.direction.x)) == -facing
	if barrier_active and from_front:
		# Bariera stoi przed Magiem jak tarcza: wchłania cios z przodu,
		# a cios w plecy przechodzi. Źródło widzi wynik w HitInfo.absorbed.
		hit.absorbed = true
		_drop_barrier(true)
		_flash(Color(0.6, 0.95, 1.0))
		return
	if blocking and from_front:
		# Blok tarczą: źródło dowie się o tym z HitInfo.blocked (wilk się odbija).
		hit.blocked = true
		damage = int(roundf(float(damage) * stats.block_damage_multiplier))
		velocity.x = hit.direction.x * hit.knockback * 0.25
		_flash(Color(0.8, 0.9, 1.0))
		if damage > 0:
			_apply_damage(damage)
		return
	_apply_damage(damage)
	if state == State.DEAD:
		return
	if hit.bleed_seconds > 0.0:
		bleed_left = maxf(bleed_left, hit.bleed_seconds)
	if hit.element == Elements.Kind.FIRE and hit.element_seconds > 0.0:
		burn_left = maxf(burn_left, hit.element_seconds)
	if hit.element == Elements.Kind.ICE and hit.element_seconds > 0.0:
		slow_left = maxf(slow_left, hit.element_seconds)
	velocity = Vector2(hit.direction.x * hit.knockback, stats.hurt_knockback_up)
	_hurt_stun = stats.knockdown_stun if hit.knockdown else stats.hurt_stun
	if state == State.ATTACK and _atk_hitbox != null:
		_atk_hitbox.deactivate()
	hurtbox.enabled = true
	_flash(Color(1.0, 0.4, 0.4))
	_set_state(State.HURT)


func _tick_bleed(delta: float) -> void:
	if state == State.DEAD:
		return
	if bleed_left > 0.0:
		bleed_left = maxf(bleed_left - delta, 0.0)
		_bleed_tick += delta
		if _bleed_tick >= stats.bleed_interval:
			_bleed_tick -= stats.bleed_interval
			_apply_damage(stats.bleed_damage)
	if burn_left > 0.0 and state != State.DEAD:
		burn_left = maxf(burn_left - delta, 0.0)
		_burn_tick += delta
		if _burn_tick >= stats.burn_interval:
			_burn_tick -= stats.burn_interval
			_flash(Color(1.0, 0.7, 0.3))
			_apply_damage(stats.burn_damage)


## Obrażenia bez trafienia hitboxem: upadek, pułapka, otoczenie.
func apply_direct_damage(amount: int, source: Node2D = null) -> void:
	if state == State.DEAD:
		return
	last_hit_by = source
	_flash(Color(1.0, 0.5, 0.5))
	_apply_damage(amount)


## Podpowiedź do HUD: żywioł pocisku i odnowienie Przerwij.
func combat_hint() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if stats.projectile_scene != null:
		parts.append(Elements.label(current_element))
	if interrupt_cooldown_left > 1.0:
		var verb: String = "impuls" if stats.interrupt_kind == 1 else "tarcza"
		parts.append("%s za %d s" % [verb, ceili(interrupt_cooldown_left)])
	return " · ".join(parts)


func has_status() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if bleed_left > 0.0:
		parts.append("krwawi")
	if burn_left > 0.0:
		parts.append("płonie")
	if slow_left > 0.0:
		parts.append("zamrożony")
	if barrier_active:
		parts.append("bariera")
	elif stats.has_barrier and barrier_cooldown_left > 0.0:
		parts.append("bariera za %d s" % ceili(barrier_cooldown_left))
	return ", ".join(parts)


func _apply_damage(damage: int) -> void:
	hp = maxi(hp - damage, 0)
	health_changed.emit(hp, stats.max_hp)
	if hp == 0:
		_die()


func _die() -> void:
	blocking = false
	if barrier_active:
		_drop_barrier(false)
	hurtbox.enabled = false
	hitbox.deactivate()
	velocity = Vector2.ZERO
	_set_state(State.DEAD)
	died.emit(self)


func heal_full() -> void:
	hp = stats.max_hp
	bleed_left = 0.0
	burn_left = 0.0
	slow_left = 0.0
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
	barrier_cooldown_left = maxf(barrier_cooldown_left - delta, 0.0)
	interrupt_cooldown_left = maxf(interrupt_cooldown_left - delta, 0.0)
	slow_left = maxf(slow_left - delta, 0.0)
	if barrier_active:
		barrier_left -= delta
		if barrier_left <= 0.0:
			_drop_barrier(false)


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	_state_time = 0.0
	state_changed.emit(new_state)


func _update_visual() -> void:
	visual.scale.x = float(facing)
	match state:
		State.DEAD:
			_rig.play(&"dead")
		State.HURT:
			# Powalenie kładzie postać; zwykłe trafienie tylko nią szarpie.
			if _hurt_stun > stats.hurt_stun:
				_rig.play(&"knockdown", _hurt_stun)
			else:
				_rig.play(&"hurt", _hurt_stun)
		State.DODGE:
			_rig.play(&"dodge", stats.dodge_duration)
		State.ATTACK:
			_rig.play(_atk_anim, _atk_startup + _atk_active + _atk_recovery)
		State.AIR:
			_rig.play(&"jump" if velocity.y < 0.0 else &"fall")
		State.RUN:
			_rig.play(&"block_walk" if blocking else &"run")
		_:
			_rig.play(&"block" if blocking else &"idle")


func _flash(color: Color) -> void:
	_rig.flash(color)
