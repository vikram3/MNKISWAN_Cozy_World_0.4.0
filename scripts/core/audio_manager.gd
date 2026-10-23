extends Node
## AudioManager: creates Music/Ambience/SFX buses and synthesises original placeholder audio at
## startup (no third-party audio, so no licence risk — GDD §14). Replace with final audio later by
## dropping streams into `sfx` / `set_music_stream()`.

const SR := 22050

var sfx: Dictionary = {}
var _players: Array = []
var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _music_stream: AudioStreamWAV
var _ambience_stream: AudioStreamWAV
var _task_id := -1
var _music_wanted := false
var _ducked := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_buses()
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new(); _music.bus = "Music"; add_child(_music)
	_ambience = AudioStreamPlayer.new(); _ambience.bus = "Ambience"; add_child(_ambience)
	_build_sfx()
	Settings.apply()
	if DisplayServer.get_name() != "headless":
		_task_id = WorkerThreadPool.add_task(_build_loops)


func _process(_delta: float) -> void:
	if _task_id >= 0 and WorkerThreadPool.is_task_completed(_task_id):
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1
		_music.stream = _music_stream
		_ambience.stream = _ambience_stream
		if _music_wanted:
			_music.play()
			_ambience.play()
	var target_db := -9.0 if _ducked else 0.0
	_ambience.volume_db = lerpf(_ambience.volume_db, target_db, 0.05)
	_music.volume_db = lerpf(_music.volume_db, target_db * 0.6, 0.05)


func _make_buses() -> void:
	for b in ["Music", "Ambience", "SFX"]:
		if AudioServer.get_bus_index(b) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, b)
			AudioServer.set_bus_send(idx, "Master")


func play_sfx(id: String, pitch: float = 1.0) -> void:
	if DisplayServer.get_name() == "headless" or not sfx.has(id):
		return
	for p in _players:
		if not p.playing:
			p.stream = sfx[id]
			p.pitch_scale = pitch
			p.play()
			return
	_players[0].stream = sfx[id]
	_players[0].play()


func start_world_audio() -> void:
	_music_wanted = true
	if _music.stream:
		if not _music.playing:
			_music.play()
		if not _ambience.playing:
			_ambience.play()


func stop_world_audio() -> void:
	_music_wanted = false
	_music.stop()
	_ambience.stop()


func _exit_tree() -> void:
	if _task_id >= 0:
		WorkerThreadPool.wait_for_task_completion(_task_id)
		_task_id = -1
	for player in _players:
		player.stop()
		player.stream = null
	_music.stop()
	_ambience.stop()
	_music.stream = null
	_ambience.stream = null
	_music_stream = null
	_ambience_stream = null
	sfx.clear()


## Duck ambience and music under dialogue (GDD §14).
func set_ducked(on: bool) -> void:
	_ducked = on


# --- Synthesis ----------------------------------------------------------------------------------

static func _note(n: int) -> float:
	return 440.0 * pow(2.0, float(n - 69) / 12.0)


