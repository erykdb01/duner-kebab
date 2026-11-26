@tool
extends RefCounted
# Klocki do budowania low-poly otoczenia w kodzie: pudełka, walce, naklejki, napisy, światła.
# Tekstury z Textures/swiat, zawsze z filtrem "nearest" (piksele).

const TEXTURE := "res://Textures/swiat/%s.png"

static var _cache := {}

static func texture(name: String) -> Texture2D:
	return load(TEXTURE % name)

# Materiał kafelkowany po bryle. Pusta nazwa = sam kolor. "tiles" = powtórzenia na metr.
static func mat(name: String, tint := Color.WHITE, tiles := 1.0) -> StandardMaterial3D:
	var key := "%s %s %s" % [name, tint, tiles]
	if not _cache.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		material.roughness = 0.9
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		if name:
			material.albedo_texture = texture(name)
			material.uv1_triplanar = true
			material.uv1_scale = Vector3.ONE * tiles
		_cache[key] = material
	return _cache[key]

# Elewacja ze świecącymi oknami (obok tekstury "<nazwa>_swiatlo").
static func facade(name: String) -> StandardMaterial3D:
	var key := "facade " + name
	if not _cache.has(key):
		var material: StandardMaterial3D = mat(name, Color.WHITE, 0.25).duplicate()
		material.emission_enabled = true
		material.emission = Color.BLACK
		material.emission_texture = texture(name + "_swiatlo")
		_cache[key] = material
	return _cache[key]

# Obrazek rozciągnięty na płaszczyźnie, z przezroczystością (plamy, plakaty, siatka).
static func picture(name: String, tint := Color.WHITE, glowing := false) -> StandardMaterial3D:
	var key := "picture %s %s %s" % [name, tint, glowing]
	if not _cache.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_texture = texture(name)
		material.albedo_color = tint
		material.roughness = 1.0
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if glowing:
			material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_cache[key] = material
	return _cache[key]

# Kolor świecący własnym światłem.
static func glow(color: Color) -> StandardMaterial3D:
	var key := "glow %s" % color
	if not _cache.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if color.a < 1.0:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_cache[key] = material
	return _cache[key]

static func _mesh(parent: Node, mesh: Mesh, pos: Vector3, rot: Vector3) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos
	instance.rotation_degrees = rot
	parent.add_child(instance)
	return instance

static func box(parent: Node, pos: Vector3, size: Vector3, material: Material,
		rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	return _mesh(parent, mesh, pos, rot)

static func cyl(parent: Node, pos: Vector3, radius: float, height: float, material: Material,
		rot := Vector3.ZERO, top := -1.0, sides := 7) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius if top < 0.0 else top
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 0
	mesh.material = material
	return _mesh(parent, mesh, pos, rot)

static func ball(parent: Node, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 7
	mesh.rings = 3
	mesh.material = material
	var instance := _mesh(parent, mesh, pos, Vector3.ZERO)
	instance.scale = size
	return instance

static func quad(parent: Node, pos: Vector3, size: Vector2, material: Material,
		rot := Vector3.ZERO) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = size
	mesh.material = material
	return _mesh(parent, mesh, pos, rot)

# Plama na podłodze.
static func on_floor(parent: Node, name: String, pos: Vector3, size: float, yaw := 0.0) -> MeshInstance3D:
	return quad(parent, pos, Vector2(size, size), picture(name), Vector3(-90, yaw, 0))

# Plama na ścianie. yaw: 0 = przodem do +z, 90 = do +x, -90 = do -x, 180 = do -z.
static func on_wall(parent: Node, name: String, pos: Vector3, size: Vector2, yaw: float) -> MeshInstance3D:
	return quad(parent, pos, size, picture(name), Vector3(0, yaw, 0))

static func label(parent: Node, pos: Vector3, text: String, font_size: int, color: Color,
		yaw := 0.0, pixel := 0.002) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.font_size = font_size
	node.outline_size = 6
	node.pixel_size = pixel
	node.modulate = color
	node.position = pos
	node.rotation_degrees.y = yaw
	node.double_sided = false
	parent.add_child(node)
	return node

static func light(parent: Node, pos: Vector3, color: Color, energy: float, reach: float) -> OmniLight3D:
	var node := OmniLight3D.new()
	node.position = pos
	node.light_color = color
	node.light_energy = energy
	node.omni_range = reach
	parent.add_child(node)
	return node

# Niewidzialna przeszkoda dla gracza.
static func solid(parent: Node, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var form := BoxShape3D.new()
	form.size = size
	shape.shape = form
	body.position = pos
	body.add_child(shape)
	parent.add_child(body)

static func group(parent: Node, pos: Vector3, yaw := 0.0) -> Node3D:
	var node := Node3D.new()
	node.position = pos
	node.rotation_degrees.y = yaw
	parent.add_child(node)
	return node
