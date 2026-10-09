import copy
import json
import sys
import unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from validate_dialogue import ROOT, validate, unique_object

class DialogueValidatorTests(unittest.TestCase):
    def setUp(self):
        self.trees=json.loads((ROOT/'data/dialogue_trees.json').read_text())
        self.npcs=json.loads((ROOT/'data/npcs.json').read_text())
        self.quests=json.loads((ROOT/'data/quests.json').read_text())
    def rejected(self, fragment):
        self.assertTrue(any(fragment in e for e in validate(self.trees,self.npcs,self.quests)))
    def test_authored_content_passes(self):
        self.assertEqual(validate(self.trees,self.npcs,self.quests),[])
    def test_duplicate_node_keys(self):
        with self.assertRaises(ValueError):
            json.loads('{"root":{},"root":{}}',object_pairs_hook=unique_object)
    def test_missing_node(self):
        del self.trees['brann']['nodes']['king']; self.rejected('invalid/cross-NPC target')
    def test_cross_npc_target(self):
        self.trees['brann']['nodes']['root']['choices'][0]['next']='mara/identity'; self.rejected('invalid/cross-NPC target')
    def test_duplicate_choice_id(self):
        choices=self.trees['brann']['nodes']['root']['choices']; choices[1]['id']=choices[0]['id']; self.rejected('duplicate choice IDs')
    def test_unreachable_node(self):
        self.trees['brann']['nodes']['stray']=copy.deepcopy(self.trees['brann']['nodes']['home']); self.rejected('unreachable nodes')
    def test_unrevealed_condition(self):
        self.trees['brann']['nodes']['root']['choices'][0]['condition']={'knowledge':'never_revealed'}; self.rejected('unrevealable knowledge')
    def test_invalid_quest(self):
        self.trees['brann']['nodes']['root']['choices'][0]['condition']={'quest':'missing','state':'active'}; self.rejected('invalid quest condition')
    def test_invalid_action(self):
        self.trees['brann']['nodes']['root']['choices'][0]['action']={'kind':'grant_crowns'}; self.rejected('invalid service/action')
    def test_invalid_quest_owner(self):
        self.trees['brann']['nodes']['root']['choices'][0]['action']={'kind':'accept','quest':'herbs'}; self.rejected('invalid quest owner')
    def test_missing_exit(self):
        node=self.trees['brann']['nodes']['home']; node['choices']=[c for c in node['choices'] if c['next']!='@exit']; self.rejected('missing goodbye')
    def test_unknown_condition(self):
        self.trees['brann']['nodes']['root']['choices'][0]['condition']={'keyword':'king'}; self.rejected('unknown condition fields')
    def test_unknown_world_flag(self):
        self.trees['brann']['nodes']['root']['choices'][0]['condition']={'flag':'boss_defeet_typo'}; self.rejected('unknown world flag')
    def test_foreign_choice_scope(self):
        self.trees['brann']['nodes']['root']['choices'][0]['id']='mara:root:0'; self.rejected('foreign choice ID')

if __name__=='__main__': unittest.main()
