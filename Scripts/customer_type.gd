extends Resource
# Rodzaj klienta (pliki w folderze Customers). Teksty i imiona są w Data/dialogi.json.

@export var kind: StringName = &"regular" # regular, sanepid, gourmet, owner
@export var patience := 75.0
@export var tip := 5
