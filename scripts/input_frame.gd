class_name InputFrame
extends RefCounted
## Jedna klatka wejścia gracza.
##
## Lokalnie składa ją [PlayerInput] z urządzenia (klawiatura albo pad).
## W kroku 2 M0 klient wyśle tę samą strukturę do hosta jako RPC,
## a host podstawi ją swojej kopii postaci gościa. Postać nigdy nie
## odpytuje [Input] bezpośrednio.

var move: Vector2 = Vector2.ZERO
var jump_pressed: bool = false
var jump_held: bool = false
var attack_pressed: bool = false
var dodge_pressed: bool = false
var block_held: bool = false
var interact_pressed: bool = false
var flask_pressed: bool = false
var ping_pressed: bool = false


## Zwięzła postać do wysłania przez sieć (krok 2 M0).
func to_packed() -> PackedFloat32Array:
	var bits: int = 0
	bits |= 1 if jump_pressed else 0
	bits |= 2 if jump_held else 0
	bits |= 4 if attack_pressed else 0
	bits |= 8 if dodge_pressed else 0
	bits |= 16 if block_held else 0
	bits |= 32 if interact_pressed else 0
	bits |= 64 if flask_pressed else 0
	bits |= 128 if ping_pressed else 0
	return PackedFloat32Array([move.x, move.y, float(bits)])


static func from_packed(data: PackedFloat32Array) -> InputFrame:
	var f: InputFrame = InputFrame.new()
	if data.size() < 3:
		return f
	f.move = Vector2(data[0], data[1])
	var bits: int = int(data[2])
	f.jump_pressed = (bits & 1) != 0
	f.jump_held = (bits & 2) != 0
	f.attack_pressed = (bits & 4) != 0
	f.dodge_pressed = (bits & 8) != 0
	f.block_held = (bits & 16) != 0
	f.interact_pressed = (bits & 32) != 0
	f.flask_pressed = (bits & 64) != 0
	f.ping_pressed = (bits & 128) != 0
	return f
