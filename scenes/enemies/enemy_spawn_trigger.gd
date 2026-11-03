class_name EnemySpawnTrigger
extends Area2D
## Wrogowie Boru nie stoją w pomieszczeniu: wbiegają z krawędzi ekranu,
## gdy gracze wejdą w strefę, a chwilę wcześniej przy krawędzi migają oczy
## (docs/biom-1-przeklety-bor.md: "Bór patrzy"). Strefa to kształty tego
## Area2D, więc jeden wyzwalacz może pilnować kilku miejsc (dwie dźwignie).
##
## Kleszcze z dwóch wilków to dwa wyzwalacze z przeciwnymi krawędziami
## i różnym [member warning_seconds].

signal spawned(enemy: Enemy)

@export var enemy_scene: PackedScene
## Miejsce tuż za krawędzią ekranu, na wysokości podłogi.
@export var spawn_position: Vector2 = Vector2(-24, 314)
## 1 = wbiega w prawo (z lewej krawędzi), -1 = w lewo (z prawej).
@export var enter_direction: int = 1
@export var warning_seconds: float = 1.0
## Węzeł z oczami przy krawędzi; migają przez czas ostrzeżenia.
@export var eyes: NodePath
## Gdzie wstawić wroga; domyślnie rodzic wyzwalacza.
@export var enemies_container: NodePath
@export var once: bool = true

var _armed: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var eyes_node: Node2D = get_node_or_null(eyes) as Node2D
	if eyes_node != null:
		eyes_node.visible = false


func _on_body_entered(body: Node2D) -> void:
	var player: Player = body as Player
	if not _armed or player == null:
		return
	_armed = false
	_spawn_after_warning()


func _spawn_after_warning() -> void:
	var eyes_node: Node2D = get_node_or_null(eyes) as Node2D
	if eyes_node != null:
		eyes_node.visible = true
		eyes_node.modulate = Color.WHITE
		var blink: Tween = create_tween()
		blink.set_loops(maxi(int(warning_seconds / 0.25), 1))
		blink.tween_property(eyes_node, ^"modulate:a", 0.15, 0.12)
		blink.tween_property(eyes_node, ^"modulate:a", 1.0, 0.13)
	await get_tree().create_timer(warning_seconds).timeout
	if not is_inside_tree():
		return
	if eyes_node != null:
		eyes_node.visible = false
	var enemy: Enemy = enemy_scene.instantiate() as Enemy
	var container: Node = get_node_or_null(enemies_container)
	if container == null:
		container = get_parent()
	enemy.position = spawn_position
	container.add_child(enemy)
	enemy.enter_from(enter_direction)
	print("[Bór] %s wbiega z krawędzi" % enemy.display_name)
	spawned.emit(enemy)
	if not once:
		_armed = true
