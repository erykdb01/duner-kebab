@tool
extends Node3D
# Detale wnętrza: brud, grzyb, ścierki, wyposażenie blatu, ekrany z menu, okna i drobiazgi.
# Węzły z grupy "powered" gasną podczas awarii prądu.

const B = preload("res://Scripts/build.gd")
const Night = preload("res://Scripts/night.gd")
const COUNTER_Y := 1.095
const FLOOR := 0.053

var _spit: Node3D
var _tube: Node3D
var _time := 0.0

func _ready() -> void:
	_dirt()
	_counter()
	_screens()
	_kitchen()
	_hall()
	_windows()

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or Night.dark:
		return
	_time += delta
	_spit.rotate_y(delta * 0.8)
	# Zmęczona świetlówka w kuchni co jakiś czas mruga.
	_tube.visible = fmod(_time, 7.0) > 0.35 or fmod(_time, 0.12) > 0.06

func _powered(node: Node) -> void:
	node.add_to_group("powered")

func _dirt() -> void:
	# podłoga
	for spot in [
			["brud", -3.3, -3.7, 1.1], ["brud", -2.7, 0.2, 0.8], ["tluszcz", -2.5, 0.8, 0.9],
			["tluszcz", -3.2, 2.7, 0.7], ["sos_plama", -2.6, -1.5, 0.45], ["brud", -3.5, 4.4, 1.2],
			["brud", 0.0, -4.2, 1.3], ["brud", 0.5, -2.9, 0.8], ["sos_plama", 0.1, 2.1, 0.5],
			["brud", 3.4, 3.9, 1.2], ["kaluza", 3.0, 4.2, 0.9], ["tluszcz", 2.4, -1.0, 0.7],
			["brud", 3.5, -4.4, 1.0], ["sos_plama", 1.7, 1.9, 0.35]]:
		B.on_floor(self, spot[0], Vector3(spot[1], FLOOR + randf() * 0.002, spot[2]), spot[3],
			spot[1] * 97.0)
	for litter in [Vector2(3.6, -4.5), Vector2(3.5, 0.9), Vector2(-0.5, 4.6), Vector2(-3.6, 1.2)]:
		B.on_floor(self, "smieci", Vector3(litter.x, FLOOR + 0.004, litter.y), 0.5, litter.y * 53.0)
	# grzyb w rogach i zacieki na ścianach
	B.on_wall(self, "grzyb", Vector3(-3.94, 3.35, 4.35), Vector2(1.4, 1.2), 90)
	B.on_wall(self, "grzyb", Vector3(-3.4, 3.4, 4.94), Vector2(1.2, 1.0), 180)
	B.on_wall(self, "grzyb", Vector3(3.3, 3.25, 4.94), Vector2(1.5, 1.3), 180)
	B.on_wall(self, "grzyb", Vector3(-3.94, 0.45, -4.2), Vector2(1.0, 0.8), 90)
	B.on_wall(self, "grzyb", Vector3(3.4, 3.5, -4.94), Vector2(0.9, 0.7), 0)
	B.on_wall(self, "tluszcz", Vector3(-3.94, 1.5, 0.3), Vector2(1.2, 1.1), 90)
	B.on_wall(self, "brud", Vector3(-3.94, 0.4, 2.0), Vector2(1.6, 0.8), 90)
	B.on_wall(self, "brud", Vector3(-1.8, 0.35, -4.94), Vector2(1.4, 0.7), 0)
	B.on_wall(self, "sos_plama", Vector3(3.94, 0.7, 1.7), Vector2(0.5, 0.5), -90)
	B.on_wall(self, "brud", Vector3(1.9, 0.4, 4.94), Vector2(1.2, 0.8), 180)
	B.on_wall(self, "pajeczyna", Vector3(-3.55, 3.52, -4.93), Vector2(0.7, 0.7), 0)
	var web := B.on_wall(self, "pajeczyna", Vector3(3.93, 3.52, 4.55), Vector2(0.7, 0.7), -90)
	web.scale.x = -1

