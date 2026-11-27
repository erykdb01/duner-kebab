@tool
extends Node3D
# Podwórko z altaną śmietnikową: murki, brama z krat na ulicę, kubły, kartony i brud.
# x od -7 do -1.2, z od 5 do 13. Wschodnie kubły i róg z kontenerem omijają trasę szczura.

const B = preload("res://Scripts/build.gd")

var _lamp: OmniLight3D
var _time := 0.0

func _ready() -> void:
	_walls()
	_gate()
	_shelter()
	_bins()
	_junk()
	_dirt()

# Lampa na murze mruga.
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	var flicker := fmod(_time, 5.3) < 0.4 and fmod(_time, 0.16) < 0.08
	_lamp.light_energy = 0.15 if flicker else 1.0

func _walls() -> void:
	B.box(self, Vector3(-4.1, -0.012, 9.0), Vector3(5.8, 0.02, 8.0), B.mat("beton", Color.WHITE, 0.6))
	var brick := B.mat("cegla", Color.WHITE, 0.8)
	var cap := B.mat("beton", Color(0.8, 0.8, 0.8), 1.0)
	for x in [-7.0, -1.2]:
		B.box(self, Vector3(x, 1.1, 9), Vector3(0.14, 2.2, 8), brick)
		B.box(self, Vector3(x, 2.25, 9), Vector3(0.22, 0.1, 8.05), cap)
		B.solid(self, Vector3(x, 1.1, 9), Vector3(0.14, 2.2, 8))
	B.box(self, Vector3(-5.5, 1.1, 5), Vector3(3, 2.2, 0.12), B.mat("deski", Color.WHITE, 0.8))
	B.solid(self, Vector3(-5.5, 1.1, 5), Vector3(3, 2.2, 0.12))
	B.on_wall(self, "grzyb", Vector3(-6.92, 0.6, 7.0), Vector2(1.6, 1.2), 90)
	B.on_wall(self, "brud", Vector3(-1.28, 0.5, 10.6), Vector2(1.8, 1.0), -90)
	B.on_wall(self, "tluszcz", Vector3(-6.92, 1.0, 11.6), Vector2(1.2, 1.1), 90)
	B.on_wall(self, "grzyb", Vector3(-1.28, 0.4, 6.0), Vector2(1.2, 0.9), -90)
	B.label(self, Vector3(-1.28, 1.7, 11.2), "SZCZUROM\nWSTĘP WZBRONIONY", 48, Color(0.9, 0.85, 0.7), -90)
	B.label(self, Vector3(-6.92, 1.75, 7.9), "PIMPEK TU BYŁ", 40, Color(0.75, 0.2, 0.25), 90, 0.0025).rotation_degrees.z = 6
	# lampa na ścianie
	B.box(self, Vector3(-6.86, 2.45, 7.0), Vector3(0.16, 0.14, 0.3), B.mat("metal_ciemny"))
	B.box(self, Vector3(-6.76, 2.4, 7.0), Vector3(0.05, 0.08, 0.2), B.glow(Color(1, 0.82, 0.45)))
	_lamp = B.light(self, Vector3(-6.4, 2.4, 7.0), Color(1, 0.75, 0.4), 1.0, 4.5)

# Zamknięta brama z krat: widać ulicę, nie da się wyjść.
func _gate() -> void:
	var metal := B.mat("metal_ciemny", Color(0.9, 0.9, 1.0), 2.0)
	for i in 30:
		var x := -6.9 + i * 0.197
		B.box(self, Vector3(x, 1.1, 13), Vector3(0.03, 2.2, 0.03), metal)
		B.ball(self, Vector3(x, 2.25, 13), Vector3(0.06, 0.11, 0.06), metal)
	for y in [0.18, 1.1, 2.05]:
		B.box(self, Vector3(-4.1, y, 13), Vector3(5.8, 0.06, 0.06), metal)
	for x in [-5.45, -2.75]:
		B.box(self, Vector3(x, 1.2, 13), Vector3(0.12, 2.4, 0.12), metal)
	B.solid(self, Vector3(-4.1, 1.2, 13), Vector3(5.8, 2.4, 0.12))
	B.box(self, Vector3(-4.1, 1.05, 12.95), Vector3(0.14, 0.18, 0.08), B.mat("metal_zolty", Color.WHITE, 4.0))

