class_name Guslarz
extends Node2D
## Guślarz: przewodnik, który nie rozmawia, tylko wypowiada jedną kwestię
## na wizytę (docs/npc-guslarz.md). Priorytet, nie losowość: warunki
## sprawdzane od góry, pierwszy spełniony wygrywa, a każda kwestia
## warunkowa pada raz.
##
## Krok 1 M0: kwestia pierwszej wizyty i domyślna. Kwestie 1 do 5 wymagają
## zapytań do bazy z kroku 3 (WorldStore.count_events).

const NPC_ID: StringName = &"guslarz"
const LINE_FIRST_VISIT: int = 0
const LINE_DEFAULT: int = -1

@export var speech_seconds: float = 7.0
## Zwłoka po wejściu do Osady, żeby oboje zdążyli się pojawić.
@export var delay_seconds: float = 0.8

@onready var _speech: Label = $Speech as Label


func _ready() -> void:
	_speech.visible = false
	await get_tree().create_timer(delay_seconds).timeout
	if is_inside_tree():
		speak()


func speak() -> void:
	var line_id: int = pick_line()
	_speech.text = line_text(line_id)
	_speech.visible = true
	if line_id >= 0:
		WorldStore.mark_line_said(NPC_ID, line_id)
	print("[Guślarz] kwestia %d" % line_id)
	var tween: Tween = create_tween()
	tween.tween_interval(speech_seconds)
	tween.tween_callback(_hide_speech)


func pick_line() -> int:
	if not WorldStore.was_line_said(NPC_ID, LINE_FIRST_VISIT):
		return LINE_FIRST_VISIT
	# Kwestie warunkowe 1 do 5 (boss, Leszy, różnica śmierci, 3 śmierci,
	# kapliczka 2 bez flaszki) dochodzą z danymi z kroku 3 M0.
	return LINE_DEFAULT


static func line_text(line_id: int) -> String:
	match line_id:
		LINE_FIRST_VISIT:
			return "Dwoje wchodzi – dwoje piszę.\nBór ma oczy. Bór ma ciszę.\nNie miecz go budzi, nie tarcza –\nkrok między wami mu starcza."
		_:
			return "Karta pełna, pióro schnie.\nIdźcie w dół. Bór już wie."


func _hide_speech() -> void:
	_speech.visible = false
