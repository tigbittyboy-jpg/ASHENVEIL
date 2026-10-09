extends Node
signal reply(text: String)
var request: HTTPRequest
var current_npc := ""
var history: Array = []
var histories: Dictionary = {}
var profiles: Dictionary
func _ready():
	profiles = State.read_data("dialogue")
	request = HTTPRequest.new()
	request.timeout = 4.0
	add_child(request)
	request.request_completed.connect(_completed)
func fallback(id: String, question: String) -> String:
	var npc: Dictionary = State.npcs[id]
	var q := question.strip_edges().to_lower()
	var answer: String = npc.line
	if q == "": return npc.name+": "+answer
	if "insult" in q or "fool" in q:
		State.s.memory[id+"_insult"] = true
		return npc.name+": I will remember that. Speak plainly if you want my help."
	if "name" in q or "who are you" in q or "yourself" in q:
		answer = "I am %s, the village %s. %s" % [npc.name,npc.role,npc.line]
	elif "forest" in q or "sigil" in q or "key" in q or "crypt" in q:
		answer = "The forest sentinel holds the crypt sigil. Follow the eastern road, then enter the stone gate. Herbs grow off the path; the lost hound prowls the southwest hollow."
	elif "boss" in q or "bell" in q or "fight" in q:
		answer = "The bell is silent. Visit the shrine beyond its guardian's chamber." if State.s.flags.get("boss",false) else "The Bellkeeper marks the ground before striking. Leave the orange circle, then hit during recovery. A dodge can carry you clear; his waves have gaps."
	elif "memory" in q or "past" in q or "veil" in q or "shrine" in q:
		answer = profiles[id].past if "past" in q or "memory" in q else profiles[id].veil
	elif "quest" in q or "work" in q or "help" in q or "reward" in q:
		var quests := {"sister":"herbs","brann":"iron","tovin":"charm","ilya":"bell"}
		if quests.has(id):
			var quest: String = quests[id]
			answer = State.quest_defs[quest].text + " Reward: %d Crowns and 60 XP. " % State.quest_defs[quest].reward + State.quest_progress(quest) + ". Ask to accept, or use the choices below."
		else: answer = "Ilya needs help with the bell. Elowen needs three herbs; Brann needs three Grave Iron; Tovin seeks his brother's charm. Ask each of them about work."
	elif "herb" in q or "healing" in q or "wound" in q:
		answer = "Bring three Weeping Herbs to Elowen's chapel. She pays 35 Crowns and 60 XP; she also heals wounds for eight Crowns."
	elif "iron" in q or "upgrade" in q or "weapon" in q:
		answer = "Brann works by the forge west of the square. Upgrades cost 25 Crowns times the next upgrade level, and that many Grave Iron. His iron delivery quest pays 40 Crowns and 60 XP."
	elif "charm" in q or "brother" in q:
		answer = "My brother's Silver Charm is in the southwest forest chest. Return it or admit you want to keep it. I pay 40 Crowns and 60 XP either way, but I will remember your choice." if id == "tovin" else "Tovin seeks a Silver Charm in the southwest forest chest. Speak with him after you find it."
	elif "buy" in q or "shop" in q or "potion" in q or "sell" in q:
		answer = "Mara's stall is beside the square. Type 'buy potion' to her, then confirm the purchase. Sell spare equipment through your inventory."
	elif "rest" in q or "inn" in q or "rumor" in q:
		answer = "Nell's inn stands north of the square. Five Crowns buys rest and a save. The blue crystals heal for free."
	elif "hello" in q or "hi" == q or "thank" in q:
		answer = "You are welcome here. Ask about work, the forest, the bell, or my past."
	else:
		answer = "I do not know what you mean by that. Ask me about work, the forest, the bell, my name or the Veil. "+npc.line
	if id == "tovin" and State.s.memory.get("tovin_helped",false): answer += " You returned my brother's charm. Thank you."
	if id == "tovin" and State.s.memory.get("tovin_betrayed",false): answer += " I still remember that you kept his charm."
	return npc.name+": "+answer
func ask(id: String, question: String):
	cancel()
	current_npc = id
	history = histories.get(id,[])
	if not State.s.settings.ollama:
		reply.emit(fallback(id,question)); return
	var prompt: String = "You are "+State.npcs[id].name+" in a dark fantasy village. "+State.npcs[id].line+" Reply in under 80 words. You cannot grant items, rewards, or change game state. Facts: Bellkeeper defeated="+str(State.s.flags.get("boss",false))+". Player asks: "+question.left(300)+" Previous questions: "+JSON.stringify(history)+" Validated memories: "+JSON.stringify(State.s.memory)
	var error := request.request("http://127.0.0.1:11434/api/generate",["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify({"model":"llama3.2","prompt":prompt,"stream":false,"options":{"num_predict":100}}))
	history.append(question.left(300))
	if history.size() > 6: history.pop_front()
	histories[id] = history
	if error != OK: reply.emit(fallback(id,question))
func cancel():
	if request: request.cancel_request()
func _completed(result, code, _headers, body):
	var parser := JSON.new()
	var parsed = null
	if parser.parse(body.get_string_from_utf8()) == OK: parsed = parser.data
	if result == HTTPRequest.RESULT_SUCCESS and code == 200 and parsed is Dictionary and parsed.has("response"):
		reply.emit(State.npcs[current_npc].name+": "+str(parsed.response).left(600))
	else: reply.emit(fallback(current_npc,history.back() if not history.is_empty() else ""))
func intent_for(id: String, question: String) -> Dictionary:
	if not State.npcs.has(id): return {}
	var q := question.strip_edges().to_lower()
	var quests := {"sister":"herbs","brann":"iron","tovin":"charm","ilya":"bell"}
	if quests.has(id):
		var quest: String = "elites" if id == "ilya" and ("elite" in q or "souls" in q) else quests[id]
		if "accept" in q or "take the quest" in q or "i will help" in q: return {"kind":"quest_accept","quest":quest}
		if "deliver" in q or "turn in" in q or "return" in q or "i have" in q or (id == "tovin" and "keep" in q):
			return {"kind":"quest_turnin","quest":quest,"choice":"keep" if "keep" in q else "return"}
	if id == "sister" and ("heal me" in q or "heal please" in q): return {"kind":"heal"}
	if id == "brann" and "upgrade" in q: return {"kind":"upgrade"}
	if id == "nell" and ("rest" in q or "sleep" in q): return {"kind":"rest"}
	if id != "mara": return {}
	if "shop" in q or "wares" in q: return {"kind":"shop"}
	if not "buy" in q and not "purchase" in q and not "can i get" in q and not "do you have" in q: return {}
	for item in State.items:
		if item in ["rust_sword","bellblade","ore","herb","key","ember"]: continue
		if item in q or State.items[item].name.to_lower() in q or (item == "potion" and "healing" in q): return {"kind":"purchase","item":item}
	return {}
