class_name PlayerInput
extends Node
## Czyta jedno urządzenie (klawiatura albo pad) i składa z niego [InputFrame].
##
## Każdy profil ma własny zestaw akcji w project.godot: [code]kb_*[/code]
## dla klawiatury i [code]pad_*[/code] dla pada. Dzięki temu w jednym
## procesie dwie postacie czytają dwa różne urządzenia, a w kroku 2 M0
## każda instancja po prostu dostaje inny profil (docs/technika.md:
## "Testowanie we dwóch").

enum Profile { KEYBOARD, JOYPAD }

@export var profile: Profile = Profile.KEYBOARD:
	set(value):
		profile = value
		_rebuild_actions()

var _a_left: StringName
var _a_right: StringName
var _a_up: StringName
var _a_down: StringName
var _a_jump: StringName
var _a_attack: StringName
var _a_dodge: StringName
var _a_block: StringName
var _a_interact: StringName
var _a_flask: StringName
var _a_ping: StringName


func _ready() -> void:
	_rebuild_actions()


## Składa klatkę wejścia. Wołane raz na tick fizyki przez [Player].
func poll() -> InputFrame:
	var f: InputFrame = InputFrame.new()
	f.move = Input.get_vector(_a_left, _a_right, _a_up, _a_down)
	f.jump_pressed = Input.is_action_just_pressed(_a_jump)
	f.jump_held = Input.is_action_pressed(_a_jump)
	f.attack_pressed = Input.is_action_just_pressed(_a_attack)
	f.dodge_pressed = Input.is_action_just_pressed(_a_dodge)
	f.block_held = Input.is_action_pressed(_a_block)
	f.block_pressed = Input.is_action_just_pressed(_a_block)
	f.interact_pressed = Input.is_action_just_pressed(_a_interact)
	f.flask_pressed = Input.is_action_just_pressed(_a_flask)
	f.ping_pressed = Input.is_action_just_pressed(_a_ping)
	return f


func profile_label() -> String:
	match profile:
		Profile.JOYPAD:
			return "pad"
		_:
			return "klawiatura"


func _rebuild_actions() -> void:
	var prefix: String = "pad_" if profile == Profile.JOYPAD else "kb_"
	_a_left = StringName(prefix + "move_left")
	_a_right = StringName(prefix + "move_right")
	_a_up = StringName(prefix + "move_up")
	_a_down = StringName(prefix + "move_down")
	_a_jump = StringName(prefix + "jump")
	_a_attack = StringName(prefix + "attack")
	_a_dodge = StringName(prefix + "dodge")
	_a_block = StringName(prefix + "block")
	_a_interact = StringName(prefix + "interact")
	_a_flask = StringName(prefix + "flask")
	_a_ping = StringName(prefix + "ping")
