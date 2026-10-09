extends Node
var trees: Dictionary
var context: Dictionary = {}
const QUEST_OWNERS = {"brann":["iron"],"sister":["herbs"],"tovin":["charm"],"ilya":["bell","elites"]}
const SERVICES = {"mara":["shop","sell"],"brann":["upgrade"],"sister":["heal"],"nell":["rest"]}
func _ready(): trees = State.read_data("dialogue_trees")
func knowledge(npc: String) -> Dictionary:
	var discoveries = State.s.memory.get("dialogue_knowledge",{})
	if not discoveries is Dictionary or not discoveries.get(npc,{}) is Dictionary: return {}
	return discoveries.get(npc,{})
func allowed(condition: Dictionary, npc: String = "") -> bool:
	if condition.has("flag") and not State.s.flags.get(condition.flag,false): return false
	if condition.has("memory") and not State.s.memory.get(condition.memory,false): return false
	if condition.has("knowledge") and not knowledge(npc).get(condition.knowledge,false): return false
	if condition.has("not_knowledge") and knowledge(npc).get(condition.not_knowledge,false): return false
	if condition.has("quest") and State.s.quests.get(condition.quest,"absent") != condition.state: return false
	return true
func node_for(npc: String, id: String) -> Dictionary:
	# Missing links are errors, never an unrelated fallback greeting.
	if not trees.has(npc) or not trees[npc].nodes.has(id): return {}
	var node: Dictionary = trees[npc].nodes[id]
	var text: String = node.text
	for variant in node.get("variants",[]):
		if allowed(variant.condition,npc): text = variant.text; break
	var choices: Array = []
	for option in node.choices:
		if allowed(option.get("condition",{}),npc): choices.append(option.duplicate(true))
	return {"text":text,"choices":choices,"topic":node.get("topic",id)}
func end(): context.clear()
func begin(npc: String) -> bool:
	if not trees.has(npc): return false
	context = {"npc":npc,"node":"","previous":"","topic":"","history":[],"questions":[],"revealed":[],"quests":{},"flags":{}}
	return enter("root",false)
func enter(id: String, remember: bool = true) -> bool:
	if context.is_empty() or not trees[context.npc].nodes.has(id): return false
	var old: String = context.node
	if remember and old != "" and old != id:
		# Revisiting an earlier branch trims cycles instead of growing history forever.
		var index: int = context.history.find(id)
		if index >= 0: context.history.resize(index)
		else: context.history.append(old)
		if context.history.size()>24: context.history.pop_front()
	context.previous = old; context.node = id
	context.topic = trees[context.npc].nodes[id].get("topic",id)
	if not State.s.memory.get("dialogue_knowledge",{}) is Dictionary: State.s.memory.dialogue_knowledge = {}
	if not State.s.memory.has("dialogue_knowledge"): State.s.memory.dialogue_knowledge = {}
	if not State.s.memory.dialogue_knowledge.get(context.npc) is Dictionary: State.s.memory.dialogue_knowledge[context.npc] = {}
	for fact in trees[context.npc].nodes[id].get("reveals",[]):
		State.s.memory.dialogue_knowledge[context.npc][fact] = true
		if fact not in context.revealed: context.revealed.append(fact)
	context.quests = State.s.quests.duplicate(true); context.flags = State.s.flags.duplicate(true)
	return true
func back() -> bool:
	if context.is_empty(): return false
	var id: String = context.history.pop_back() if not context.history.is_empty() else "root"
	return enter(id,false)
func main() -> bool:
	context.history.clear(); return enter("root",false)
func choice(id: String) -> Dictionary:
	if context.is_empty(): return {}
	for option in node_for(context.npc,context.node).choices:
		if option.id == id: return option
	return {}
func record_question(id: String):
	if id not in context.questions: context.questions.append(id)
func execute(npc: String, action: Dictionary) -> String:
	if action.get("kind","") in ["accept","turn_in"]:
		if action.get("quest","") not in QUEST_OWNERS.get(npc,[]): return "That request does not belong to this villager."
		if action.kind == "accept": State.accept(action.quest); return "The work is recorded in your journal."
		if State.turn_in(action.quest,action.get("choice","return")): return "As promised: %d Crowns and 60 XP. Thank you."%State.quest_defs[action.quest].reward
		return "Not yet. "+State.quest_progress(action.quest)
	return ""
