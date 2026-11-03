extends SceneTree
## Sprawdzenie projektu bez otwierania edytora:
##   godot --headless --path . --script res://tools/check_project.gd
##
## Ładuje każdy skrypt, scenę i zasób; kod wyjścia 1 przy pierwszym błędzie.
## Ostrzeżenia o brakujących typach są w project.godot ustawione na błąd,
## więc skrypt bez typów tu nie przejdzie.

const SKIP_DIRS: Array[String] = [".godot", ".git", "addons", "build", "export"]
const CHECKED_EXTENSIONS: Array[String] = ["gd", "tscn", "tres"]


func _initialize() -> void:
	var paths: PackedStringArray = PackedStringArray()
	_collect("res://", paths)
	var failures: int = 0
	var checked: int = 0
	for path: String in paths:
		if not CHECKED_EXTENSIONS.has(path.get_extension()):
			continue
		checked += 1
		var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if res == null:
			failures += 1
			printerr("BŁĄD: nie wczytano %s" % path)
			continue
		var script: GDScript = res as GDScript
		if script != null and not script.can_instantiate():
			failures += 1
			printerr("BŁĄD: skrypt nie kompiluje się: %s" % path)
			continue
		var packed: PackedScene = res as PackedScene
		if packed != null and not packed.can_instantiate():
			failures += 1
			printerr("BŁĄD: scena nie daje się utworzyć: %s" % path)
	print("Sprawdzono %d plików, błędów: %d" % [checked, failures])
	quit(1 if failures > 0 else 0)


func _collect(dir_path: String, out: PackedStringArray) -> void:
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not SKIP_DIRS.has(entry):
				_collect(dir_path.path_join(entry), out)
		else:
			out.append(dir_path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