func _counter() -> void:
	var metal := B.mat("metal_ciemny")
	var red := B.mat("metal_czerwony", Color.WHITE, 2.0)
	var cream := B.mat("plastik_kremowy", Color.WHITE, 2.0)
	# dzwonek
	B.cyl(self, Vector3(-1.05, COUNTER_Y + 0.012, 0.75), 0.06, 0.024, metal)
	B.ball(self, Vector3(-1.05, COUNTER_Y + 0.04, 0.75), Vector3(0.1, 0.07, 0.1), B.mat("metal_zolty", Color.WHITE, 4.0))
	# słoik na napiwki
	B.cyl(self, Vector3(-1.08, COUNTER_Y + 0.08, 1.55), 0.065, 0.16, B.glow(Color(0.6, 0.8, 0.85, 0.28)))
	B.cyl(self, Vector3(-1.08, COUNTER_Y + 0.025, 1.55), 0.052, 0.045, B.mat("metal_zolty", Color.WHITE, 6.0))
	B.label(self, Vector3(-1.005, COUNTER_Y + 0.09, 1.55), "NAPIWKI", 28, Color(1, 0.95, 0.7), 90, 0.0012)
	# kasa fiskalna
	var register := B.group(self, Vector3(-1.38, COUNTER_Y, 2.15))
	B.box(register, Vector3(0, 0.07, 0), Vector3(0.38, 0.14, 0.42), metal)
	B.box(register, Vector3(-0.1, 0.18, 0), Vector3(0.14, 0.1, 0.36), cream, Vector3(0, 0, -15))
	B.box(register, Vector3(0.19, 0.04, 0), Vector3(0.02, 0.06, 0.36), cream)
	for row in 3:
		for column in 4:
			B.box(register, Vector3(0.0 + row * 0.055, 0.148, -0.12 + column * 0.075),
				Vector3(0.035, 0.016, 0.045), cream if (row + column) % 3 else red)
	_powered(B.label(register, Vector3(-0.185, 0.2, 0), "20.00", 40, Color(0.4, 1, 0.5), -90, 0.0016))
	_powered(B.label(register, Vector3(-0.02, 0.215, 0), "20.00", 40, Color(0.4, 1, 0.5), 90, 0.0014))
	# serwetnik
	B.box(self, Vector3(-1.1, COUNTER_Y + 0.07, 2.65), Vector3(0.09, 0.14, 0.18), metal)
	B.box(self, Vector3(-1.1, COUNTER_Y + 0.16, 2.65), Vector3(0.05, 0.05, 0.14), B.mat("", Color(0.85, 0.83, 0.78)))
	# piramida puszek
	var colors := [Color(1, 0.35, 0.3), Color(0.4, 0.55, 1), Color(0.5, 0.9, 0.45)]
	for level in 3:
		for i in 3 - level:
			var at := Vector3(-1.55, COUNTER_Y + 0.065 + level * 0.13, 2.85 + i * 0.1 + level * 0.05)
			B.cyl(self, at, 0.045, 0.125, B.mat("metal_ciemny", colors[(i + level) % 3] * 1.8, 5.0))
	# butelki i pudełka na wynos
	for i in 3:
		var at := Vector3(-1.62, COUNTER_Y + 0.12, 1.2 + i * 0.13)
		var drink := B.mat("", [Color(0.35, 0.14, 0.05), Color(0.85, 0.5, 0.1), Color(0.2, 0.45, 0.2)][i])
		B.cyl(self, at, 0.045, 0.24, drink)
		B.cyl(self, at + Vector3(0, 0.16, 0), 0.018, 0.09, drink)
		B.cyl(self, at + Vector3(0, 0.215, 0), 0.022, 0.025, red)
	for i in 4:
		B.box(self, Vector3(-1.62, COUNTER_Y + 0.03 + i * 0.055, 4.4), Vector3(0.3, 0.05, 0.24),
			B.mat("karton", Color.WHITE, 3.0), Vector3(0, i * 11 - 15, 0))
	_doner(Vector3(-1.55, COUNTER_Y, 3.7))
	# ścierki i plamy na blacie
	var cloth := B.mat("scierka", Color.WHITE, 3.0)
	B.box(self, Vector3(-1.12, COUNTER_Y + 0.008, 0.45), Vector3(0.24, 0.014, 0.3), cloth, Vector3(0, 24, 0))
	B.box(self, Vector3(-1.1, COUNTER_Y + 0.022, 0.48), Vector3(0.16, 0.016, 0.2), cloth, Vector3(0, -12, 3))
	B.box(self, Vector3(-0.862, 0.93, 3.25), Vector3(0.012, 0.34, 0.24), cloth, Vector3(4, 0, 0))
	B.on_floor(self, "sos_plama", Vector3(-1.15, COUNTER_Y + 0.003, -0.55), 0.22, 30)
	B.on_floor(self, "tluszcz", Vector3(-1.45, COUNTER_Y + 0.003, 3.35), 0.4, 80)

