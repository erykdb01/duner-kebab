@tool
extends RefCounted
# Barwa sprite'ów (postacie i szczury nie reagują same na światła).

const INSIDE := Color(0.93, 0.85, 0.78)
const YARD := Color(0.62, 0.68, 0.78)
const STREET := Color(0.66, 0.6, 0.68)

static func tint(at: Vector3) -> Color:
	if at.z > 5.0 and at.x < -1.2:
		return YARD
	if at.z < -5.0 or at.x > 4.0:
		return STREET
	return INSIDE
