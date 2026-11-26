@tool
extends RefCounted
# Stan światła w grze i barwa sprite'ów (postacie i szczury nie reagują same na światła).

const INSIDE := Color(0.93, 0.85, 0.78)
const YARD := Color(0.62, 0.68, 0.78)
const STREET := Color(0.66, 0.6, 0.68)
const DARK := Color(0.07, 0.08, 0.15)
const LIT := Color(0.95, 0.92, 0.82)

static var dark := false # awaria prądu
static var torch: SpotLight3D # latarka gracza

static func tint(at: Vector3) -> Color:
	if dark:
		return DARK.lerp(LIT, _in_torch(at + Vector3(0, 0.5, 0)))
	if at.z > 5.0 and at.x < -1.2:
		return YARD
	if at.z < -5.0 or at.x > 4.0:
		return STREET
	return INSIDE

# 0 = poza snopem latarki, 1 = w środku.
static func _in_torch(at: Vector3) -> float:
	if not is_instance_valid(torch) or not torch.visible:
		return 0.0
	var offset := at - torch.global_position
	var facing := offset.normalized().dot(-torch.global_basis.z)
	var beam := clampf((facing - 0.84) / 0.1, 0.0, 1.0)
	return beam * clampf((9.0 - offset.length()) / 4.0, 0.0, 1.0)
