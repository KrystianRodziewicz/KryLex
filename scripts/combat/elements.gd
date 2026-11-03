class_name Elements
extends RefCounted
## Żywioły z README (sekcja 4): podpalenie (obrażenia w czasie), zamrożenie
## (spowolnienie), porażenie (łańcuch na sąsiadów). Jedno miejsce na nazwy
## i kolory, żeby HUD, pociski i etykiety wrogów mówiły tym samym językiem.

enum Kind { NONE, FIRE, ICE, LIGHTNING }

const CYCLE: Array[Kind] = [Kind.FIRE, Kind.ICE, Kind.LIGHTNING]


static func label(kind: Kind) -> String:
	match kind:
		Kind.FIRE:
			return "ogień"
		Kind.ICE:
			return "lód"
		Kind.LIGHTNING:
			return "piorun"
		_:
			return "brak"


## Nazwa statusu na wrogu albo graczu.
static func status_label(kind: Kind) -> String:
	match kind:
		Kind.FIRE:
			return "płonie"
		Kind.ICE:
			return "zamrożony"
		Kind.LIGHTNING:
			return "porażony"
		_:
			return ""


static func color(kind: Kind) -> Color:
	match kind:
		Kind.FIRE:
			return Color(1.0, 0.6, 0.25)
		Kind.ICE:
			return Color(0.6, 0.85, 1.0)
		Kind.LIGHTNING:
			return Color(1.0, 0.95, 0.4)
		_:
			return Color.WHITE


static func next(kind: Kind) -> Kind:
	var idx: int = CYCLE.find(kind)
	return CYCLE[(idx + 1) % CYCLE.size()]