# Rożen z kebabem: obraca się, grzałka świeci.
func _doner(at: Vector3) -> void:
	var metal := B.mat("metal_ciemny", Color(1.4, 1.4, 1.5), 3.0)
	B.cyl(self, at + Vector3(0, 0.025, 0), 0.24, 0.05, metal, Vector3.ZERO, -1.0, 10)
	B.cyl(self, at + Vector3(0, 0.42, 0), 0.012, 0.84, metal)
	_spit = B.group(self, at)
	var meat := B.mat("doner", Color.WHITE, 3.0)
	var radii := [0.09, 0.13, 0.16, 0.18, 0.12]
	for i in 4:
		B.cyl(_spit, Vector3(0, 0.15 + i * 0.13, 0), radii[i], 0.13, meat, Vector3(0, i * 17, 0),
			radii[i + 1])
	B.ball(_spit, Vector3(0.03, 0.69, 0), Vector3(0.1, 0.08, 0.1), B.mat("surowka", Color(1, 0.5, 0.4), 6.0))
	B.box(self, at + Vector3(-0.25, 0.38, 0), Vector3(0.05, 0.66, 0.46), metal)
	for i in 6:
		_powered(B.box(self, at + Vector3(-0.22, 0.14 + i * 0.1, 0), Vector3(0.012, 0.025, 0.4),
			B.glow(Color(1, 0.35, 0.08))))
	_powered(B.light(self, at + Vector3(-0.1, 0.4, 0), Color(1, 0.45, 0.15), 0.5, 1.4))

# Podświetlane ekrany z menu pod sufitem.
func _screens() -> void:
	var menus := [
		"KEBAB ......... 20 zł\nPodwójne mięso . +5 zł\nSurówka ........ gratis\nSos ............ gratis\nTortilla x2 .... gratis",
		"PROMOCJA NOCNA\nMięso 100% mięsne\nZ wkładką?\nZapytaj szeptem.\nReklamacji brak"]
	var places := [-1.15, 3.15]
	for i in 2:
		var screen := B.group(self, Vector3(-1.35, 2.78, places[i]))
		B.box(screen, Vector3.ZERO, Vector3(0.07, 0.74, 1.32), B.mat("metal_ciemny", Color(0.6, 0.6, 0.65), 2.0))
		for z in [-0.5, 0.5]:
			B.cyl(screen, Vector3(0, 0.75, z), 0.012, 0.76, B.mat("metal_ciemny"))
		for side in [1, -1]:
			_powered(B.quad(screen, Vector3(0.037 * side, 0, 0), Vector2(1.24, 0.66),
				B.picture("ekran", Color.WHITE, true), Vector3(0, 90 * side, 0)))
			_powered(B.label(screen, Vector3(0.042 * side, 0, 0), menus[i], 36,
				Color(1, 0.85, 0.45), 90 * side, 0.0023))

