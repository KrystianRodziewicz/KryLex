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
		var status: String = "  (martwy)" if not player.is_alive() else ""
		var effects: String = player.has_status()
		if player.is_alive() and effects != "":
			status = "  (%s)" % effects
		var hint: String = player.combat_hint()
		label.text = "P%d %s [%s]  HP %d/%d%s%s" % [
			player.player_id, player.stats.label, player.input.profile_label(),
			current, maximum, status, "  · " + hint if hint != "" else ""]
	player.health_changed.connect(refresh)
	player.state_changed.connect(func(_new_state: Player.State) -> void:
		refresh.call(player.hp, player.stats.max_hp))
	# Odliczanie bariery zmienia się bez zmiany HP, więc etykieta odświeża się też co sekundę.
	var ticker: Timer = Timer.new()
	ticker.wait_time = 1.0
	ticker.autostart = true
	ticker.timeout.connect(func() -> void: refresh.call(player.hp, player.stats.max_hp))
	label.add_child(ticker)
	refresh.call(player.hp, player.stats.max_hp)


func set_room(room: Room) -> void:
	_room_label.text = "%s · %s" % [room.biome, room.title]
