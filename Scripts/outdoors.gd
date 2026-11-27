@tool
extends Node3D
# Prowizoryczne otoczenie lokalu: ulice, chodniki, kamienice, latarnie i auta.
# Widać je przez okna, drzwi, z podwórka i w menu. Gracz tam nie wchodzi.
# Po ulicach dookoła lokalu powoli jeżdżą dwa auta, każde swoim pasem i w przeciwną stronę.

const B = preload("res://Scripts/build.gd")
const CAR_SPEED := 3.5
const MIN_CAR_WAIT := 5.0 # przerwa, zanim auto pojawi się znowu
const MAX_CAR_WAIT := 20.0
const TURN_RADIUS := 2.5
# Rogi tras (x, z): przed lokalem, wzdłuż okien i za podwórkiem. Końce giną w ciemności na zachodzie.
const ROUTES: Array = [
	[Vector2(-34, -9.5), Vector2(7.2, -9.5), Vector2(7.2, 16.1), Vector2(-34, 16.1)],
	[Vector2(-34, 18.1), Vector2(9.2, 18.1), Vector2(9.2, -11.5), Vector2(-34, -11.5)],
]
const ASPHALT := Color(0.45, 0.45, 0.52)
const PAVEMENT := Color(0.45, 0.45, 0.52)

var _traffic: Array[Dictionary] = []

func _ready() -> void:
	# grunt pod wszystkim
	B.box(self, Vector3(0, -0.14, 2), Vector3(80, 0.04, 80), B.mat("asfalt", ASPHALT, 0.5))
	_front()
	_east()
	_back()
	_west()
	_distant()
	_restaurant_outside()
	# Na zewnątrz cienie nic nie wnoszą, a kosztują.
	for mesh in find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not Engine.is_editor_hint():
		_start_traffic()

func _process(delta: float) -> void:
	for car in _traffic:
		_drive(car, delta)

# Ulica przed wejściem (stąd przychodzą klienci).
func _front() -> void:
	_pavement(Vector3(-4, -0.02, -6.8), Vector3(16, 0.03, 3.5))
	_road(Vector3(-12, -0.017, -10.5), Vector3(46, 0.02, 4), false)
	_pavement(Vector3(-5, -0.02, -13.3), Vector3(32, 0.04, 1.6))
	for house in [[-15.0, 6.0, "blok"], [-8.5, 7.5, "kamienica"], [-2.0, 5.5, "blok"], [4.5, 8.0, "kamienica"], [11.0, 6.5, "blok"]]:
		_building(Vector3(house[0], house[1] / 2, -16.0), Vector3(6.2, house[1], 3.6), house[2])
	_lamp(Vector3(-4.2, 0, -8.2), Vector3(0, 0, -1))
	_lamp(Vector3(7.5, 0, -12.9), Vector3(0, 0, 1))
	_shop_sign(Vector3(-2.0, 2.9, -14.15), "APTEKA", Color(0.3, 1, 0.45), 0)
	_shop_sign(Vector3(-8.5, 2.6, -14.15), "ALKOHOLE 24", Color(1, 0.75, 0.2), 0)
	_prop_can(Vector3(-2.9, 0, -8.1))
	B.on_floor(self, "kaluza", Vector3(1.8, 0.003, -9.6), 1.8)

