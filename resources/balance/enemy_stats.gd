class_name EnemyStats
extends Resource
## Liczby wspólne dla każdego wroga. Właściciel: Alex.
## Karty wrogów z opisem zachowań: docs/biom-1-przeklety-bor.md.

@export_group("Zdrowie i postawa")
@export var max_hp: int = 40
## Ukryty pasek postawy (README, sekcja 4). Każde trafienie zdejmuje tyle, ile zadało obrażeń.
@export var posture_max: int = 30
## Mnożnik obrażeń w oknie krytycznym (ogłuszenie, odsłonięte plecy).
@export var crit_multiplier: float = 2.0
@export var stun_seconds: float = 2.0

@export_group("Ruch")
@export var move_speed: float = 80.0
@export var gravity: float = 900.0
@export var max_fall_speed: float = 420.0
## Odrzut przy zwykłym trafieniu (bez zmiany stanu).
@export var hit_flinch: float = 40.0

@export_group("Statusy żywiołowe")
## Podpalenie: tyle obrażeń co pół sekundy.
@export var burn_damage: int = 2
@export var burn_interval: float = 0.5
## Zamrożenie: mnożnik prędkości ruchu.
@export_range(0.0, 1.0) var freeze_speed_multiplier: float = 0.4
## Roztrzaskanie (zamrożony + cios fizyczny): dodatkowe obrażenia i obszar.
@export var shatter_damage: int = 15
@export var shatter_radius: float = 40.0
## Porażenie: piorun przeskakuje na sąsiadów w tym promieniu.
@export var shock_chain_range: float = 56.0
@export var shock_chain_damage: int = 4

@export_group("Osłona żywiołowa")
## Kora Biesa, futro Włodarza: bez statusu wróg nie przyjmuje obrażeń ani postawy.
@export var elemental_shield: bool = false
## Po podpaleniu osłona płonie tyle sekund, potem odpada.
@export var shield_burn_seconds: float = 2.0
