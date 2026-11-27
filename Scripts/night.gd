@tool
extends RefCounted
# Barwa sprite'ów (postacie i szczury nie reagują same na światła).

const INSIDE := Color(0.93, 0.85, 0.78)
const YARD := Color(0.46, 0.5, 0.62)
const STREET := Color(0.42, 0.38, 0.48)

static func tint(at: Vector3) -> Color:
	if at.z > 5.0 and at.x < -1.2:
		return YARD
	if at.z < -5.0 and absf(at.x) < 2.0:
		# Przed drzwiami pada światło z lokalu i słabnie z odległością.
		return INSIDE.lerp(STREET, clampf((-5.0 - at.z) / 3.5, 0.0, 1.0))
	if at.z < -5.0 or at.x > 4.0:
		return STREET
	return INSIDE
