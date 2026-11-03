class_name VowPillar
extends Interactable
## Słup Ślubów: rzeźbiony totem w Osadzie. Wybór Ślubów (README, sekcja 3)
## wchodzi w M1; w kroku 1 M0 to tylko znacznik z podpowiedzią.

@onready var _hint: Label = $Hint as Label


func interact(player: Player) -> void:
	_hint.text = "Śluby wchodzą w M1 (P%d)" % player.player_id
	_hint.visible = true
	var tween: Tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(_hide_hint)


func _hide_hint() -> void:
	_hint.visible = false
