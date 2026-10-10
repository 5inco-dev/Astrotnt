class_name CharacterCatalog
extends RefCounted

# Load once on first use, after script classes have finished initializing.
static var _characters: Array[CharacterProfile] = []
static var _equipment: Array[EquipmentProfile] = []
static var CHARACTERS: Array[CharacterProfile]:
	get:
		if _characters.is_empty():
			for id in ["naro", "brumo", "vexa", "lume"]:
				_characters.append(load("res://resources/characters/%s.tres" % id))
		return _characters
static var EQUIPMENT: Array[EquipmentProfile]:
	get:
		if _equipment.is_empty():
			for id in ["faixa", "viseira", "capuz", "malha", "placa", "colete", "presilha", "nucleo", "aleta"]:
				_equipment.append(load("res://resources/equipment/%s.tres" % id))
		return _equipment

static func character(id: String) -> CharacterProfile:
	for item: CharacterProfile in CHARACTERS:
		if item.id == id:
			return item
	return null

static func equipment(id: String) -> EquipmentProfile:
	for item: EquipmentProfile in EQUIPMENT:
		if item.id == id:
			return item
	return null

static func for_slot(slot: String) -> Array[EquipmentProfile]:
	var result: Array[EquipmentProfile] = []
	for item: EquipmentProfile in EQUIPMENT:
		if item.slot == slot:
			result.append(item)
	return result
