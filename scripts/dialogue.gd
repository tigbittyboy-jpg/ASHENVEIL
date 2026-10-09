extends Node
var trees: Dictionary
func _ready(): trees = State.read_data("dialogue_trees")
func allowed(condition: Dictionary) -> bool:
	if condition.has("flag") and not State.s.flags.get(condition.flag,false): return false
	if condition.has("memory") and not State.s.memory.get(condition.memory,false): return false
	if condition.has("quest"):
		var status: String = State.s.quests.get(condition.quest,"absent")
		if status != condition.state: return false
	return true
func node_for(npc: String, id: String) -> Dictionary:
	if not trees.has(npc): return {}
	var node: Dictionary = trees[npc].nodes.get(id,trees[npc].nodes.root)
	var text: String = node.text
	for variant in node.get("variants",[]):
		if allowed(variant.condition): text = variant.text; break
	var choices: Array = []
	for option in node.choices:
		if allowed(option.get("condition",{})): choices.append(option)
	return {"text":text,"choices":choices}
func execute(npc: String, action: Dictionary) -> String:
	# Stable authored action IDs only; no text evaluation or network calls.
	var quests := {"brann":["iron"],"sister":["herbs"],"tovin":["charm"],"ilya":["bell","elites"]}
	if action.kind in ["accept","turn_in"]:
		if action.get("quest","") not in quests.get(npc,[]): return "That request does not belong to this villager."
		if action.kind == "accept": State.accept(action.quest); return "The work is recorded in your journal."
		if State.turn_in(action.quest,action.get("choice","return")): return "As promised: %d Crowns and 60 XP. Thank you."%State.quest_defs[action.quest].reward
		return "Not yet. "+State.quest_progress(action.quest)
	return ""
