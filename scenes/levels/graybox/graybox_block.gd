@tool
class_name GrayboxBlock
extends StaticBody2D
## Szary prostokąt z kolizją: podłoga, ściana, półka. Graybox prototypu
## (scenes/levels/README.md). Początek układu to lewy górny róg,
## więc pozycja i [member size] czyta się jak prostokąt.
##
## Gdy pojawi się tileset, pomieszczenia przechodzą na [TileMapLayer],
## a bloki zostają do szybkich szkiców.

@export var size: Vector2 = Vector2(64, 16):
	set(value):
		size = value
		_apply()
@export var color: Color = Color(0.33, 0.33, 0.38, 1.0):
	set(value):
		color = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	if not is_node_ready():
		return
	var rect: ColorRect = get_node_or_null(^"ColorRect") as ColorRect
	var shape_node: CollisionShape2D = get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if rect == null or shape_node == null:
		return
	rect.position = Vector2.ZERO
	rect.size = size
	rect.color = color
	shape_node.position = size * 0.5
	var rect_shape: RectangleShape2D = shape_node.shape as RectangleShape2D
	if rect_shape == null:
		rect_shape = RectangleShape2D.new()
		shape_node.shape = rect_shape
	rect_shape.size = size