func _kitchen() -> void:
	var metal := B.mat("metal_ciemny", Color(1.5, 1.5, 1.6), 2.0)
	var wood := B.mat("deski", Color.WHITE, 1.5)
	# półki z zapasami
	for level in 2:
		var y := 1.55 + level * 0.5
		B.box(self, Vector3(-3.78, y, 3.75), Vector3(0.32, 0.04, 1.3), wood)
		for i in 5:
			var z := 3.25 + i * 0.25
			var jar := B.mat(["surowka", "sos", "metal_zolty", "karton", "metal_niebieski"][(i + level * 2) % 5], Color.WHITE, 5.0)
			B.cyl(self, Vector3(-3.78, y + 0.12, z), 0.075, 0.2, jar)
			B.cyl(self, Vector3(-3.78, y + 0.23, z), 0.05, 0.025, metal)
	# listwa z narzędziami
	B.box(self, Vector3(-3.91, 1.95, -0.7), Vector3(0.03, 0.03, 1.1), metal)
	for i in 4:
		var z := -1.1 + i * 0.27
		B.box(self, Vector3(-3.9, 1.78, z), Vector3(0.015, 0.3, 0.025), metal)
		if i % 2:
			B.box(self, Vector3(-3.9, 1.57, z), Vector3(0.012, 0.16, 0.1), metal)
		else:
			B.cyl(self, Vector3(-3.89, 1.6, z), 0.065, 0.02, metal, Vector3(0, 0, 90))
	# rura z zaciekiem
	B.cyl(self, Vector3(-3.86, 3.2, 0), 0.06, 9.9, B.mat("metal_brazowy"), Vector3(90, 0, 0))
	B.cyl(self, Vector3(-3.86, 1.6, -3.5), 0.045, 3.2, B.mat("metal_brazowy"))
	B.on_floor(self, "kaluza", Vector3(-3.65, FLOOR + 0.005, -3.4), 0.55)
	# wiadro i mop w kącie
	B.cyl(self, Vector3(-3.6, 0.2, 4.6), 0.16, 0.3, B.mat("metal_niebieski", Color.WHITE, 3.0), Vector3.ZERO, 0.2)
	B.cyl(self, Vector3(-3.6, 0.34, 4.6), 0.17, 0.02, B.mat("", Color(0.18, 0.16, 0.1)))
	B.cyl(self, Vector3(-3.76, 0.8, 4.72), 0.018, 1.45, wood, Vector3(-9, 0, 9))
	B.box(self, Vector3(-3.64, 0.1, 4.55), Vector3(0.2, 0.08, 0.14), B.mat("scierka", Color(0.7, 0.7, 0.6), 3.0))
	B.box(self, Vector3(-2.7, 0.062, -4.55), Vector3(0.42, 0.015, 0.34), B.mat("scierka", Color(0.65, 0.6, 0.5), 3.0), Vector3(0, 38, 0))
	# kartki na ścianie
	B.box(self, Vector3(-3.935, 1.95, 0.75), Vector3(0.01, 0.36, 0.5), B.mat("", Color(0.82, 0.8, 0.7)))
	B.label(self, Vector3(-3.925, 1.95, 0.75), "UMYJ RĘCE\n(czasem)", 36, Color(0.15, 0.1, 0.2), 90, 0.0017)
	B.label(self, Vector3(-3.925, 2.35, -2.6), "BEZPIECZNIKI", 32, Color(1, 0.85, 0.3), 90, 0.0017)
	# świetlówka
	B.box(self, Vector3(-3.0, 3.84, -0.5), Vector3(0.22, 0.05, 1.5), metal)
	_tube = B.group(self, Vector3(-3.0, 3.8, -0.5))
	_powered(B.box(_tube, Vector3.ZERO, Vector3(0.08, 0.04, 1.35), B.glow(Color(0.75, 1, 0.85))))

