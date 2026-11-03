class_name Lever
extends Interactable
## Dźwignia. Po pociągnięciu trzyma przez [member hold_seconds], potem
## wraca. Dwie dźwignie "na dwóch" łączy [DualLeverGate]: obie muszą być
## pociągnięte w tym samym oknie czasu (S2 w docs/biom-1-przeklety-bor.md).

signal pulled_changed(lever: Lever, pulled: bool)

@export var hold_seconds: float = 3.0

var pulled: bool = false
var latched: bool = false

var _hold_left: float = 0.0

@onready var _handle: ColorRect = $Handle as ColorRect
@onready var _timer_label: Label = $TimerLabel as Label


func _ready() -> void:
	_timer_label.visible = false


func interact(player: Player) -> void:
	if latched or pulled:
		return
	pulled = true
	_hold_left = hold_seconds
	_handle.rotation = 0.9
	_timer_label.visible = true
	print("[Dźwignia] %s pociągnięta przez P%d" % [interactable_id, player.player_id])
	pulled_changed.emit(self, true)


func _process(delta: float) -> void:
	if not pulled or latched:
		return
	_hold_left -= delta
	_timer_label.text = "%.1f" % maxf(_hold_left, 0.0)
	if _hold_left <= 0.0:
		pulled = false
		_handle.rotation = 0.0
		_timer_label.visible = false
		print("[Dźwignia] %s wraca" % interactable_id)
		pulled_changed.emit(self, false)


## Zostaje pociągnięta na stałe (krata otwarta).
func latch() -> void:
	latched = true
	pulled = true
	_handle.rotation = 0.9
	_timer_label.visible = false