# Zadaszona wiata nad kontenerem w zachodnim rogu.
func _shelter() -> void:
	var post := B.mat("metal_brazowy", Color.WHITE, 2.0)
	for z in [9.5, 11.3, 12.92]:
		B.box(self, Vector3(-5.55, 1.25, z), Vector3(0.09, 2.5, 0.09), post)
		B.box(self, Vector3(-6.25, 2.55, z), Vector3(1.55, 0.07, 0.07), post, Vector3(0, 0, -7))
	B.box(self, Vector3(-6.22, 2.62, 11.2), Vector3(1.75, 0.05, 3.75), B.mat("blacha", Color.WHITE, 0.9), Vector3(0, 0, -7))
	var mesh := B.picture("siatka")
	for i in 3:
		B.quad(self, Vector3(-6.55 + i * 0.5, 0.9, 9.5), Vector2(0.5, 0.5), mesh)
		B.quad(self, Vector3(-6.55 + i * 0.5, 1.4, 9.5), Vector2(0.5, 0.5), mesh)
	B.box(self, Vector3(-6.2, 1.68, 9.5), Vector3(1.4, 0.05, 0.05), post)
	B.label(self, Vector3(-6.1, 1.9, 9.46), "ALTANA ŚMIETNIKOWA", 36, Color(0.95, 0.9, 0.7), 180, 0.0022)

func _bins() -> void:
	# kubły na kółkach pod wschodnim murem
	var kinds := [["metal_niebieski", "PAPIER", 7.1], ["metal_zolty", "PLASTIK", 8.0], ["metal_brazowy", "BIO", 8.9]]
	for kind in kinds:
		_wheelie(Vector3(-1.65, 0, kind[2]), kind[0], kind[1])
	# dzwon na szkło
	B.cyl(self, Vector3(-1.85, 0.5, 12.3), 0.5, 1.0, B.mat("metal_zielony", Color(1.1, 1.3, 1.1), 1.5), Vector3.ZERO, 0.45, 8)
	B.ball(self, Vector3(-1.85, 1.0, 12.3), Vector3(0.9, 0.5, 0.9), B.mat("metal_zielony", Color(0.9, 1.1, 0.9), 1.5))
	for z in [-0.18, 0.18]:
		B.cyl(self, Vector3(-2.3, 0.85, 12.3 + z), 0.09, 0.08, B.mat("folia"), Vector3(0, 0, 90))
	B.label(self, Vector3(-2.34, 0.5, 12.3), "SZKŁO", 40, Color(0.9, 1, 0.9), -90, 0.0022)
	B.solid(self, Vector3(-1.85, 0.65, 12.3), Vector3(0.95, 1.3, 0.95))
	# stare blaszane kosze
	for at in [Vector3(-6.6, 0, 5.5), Vector3(-6.55, 0, 6.15)]:
		B.cyl(self, at + Vector3(0, 0.36, 0), 0.22, 0.72, B.mat("blacha", Color.WHITE, 2.0), Vector3.ZERO, 0.27)
		B.solid(self, at + Vector3(0, 0.4, 0), Vector3(0.5, 0.8, 0.5))
	B.cyl(self, Vector3(-6.6, 0.76, 5.5), 0.3, 0.06, B.mat("metal_ciemny"))
	B.cyl(self, Vector3(-6.2, 0.2, 6.55), 0.29, 0.05, B.mat("metal_ciemny"), Vector3(0, 0, 55))

func _wheelie(at: Vector3, paint: String, text: String) -> void:
	var bin := B.group(self, at)
	var body := B.mat(paint, Color.WHITE, 1.5)
	var black := B.mat("folia", Color.WHITE, 3.0)
	B.box(bin, Vector3(0, 0.58, 0), Vector3(0.62, 0.88, 0.62), body)
	B.box(bin, Vector3(-0.02, 1.07, 0), Vector3(0.72, 0.09, 0.7), body, Vector3(0, 0, 4))
	B.box(bin, Vector3(0.36, 1.02, 0), Vector3(0.05, 0.05, 0.56), black)
	for z in [-0.26, 0.26]:
		B.cyl(bin, Vector3(0.24, 0.11, z), 0.11, 0.08, black, Vector3(90, 0, 0), -1.0, 8)
	B.box(bin, Vector3(-0.24, 0.08, 0), Vector3(0.08, 0.16, 0.5), black)
	B.label(bin, Vector3(-0.318, 0.7, 0), text, 40, Color(0.95, 0.93, 0.85), -90, 0.0024)
	B.solid(bin, Vector3(0, 0.55, 0), Vector3(0.66, 1.1, 0.66))

