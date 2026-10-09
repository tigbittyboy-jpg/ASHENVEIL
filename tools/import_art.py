"""Deterministic atlas extraction and size normalization for original generated art.
The source atlas uses manually inspected row boundaries (not guessed equal rows).
"""
from pathlib import Path
from PIL import Image
import shutil
root=Path(__file__).resolve().parents[1]
source=root/'assets/source/gothic_atlas.png'
if not source.exists(): raise FileNotFoundError(source)
im=Image.open(source).convert('RGBA')
rows=[0,160,350,530,710,883,1045,1138,1254]
cols=[0,155,318,470,630,785,942,1100,1254]
def extract(row,col,path,size=(64,64),bounds=None):
 crop=im.crop(bounds or (cols[col],rows[row],cols[col+1],rows[row+1]))
 bbox=crop.getbbox()
 if not bbox:raise ValueError(path)
 crop=crop.crop(bbox); crop.thumbnail((size[0]-8,size[1]-8),Image.Resampling.NEAREST)
 out=Image.new('RGBA',size);out.alpha_composite(crop,((size[0]-crop.width)//2,size[1]-crop.height-4))
 target=root/'assets'/path;target.parent.mkdir(parents=True,exist_ok=True);out.save(target)
for i in range(8):extract(0,i,f'player/direction_{i}.png')
shutil.copyfile(root/'assets/player/direction_0.png',root/'assets/player.png')
ids=['mara','brann','sister','nell','ilya','osric','tovin','vesper']
for i,id in enumerate(ids):
 extract(1,i,f'npcs/{id}.png');extract(5,i,f'portraits/{id}.png',(128,128))
for i,id in enumerate(['wanderer','hound','cultist','guardian','wraith','knight','boss','statue']):
 bounds=(908,350,1138,530) if id=='boss' else ((1138,350,1254,530) if id=='statue' else None)
 extract(2,i,id+'.png',(128,128) if id in ['boss','statue'] else (64,64),bounds)
for i,id in enumerate(['inn','forgehouse','chapel','cottage','tower','stall','well','door']):extract(3,i,'buildings/'+id+'.png',(256,192) if i<5 else (128,128))
for i,id in enumerate(['tree','dead_tree','rock','sarcophagus','grave','chest','torch','shrine_altar']):extract(4,i,id+'.png',(128,128))
for i,id in enumerate(['sword','dagger','axe','staff','bow','potion','ore','charm']):extract(6,i,'icons/'+id+'.png',(48,48))
for i,id in enumerate(['cart','banner','sign','herb','reeds','column','gate','checkpoint']):extract(7,i,id+'.png',(96,96))
# Stable names used by existing world interactions.
shutil.copyfile(root/'assets/buildings/stall.png',root/'assets/stall.png')
shutil.copyfile(root/'assets/buildings/well.png',root/'assets/well.png')
shutil.copyfile(root/'assets/buildings/door.png',root/'assets/door.png')
shutil.copyfile(root/'assets/buildings/tower.png',root/'assets/ruin.png')
shutil.copyfile(root/'assets/buildings/forgehouse.png',root/'assets/forge.png')
print('Imported original detailed actors, eight portraits, buildings, props and icons.')

terrain=Image.open(root/'assets/source/terrain_atlas.png').convert('RGBA')
for row,names in enumerate([['grass','cobble','dirt','water'],['stone','mud','ash','shrine'],['masonry','roof','timber','crag'],['leaves','gravel','planks','ritual']]):
 for col,name in enumerate(names):
  cell=terrain.crop((round(col*terrain.width/4),round(row*terrain.height/4),round((col+1)*terrain.width/4),round((row+1)*terrain.height/4)))
  # Downsample to discrete game pixels; each complete tile is drawn at 48 logical pixels.
  cell.resize((192,192) if name=='ritual' else (48,48),Image.Resampling.NEAREST if name=='ritual' else Image.Resampling.LANCZOS).save(root/'assets'/f'{name}.png')
Image.blend(Image.open(root/'assets/grass.png'),Image.open(root/'assets/leaves.png'),.3).save(root/'assets/moss.png')
print('Imported sixteen dark terrain materials and a leafy forest floor.')

actor=Image.open(root/'assets/source/player_animation_atlas.png').convert('RGBA')
for row in range(8):
 for col in range(8):
  crop=actor.crop((round(col*actor.width/8),round(row*actor.height/8),round((col+1)*actor.width/8),round((row+1)*actor.height/8)))
  box=crop.getbbox()
  if not box: raise ValueError(f'Empty actor frame {row},{col}')
  crop=crop.crop(box)
  factor=56/(actor.height/8)
  crop=crop.resize((max(1,round(crop.width*factor)),max(1,round(crop.height*factor))),Image.Resampling.NEAREST)
  out=Image.new('RGBA',(64,64));out.alpha_composite(crop,((64-crop.width)//2,60-crop.height))
  out.save(root/'assets/player'/f'action_{row}_{col}.png')
  if row==0:out.save(root/'assets/player'/f'direction_{col}.png')
shutil.copyfile(root/'assets/player/direction_0.png',root/'assets/player.png')
print('Imported 64 directional idle, walk, attack, dodge and hit frames.')
