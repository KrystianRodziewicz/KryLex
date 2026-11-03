class_name Shrine
extends Interactable
## Kapliczka: punkt kontrolny. Odpoczynek leczy oboje graczy (także ducha),
## a w kroku 3 M0 odnowi też wspólną flaszkę i zrespawnuje wrogów.
## Pierwsze dotknięcie przez jednego gracza odblokowuje ją dla obojga
## (README, sekcja 2), więc zdarzenie idzie z id gracza, a odpoczynek
## obejmuje całą grupę.

signal rested(shrine: Shrine, player: Player)

@onready var _flame: ColorRect = $Flame as ColorRect


func _ready() -> void:
	add_to_group(&"shrines")


func interact(player: Player) -> void:
	for node: Node in get_tree().get_nodes_in_group(&"players"):
		var other: Player = node as Player
		if other != null:
			other.heal_full()
	WorldStore.record_event(&"shrine_reached", player.player_id, String(interactable_id), &"",
		global_position)
	WorldStore.flush()
	_flame.modulate = Color(2.0, 1.6, 0.8)
	var tween: Tween = create_tween()
	tween.tween_property(_flame, ^"modulate", Color.WHITE, 0.6)
	rested.emit(self, player)