func _junk() -> void:
	var cardboard := B.mat("karton", Color.WHITE, 2.0)
	var wood := B.mat("deski", Color(0.85, 0.75, 0.65), 2.0)
	var bag := B.mat("folia", Color.WHITE, 2.0)
	# kartony
	var boxes := [[-6.6, 0.2, 8.7, 0.55, 0.4, 0.5, 12], [-6.62, 0.54, 8.72, 0.42, 0.28, 0.4, -20],
		[-6.5, 0.15, 9.2, 0.4, 0.3, 0.35, 40], [-6.15, 0.03, 8.85, 0.6, 0.04, 0.45, -33]]
	for b in boxes:
		B.box(self, Vector3(b[0], b[1], b[2]), Vector3(b[3], b[4], b[5]), cardboard, Vector3(0, b[6], 0))
	B.solid(self, Vector3(-6.6, 0.35, 8.9), Vector3(0.6, 0.7, 0.9))
	# palety oparte o płot
	for i in 2:
		var pallet := B.group(self, Vector3(-6.0 + i * 0.1, 0.5, 5.28 + i * 0.1))
		pallet.rotation_degrees.x = -12
		for k in 5:
			B.box(pallet, Vector3(0, -0.4 + k * 0.2, 0), Vector3(0.9, 0.1, 0.03), wood)
		for x in [-0.4, 0.0, 0.4]:
			B.box(pallet, Vector3(x, 0, -0.04), Vector3(0.08, 0.95, 0.04), wood)
	# worki
	for spot in [Vector3(-6.55, 0.24, 7.5), Vector3(-6.2, 0.18, 7.85), Vector3(-6.55, 0.6, 7.65),
			Vector3(-1.6, 0.2, 9.75), Vector3(-1.62, 0.2, 6.3)]:
		B.ball(self, spot, Vector3(0.62, 0.48, 0.58), bag)
		B.cyl(self, spot + Vector3(0, 0.27, 0), 0.025, 0.12, bag, Vector3(0, 0, 12), 0.07, 5)
	B.solid(self, Vector3(-6.4, 0.4, 7.65), Vector3(0.75, 0.8, 0.8))
	# porzucone krzesło bez nogi
	var chair := B.group(self, Vector3(-1.75, 0.18, 10.5), 35)
	chair.rotation_degrees.z = 20
	B.box(chair, Vector3.ZERO, Vector3(0.45, 0.06, 0.45), wood)
	B.box(chair, Vector3(0.2, 0.3, 0), Vector3(0.05, 0.55, 0.45), wood)
	for leg in [Vector2(-0.18, -0.18), Vector2(-0.18, 0.18), Vector2(0.18, 0.18)]:
		B.box(chair, Vector3(leg.x, -0.2, leg.y), Vector3(0.05, 0.38, 0.05), wood)
	# butelki
	for i in 6:
		var at := Vector3(-2.2 - (i % 3) * 0.17, 0.045, 5.5 + floorf(i / 3.0) * 0.2 + i * 0.03)
		if i > 2:
			at = Vector3(-5.2 + i * 0.12, 0.045, 12.6 - (i % 2) * 0.2)
		B.cyl(self, at, 0.04, 0.22, B.mat("", Color(0.12, 0.3, 0.14)), Vector3(90, i * 61, 0))

func _dirt() -> void:
	var spots := [["brud", -5.8, 10.5, 1.8], ["brud", -3.0, 12.0, 1.5], ["brud", -2.2, 8.0, 1.2],
		["kaluza", -4.4, 7.4, 1.3], ["kaluza", -5.2, 11.9, 1.1], ["tluszcz", -6.1, 11.3, 1.4],
		["brud", -4.6, 5.8, 1.1], ["sos_plama", -3.6, 9.8, 0.6], ["grzyb", -6.4, 12.4, 1.0]]
	for i in spots.size():
		var spot: Array = spots[i]
		B.on_floor(self, spot[0], Vector3(spot[1], 0.001 + i * 0.0004, spot[2]), spot[3], i * 47.0)
	var litter := [Vector2(-5.9, 6.9), Vector2(-4.8, 10.3), Vector2(-2.4, 9.4), Vector2(-3.4, 12.5),
		Vector2(-6.0, 12.2), Vector2(-2.0, 6.8), Vector2(-5.0, 8.4)]
	for i in litter.size():
		B.on_floor(self, "smieci", Vector3(litter[i].x, 0.006, litter[i].y), 0.65, i * 73.0)