func _build_sfx() -> void:
	# [midi_note, start_s, dur_s, vol, wave(0 sine,1 tri,2 noise)]
	sfx["pickup"] = _render([[79, 0.0, 0.12, 0.5, 1], [86, 0.07, 0.18, 0.45, 1]], 0.3)
	sfx["gather"] = _render([[72, 0.0, 0.1, 0.35, 2], [84, 0.05, 0.16, 0.45, 1], [88, 0.12, 0.2, 0.35, 0]], 0.36)
	sfx["coin"] = _render([[88, 0.0, 0.12, 0.45, 0], [93, 0.08, 0.3, 0.45, 0]], 0.42)
	sfx["sale"] = _render([[84, 0.0, 0.1, 0.4, 0], [88, 0.08, 0.1, 0.4, 0], [91, 0.16, 0.1, 0.4, 0], [96, 0.24, 0.4, 0.45, 0]], 0.7)
	sfx["bite"] = _render([[60, 0.0, 0.08, 0.6, 2], [81, 0.02, 0.22, 0.6, 1], [81, 0.26, 0.22, 0.5, 1]], 0.5)
	sfx["splash"] = _render([[55, 0.0, 0.35, 0.5, 2]], 0.4)
	sfx["catch"] = _render([[72, 0.0, 0.1, 0.4, 1], [76, 0.08, 0.1, 0.4, 1], [79, 0.16, 0.1, 0.4, 1], [84, 0.24, 0.35, 0.45, 1]], 0.65)
	sfx["miss"] = _render([[67, 0.0, 0.15, 0.35, 1], [62, 0.12, 0.3, 0.3, 1]], 0.45)
	sfx["quest_start"] = _render([[76, 0.0, 0.14, 0.35, 0], [83, 0.1, 0.3, 0.35, 0]], 0.45)
	sfx["quest_step"] = _render([[79, 0.0, 0.12, 0.3, 0], [84, 0.08, 0.25, 0.3, 0]], 0.36)
	sfx["quest_complete"] = _render([[72, 0.0, 0.5, 0.25, 1], [76, 0.08, 0.5, 0.25, 1], [79, 0.16, 0.5, 0.25, 1], [84, 0.24, 0.7, 0.3, 1], [88, 0.34, 0.6, 0.25, 0]], 1.0)
	sfx["save"] = _render([[81, 0.0, 0.18, 0.25, 0], [88, 0.12, 0.35, 0.25, 0]], 0.5)
	sfx["ui"] = _render([[84, 0.0, 0.05, 0.25, 1]], 0.08)
	sfx["ui_back"] = _render([[77, 0.0, 0.06, 0.22, 1]], 0.09)
	sfx["pet"] = _render([[64, 0.0, 0.12, 0.3, 1], [67, 0.1, 0.16, 0.28, 1]], 0.3)
	sfx["cluck"] = _render([[74, 0.0, 0.05, 0.35, 1], [70, 0.06, 0.08, 0.3, 1], [77, 0.15, 0.06, 0.3, 1]], 0.25)
	sfx["moo"] = _render([[45, 0.0, 0.6, 0.45, 1], [43, 0.3, 0.4, 0.35, 1]], 0.75)
	sfx["baa"] = _render([[64, 0.0, 0.35, 0.35, 1], [63, 0.05, 0.3, 0.2, 2]], 0.4)
	sfx["water"] = _render([[50, 0.0, 0.45, 0.35, 2], [86, 0.05, 0.05, 0.15, 0], [90, 0.15, 0.05, 0.15, 0]], 0.5)
	sfx["plant"] = _render([[52, 0.0, 0.12, 0.4, 2], [67, 0.05, 0.15, 0.3, 1]], 0.25)
	sfx["harvest"] = _render([[74, 0.0, 0.1, 0.4, 1], [79, 0.06, 0.1, 0.4, 1], [86, 0.12, 0.25, 0.4, 0]], 0.4)
	sfx["door"] = _render([[48, 0.0, 0.25, 0.4, 2], [55, 0.05, 0.2, 0.25, 1]], 0.32)
	sfx["chime"] = _render([[88, 0.0, 0.8, 0.25, 0], [95, 0.12, 0.8, 0.2, 0], [91, 0.25, 0.9, 0.2, 0]], 1.2)
	sfx["sleep"] = _render([[72, 0.0, 0.6, 0.25, 0], [67, 0.3, 0.6, 0.25, 0], [64, 0.6, 0.8, 0.25, 0], [60, 0.9, 1.0, 0.25, 0]], 2.0)
	sfx["upgrade"] = _render([[67, 0.0, 0.2, 0.3, 1], [72, 0.12, 0.2, 0.3, 1], [76, 0.24, 0.2, 0.3, 1], [79, 0.36, 0.3, 0.3, 1], [84, 0.5, 0.7, 0.35, 0]], 1.2)
	sfx["error"] = _render([[58, 0.0, 0.12, 0.3, 1], [55, 0.1, 0.16, 0.3, 1]], 0.28)
	sfx["step"] = _render([[40, 0.0, 0.05, 0.12, 2]], 0.06)


