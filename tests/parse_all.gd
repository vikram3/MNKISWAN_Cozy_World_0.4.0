extends Node
## Loads every script and scene to surface parse errors. Run: godot --headless res://tests/parse_all.tscn
func _ready() -> void:
	var bad := 0
	var files: Array = []
	_collect("res://scripts", files)
	_collect("res://scenes", files)
	for f in files:
		var r = load(f)
		if r == null:
			bad += 1
			printerr("FAILED: ", f)
		elif r is GDScript and not (r as GDScript).can_instantiate():
			bad += 1
			printerr("CANNOT INSTANTIATE: ", f)
	print("Checked %d files, %d failures" % [files.size(), bad])
	get_tree().quit(1 if bad > 0 else 0)

func _collect(dir: String, out: Array) -> void:
	var d := DirAccess.open(dir)
	for f in d.get_files():
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			out.append(dir + "/" + f)
	for sub in d.get_directories():
		_collect(dir + "/" + sub, out)
