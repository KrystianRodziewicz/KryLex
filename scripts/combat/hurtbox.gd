class_name Hurtbox
extends Area2D
## Obszar, w który można trafić. Właściciel (gracz, wróg, kukła) podpina się
## pod [signal hit_received] i sam decyduje, co z trafieniem zrobić.
##
## Hurtbox niczego nie monitoruje: to [Hitbox] szuka hurtboxów,
## więc tu wystarczy [code]monitorable = true[/code] i właściwa warstwa.

signal hit_received(hit: HitInfo)

## Wyłączany na czas klatek nietykalności (unik, duch, śmierć).
var enabled: bool = true


func receive_hit(hit: HitInfo) -> void:
	if not enabled:
		return
	hit_received.emit(hit)
