class_name Enemy
extends CharacterBody2D
## Baza każdego moba, Elity i bossa: HP, ukryty pasek postawy, ogłuszenie,
## okno krytyczne, statusy żywiołowe, osłona żywiołowa i śmierć zapisana
## do WorldStore. Zachowanie (patrol, zauważenie, atak) pisze klasa pochodna
## w [method _tick_behaviour].
##
## Statusy (README, sekcja 4): podpalenie zadaje obrażenia w czasie,
## zamrożenie spowalnia ([method speed_scale]), porażenie przeskakuje na
## sąsiadów. Reakcja prototypu: zamrożony + cios fizyczny = roztrzaskanie
## (dodatkowe obrażenia, złamana postawa, obrażenia w promieniu).
## Osłona żywiołowa (kora Biesa) blokuje wszystko, dopóki nie nałoży się statusu.
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

## Statusy żywiołowe (pozostały czas w sekundach).
var burn_left: float = 0.0
var frozen_left: float = 0.0
var shocked_left: float = 0.0
## Osłona żywiołowa.
var shield_up: bool = false
var shield_cracked: bool = false
var shield_burning_left: float = 0.0

var _burn_tick: float = 0.0
var _burn_source: Node2D = null
var _base_tint: Color = Color.WHITE

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
	shield_up = stats.elemental_shield
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
	_tick_statuses(delta)
	if dead:
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


## Przerwij: uderzenie tarczą albo impuls trafiły wroga (przed ogłuszeniem).
func _on_interrupted(_hit: HitInfo) -> void:
	pass


## Wołane po zmianie statusu (podpalenie, zamrożenie, porażenie, utrata osłony).
func _on_status_changed() -> void:
	pass


# --- Statusy ---------------------------------------------------------------------


func is_frozen() -> bool:
	return frozen_left > 0.0


## Mnożnik prędkości ruchu: zamrożony wróg jest wolny.
func speed_scale() -> float:
	return stats.freeze_speed_multiplier if frozen_left > 0.0 else 1.0


func apply_element(kind: Elements.Kind, seconds: float, source: Node2D) -> void:
	if dead or kind == Elements.Kind.NONE or seconds <= 0.0:
		return
	match kind:
		Elements.Kind.FIRE:
			burn_left = maxf(burn_left, seconds)
			_burn_source = source
			if shield_up and shield_burning_left <= 0.0:
				shield_burning_left = stats.shield_burn_seconds
				print("[%s] osłona płonie" % display_name)
		Elements.Kind.ICE:
			frozen_left = maxf(frozen_left, seconds)
			if shield_up:
				shield_cracked = true
				print("[%s] osłona pęka od mrozu" % display_name)
		Elements.Kind.LIGHTNING:
			shocked_left = maxf(shocked_left, seconds)
			_chain_shock(source, seconds)
	print("[%s] status: %s" % [display_name, Elements.status_label(kind)])
	_refresh_tint()
	_refresh_label()
	_on_status_changed()


## Piorun przeskakuje na innych wrogów w promieniu, bez dalszego łańcucha.
func _chain_shock(source: Node2D, seconds: float) -> void:
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var other: Enemy = node as Enemy
		if other == null or other == self or other.dead:
			continue
		if global_position.distance_to(other.global_position) > stats.shock_chain_range:
			continue
		other.shocked_left = maxf(other.shocked_left, seconds)
		other.apply_direct_damage(stats.shock_chain_damage, source)
		other._refresh_tint()
		other._refresh_label()
		print("[%s] piorun przeskakuje na %s" % [display_name, other.display_name])


func _tick_statuses(delta: float) -> void:
	var changed: bool = false
	if burn_left > 0.0:
		burn_left = maxf(burn_left - delta, 0.0)
		_burn_tick += delta
		if _burn_tick >= stats.burn_interval:
			_burn_tick -= stats.burn_interval
			_flash(Color(1.4, 0.9, 0.6))
			apply_direct_damage(stats.burn_damage, _burn_source)
		if burn_left == 0.0:
			changed = true
	if frozen_left > 0.0:
		frozen_left = maxf(frozen_left - delta, 0.0)
		if frozen_left == 0.0:
			changed = true
	if shocked_left > 0.0:
		shocked_left = maxf(shocked_left - delta, 0.0)
		if shocked_left == 0.0:
			changed = true
	if shield_up and shield_burning_left > 0.0:
		shield_burning_left = maxf(shield_burning_left - delta, 0.0)
		if shield_burning_left == 0.0:
			_drop_shield()
			changed = true
	if changed:
		_refresh_tint()
		_refresh_label()
		_on_status_changed()


