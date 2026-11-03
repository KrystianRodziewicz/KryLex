class_name Interactable
extends Area2D
## Rzecz, z którą gracz może wejść w interakcję (kapliczka, słup, dźwignia).
## Leży na warstwie [code]interactable[/code]; gracz szuka jej swoim
## [code]InteractArea[/code] i woła [method interact].
##
## [member interactable_id] to stałe tekstowe id do bazy świata
## (docs/technika.md: "Stałe id"), np. [code]shrine_1[/code].

@export var interactable_id: StringName = &""
@export var prompt: String = "E / Y"


## Nadpisz w klasie pochodnej.
func interact(_player: Player) -> void:
	pass
