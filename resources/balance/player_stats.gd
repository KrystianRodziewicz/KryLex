class_name PlayerStats
extends Resource
## Liczby do strojenia jednej klasy gracza. Właściciel: Alex.
## Instancje: [code]player_warrior.tres[/code], [code]player_mage.tres[/code].
## Balans zmienia się tutaj, bez ruszania sceny gracza.

@export_group("Tożsamość")
@export var class_id: StringName = &"warrior"
@export var label: String = "Wojownik"
@export var color: Color = Color.WHITE
## Blok ma tylko klasa z tarczą (README, sekcja 4: "blok – tylko tarcza").
@export var can_block: bool = true

@export_group("Zdrowie")
@export var max_hp: int = 100

@export_group("Ruch")
@export var move_speed: float = 100.0
@export var acceleration: float = 1100.0
@export var friction: float = 1400.0
## Mnożnik przyspieszenia i hamowania w powietrzu.
@export_range(0.0, 1.0) var air_control: float = 0.6
@export var gravity: float = 900.0
@export var max_fall_speed: float = 420.0
## Przy grawitacji 900 skok -330 daje ok. 60 px wysokości (2,5 postaci).
@export var jump_velocity: float = -330.0
## Po puszczeniu skoku prędkość w górę spada do tej części skoku.
@export_range(0.0, 1.0) var jump_cut_multiplier: float = 0.45
@export var coyote_time: float = 0.1
@export var jump_buffer: float = 0.12
## Prędkość ruchu podczas trzymania bloku (ułamek move_speed).
@export_range(0.0, 1.0) var block_move_multiplier: float = 0.3

@export_group("Unik")
@export var dodge_speed: float = 220.0
@export var dodge_duration: float = 0.3
## Klatki nietykalności liczone od początku uniku.
@export var dodge_iframes: float = 0.22
@export var dodge_cooldown: float = 0.45

@export_group("Atak")
@export var attack_damage: int = 10
@export var attack_knockback: float = 120.0
@export var attack_startup: float = 0.08
@export var attack_active: float = 0.1
@export var attack_recovery: float = 0.2
## Odległość środka hitboxa od środka postaci.
@export var attack_reach: float = 16.0

@export_group("Obrona")
## Ułamek obrażeń przechodzący przez blok (0 = pełny blok).
@export_range(0.0, 1.0) var block_damage_multiplier: float = 0.0
@export var hurt_stun: float = 0.25
## Ogłuszenie po powaleniu (szarża wilkołaka).
@export var knockdown_stun: float = 0.7
@export var hurt_knockback_up: float = -90.0
## Krwawienie: tyle obrażeń co pół sekundy, przez czas z trafienia.
@export var bleed_damage: int = 1
@export var bleed_interval: float = 0.5