func _hall() -> void:
	var metal := B.mat("metal_ciemny", Color(1.3, 1.3, 1.4), 2.0)
	var wood := B.mat("deski", Color(0.8, 0.7, 0.6), 2.0)
	# futryna drzwi wejściowych
	for side in [-1.15, 1.15]:
		B.box(self, Vector3(side, 1.05, -4.93), Vector3(0.09, 2.1, 0.08), wood)
	B.box(self, Vector3(0, 2.1, -4.93), Vector3(2.4, 0.1, 0.08), wood)
	# neon
	_powered(B.label(self, Vector3(2.55, 2.75, 4.92), "KEBAB 24H", 96, Color(1, 0.3, 0.65), 180, 0.003))
	_powered(B.label(self, Vector3(2.55, 2.42, 4.92), "prawie zawsze świeży", 40, Color(0.35, 0.9, 1), 180))
	_powered(B.light(self, Vector3(2.5, 2.6, 4.5), Color(1, 0.25, 0.6), 0.7, 3.0))
	# tabliczki i gaśnica
	B.box(self, Vector3(-2.3, 1.9, -4.935), Vector3(0.75, 0.34, 0.01), B.mat("", Color(0.82, 0.8, 0.7)))
	B.label(self, Vector3(-2.3, 1.9, -4.925), "NIE KARMIĆ\nSZCZURÓW", 36, Color(0.6, 0.05, 0.03), 0, 0.0018)
	B.cyl(self, Vector3(1.5, 0.95, 4.84), 0.09, 0.45, B.mat("metal_czerwony", Color.WHITE, 3.0))
	B.cyl(self, Vector3(1.5, 1.22, 4.84), 0.03, 0.1, metal)
	# tabliczka "mokra podłoga"
	var sign_group := B.group(self, Vector3(2.95, 0.05, 4.05), 200)
	for side in [-1, 1]:
		B.box(sign_group, Vector3(0, 0.27, 0.09 * side), Vector3(0.34, 0.56, 0.015),
			B.mat("metal_zolty", Color(1.2, 1.2, 1.0), 3.0), Vector3(-18 * side, 0, 0))
	B.label(sign_group, Vector3(0, 0.3, 0.115), "UWAGA\nŚLISKO", 36, Color(0.1, 0.07, 0.03), 0, 0.0018).rotation_degrees.x = -18
	# kosz z serwetkami i doniczka z suchym kwiatkiem
	B.cyl(self, Vector3(3.6, 0.25, -1.65), 0.16, 0.4, B.mat("cegla", Color.WHITE, 3.0), Vector3.ZERO, 0.22)
	for i in 5:
		B.box(self, Vector3(3.6, 0.7, -1.65), Vector3(0.02, 0.55, 0.02), wood,
			Vector3(i * 11 - 22, i * 70, i * 9 - 18))

# Ramy i szyby w oknach od ulicy.
func _windows() -> void:
	var frame := B.mat("deski", Color(0.65, 0.5, 0.4), 2.0)
	for z in [-3.32, 0.03, 3.36]:
		for y in [0.99, 2.95]:
			B.box(self, Vector3(3.98, y, z), Vector3(0.2, 0.08, 2.74), frame)
		for offset in [-1.34, -0.45, 0.45, 1.34]:
			B.box(self, Vector3(4.0, 1.97, z + offset), Vector3(0.07, 2.0, 0.06), frame)
		B.box(self, Vector3(4.0, 2.35, z), Vector3(0.07, 0.05, 2.7), frame)
		B.quad(self, Vector3(4.01, 1.97, z), Vector2(2.66, 2.0), B.glow(Color(0.25, 0.4, 0.7, 0.08)), Vector3(0, -90, 0))
		B.solid(self, Vector3(4.0, 1.97, z), Vector3(0.1, 2.0, 2.7))
