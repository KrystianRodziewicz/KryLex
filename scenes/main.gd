class_name LocalSession
extends Node
## Krok 1 M0: dwie postacie w jednym procesie, bez sieci.
## Jedna na klawiaturze, druga na padzie (docs/technika.md:
## "Kolejność prac w M0"). Sesja spawnuje graczy, podmienia pomieszczenia
## i trzyma punkt kontrolny.
##
## W kroku 2 ten węzeł rozdziela się na hosta (spawnuje oboje, liczy świat)
## i klienta (wysyła InputFrame, odtwarza stan).

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const ROOMS_DIR: String = "res://scenes/levels/"
const RESPAWN_DELAY: float = 2.0

@export var p1_stats: PlayerStats
@export var p1_profile: PlayerInput.Profile = PlayerInput.Profile.KEYBOARD
@export var p2_stats: PlayerStats
@export var p2_profile: PlayerInput.Profile = PlayerInput.Profile.JOYPAD
@export var first_room: StringName = &"osada"

var players: Array[Player] = []
var current_room: Room = null

var _checkpoint_room: StringName = &""
var _checkpoint_entry: StringName = &"default"
var _respawning: bool = false

@onready var _room_slot: Node2D = $World/RoomSlot as Node2D
@onready var _players_root: Node2D = $World/Players as Node2D
@onready var _camera: RoomCamera = $World/RoomCamera as RoomCamera
@onready var _hud: Hud = $Hud as Hud


func _ready() -> void:
	add_to_group(&"session")
	_spawn_player(1, p1_stats, p1_profile)
	_spawn_player(2, p2_stats, p2_profile)
	_checkpoint_room = first_room
	change_room(first_room, &"default")


func _spawn_player(id: int, stats: PlayerStats, profile: PlayerInput.Profile) -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	player.name = "Player%d" % id
	player.player_id = id
	player.stats = stats
	player.input_profile = profile
	_players_root.add_child(player)
	players.append(player)
	_camera.targets.append(player)
	_hud.bind_player(player)
	player.died.connect(_on_player_died)
	player.ping_requested.connect(_on_ping_requested)
	player.flask_requested.connect(_on_flask_requested)
	return player


## Podmienia pomieszczenie i stawia oboje graczy przy wejściu [param entry].
func change_room(room_id: StringName, entry: StringName) -> void:
	var path: String = ROOMS_DIR + String(room_id) + ".tscn"
	if not ResourceLoader.exists(path):
		push_warning("Pomieszczenie '%s' jeszcze nie istnieje (%s)" % [room_id, path])
		return
	WorldStore.flush()
	if current_room != null:
		_room_slot.remove_child(current_room)
		current_room.queue_free()
		current_room = null
	var scene: PackedScene = load(path) as PackedScene
	var room: Room = scene.instantiate() as Room
	_room_slot.add_child(room)
	current_room = room
	room.exit_triggered.connect(_on_room_exit)
	for node: Node in get_tree().get_nodes_in_group(&"shrines"):
		var shrine: Shrine = node as Shrine
		if shrine != null:
			shrine.rested.connect(_on_shrine_rested)
	var spawn: Vector2 = room.get_spawn(entry)
	for i: int in players.size():
		var player: Player = players[i]
		player.global_position = spawn + Vector2(float(i) * 20.0, 0.0)
		player.reset_motion()
	_camera.set_bounds(room.bounds)
	_camera.snap_now()
	WorldStore.set_location(room.biome, room.room_id)
	_hud.set_room(room)
	print("[Sesja] pomieszczenie %s, wejście %s" % [room.room_id, entry])


func _on_room_exit(target_room: StringName, entry: StringName) -> void:
	# Sygnał przychodzi z callbacku fizyki, więc podmiana drzewa idzie z opóźnieniem.
	change_room.call_deferred(target_room, entry)


func _on_shrine_rested(shrine: Shrine, player: Player) -> void:
	_checkpoint_room = current_room.room_id
	_checkpoint_entry = &"default"
	print("[Sesja] punkt kontrolny: %s (%s, P%d)" % [shrine.interactable_id, current_room.room_id,
		player.player_id])


func _on_player_died(player: Player) -> void:
	# Jedno zdarzenie śmierci, z którego czytają wszystkie systemy (README, sekcja 4).
	WorldStore.record_event(&"player_death", player.player_id, "", &"", player.global_position)
	for other: Player in players:
		if other.is_alive():
			return
	if _respawning:
		return
	_respawning = true
	print("[Sesja] oboje polegli, powrót do ostatniej kapliczki")
	await get_tree().create_timer(RESPAWN_DELAY).timeout
	for other: Player in players:
		other.heal_full()
	change_room(_checkpoint_room, _checkpoint_entry)
	_respawning = false


func _on_ping_requested(player: Player) -> void:
	# Ping kontekstowy (README, sekcja 5) wchodzi razem z siecią.
	print("[Ping] P%d" % player.player_id)


func _on_flask_requested(player: Player) -> void:
	# Wspólna flaszka z zatwierdzaniem przez hosta to krok 3 M0.
	print("[Flaszka] P%d prosi o łyk (wspólna flaszka: krok 3 M0)" % player.player_id)
