extends RefCounted
# Wygląd interfejsu minigier (walka, sekwencja klawiszy): ostre ramki, ciemne, przybrudzone
# kolory i czcionka bez wygładzania.

const TEXT := Color(0.86, 0.82, 0.68)
const DIM := Color(0.46, 0.44, 0.38)
const ACCENT := Color(0.93, 0.62, 0.22)
const DANGER := Color(0.92, 0.28, 0.2)
const BACK := Color(0.035, 0.04, 0.03, 0.92)
const BORDER := Color(0.3, 0.3, 0.2)
const EMPTY := Color(0.12, 0.12, 0.1)
const GOOD := Color(0.35, 0.56, 0.22)
const WARN := Color(0.78, 0.58, 0.14)
const BAD := Color(0.68, 0.16, 0.12)
const OUTLINE := Color(0.01, 0.01, 0.01)
const SEGMENT := 14.0 # szerokość kratki na pasku zdrowia

static var _theme: Theme

static func theme() -> Theme:
	if not _theme:
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["DejaVu Sans Mono", "Consolas", "Courier New", "monospace"])
		font.font_weight = 700
		font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		font.hinting = TextServer.HINTING_NORMAL
		font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		_theme = Theme.new()
		_theme.default_font = font
		_theme.set_color("font_color", "Label", TEXT)
		_theme.set_color("font_outline_color", "Label", OUTLINE)
		_theme.set_constant("outline_size", "Label", 4)
	return _theme

static func label(size: int, text := "") -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	return node

# Kanciasta ramka bez zaokrągleń.
static func frame(background := BACK, border := BORDER, margin := 10.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(4)
	style.set_content_margin_all(margin)
	style.anti_aliasing = false
	return style

# Pasek z kratek: wypełnienie i na wierzchu ciemne przerwy.
static func bar(parent: Node, node: ProgressBar) -> void:
	var fill := StyleBoxFlat.new()
	fill.anti_aliasing = false
	var empty := StyleBoxFlat.new()
	empty.bg_color = EMPTY
	empty.anti_aliasing = false
	node.add_theme_stylebox_override("fill", fill)
	node.add_theme_stylebox_override("background", empty)
	node.show_percentage = false
	node.custom_minimum_size = Vector2(260, 16)
	node.draw.connect(func():
		var x := SEGMENT
		while x < node.size.x:
			node.draw_rect(Rect2(x - 1.0, 0, 3, node.size.y), OUTLINE)
			x += SEGMENT)
	parent.add_child(node)

static func button(text: String) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_size_override("font_size", 17)
	node.add_theme_color_override("font_color", TEXT)
	node.add_theme_color_override("font_hover_color", ACCENT)
	node.add_theme_color_override("font_pressed_color", ACCENT)
	node.add_theme_color_override("font_disabled_color", DIM)
	node.add_theme_stylebox_override("normal", frame(Color(0.09, 0.09, 0.065), BORDER, 4.0))
	node.add_theme_stylebox_override("hover", frame(Color(0.15, 0.11, 0.05), ACCENT, 4.0))
	node.add_theme_stylebox_override("pressed", frame(Color(0.22, 0.14, 0.05), ACCENT, 4.0))
	node.add_theme_stylebox_override("disabled", frame(Color(0.05, 0.05, 0.045), Color(0.14, 0.14, 0.11), 4.0))
	return node
