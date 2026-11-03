class_name Enemy
extends CharacterBody2D
## Baza każdego moba, Elity i bossa: HP, ukryty pasek postawy, ogłuszenie,
## okno krytyczne i śmierć zapisana do WorldStore. Zachowanie (patrol,
## zauważenie, atak) pisze klasa pochodna w [method _tick_behaviour].
##
## W sieci wrogami zarządza host (docs/technika.md), więc ta klasa nie ma
## żadnego kodu sieciowego.

signal died(enemy: Enemy, killer: Player)
signal posture_broken(enemy: Enemy)
signal health_changed(current: int, maximum: int)

## Stałe id do bazy świata, np. [code]werewolf[/code], [code]leszy[/code].
@export var enemy_id: StringName = &"enemy"
@export var display_name: String = "Wróg"
@export var stats: EnemyStats

var hp: int = 0
var posture: int = 0
## 1 = w prawo, -1 = w lewo.
var facing: int = -1
var dead: bool = false
var stunned_left: float = 0.0
## Granice pomieszczenia (z [Room] nad wrogiem). Ściany boczne są na warstwie
## "bounds" tylko dla graczy, żeby wróg mógł wbiec spoza ekranu, więc
## w środku pomieszczenia trzyma go ta prostokąt.
var room_bounds: Rect2 = Rect2(-1.0e6, -1.0e6, 2.0e6, 2.0e6)

@onready var visual: Node2D = $Visual as Node2D
@onready var hurtbox: Hurtbox = $Hurtbox as Hurtbox
@onready var hitbox: Hitbox = $Hitbox as Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D as CollisionShape2D
@onready var label: Label = $Label as Label


func _ready() -> void:
	assert(stats != null, "Enemy potrzebuje EnemyStats (resources/balance/)")
	add_to_group(&"enemies")
	hp = stats.max_hp
	posture = stats.posture_max
	hurtbox.hit_received.connect(_on_hit_received)
	hitbox.landed.connect(_on_hit_landed)
	var room: Room = _find_room()
	if room != null:
		room_bounds = room.bounds
	_refresh_label()


func _physics_process(delta: float) -> void:
	if dead:
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
		move_and_slide()
		return
	if stunned_left > 0.0:
		stunned_left = maxf(stunned_left - delta, 0.0)
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		move_and_slide()
		if stunned_left == 0.0:
			_on_stun_ended()
		_update_visual()
		return
	_tick_behaviour(delta)
	move_and_slide()
	_after_move()
	_update_visual()


# --- Do nadpisania --------------------------------------------------------------


## Po ruchu w tym ticku, np. przytrzymanie w granicach pomieszczenia.
func _after_move() -> void:
	pass


## Zachowanie wroga; wołane co tick, gdy żyje i nie jest ogłuszony.
func _tick_behaviour(delta: float) -> void:
	_apply_gravity(delta)


## Wejście spoza ekranu po dodaniu do drzewa: 1 = biegnie w prawo, -1 = w lewo.
func enter_from(direction: int) -> void:
	facing = direction


## Czy trafienie teraz liczy się jako krytyczne (ogłuszenie, odsłonięte plecy).
func is_critical_window() -> bool:
	return stunned_left > 0.0


## Wołane, gdy ogłuszenie mija.
func _on_stun_ended() -> void:
	pass


## Wynik własnego trafienia (np. szarża zatrzymana tarczą).
func _on_hit_landed(_hit: HitInfo) -> void:
	pass


## Reakcja na zwykłe trafienie, które nie złamało postawy.
func _on_flinched(_hit: HitInfo) -> void:
	pass


# --- Obrażenia -------------------------------------------------------------------


func _on_hit_received(hit: HitInfo) -> void:
	if dead:
		return
	var damage: int = hit.damage
	var critical: bool = is_critical_window()
	if critical:
		damage = int(roundf(float(damage) * stats.crit_multiplier))
	hp = maxi(hp - damage, 0)
	health_changed.emit(hp, stats.max_hp)
	_flash(Color(1.6, 1.2, 1.2) if critical else Color(1.3, 1.3, 1.3))
	_refresh_label()
	if hp == 0:
		_die(hit.source as Player)
		return
	posture -= hit.damage * (2 if critical else 1)
	if posture <= 0 and stunned_left <= 0.0:
		break_posture()
		return
	if stunned_left <= 0.0:
		velocity.x = hit.direction.x * stats.hit_flinch
		_on_flinched(hit)


## Złamanie postawy: ogłuszenie i okno na atak krytyczny.
func break_posture() -> void:
	posture = stats.posture_max
	stun(stats.stun_seconds)
	posture_broken.emit(self)


func stun(seconds: float) -> void:
	stunned_left = maxf(stunned_left, seconds)
	hitbox.deactivate()


func _die(killer: Player) -> void:
	dead = true
	hurtbox.enabled = false
	hitbox.deactivate()
	set_collision_layer_value(4, false)
	var killer_id: int = killer.player_id if killer != null else 0
	WorldStore.record_event(&"enemy_killed", killer_id, String(enemy_id), &"", global_position)
	print("[%s] pada od P%d" % [display_name, killer_id])
	label.text = "%s ✝" % display_name
	var tween: Tween = create_tween()
	tween.tween_property(visual, ^"modulate", Color(0.3, 0.3, 0.3, 0.0), 1.2)
	tween.tween_callback(queue_free)
	died.emit(self, killer)


# --- Pomocnicze ---------------------------------------------------------------------


func face_towards(x: float) -> void:
	if absf(x - global_position.x) > 1.0:
		facing = 1 if x > global_position.x else -1


func clamp_to_room(margin: float) -> void:
	global_position.x = clampf(global_position.x, room_bounds.position.x + margin,
		room_bounds.end.x - margin)


func near_room_edge(margin: float) -> bool:
	return global_position.x <= room_bounds.position.x + margin \
		or global_position.x >= room_bounds.end.x - margin


func _find_room() -> Room:
	var node: Node = get_parent()
	while node != null:
		var room: Room = node as Room
		if room != null:
			return room
		node = node.get_parent()
	return null


func _apply_gravity(delta: float) -> void:
	velocity.y = minf(velocity.y + stats.gravity * delta, stats.max_fall_speed)


func _update_visual() -> void:
	visual.scale.x = float(facing)
	hitbox_shape.position.x = absf(hitbox_shape.position.x) * float(facing)


func _flash(color: Color) -> void:
	visual.modulate = color
	var tween: Tween = create_tween()
	tween.tween_property(visual, ^"modulate", Color.WHITE, 0.12)


func _refresh_label() -> void:
	label.text = "%s %d/%d" % [display_name, hp, stats.max_hp]


## Żywi gracze w pomieszczeniu.
func alive_players() -> Array[Player]:
	var result: Array[Player] = []
	for node: Node in get_tree().get_nodes_in_group(&"players"):
		var player: Player = node as Player
		if player != null and player.is_alive():
			result.append(player)
	return result
