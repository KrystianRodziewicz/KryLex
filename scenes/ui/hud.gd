class_name Hud
extends CanvasLayer
## HUD kroku 1 M0: nazwa pomieszczenia, zdrowie obu postaci i ściąga
## sterowania. Wspólna flaszka i wskaźnik partnera poza ekranem
## (README, sekcja 5) dochodzą w kolejnych krokach.

@onready var _room_label: Label = $Margin/VBox/RoomLabel as Label
@onready var _players_box: VBoxContainer = $Margin/VBox/Players as VBoxContainer


func bind_player(player: Player) -> void:
	var label: Label = Label.new()
	label.add_theme_font_size_override(&"font_size", 10)
	_players_box.add_child(label)
	var refresh: Callable = func(current: int, maximum: int) -> void:
		var status: String = "" if player.is_alive() else "  (martwy)"
		label.text = "P%d %s [%s]  HP %d/%d%s" % [
			player.player_id, player.stats.label, player.input.profile_label(),
			current, maximum, status]
	player.health_changed.connect(refresh)
	player.state_changed.connect(func(_new_state: Player.State) -> void:
		refresh.call(player.hp, player.stats.max_hp))
	refresh.call(player.hp, player.stats.max_hp)


func set_room(room: Room) -> void:
	_room_label.text = "%s · %s" % [room.biome, room.title]