# Widok przez duże okna sali.
func _east() -> void:
	_pavement(Vector3(5.1, -0.015, 1), Vector3(1.9, 0.03, 20))
	_road(Vector3(8.2, -0.018, 0), Vector3(4.3, 0.02, 34), true)
	_pavement(Vector3(11.2, -0.015, 0), Vector3(1.7, 0.04, 34))
	for house in [[-12.0, 7.0, "kamienica"], [-5.8, 5.0, "blok"], [0.4, 8.5, "kamienica"], [6.6, 6.0, "blok"], [12.8, 7.5, "kamienica"]]:
		_building(Vector3(13.8, house[1] / 2, house[0]), Vector3(3.5, house[1], 6), house[2])
	# słup latarni dla istniejącego światła ulicznego
	_lamp(Vector3(10.6, 0, -3), Vector3(-1, 0, 0), 2.0, false)
	_lamp(Vector3(5.8, 0, 5.2), Vector3(1, 0, 0))
	_shop_sign(Vector3(11.95, 2.5, 0.4), "LOMBARD", Color(0.5, 0.7, 1), -90)
	_shop_sign(Vector3(11.95, 2.4, -5.8), "KEBAB U KONKURENCJI\n(zamknięte)", Color(1, 0.35, 0.3), -90)
	# przystanek
	var stop := B.group(self, Vector3(11.1, 0, 4.2))
	var frame := B.mat("metal_ciemny")
	for z in [-0.8, 0.8]:
		B.box(stop, Vector3(0, 1.1, z), Vector3(0.08, 2.2, 0.08), frame)
	B.box(stop, Vector3(-0.2, 2.25, 0), Vector3(0.9, 0.08, 1.9), frame)
	B.box(stop, Vector3(0.05, 0.5, 0), Vector3(0.35, 0.08, 1.4), B.mat("deski"))
	B.label(stop, Vector3(-0.66, 2.25, 0), "NOCNY 13", 40, Color(1, 0.85, 0.4), -90)

# Ulica za podwórkiem, widoczna przez bramę z krat.
func _back() -> void:
	_pavement(Vector3(-5, -0.015, 14.1), Vector3(18, 0.03, 2.0))
	_road(Vector3(-12, -0.017, 17.1), Vector3(46, 0.02, 4), false)
	_pavement(Vector3(-5, -0.015, 19.9), Vector3(32, 0.04, 1.6))
	for house in [[-13.0, 5.5, "kamienica"], [-6.8, 7.0, "blok"], [-0.6, 5.0, "kamienica"], [5.6, 6.5, "blok"]]:
		_building(Vector3(house[0], house[1] / 2, 22.6), Vector3(6, house[1], 3.6), house[2])
	_lamp(Vector3(-1.9, 0, 14.6), Vector3(0, 0, 1))
	_lamp(Vector3(-8.5, 0, 19.4), Vector3(0, 0, -1))
	_shop_sign(Vector3(-6.8, 2.4, 20.75), "WULKANIZACJA", Color(1, 0.6, 0.2), 180)
	_shop_sign(Vector3(-0.6, 2.2, 20.75), "SKUP ZŁOMU", Color(0.55, 0.8, 1), 180)
	_prop_can(Vector3(-6.3, 0, 13.8))
	B.on_floor(self, "kaluza", Vector3(-3.0, 0.004, 15.2), 1.6, 40)

# Zabudowa po zachodniej stronie.
func _west() -> void:
	for house in [[-4.0, 6.5, "blok"], [3.0, 5.0, "kamienica"], [10.5, 7.0, "blok"]]:
		_building(Vector3(-11.0, house[1] / 2, house[0]), Vector3(5, house[1], 6.4), house[2])
	_building(Vector3(-6.2, 1.9, 0.0), Vector3(3.2, 3.8, 9.6), "blok")

# Dalekie wieżowce na horyzoncie.
func _distant() -> void:
	var spots := [Vector3(-28, 0, -24), Vector3(-12, 0, -30), Vector3(14, 0, -27), Vector3(27, 0, -8),
		Vector3(26, 0, 17), Vector3(10, 0, 33), Vector3(-17, 0, 32), Vector3(-27, 0, 8)]
	for i in spots.size():
		var height := 10.0 + (i * 5) % 9
		_building(spots[i] + Vector3(0, height / 2, 0), Vector3(7, height, 7), "blok" if i % 2 else "kamienica")

