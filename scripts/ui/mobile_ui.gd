class_name MobileUI
extends RefCounted
## Shared helpers for phones and touchscreens: when to show touch controls, notch-safe insets,
## physical-size scaling, haptics and touch-friendly wording. Everything is static so HUD,
## touch layer, tutorial and minimap agree on one layout.

## A real finger touched the screen this session (lets touch laptops switch on automatically).
static var touch_seen := false
## Tests and the phone gallery can simulate a phone without exporting to one.
static var force_mobile := false
## Optional simulated notch/rounded-corner insets in canvas units: (left, top, right, bottom).
static var debug_safe_insets = null

const BASE_PX_PER_MM := 15.9  # 1080 canvas px across a typical 68 mm landscape phone height


static func is_mobile() -> bool:
	return force_mobile or OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")


static func touch_enabled() -> bool:
	match String(Settings.get_value("touch_controls")):
		"on":
			return true
		"off":
			return false
	return is_mobile() or touch_seen


## Called by the touch layer for every input event so "auto" follows what the player uses.
static func note_event(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch and ev.pressed:
		touch_seen = true
	elif ev is InputEventKey and ev.pressed and not is_mobile():
		touch_seen = false


## Notch / rounded-corner / gesture-bar insets in canvas units: Vector4(left, top, right, bottom).
static func safe_insets(vp: Viewport) -> Vector4:
	if debug_safe_insets != null:
		return debug_safe_insets
	if not OS.has_feature("mobile") or vp == null:
		return Vector4.ZERO
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := DisplayServer.get_display_safe_area()
	if screen.x <= 0 or safe.size.x <= 0:
		return Vector4.ZERO
	var ratio := vp.get_visible_rect().size.x / maxf(float(vp.get_window().size.x), 1.0)
	return Vector4(safe.position.x, safe.position.y, screen.x - safe.end.x, screen.y - safe.end.y) * ratio


## Touch-control scale: the player's size slider times a physical-size fit, so buttons stay
## roughly thumb-sized on small phones, big phones and tablets alike.
static func control_scale(vp: Viewport) -> float:
	return float(Settings.get_value("touch_scale")) * physical_fit(vp)


static func physical_fit(vp: Viewport) -> float:
	if not OS.has_feature("mobile") or vp == null:
		return 1.0
	var dpi := float(DisplayServer.screen_get_dpi())
	var win_h := float(vp.get_window().size.y)
	if dpi <= 0.0 or win_h <= 0.0:
		return 1.0
	var mm_h := win_h / dpi * 25.4
	var px_per_mm := vp.get_visible_rect().size.y / maxf(mm_h, 1.0)
	return clampf(px_per_mm / BASE_PX_PER_MM, 0.72, 1.25)


## HUD readability boost on small handheld screens.
static func hud_scale() -> float:
	return 1.15 if touch_enabled() else 1.0


static func vibrate(ms: int = 12) -> void:
	if is_mobile() and bool(Settings.get_value("haptics")) and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


## Key-centric hints read naturally on a phone.
static func adapt_text(s: String) -> String:
	if not touch_enabled():
		return s
	for pair in [["press E again", "tap the action button again"], ["Press E", "Tap the action button"], ["press E", "tap the action button"],
			["E / Space / Click to continue", "Tap to continue"]]:
		s = s.replace(String(pair[0]), String(pair[1]))
	return s
