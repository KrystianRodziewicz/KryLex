class_name RoomCamera
extends Camera2D
## Kamera kroku 1 M0: jedno okno, dwie postacie, więc kamera śledzi środek
## między żywymi graczami i trzyma się granic pomieszczenia.
##
## Docelowo (README, sekcja 5) każdy gracz ma własną kamerę na własnym
## ekranie; ta klasa zostaje wtedy dla trybu testowego na jednym PC.

var targets: Array[Node2D] = []


func set_bounds(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)


func snap_now() -> void:
	_follow()
	reset_smoothing()


func _process(_delta: float) -> void:
	_follow()


func _follow() -> void:
	var sum: Vector2 = Vector2.ZERO
	var count: int = 0
	for target: Node2D in targets:
		if not is_instance_valid(target):
			continue
		var player: Player = target as Player
		if player != null and player.state == Player.State.DEAD:
			continue
		sum += target.global_position
		count += 1
	if count == 0:
		return
	global_position = (sum / float(count)).round()