# Szyld, daszek i dach lokalu widziane z zewnątrz.
func _restaurant_outside() -> void:
	var trim := B.mat("cegla_szara", Color.WHITE, 0.8)
	B.box(self, Vector3(0, 4.3, -5.9), Vector3(10.2, 0.45, 0.25), trim)
	B.box(self, Vector3(4.95, 4.3, 0), Vector3(0.25, 0.45, 12), trim)
	for i in 8:
		var stripe := B.mat("scierka" if i % 2 else "metal_czerwony", Color.WHITE, 2.0)
		B.box(self, Vector3(-1.4 + i * 0.4, 2.4, -5.42), Vector3(0.4, 0.05, 0.85), stripe, Vector3(-18, 0, 0))
	B.box(self, Vector3(0.1, 3.15, -5.1), Vector3(2.9, 0.75, 0.08), B.mat("metal_ciemny", Color(0.5, 0.45, 0.5)))
	B.label(self, Vector3(0.1, 3.27, -5.16), "RAT KEBAB", 96, Color(1, 0.55, 0.15), 180, 0.0042)
	B.label(self, Vector3(0.1, 2.92, -5.16), "czynne nocą", 48, Color(0.35, 0.9, 1), 180, 0.003)
	B.light(self, Vector3(0.1, 2.5, -6.4), Color(1, 0.55, 0.25), 1.1, 4.5)
	# Ciepłe światło z wnętrza, padające przez drzwi na chodnik.
	var spill := SpotLight3D.new()
	spill.position = Vector3(0, 2.1, -4.9)
	spill.rotation_degrees.x = -32 # w dół i na ulicę (-z)
	spill.light_color = Color(1, 0.76, 0.47)
	spill.light_energy = 3.0
	spill.spot_range = 7.0
	spill.spot_angle = 48.0
	add_child(spill)

# --- Klocki ---

func _pavement(pos: Vector3, size: Vector3) -> void:
	B.box(self, pos, size, B.mat("chodnik", PAVEMENT, 0.6))

func _road(pos: Vector3, size: Vector3, along_z: bool) -> void:
	B.box(self, pos, size, B.mat("asfalt", ASPHALT, 0.6))
	var length := size.z if along_z else size.x
	var line := B.mat("", Color(0.4, 0.38, 0.3))
	for i in int(length / 2.4):
		var offset := -length / 2 + 1.2 + i * 2.4
		var at := pos + Vector3(0, size.y / 2 + 0.002, offset) if along_z \
			else pos + Vector3(offset, size.y / 2 + 0.002, 0)
		B.box(self, at, Vector3(0.12, 0.004, 1.1) if along_z else Vector3(1.1, 0.004, 0.12), line)

func _building(pos: Vector3, size: Vector3, facade: String) -> void:
	B.box(self, pos, size, B.facade(facade))
	B.box(self, pos + Vector3(0, size.y / 2 + 0.12, 0), Vector3(size.x + 0.25, 0.24, size.z + 0.25),
		B.mat("metal_ciemny", Color(0.45, 0.4, 0.45), 0.5))

# "arm" to kierunek wysięgnika; bez światła, gdy świeci już inna lampa.
func _lamp(pos: Vector3, arm: Vector3, reach := 0.7, lit := true) -> void:
	var metal := B.mat("metal_ciemny")
	B.cyl(self, pos + Vector3(0, 1.8, 0), 0.07, 3.6, metal)
	var head := pos + Vector3(0, 3.6, 0) + arm * reach
	B.box(self, pos + Vector3(0, 3.6, 0) + arm * reach / 2,
		Vector3(absf(arm.x) * reach + 0.08, 0.07, absf(arm.z) * reach + 0.08), metal)
	B.box(self, head, Vector3(0.34, 0.12, 0.34), metal)
	B.box(self, head + Vector3(0, -0.08, 0), Vector3(0.24, 0.05, 0.24), B.glow(Color(1, 0.72, 0.3)))
	if lit:
		B.light(self, head + Vector3(0, -0.3, 0), Color(1, 0.55, 0.18), 0.8, 5.5)

