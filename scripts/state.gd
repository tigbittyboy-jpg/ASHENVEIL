extends Node
signal changed
signal notice(text: String)
signal cleansed
var items: Dictionary
var npcs: Dictionary
var enemies: Dictionary
var quest_defs: Dictionary
var s: Dictionary
const SAVE_VERSION = 1
func _ready():
	items = read_data("items")
	npcs = read_data("npcs")
	enemies = read_data("enemies")
	quest_defs = read_data("quests")
	reset()
func read_data(id: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/" + id + ".json"))
func reset():
	s = {"version":SAVE_VERSION,"map":"village","position":[480,480],"hp":100.0,"mana":60.0,"stamina":100.0,"level":1,"xp":0,"points":0,"crowns":85,"inventory":{"rust_sword":1,"potion":3},"equipment":{"weapon":"rust_sword"},"upgrades":{},"attributes":{"Vitality":0,"Strength":0,"Dexterity":0,"Intelligence":0,"Endurance":0},"skills":[],"quests":{},"flags":{},"memory":{},"checkpoint":{"map":"village","position":[480,480]},"settings":{"master":0.8,"music":0.35,"sfx":0.7,"ambient":0.5,"ollama":false}}
	changed.emit()
func stat(id: String) -> float:
	var a: Dictionary = s.attributes
	match id:
		"hp": return 100 + a.Vitality * 12 + (20 if "Bulwark" in s.skills else 0)
		"mana": return 60 + a.Intelligence * 8
		"stamina": return 100 + a.Endurance * 10
		"attack":
			var weapon: String = s.equipment.get("weapon","rust_sword")
			return items[weapon].attack + a.Strength * 2 + s.upgrades.get(weapon,0)*4 + (5 if "Cleave" in s.skills else 0)
		"defense":
			var result := 0.0
			for item in s.equipment.values(): result += items[item].get("defense",0)
			return result
		"speed": return 140 + a.Dexterity*3 + (20 if "Fleet" in s.skills else 0)
	return 0
func damage(attack: float, defense: float, blocking: bool = false) -> float:
	return maxf(1,attack - defense) * (0.35 if blocking else 1.0)
func add_item(id: String, count: int = 1) -> bool:
	if not items.has(id) or count <= 0: return false
	if not s.inventory.has(id) and s.inventory.size() >= 24: return false
	s.inventory[id] = s.inventory.get(id,0) + count
	changed.emit()
	return true
func remove_item(id: String, count: int = 1) -> bool:
	if count <= 0 or s.inventory.get(id,0) < count: return false
	s.inventory[id] -= count
	if s.inventory[id] == 0:
		s.inventory.erase(id)
		for slot in s.equipment.keys():
			if s.equipment[slot] == id: s.equipment.erase(slot)
		if not s.equipment.has("weapon") and s.inventory.has("rust_sword"): s.equipment.weapon = "rust_sword"
	changed.emit()
	return true
func buy(id: String) -> bool:
	if not items.has(id) or items[id].price <= 0 or s.crowns < items[id].price: return false
	if not add_item(id): return false
	s.crowns -= items[id].price
	s.memory["mara_purchase"] = true
	changed.emit()
	return true
func sell(id: String) -> bool:
	if id in s.equipment.values() or not items.has(id) or items[id].price <= 0: return false
	if not remove_item(id): return false
	s.crowns += maxi(1,int(items[id].price/2))
	changed.emit()
	return true
func equip(id: String) -> bool:
	if s.inventory.get(id,0) <= 0 or items[id].slot == "": return false
	s.equipment[items[id].slot] = id
	changed.emit()
	return true
func use(id: String) -> bool:
	if not items.has(id) or items[id].get("effect","") == "" or s.inventory.get(id,0) < 1: return false
	remove_item(id)
	match items[id].effect:
		"heal": s.hp = minf(stat("hp"),s.hp+55)
		"mana": s.mana = minf(stat("mana"),s.mana+40)
		"stamina": s.stamina = stat("stamina")
		"cleanse": cleansed.emit()
	changed.emit()
	return true
func upgrade() -> bool:
	var id: String = s.equipment.weapon
	var level: int = s.upgrades.get(id,0)
	var cost := 25*(level+1)
	if level >= 5 or s.crowns < cost or s.inventory.get("ore",0) < level+1: return false
	remove_item("ore",level+1)
	s.crowns -= cost
	s.upgrades[id] = level+1
	changed.emit()
	return true
func gain_xp(amount: int):
	s.xp += amount
	while s.level < 20 and s.xp >= s.level*45:
		s.xp -= s.level*45
		s.level += 1
		s.points += 3
		s.hp = stat("hp")
		notice.emit("Level %d — three attribute points earned" % s.level)
	changed.emit()
func accept(id: String):
	if not quest_defs.has(id): return
	if not s.quests.has(id):
		s.quests[id] = "active"
		notice.emit("Quest accepted: " + quest_defs[id].name)
	if id in ["bell","elites"] and objective_ready(id): reward(id)
	changed.emit()
func objective_ready(id: String) -> bool:
	match id:
		"herbs": return s.inventory.get("herb",0) >= 3
		"iron": return s.inventory.get("ore",0) >= 3
		"charm": return s.inventory.get("charm",0) >= 1
		"bell": return s.flags.get("ending",false)
		"elites": return s.flags.get("sentinel",false) and s.flags.get("lost_hound",false) and s.flags.get("crypt_knight",false)
	return false
func quest_progress(id: String) -> String:
	match id:
		"herbs": return "Weeping Herbs: %d/3 — return to Elowen" % mini(3,s.inventory.get("herb",0))
		"iron": return "Grave Iron: %d/3 — return to Brann" % mini(3,s.inventory.get("ore",0))
		"charm": return "Charm found — choose Return or Keep with Tovin" if objective_ready(id) else "Find the southwest forest chest"
		"elites": return "Elites defeated: %d/3" % (int(s.flags.get("sentinel",false))+int(s.flags.get("lost_hound",false))+int(s.flags.get("crypt_knight",false)))
		"bell": return "Visit the shrine" if s.flags.get("boss",false) else ("Enter the crypt" if s.flags.get("sentinel",false) else "Defeat the forest sentinel for the sigil")
	return ""
func turn_in(id: String, choice: String = "return") -> bool:
	if not quest_defs.has(id): return false
	if s.quests.get(id,"") == "complete":
		notice.emit("Already rewarded: " + quest_defs[id].name); return false
	if not s.quests.has(id): accept(id)
	if not objective_ready(id):
		notice.emit("Not ready: " + quest_progress(id)); return false
	if id == "charm" and choice not in ["return","keep"]: return false
	# Reward and item consumption happen together, through one validated path.
	if not reward(id): return false
	match id:
		"herbs": remove_item("herb",3); s.memory["sister_helped"] = true
		"iron": remove_item("ore",3); s.memory["brann_helped"] = true
		"charm":
			if choice == "return": remove_item("charm"); s.memory["tovin_helped"] = true
			else: s.memory["tovin_betrayed"] = true
	changed.emit()
	return true
func reconcile_quests():
	for id in ["bell","elites"]:
		if s.quests.get(id,"") == "active" and objective_ready(id): reward(id)
func reward(id: String) -> bool:
	if not quest_defs.has(id) or s.quests.get(id,"") != "active" or not objective_ready(id): return false
	s.quests[id] = "complete"
	var crowns: int = quest_defs[id].reward
	s.crowns += crowns
	gain_xp(60)
	notice.emit("%s COMPLETE · +%d Crowns · +60 XP" % [quest_defs[id].name,crowns])
	return true
func spend_attribute(id: String) -> bool:
	if s.points < 1 or not s.attributes.has(id): return false
	s.points -= 1
	s.attributes[id] += 1
	changed.emit()
	return true
func unlock(id: String) -> bool:
	if id not in ["Cleave","Bulwark","Fleet","Shadow","Ember","Hex"] or id in s.skills or s.points < 2: return false
	s.points -= 2
	s.skills.append(id)
	changed.emit()
	return true
func save_game(slot: int = 0) -> bool:
	if slot < 0 or slot > 3: return false
	if not valid_save(s): return false
	var path := "user://slot_%d.json" % slot
	var f := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f == null: return false
	f.store_string(JSON.stringify(s))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path+".bak")
		DirAccess.rename_absolute(path,path+".bak")
	return DirAccess.rename_absolute(path+".tmp",path) == OK
