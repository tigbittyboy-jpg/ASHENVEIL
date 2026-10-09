extends Node
signal reply(text: String)
var request: HTTPRequest
var current_npc := ""
var history: Array = []
var histories: Dictionary = {}
func _ready():
	request = HTTPRequest.new()
	request.timeout = 4.0
	add_child(request)
	request.request_completed.connect(_completed)
func fallback(id: String, question: String) -> String:
	var npc: Dictionary = State.npcs[id]
	var q := question.to_lower()
	if State.s.flags.get("boss",false): return npc.name+": The bell is silent at last. The shrine is waiting for you."
	if "forest" in q: return npc.name+": The sentinel holds the crypt sigil. Follow the eastern road, but watch the thorns."
	if "buy" in q or "potion" in q: return npc.name+": Use the trade choices below. Every purchase needs your confirmation."
	if "insult" in q or "fool" in q:
		State.s.memory[id+"_insult"] = true
		return npc.name+": I will remember that."
	if State.s.memory.get(id+"_insult",false): return npc.name+": I have not forgotten your cruelty. "+npc.line
	return npc.name+": "+npc.line
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
	# This authored parser creates only a proposal. It never executes a transaction.
	if not State.npcs.has(id) or State.npcs[id].role != "merchant": return {}
	var q := question.to_lower()
	if not "buy" in q and not "purchase" in q: return {}
	for item in State.items:
		if item in ["rust_sword","bellblade","ore","herb","key","ember"]: continue
		if item in q or State.items[item].name.to_lower() in q or (item == "potion" and "healing" in q):
			return {"kind":"purchase","item":item}
	return {}
