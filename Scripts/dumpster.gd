@tool
extends StaticBody3D
# Długi kontener na kółkach. Pod spodem prześwit ok. 0,5 m, w którym chowają się szczury.

const B = preload("res://Scripts/build.gd")

func _ready() -> void:
	var body := B.mat("metal_zielony", Color.WHITE, 1.1)
	var trim := B.mat("metal_ciemny", Color(0.8, 0.95, 0.8), 1.5)
	var black := B.mat("folia", Color.WHITE, 2.0)
	# skrzynia ze skośnymi bokami
	B.box(self, Vector3(0, 0.92, 0), Vector3(2.8, 0.72, 0.82), body)
	for z in [-0.42, 0.42]:
		B.box(self, Vector3(0, 0.95, z), Vector3(2.86, 0.7, 0.05), body, Vector3(signf(z) * 8, 0, 0))
		for x in [-1.32, -0.45, 0.45, 1.32]:
			B.box(self, Vector3(x, 0.95, z * 1.1), Vector3(0.07, 0.7, 0.05), trim, Vector3(signf(z) * 8, 0, 0))
	B.box(self, Vector3(0, 0.56, 0), Vector3(2.92, 0.07, 0.94), trim)
	B.box(self, Vector3(0, 1.31, 0), Vector3(3.0, 0.07, 1.04), trim)
	# klapy: jedna zamknięta, druga uchylona, spod niej wystają worki
	B.box(self, Vector3(-0.74, 1.38, 0), Vector3(1.45, 0.05, 1.02), black, Vector3(-3, 0, 0))
	B.box(self, Vector3(0.74, 1.62, 0.1), Vector3(1.45, 0.05, 1.0), black, Vector3(-28, 0, 0))
	for spot in [Vector3(0.35, 1.42, -0.1), Vector3(0.95, 1.46, -0.18), Vector3(0.7, 1.4, 0.15)]:
		B.ball(self, spot, Vector3(0.6, 0.42, 0.52), black)
	B.box(self, Vector3(1.15, 1.5, -0.3), Vector3(0.35, 0.04, 0.3), B.mat("karton", Color.WHITE, 3.0), Vector3(10, 30, 25))
	# nogi, kółka i uchwyty
	for x in [-1.35, 1.35]:
		B.box(self, Vector3(x * 1.11, 1.1, 0), Vector3(0.1, 0.06, 0.6), black)
		for z in [-0.37, 0.37]:
			B.box(self, Vector3(x, 0.33, z), Vector3(0.08, 0.4, 0.1), black)
			B.cyl(self, Vector3(x, 0.1, z), 0.1, 0.07, black, Vector3(90, 0, 0), -1.0, 8)
	for z in [-0.5, 0.5]:
		var side: float = signf(z)
		var yaw := 0.0 if side > 0 else 180.0
		B.label(self, Vector3(-0.85, 0.98, side * 0.53), "ZMIESZANE", 56, Color(0.92, 0.9, 0.8), yaw, 0.0026)
		B.on_wall(self, "brud", Vector3(0.8, 0.85, side * 0.525), Vector2(0.9, 0.6), yaw)