func _render(notes: Array, length: float) -> AudioStreamWAV:
	var n := int(length * SR)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for note in notes:
		var f := _note(int(note[0]))
		var start := int(float(note[1]) * SR)
		var dur := int(float(note[2]) * SR)
		var vol := float(note[3])
		var wave := int(note[4])
		var lp := 0.0
		for i in dur:
			var idx := start + i
			if idx >= n:
				break
			var t := float(i) / SR
			var env: float = min(1.0, t * 200.0) * exp(-t * 4.0 / max(float(note[2]), 0.05))
			var s := 0.0
			match wave:
				0:
					s = sin(TAU * f * t) * 0.8 + sin(TAU * f * 2.0 * t) * 0.15
				1:
					var ph := fmod(f * t, 1.0)
					s = (4.0 * absf(ph - 0.5) - 1.0)
				_:
					lp = lp + (rng.randf_range(-1.0, 1.0) - lp) * 0.25
					s = lp * 1.6
			buf[idx] += s * vol * env
	return _to_wav(buf, false)


func _to_wav(buf: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = SR
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
	return w


## Gentle plucked-string theme + forest ambience, rendered on a worker thread.
func _build_loops() -> void:
	var bpm := 84.0
	var beat := 60.0 / bpm
	var bars := 8
	var length := beat * 4.0 * bars
	var n := int(length * SR)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var chords := [[60, 64, 67], [57, 60, 64], [65, 69, 72], [67, 71, 74], [60, 64, 67], [65, 69, 72], [62, 65, 69], [67, 71, 74]]
	var scale := [60, 62, 64, 67, 69, 72, 74, 76, 79]
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var melody_idx := 4
	for bar in bars:
		var chord: Array = chords[bar]
		# Soft bass + arpeggio
		_pluck(buf, _note(int(chord[0]) - 24), bar * 4 * beat, beat * 3.5, 0.22)
		for b in 4:
			_pluck(buf, _note(int(chord[b % 3]) - 12), (bar * 4 + b) * beat + beat * 0.5, beat * 1.2, 0.1)
		# Melody: gentle stepwise pentatonic walk
		for step in 8:
			if rng.randf() < 0.3:
				continue
			melody_idx = clampi(melody_idx + rng.randi_range(-2, 2), 0, scale.size() - 1)
			var t0 := (bar * 4.0 + step * 0.5) * beat
			_pluck(buf, _note(int(scale[melody_idx])), t0, beat * 1.6, 0.14)
	_music_stream = _to_wav(buf, true)

	# Ambience: breeze (filtered noise swell) + occasional bird chirps.
	var alen := 16.0
	var an := int(alen * SR)
	var abuf := PackedFloat32Array()
	abuf.resize(an)
	var lp := 0.0
	var lp2 := 0.0
	for i in an:
		var t := float(i) / SR
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.02
		lp2 += (lp - lp2) * 0.05
		var swell := 0.55 + 0.45 * sin(TAU * t / alen * 2.0)
		abuf[i] = lp2 * 2.2 * swell
	for c in 7:
		var t0 := rng.randf_range(0.5, alen - 1.0)
		var base := rng.randf_range(2600.0, 4200.0)
		for k in rng.randi_range(2, 4):
			var st := int((t0 + k * 0.13) * SR)
			var dur := int(0.09 * SR)
			for i in dur:
				if st + i >= an:
					break
				var tt := float(i) / SR
				var f := base + 1800.0 * tt / 0.09
				abuf[st + i] += sin(TAU * f * tt) * 0.07 * sin(PI * float(i) / dur)
	_ambience_stream = _to_wav(abuf, true)


func _pluck(buf: PackedFloat32Array, f: float, t0: float, dur: float, vol: float) -> void:
	var st := int(t0 * SR)
	var cnt := int(dur * SR)
	var n := buf.size()
	for i in cnt:
		var idx := (st + i) % n   # wrap so the loop seam stays smooth
		var t := float(i) / SR
		var env := minf(1.0, t * 300.0) * exp(-t * 3.2)
		buf[idx] += (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t) + 0.1 * sin(TAU * f * 3.0 * t)) * vol * env
