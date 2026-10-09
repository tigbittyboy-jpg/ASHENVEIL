"""Reproducible environmental dressing and smooth original ambient soundtrack."""
from PIL import Image, ImageDraw
from pathlib import Path
import math, random, wave, struct
root=Path(__file__).resolve().parents[1]/'assets'
rng=random.Random(801)
for name in ['water','cobble','mud','moss','ash']:
 colors={'water':('#14222c','#223540'),'cobble':('#30343c','#484951'),'mud':('#282823','#39372f'),'moss':('#202d29','#2b3931'),'ash':('#25252f','#363441')}
 im=Image.new('RGBA',(16,16),colors[name][0]);d=ImageDraw.Draw(im)
 if name=='cobble':
  for y in range(0,16,4):
   for x in range(-3 if y%8 else 0,16,6):d.rounded_rectangle((x,y,x+4,y+2),radius=1,fill=colors[name][1])
 else:
  for i in range(22):
   x,y=rng.randrange(16),rng.randrange(16);d.line((x,y,x+2,y),fill=colors[name][1])
 im.save(root/(name+'.png'))
for name in ['well','forge','stall','cart','rock','ruin','torch','banner','sign','reeds','herb']:
 im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
 if name=='well':
  d.ellipse((3,13,29,29),fill='#656471');d.ellipse((6,15,26,22),fill='#18232c');d.rectangle((5,3,7,23),fill='#6c5545');d.rectangle((25,3,27,23),fill='#6c5545');d.line((5,4,27,4),fill='#aa9070',width=3)
 elif name=='forge':
  d.rectangle((3,9,27,29),fill='#505160');d.rectangle((7,14,23,26),fill='#191b24');d.polygon([(9,23),(12,14),(16,22),(20,12),(22,25)],fill='#bb683f');d.rectangle((13,2,22,10),fill='#454451');d.rectangle((1,26,30,31),fill='#77717a')
 elif name=='stall':
  d.rectangle((5,9,7,29),fill='#8c7458');d.rectangle((25,9,27,29),fill='#8c7458');d.polygon([(1,10),(6,2),(26,2),(31,10)],fill='#745364');d.rectangle((3,20,29,25),fill='#746047');d.rectangle((8,17,12,20),fill='#cba47b');d.ellipse((18,15,22,20),fill='#789586')
 elif name=='cart':
  d.rectangle((5,8,28,24),fill='#655246');d.line((5,13,28,13),fill='#a0845c');d.ellipse((6,23,12,30),fill='#a18b68');d.ellipse((21,23,28,30),fill='#a18b68');d.line((0,27,6,22),fill='#9f815e',width=2)
 elif name in ['rock','ruin']:
  d.polygon([(3,27),(7,13),(16,8),(25,13),(29,27)],fill='#484957');d.line((9,15,21,12),fill='#696678',width=2)
  if name=='ruin':d.rectangle((8,1,13,20),fill='#595565');d.rectangle((20,3,24,22),fill='#595565');d.line((10,9,23,9),fill='#85757c',width=3)
 elif name=='torch':
  d.rectangle((14,14,17,31),fill='#75523a');d.polygon([(10,15),(12,6),(15,11),(18,1),(22,15),(17,20)],fill='#c07845');d.polygon([(14,14),(17,7),(19,15),(16,18)],fill='#efd79c')
 elif name=='banner':
  d.rectangle((4,0,6,31),fill='#a08a66');d.polygon([(7,2),(26,2),(26,23),(21,20),(17,25),(11,21),(7,23)],fill='#674958');d.line((14,6,14,18),fill='#b69b75',width=2);d.line((10,12,19,12),fill='#b69b75',width=2)
 elif name=='sign':
  d.rectangle((14,12,17,31),fill='#625442');d.rectangle((2,2,30,15),fill='#8b7251');d.line((6,7,25,7),fill='#3b3434');d.line((7,11,22,11),fill='#3b3434')
 elif name=='reeds':
  for x in [7,11,16,22]:d.line((x,30,x-2,12+x%8),fill='#62704d',width=1);d.line((x-2,12+x%8,x-2,18+x%8),fill='#8b8053',width=2)
 elif name=='herb':
  d.line((16,29,16,12),fill='#46614b',width=2)
  for box in [(5,14,15,20),(17,11,26,17),(6,21,16,26)]:d.ellipse(box,fill='#6b8860')
  d.ellipse((13,8,18,13),fill='#bba992')
 im.save(root/(name+'.png'))
im=Image.new('RGBA',(128,128));px=im.load()
for y in range(128):
 for x in range(128):
  r=math.hypot(x-63.5,y-63.5)/64;v=max(0,1-r)**2
  px[x,y]=(255,237,202,int(255*v))
im.save(root/'glow.png')
# Long, subdued minor chords and distant bell partials. All frequencies complete an
# integer number of cycles over the loop, so endpoints and derivatives meet.
rate=22050;duration=32;n=rate*duration
notes=[(55,82.5,110),(49,73.5,98),(44,66,88),(49,73.5,98)]
for name in ['music','ambient']:
 values=[]
 for i in range(n):
  t=i/rate;v=0.
  if name=='music':
   for chord,frequencies in enumerate(notes):
    center=chord*8+4;dist=abs((t-center+16)%32-16)
    envelope=max(0,math.cos(min(1,dist/8)*math.pi/2))**3
    for f in frequencies:
     f=round(f*duration)/duration
     v+=math.sin(2*math.pi*f*t)*envelope*.022
   for start,freq in [(2,220),(12,196),(22,165)]:
    u=(t-start)%duration
    envelope=(1-math.exp(-u*12))*math.exp(-u*.7)*(1-math.exp(-(duration-u)*12))
    v+=envelope*(math.sin(math.tau*freq*t)+.2*math.sin(math.tau*freq*2*t))*.025
  else:
   for f in [40,55,73.5]:v+=math.sin(math.tau*f*t)*(.009+.003*math.cos(math.tau*t/duration))
  values.append(int(max(-1,min(1,v))*32767))
 # Avoid any loop discontinuity introduced by finite precision.
 values[-1]=values[0]
 with wave.open(str(root/(name+'.wav')),'w') as w:
  w.setparams((1,2,rate,0,'NONE','not compressed'));w.writeframes(struct.pack('<%dh'%len(values),*values))
# Attack/impact envelopes start and finish at zero instead of abrupt retriggered waves.
for name,freq in [('hit',140),('swing',310),('loot',660),('bell',90),('menu',440)]:
 length=int(rate*.25);values=[]
 for i in range(length):
  u=i/(length-1);t=i/rate
  envelope=math.sin(math.pi*u)**2*(1-u)
  values.append(int(math.sin(math.tau*freq*t)*envelope*.12*32767))
 with wave.open(str(root/(name+'.wav')),'w') as w:
  w.setparams((1,2,rate,0,'NONE','not compressed'));w.writeframes(struct.pack('<%dh'%len(values),*values))
print('Generated detailed props and smooth 32-second audio loops.')
