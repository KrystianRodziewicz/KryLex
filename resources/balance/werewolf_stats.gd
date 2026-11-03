class_name WerewolfStats
extends EnemyStats
## Liczby wilkołaka (karta w docs/biom-1-przeklety-bor.md, sekcja 2).
## Czasy zapowiedzi i poślizgu pochodzą wprost z karty; dystanse są
## do strojenia, bo "ok. 1 ekranu" w graybox 640 px to za dużo na S2.

@export_group("Wejście")
## Ile sekund migają oczy przy krawędzi, zanim wilk wbiegnie.
@export var warning_seconds: float = 1.0
@export var enter_speed: float = 180.0
@export var enter_distance: float = 80.0

@export_group("Czajenie")
## Dystans, jaki wilk utrzymuje od celu między szarżami.
@export var stalk_distance: float = 240.0
## Przerwa między szarżami.
@export var stalk_cooldown: float = 1.6
## Minimalna odległość od celu, żeby w ogóle szarżować.
@export var min_charge_distance: float = 110.0
@export var retreat_speed: float = 160.0

@export_group("Szarża")
## Zapowiedź: przykuca i warczy.
@export var charge_windup: float = 0.6
@export var charge_speed: float = 420.0
## Bieg przez cały ekran.
@export var charge_distance: float = 640.0
@export var charge_damage: int = 18
@export var charge_knockback: float = 220.0
@export var charge_bleed_seconds: float = 3.0
## Po trafieniu wilk na chwilę staje (ugryzienie), potem odbiega.
@export var pounce_seconds: float = 0.45
## Po chybieniu ślizga się odwrócony plecami.
@export var slide_seconds: float = 0.8
## Odbicie od tarczy: ogłuszenie.
@export var blocked_stun_seconds: float = 2.0
@export var blocked_bounce: float = 140.0

@export_group("Ugryzienie")
@export var bite_range: float = 30.0
@export var bite_damage: int = 6
@export var bite_windup: float = 0.25
@export var bite_active: float = 0.1
@export var bite_recovery: float = 0.35
