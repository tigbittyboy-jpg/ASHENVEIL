from PIL import Image, ImageDraw
from pathlib import Path
import random, wave, math, struct
root=Path(__file__).resolve().parents[1]/'assets'; root.mkdir(exist_ok=True)
random.seed(71)
pal={'grass':('#263d36','#324c40'),'stone':('#393c49','#50505d'),'dirt':('#453e3b','#5c4d40'),'shrine':('#31394e','#4c5270')}
for name,colors in pal.items():
 im=Image.new('RGBA',(16,16),colors[0]); d=ImageDraw.Draw(im)
 for i in range(28):
  x,y=random.randrange(16),random.randrange(16); d.line((x,y,x+1,y),fill=colors[1])
 if name=='stone':d.line((0,7,15,7),fill='#242831');d.line((8,0,8,6),fill='#242831')
 im.save(root/(name+'.png'))
colors={'player':'#b2c1b0','wanderer':'#7d997e','hound':'#886b75','cultist':'#965e91','guardian':'#aaa9bd','wraith':'#72b5bf','knight':'#b68b72','boss':'#c0a682','npc':'#ceab86'}
for name,color in colors.items():
 im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
 d.ellipse((6,25,27,30),fill='#111b24aa')
 if name=='hound':
  d.polygon([(4,22),(8,14),(22,12),(28,18),(25,24),(10,25)],fill=color);d.polygon([(21,12),(22,5),(26,13)],fill=color);d.rectangle((25,17,27,18),fill='#efcf86')
 else:
  d.polygon([(10,12),(22,12),(26,26),(7,26)],fill=color);d.rectangle((11,4,21,13),fill='#252b39');d.rectangle((12,5,20,10),fill=color);d.rectangle((13,8,14,9),fill='#f7daaa');d.rectangle((18,8,19,9),fill='#f7daaa');d.rectangle((10,27,13,29),fill='#63585c');d.rectangle((19,27,22,29),fill='#63585c')
  d.line((8,15,5,23),fill='#c2b5a0',width=2);d.line((24,15,27,23),fill='#c2b5a0',width=2)
  if name in ['guardian','knight','player']:d.line((27,10,27,26),fill='#d9d7c8',width=2)
  if name=='boss':d.arc((3,0,29,20),180,360,fill='#d9ba83',width=3);d.rectangle((7,16,25,19),fill='#675567')
 im.save(root/(name+'.png'))
for name in ['tree','grave','chest','checkpoint','door']:
 im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
 if name=='tree':
  d.rectangle((14,14,18,31),fill='#65534b')
  for bounds in [(2,6,29,23),(5,0,27,17),(7,4,23,13)]:d.ellipse(bounds,fill=['#20382f','#2d493b','#3b5741'][[(2,6,29,23),(5,0,27,17),(7,4,23,13)].index(bounds)])
 elif name=='grave':d.rounded_rectangle((8,8,24,30),radius=5,fill='#6c6d78');d.line((16,12,16,25),fill='#363744',width=2);d.line((11,17,21,17),fill='#363744',width=2)
 elif name=='chest':d.rectangle((5,12,27,27),fill='#876644');d.arc((5,5,27,23),180,360,fill='#d2a36a',width=4);d.rectangle((5,17,27,19),fill='#cfab72');d.rectangle((15,16,18,22),fill='#ead08b')
 elif name=='checkpoint':d.polygon([(16,1),(24,16),(17,28),(8,17)],fill='#8ac9c6');d.polygon([(16,3),(16,24),(10,16)],fill='#cee2c8');d.ellipse((5,27,28,31),fill='#717f88')
 else:d.rounded_rectangle((4,0,28,31),radius=10,fill='#767181');d.rounded_rectangle((8,5,24,31),radius=8,fill='#181e2b');d.rectangle((15,14,17,31),fill='#baa17a')
 im.save(root/(name+'.png'))
for name,freq in [('hit',140),('swing',310),('loot',660),('bell',90),('menu',440),('ambient',55)]:
 duration=4 if name=='ambient' else .22
 with wave.open(str(root/(name+'.wav')),'w') as w:
  w.setparams((1,2,22050,0,'NONE','not compressed'))
  for n in range(int(22050*duration)):
   t=n/22050; envelope=(1-t/duration)**2 if name!='ambient' else .35
   value=(math.sin(t*freq*math.tau)+.3*math.sin(t*freq*1.501*math.tau))*envelope*.18
   w.writeframesraw(struct.pack('<h',int(value*32767)))
print('Generated original pixel sprites, terrain, props and synthesized audio.')
# Village masonry and layered shingle roof.
im=Image.new('RGBA',(64,48)); d=ImageDraw.Draw(im)
d.rectangle((7,16,57,45),fill='#776d6b'); d.rectangle((10,18,54,45),fill='#5a555b')
for y in range(20,45,7):
 d.line((10,y,54,y),fill='#443e4a')
 for x in range(10+(4 if y%2 else 0),54,11): d.line((x,y,x,y+7),fill='#443e4a')
d.polygon([(2,18),(14,1),(50,1),(62,18)],fill='#494456')
for y in range(3,18,4):d.line((12-y//2,y,52+y//2,y),fill='#726271')
d.rectangle((27,26,37,47),fill='#242431'); d.arc((27,22,37,30),180,360,fill='#b8a37c',width=2)
for x in [14,43]:
 d.rectangle((x,24,x+7,33),fill='#d8b781'); d.line((x+3,24,x+3,33),fill='#413744'); d.line((x,28,x+7,28),fill='#413744')
d.rectangle((48,0,54,10),fill='#736a70'); im.save(root/'house.png')
# Original eight-second minor-key ambient motif; not derived from an existing song.
with wave.open(str(root/'music.wav'),'w') as w:
 w.setparams((1,2,22050,0,'NONE','not compressed'))
 notes=[110,130.8128,164.8138,146.8324,110,98,130.8128,82.4069]
 for n in range(22050*8):
  t=n/22050; note=notes[int(t)]; u=t%1
  value=(math.sin(t*note*math.tau)*.65+math.sin(t*note*2*math.tau)*.15)*math.sin(u*math.pi)**2*.1
  w.writeframesraw(struct.pack('<h',int(value*32767)))

# Finish with the current environmental art and seamless audio revision.
import runpy
runpy.run_path(str(Path(__file__).with_name("refine_assets.py")))
