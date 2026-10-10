class_name CombatLoadout
extends RefCounted

var character_id: String = "naro"
var head: String = "faixa"
var body: String = "malha"
var accessory: String = "presilha"
var initial_weapon: String = "pulso"

func valid() -> bool:
	var profile := CharacterCatalog.character(character_id)
	if profile == null or not profile.valid() or Arsenal.find(initial_weapon) == null:
		return false
	for slot in ["head", "body", "accessory"]:
		var item := CharacterCatalog.equipment(get(slot))
		if item == null or item.slot != slot or not item.valid():
			return false
	return Arsenal.find(initial_weapon).valid()

func attributes() -> Dictionary:
	if not valid():
		return StatRules.BASE.duplicate()
	var modifiers: Array[Dictionary] = []
	for slot in ["head", "body", "accessory"]:
		modifiers.append(CharacterCatalog.equipment(get(slot)).modifiers)
	return StatRules.calculate(CharacterCatalog.character(character_id).stats, modifiers)

func to_dict() -> Dictionary:
	return {"character_id": character_id, "head": head, "body": body,
		"accessory": accessory, "initial_weapon": initial_weapon}

static func from_dict(data: Dictionary) -> CombatLoadout:
	var result := CombatLoadout.new()
	for key in result.to_dict():
		if not data.get(key) is String:
			return null
		result.set(key, data[key])
	return result if result.valid() else null

func copy() -> CombatLoadout:
	return from_dict(to_dict())
