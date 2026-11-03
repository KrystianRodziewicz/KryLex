class_name PlayerRig
extends Node2D
## Wspólny interfejs grafiki postaci. [Player] mówi rigowi tylko, jaką
## animację grać i jak długo ma trwać; nie wie, czy pod spodem są
## prostokąty (BlockRig), części z AnimationPlayer (WarriorRig) czy
## kiedyś arkusz klatek.
##
## Nazwy animacji: idle, run, jump, fall, attack, dodge, block, block_walk,
## hurt, knockdown, dead.


func setup(_stats: PlayerStats) -> void:
	pass


## Gra animację. [param duration] > 0 skaluje tempo tak, żeby animacja
## trwała dokładnie tyle sekund (okno ataku z PlayerStats, nie odwrotnie).
func play(_anim: StringName, _duration: float = -1.0) -> void:
	pass


## Gra animację od początku, nawet gdy właśnie trwa (podgląd, powtórzenie ciosu).
func restart(anim: StringName, duration: float = -1.0) -> void:
	play(anim, duration)


func flash(color: Color) -> void:
	modulate = color
	var tween: Tween = create_tween()
	tween.tween_property(self, ^"modulate", Color.WHITE, 0.15)
