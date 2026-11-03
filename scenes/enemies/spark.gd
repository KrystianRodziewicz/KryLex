class_name Spark
extends Projectile
## Iskra Błędnego Ognika: powolny pocisk, niskie obrażenia, krótkie
## podpalenie. Mechanika w [Projectile]; tu tylko wygodna sygnatura.


func throw(direction: Vector2, speed: float, damage: int, burn_seconds: float,
		life: float, source: Node2D) -> void:
	launch(direction, speed, damage, 40.0, source, burn_seconds, life)
