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