# Auto przodem do +z. Światła: jasne klosze (łapią poświatę), snop przed maską i czerwień z tyłu.
func _car(paint: String) -> Node3D:
	var car := B.group(self, Vector3.ZERO)
	var body := B.mat(paint, Color.WHITE, 0.8)
	var dark := B.mat("folia", Color.WHITE, 2.0)
	B.box(car, Vector3(0, 0.45, 0), Vector3(1.5, 0.45, 3.2), body)
	B.box(car, Vector3(0, 0.85, -0.2), Vector3(1.35, 0.42, 1.5), body)
	B.box(car, Vector3(0, 0.87, -0.2), Vector3(1.38, 0.28, 1.35), B.mat("", Color(0.06, 0.09, 0.16)))
	for x in [-0.72, 0.72]:
		for z in [-1.05, 1.05]:
			B.cyl(car, Vector3(x, 0.28, z), 0.28, 0.2, dark, Vector3(0, 0, 90), -1.0, 8)
	for x in [-0.52, 0.52]:
		B.box(car, Vector3(x, 0.5, 1.61), Vector3(0.32, 0.16, 0.03), B.glow(Color(4, 3.6, 2.4)))
		B.box(car, Vector3(x, 0.5, -1.61), Vector3(0.3, 0.12, 0.03), B.glow(Color(2.5, 0.15, 0.1)))
	var beam := SpotLight3D.new()
	beam.position = Vector3(0, 0.7, 1.7)
	beam.rotation_degrees = Vector3(-8, 180, 0) # światło świeci w -z, więc obrócone do przodu
	beam.light_color = Color(1, 0.93, 0.72)
	beam.light_energy = 8.0
	beam.spot_range = 13.0
	beam.spot_angle = 30.0
	car.add_child(beam)
	B.light(car, Vector3(0, 0.6, -2.0), Color(1, 0.1, 0.05), 0.9, 2.5)
	for mesh in car.find_children("*", "MeshInstance3D", true, false):
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return car

# --- Ruch ---

func _start_traffic() -> void:
	var paints := ["metal_czerwony", "metal_niebieski"]
	for i in ROUTES.size():
		var car := _car(paints[i])
		car.visible = false
		# Pierwsze auto rusza prawie od razu, następne po chwili.
		_traffic.append({"node": car, "path": _rounded(ROUTES[i]), "next": 0, "wait": 2.0 + i * 9.0})

func _drive(car: Dictionary, delta: float) -> void:
	var node: Node3D = car["node"]
	var path: Array = car["path"]
	if car["wait"] > 0.0:
		car["wait"] -= delta
		if car["wait"] <= 0.0:
			node.position = path[0]
			node.rotation.y = _yaw(path[1] - path[0])
			node.visible = true
			car["next"] = 1
		return
	var target: Vector3 = path[car["next"]]
	node.rotation.y = lerp_angle(node.rotation.y, _yaw(target - node.position),
		minf(delta * 8.0, 1.0))
	node.position = node.position.move_toward(target, CAR_SPEED * delta)
	if node.position.is_equal_approx(target):
		car["next"] += 1
		if car["next"] >= path.size():
			node.visible = false
			car["wait"] = randf_range(MIN_CAR_WAIT, MAX_CAR_WAIT)

func _yaw(direction: Vector3) -> float:
	return atan2(direction.x, direction.z)

# Punkty trasy z zaokrąglonymi zakrętami.
func _rounded(corners: Array) -> Array[Vector3]:
	var points: Array[Vector2] = [corners[0]]
	for i in range(1, corners.size() - 1):
		var corner: Vector2 = corners[i]
		var from := corner.move_toward(corners[i - 1], TURN_RADIUS)
		var to := corner.move_toward(corners[i + 1], TURN_RADIUS)
		for step in 7:
			var t := step / 6.0
			points.append(from.lerp(corner, t).lerp(corner.lerp(to, t), t))
	points.append(corners[-1])
	var path: Array[Vector3] = []
	for point in points:
		path.append(Vector3(point.x, 0, point.y))
	return path

func _shop_sign(pos: Vector3, text: String, color: Color, yaw: float) -> void:
	# yaw: 0 = napis przodem do +z
	B.label(self, pos, text, 72, color, yaw, 0.004)

func _prop_can(pos: Vector3) -> void:
	B.cyl(self, pos + Vector3(0, 0.35, 0), 0.22, 0.7, B.mat("metal_ciemny", Color(1.2, 1.2, 1.25), 2.0), Vector3.ZERO, 0.26)
	B.cyl(self, pos + Vector3(0, 0.74, 0), 0.28, 0.06, B.mat("metal_ciemny"))
