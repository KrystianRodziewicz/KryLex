extends Node
## Autoload [code]WorldStore[/code]: jedyne wejście do bazy świata.
## Właściciel: Krystian.
##
## Krok 1 M0: zdarzenia trafiają do bufora w pamięci i na konsolę.
## Krok 3 M0: te same metody zapisują wsadowo do SQLite przez godot-sqlite
## (schemat w db/migrations/), więc rozgrywka nie zmieni ani jednego
## wywołania. Do bazy pisze tylko host, nigdy w środku walki:
## [method flush] woła się przy kapliczce, zmianie pomieszczenia i wyjściu.
##
## Kolumny i typy zdarzeń: docs/npc-guslarz.md ("Dane").

## Jeden wiersz tabeli [code]events[/code].
class WorldEvent:
	extends RefCounted
	var time: int = 0
	var type: StringName = &""
	var player: int = 0
	var biome: StringName = &""
	var room: StringName = &""
	var killer: StringName = &""
	var detail: String = ""
	var x: float = 0.0
	var y: float = 0.0


const EVENT_TYPES: Array[StringName] = [
	&"player_death",
	&"enemy_killed",
	&"boss_killed",
	&"flask_used",
	&"shrine_reached",
	&"vow_chosen",
	&"session_aborted",
]

var biome: StringName = &""
var room: StringName = &""

## Zdarzenia już "zapisane" (po flush). W kroku 3 to będzie tabela w SQLite.
var _events: Array[WorldEvent] = []
## Zdarzenia czekające na następną transakcję.
var _pending: Array[WorldEvent] = []
## Klucze "npc:line_id" kwestii już wypowiedzianych.
var _lines_said: PackedStringArray = PackedStringArray()


## Gdzie jesteśmy; każde kolejne zdarzenie dostaje ten biom i pomieszczenie.
func set_location(p_biome: StringName, p_room: StringName) -> void:
	biome = p_biome
	room = p_room


func record_event(type: StringName, player: int, detail: String = "",
		killer: StringName = &"", pos: Vector2 = Vector2.ZERO) -> void:
	if not EVENT_TYPES.has(type):
		push_warning("WorldStore: nieznany typ zdarzenia '%s'" % type)
	var e: WorldEvent = WorldEvent.new()
	e.time = int(Time.get_unix_time_from_system())
	e.type = type
	e.player = player
	e.biome = biome
	e.room = room
	e.killer = killer
	e.detail = detail
	e.x = pos.x
	e.y = pos.y
	_pending.append(e)
	print("[WorldStore] %s p%d %s/%s killer=%s detail=%s (%d, %d)" % [
		type, player, biome, room, killer, detail, int(pos.x), int(pos.y)])


## Jedna "transakcja": kapliczka, zmiana pomieszczenia, wyjście z gry.
func flush() -> void:
	if _pending.is_empty():
		return
	_events.append_array(_pending)
	_pending.clear()


func count_events(type: StringName, killer: StringName = &"", p_biome: StringName = &"",
		player: int = 0) -> int:
	var total: int = 0
	for e: WorldEvent in _events:
		if _matches(e, type, killer, p_biome, player):
			total += 1
	for e: WorldEvent in _pending:
		if _matches(e, type, killer, p_biome, player):
			total += 1
	return total


func was_line_said(npc: StringName, line_id: int) -> bool:
	return _lines_said.has("%s:%d" % [npc, line_id])


func mark_line_said(npc: StringName, line_id: int) -> void:
	var key: String = "%s:%d" % [npc, line_id]
	if not _lines_said.has(key):
		_lines_said.append(key)


func _matches(e: WorldEvent, type: StringName, killer: StringName, p_biome: StringName,
		player: int) -> bool:
	if e.type != type:
		return false
	if killer != &"" and e.killer != killer:
		return false
	if p_biome != &"" and e.biome != p_biome:
		return false
	if player != 0 and e.player != player:
		return false
	return true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush()