func _drop_shield() -> void:
	shield_up = false
	shield_cracked = false
	print("[%s] osłona odpada" % display_name)


func _refresh_tint() -> void:
	if frozen_left > 0.0:
		_base_tint = Color(0.65, 0.85, 1.0)
	elif burn_left > 0.0:
		_base_tint = Color(1.0, 0.72, 0.5)
	elif shocked_left > 0.0:
		_base_tint = Color(1.0, 1.0, 0.6)
	else:
		_base_tint = Color.WHITE
	visual.modulate = _base_tint


## Nazwy aktywnych statusów do etykiety.
func status_suffix() -> String:
	var parts: PackedStringArray = PackedStringArray()
	if shield_up:
		parts.append("osłona")
	if burn_left > 0.0:
		parts.append(Elements.status_label(Elements.Kind.FIRE))
	if frozen_left > 0.0:
		parts.append(Elements.status_label(Elements.Kind.ICE))
	if shocked_left > 0.0:
		parts.append(Elements.status_label(Elements.Kind.LIGHTNING))
	return ", ".join(parts)


# --- Obrażenia -------------------------------------------------------------------


func _on_hit_received(hit: HitInfo) -> void:
	if dead:
		return
	# Osłona żywiołowa: cios fizyczny nic nie robi (chyba że osłona już pękła od mrozu).
	if shield_up and hit.element == Elements.Kind.NONE:
		if shield_cracked:
			_drop_shield()
			_refresh_label()
			_on_status_changed()
		else:
			_flash(Color(0.7, 0.7, 0.7))
			print("[%s] osłona odbija cios" % display_name)
		return
	if hit.element != Elements.Kind.NONE:
		apply_element(hit.element, hit.element_seconds, hit.source)
		if shield_up:
			# Status nałożony, ale obrażenia wchodzą dopiero bez osłony.
			return
	var damage: int = hit.damage
	var posture_damage: int = hit.posture_damage if hit.posture_damage >= 0 else hit.damage
	var critical: bool = is_critical_window()
	var shattered: bool = false
	if frozen_left > 0.0 and hit.is_physical():
		# Reakcja: zamrożony + cios = roztrzaskanie.
		shattered = true
		damage += stats.shatter_damage
		frozen_left = 0.0
		_shatter_neighbours(hit.source)
		print("[%s] roztrzaskanie" % display_name)
	if critical:
		damage = int(roundf(float(damage) * stats.crit_multiplier))
	hp = maxi(hp - damage, 0)
	health_changed.emit(hp, stats.max_hp)
	if shattered:
		_flash(Color(1.8, 2.0, 2.2))
		_refresh_tint()
	else:
		_flash(Color(1.6, 1.2, 1.2) if critical else Color(1.3, 1.3, 1.3))
	_refresh_label()
	if hp == 0:
		_die(hit.source as Player)
		return
	if hit.interrupt:
		_on_interrupted(hit)
	posture -= posture_damage * (2 if critical else 1)
	if shattered or (posture <= 0 and stunned_left <= 0.0):
		break_posture()
		return
	if hit.interrupt and hit.stun_seconds > 0.0:
		stun(hit.stun_seconds)
		return
	if stunned_left <= 0.0:
		velocity.x = hit.direction.x * stats.hit_flinch
		_on_flinched(hit)


func _shatter_neighbours(source: Node2D) -> void:
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var other: Enemy = node as Enemy
		if other == null or other == self or other.dead:
			continue
		if global_position.distance_to(other.global_position) <= stats.shatter_radius:
			other.apply_direct_damage(stats.shatter_damage / 2, source)


## Obrażenia bez hitboxa: podpalenie, łańcuch pioruna, odłamki, upadek.
func apply_direct_damage(amount: int, source: Node2D) -> void:
	if dead or amount <= 0:
		return
	hp = maxi(hp - amount, 0)
	health_changed.emit(hp, stats.max_hp)
	_refresh_label()
	if hp == 0:
		_die(source as Player)


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
	tween.tween_property(visual, ^"modulate", _base_tint, 0.12)


func _refresh_label() -> void:
	var suffix: String = status_suffix()
	label.text = "%s %d/%d%s" % [display_name, hp, stats.max_hp,
		" · " + suffix if suffix != "" else ""]


## Żywi gracze w pomieszczeniu.
func alive_players() -> Array[Player]:
	var result: Array[Player] = []
	for node: Node in get_tree().get_nodes_in_group(&"players"):
		var player: Player = node as Player
		if player != null and player.is_alive():
			result.append(player)
	return result
