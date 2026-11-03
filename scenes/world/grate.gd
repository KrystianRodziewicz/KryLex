class_name Grate
extends StaticBody2D
## Krata w podłodze. Zamknięta jest zwykłą podłogą; po [method open]
## traci kolizję i gracze spadają niżej. Początek układu to lewy górny róg.

signal opened

var is_open: bool = false

@onready var _shape: CollisionShape2D = $CollisionShape2D as CollisionShape2D
@onready var _bars: ColorRect = $Bars as ColorRect
@onready var _label: Label = $Label as Label


func open() -> void:
	if is_open:
		return
	is_open = true
	_shape.set_deferred(&"disabled", true)
	_bars.color = Color(0.5, 0.5, 0.55, 0.25)
	_label.text = "krata otwarta"
	print("[Krata] otwarta")
	opened.emit()
