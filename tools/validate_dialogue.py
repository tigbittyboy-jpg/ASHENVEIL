"""Validate canonical authored dialogue without overwriting it; no runtime dependencies."""
import json
from pathlib import Path
from collections import deque

ROOT = Path(__file__).resolve().parents[1]
OWNERS = {'brann': {'iron'}, 'sister': {'herbs'}, 'tovin': {'charm'}, 'ilya': {'bell', 'elites'}}
SERVICES = {'mara': {'shop', 'sell'}, 'brann': {'upgrade'}, 'sister': {'heal'}, 'nell': {'rest'}}
EXITS = {'@back', '@main', '@exit'}
WORLD_FLAGS = {'boss','ending','sentinel','lost_hound','crypt_knight'} | {f'explored_{m}' for m in ['village','forest','crypt','shrine']}
WORLD_FLAGS |= {f'forest{i}' for i in range(8)} | {f'crypt{i}' for i in range(6)}
WORLD_FLAGS |= {o['id'] for m in json.loads((ROOT/'data/maps.json').read_text()).values() for o in m['objects'] if o['kind'] in {'chest','herb'}}

def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'Duplicate JSON/node ID: {key}')
        result[key] = value
    return result

def validate(trees, npcs, quests):
    errors = []
    def require(ok, message):
        if not ok: errors.append(message)
    require(set(trees) == set(npcs), 'NPC tree IDs must match the NPC catalogue')
    for npc, tree in trees.items():
        nodes = tree.get('nodes', {})
        require('root' in nodes and tree.get('start') == 'root', f'{npc}: missing start/root')
        facts = {fact for node in nodes.values() for fact in node.get('reveals', [])}
        for node_id, node in nodes.items():
            location = f'{npc}/{node_id}'
            require(bool(node.get('text', '').strip()), f'{location}: empty NPC response')
            options = node.get('choices', [])
            require(bool(options), f'{location}: no responses/exits')
            require(any(c.get('next') == '@exit' and c.get('action', {}).get('kind') == 'goodbye' for c in options), f'{location}: missing goodbye')
            ids = [c.get('id') for c in options]
            require(all(isinstance(id,str) and id.startswith(npc+':'+node_id+':') for id in ids), f'{location}: foreign choice ID')
            require(None not in ids and len(ids) == len(set(ids)), f'{location}: missing/duplicate choice IDs')
            labels = [c.get('text') for c in options]
            require(None not in labels and len(labels) == len(set(labels)), f'{location}: missing/duplicate questions')
            for condition in [c.get('condition', {}) for c in options] + [v.get('condition', {}) for v in node.get('variants', [])]:
                require(isinstance(condition, dict), f'{location}: malformed condition')
                if not isinstance(condition, dict): continue
                require(not (set(condition)-{'quest','state','flag','memory','knowledge','not_knowledge'}), f'{location}: unknown condition fields')
                for key in ['flag','memory']:
                    if key in condition: require(isinstance(condition[key],str) and bool(condition[key]), f'{location}: invalid {key} condition')
                if 'flag' in condition: require(condition['flag'] in WORLD_FLAGS, f'{location}: unknown world flag')
                if 'memory' in condition: require(condition['memory'] in {n+suffix for n in npcs for suffix in ['_spoken','_insult']} | {'tovin_helped','tovin_betrayed','village_bell'}, f'{location}: unknown relationship memory')
                for key in ['knowledge','not_knowledge']:
                    if key in condition: require(condition[key] in facts, f'{location}: unrevealable knowledge {condition[key]}')
                if 'quest' in condition:
                    require(condition['quest'] in quests and condition.get('state') in {'absent','active','complete'}, f'{location}: invalid quest condition')
                if 'state' in condition: require('quest' in condition, f'{location}: status without quest')
                if condition.get('knowledge') == condition.get('not_knowledge') and 'knowledge' in condition:
                    errors.append(f'{location}: contradictory knowledge condition')
            for choice in options:
                target = choice.get('next')
                require(target in nodes or target in EXITS, f'{location}: invalid/cross-NPC target {target}')
                action = choice.get('action', {})
                kind = action.get('kind')
                if action:
                    require(kind in {'accept','turn_in','goodbye'} | SERVICES.get(npc,set()), f'{location}: invalid service/action {kind}')
                    if kind in {'accept','turn_in'}:
                        require(action.get('quest') in OWNERS.get(npc,set()), f'{location}: invalid quest owner')
                    if kind == 'goodbye': require(target == '@exit', f'{location}: goodbye must exit')
                elif target == '@exit': errors.append(f'{location}: exit without goodbye action')
        # Simulate explicit edges with evolving discoveries in three quest states.
        reached = set()
        for status in ['absent','active','complete']:
            pending = deque([('root',frozenset())]); visited = set()
            while pending:
                node_id, learned = pending.popleft()
                if node_id not in nodes: continue
                learned = learned | frozenset(nodes[node_id].get('reveals', []))
                state = (node_id,learned)
                if state in visited: continue
                visited.add(state); reached.add(node_id)
                for choice in nodes[node_id]['choices']:
                    condition = choice.get('condition',{})
                    if condition.get('quest') and condition['state'] != status: continue
                    if condition.get('knowledge') and condition['knowledge'] not in learned: continue
                    if condition.get('not_knowledge') in learned: continue
                    target = choice['next']
                    if target in nodes: pending.append((target,learned))
            require(bool(visited), f'{npc}: no simulated paths')
        require(not (set(nodes)-reached), f'{npc}: unreachable nodes {sorted(set(nodes)-reached)}')
    return errors

if __name__ == '__main__':
    trees = json.loads((ROOT/'data/dialogue_trees.json').read_text(),object_pairs_hook=unique_object)
    npcs = json.loads((ROOT/'data/npcs.json').read_text())
    quests = json.loads((ROOT/'data/quests.json').read_text())
    failures = validate(trees,npcs,quests)
    if failures: raise SystemExit('\n'.join(failures))
    print(f'PASS dialogue validator: {len(trees)} NPCs, {sum(len(t["nodes"]) for t in trees.values())} nodes; explicit paths and conditional discoveries valid')
