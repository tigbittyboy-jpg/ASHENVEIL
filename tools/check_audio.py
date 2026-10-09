"""Validate generated waveform boundaries; subjective listening remains a playtest."""
from pathlib import Path
import struct,wave
root=Path(__file__).resolve().parents[1]/'assets'
for name in ['music','ambient','hit','swing','loot','bell','menu']:
 with wave.open(str(root/(name+'.wav'))) as w:
  samples=struct.unpack('<%dh'%w.getnframes(),w.readframes(w.getnframes()))
  duration=len(samples)/w.getframerate()
  jump=max(abs(b-a) for a,b in zip(samples,samples[1:]));wrap=abs(samples[0]-samples[-1])
  assert jump<1200 and wrap<=1,(name,jump,wrap)
  if name in ['music','ambient']:assert duration==32
  print(f'PASS {name}: {duration:.2f}s, maximum adjacent sample difference {jump}, boundary discontinuity {wrap}')