func number(value) -> bool:
	return (value is float or value is int) and is_finite(float(value))
func valid_save(data) -> bool:
	if not data is Dictionary or data.get("version",0) != SAVE_VERSION: return false
	for key in s.keys():
		if not data.has(key): return false
	if data.map not in ["village","forest","crypt","shrine"]: return false
	for key in ["inventory","equipment","attributes","upgrades","quests","flags","memory","checkpoint","settings"]:
		if not data[key] is Dictionary: return false
	for key in ["hp","mana","stamina","level","xp","points","crowns"]:
		if not number(data[key]) or data[key] < 0: return false
	if data.level < 1 or data.level > 20 or data.inventory.size() > 24: return false
	if not data.skills is Array: return false
	for id in data.skills:
		if id not in ["Cleave","Bulwark","Fleet","Shadow","Ember","Hex"]: return false
	for key in ["Vitality","Strength","Dexterity","Intelligence","Endurance"]:
		if not number(data.attributes.get(key)) or data.attributes[key] < 0: return false
	for key in ["master","music","sfx","ambient"]:
		if not number(data.settings.get(key)) or data.settings[key] < 0 or data.settings[key] > 1: return false
	if not data.settings.get("ollama") is bool: return false
	for pos in [data.position,data.checkpoint.get("position")]:
		if not pos is Array or pos.size() != 2 or not number(pos[0]) or not number(pos[1]): return false
		if pos[0] < 16 or pos[0] > 1424 or pos[1] < 16 or pos[1] > 944: return false
	if data.checkpoint.get("map","") not in ["village","forest","crypt","shrine"]: return false
	for id in data.inventory:
		if not items.has(id) or not number(data.inventory[id]) or data.inventory[id] <= 0 or floor(data.inventory[id]) != data.inventory[id]: return false
	for slot in data.equipment:
		var id = data.equipment[slot]
		if not items.has(id) or data.inventory.get(id,0) <= 0 or items[id].slot != slot: return false
	if not data.equipment.has("weapon"): return false
	for id in data.quests:
		if not quest_defs.has(id) or data.quests[id] not in ["active","complete"]: return false
	for id in data.upgrades:
		if not items.has(id) or items[id].slot != "weapon" or not number(data.upgrades[id]) or data.upgrades[id] < 0 or data.upgrades[id] > 5: return false
	return true
func load_game(slot: int = 0) -> bool:
	for suffix in ["",".bak"]:
		var path := "user://slot_%d.json%s" % [slot,suffix]
		if not FileAccess.file_exists(path): continue
		var parser := JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK: continue
		var data = parser.data
		if valid_save(data):
			s = data
			reconcile_quests()
			changed.emit()
			return true
	return false
