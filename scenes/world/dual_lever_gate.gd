class_name DualLeverGate
extends Node
## Dźwignia na dwóch: dwie dźwignie w odległości ok. ekranu, obie
## pociągnięte w oknie [member Lever.hold_seconds], otwierają kratę
## (S2 w docs/biom-1-przeklety-bor.md). Rozdziela graczy celowo,
## w bezpiecznym miejscu, żeby poznali wskaźnik partnera poza ekranem.

signal opened

@export var lever_a: NodePath
@export var lever_b: NodePath
@export var grate: NodePath

var is_open: bool = false

@onready var _lever_a: Lever = get_node(lever_a) as Lever
@onready var _lever_b: Lever = get_node(lever_b) as Lever
@onready var _grate: Grate = get_node(grate) as Grate


func _ready() -> void:
	assert(_lever_a != null and _lever_b != null and _grate != null, "DualLeverGate: brak dźwigni albo kraty")
	_lever_a.pulled_changed.connect(_on_lever_changed)
	_lever_b.pulled_changed.connect(_on_lever_changed)


func _on_lever_changed(_lever: Lever, pulled: bool) -> void:
	if is_open or not pulled:
		return
	if _lever_a.pulled and _lever_b.pulled:
		is_open = true
		_lever_a.latch()
		_lever_b.latch()
		_grate.open()
		opened.emit()
