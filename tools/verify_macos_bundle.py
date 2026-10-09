"""Check built-in ad hoc CodeDirectory page hashes and sealed resource hashes.
This cross-platform inspection does not replace macOS codesign or Gatekeeper QA.
"""
import hashlib, plistlib, struct, sys, zipfile, tempfile
from pathlib import Path
archive=Path(sys.argv[1])
with tempfile.TemporaryDirectory() as tmp:
 with zipfile.ZipFile(archive) as z:
  assert z.testzip() is None, 'ZIP integrity failure'
  z.extractall(tmp)
 app=next(Path(tmp).glob('*.app'))
 contents=app/'Contents'
 info=plistlib.loads((contents/'Info.plist').read_bytes())
 binary=(contents/'MacOS'/info['CFBundleExecutable']).read_bytes()
 magic,count=struct.unpack_from('>II',binary)
 assert magic==0xcafebabe, 'Expected universal Mach-O'
 resource_manifest=(contents/'_CodeSignature/CodeResources').read_bytes()
 resources=plistlib.loads(resource_manifest)
 checked=0
 for name,entry in resources.get('files2',{}).items():
  if not isinstance(entry,dict):continue
  for key,algorithm in [('hash','sha1'),('hash2','sha256')]:
   if key in entry:
    data=(contents/name).read_bytes()
    assert hashlib.new(algorithm,data).digest()==entry[key], f'Resource hash mismatch: {name}'
    checked+=1
 assert checked>0, 'No sealed resources verified'
 for i in range(count):
  cpu,subcpu,offset,size,align=struct.unpack_from('>IIIII',binary,8+i*20)
  image=binary[offset:offset+size]
  assert struct.unpack_from('<I',image)[0]==0xfeedfacf
  commands=struct.unpack_from('<I',image,16)[0]
  cursor=32; signature=None
  for _ in range(commands):
   cmd,cmdsize=struct.unpack_from('<II',image,cursor)
   if cmd==0x1d:
    sigoff,sigsize=struct.unpack_from('<II',image,cursor+8)
    signature=image[sigoff:sigoff+sigsize]
   cursor+=cmdsize
  assert signature, 'Missing Mach-O code signature'
  blobmagic,bloblen,blobs=struct.unpack_from('>III',signature)
  assert blobmagic==0xfade0cc0
  cds=[]
  for j in range(blobs):
   slot,bloboffset=struct.unpack_from('>II',signature,12+j*8)
   if slot==0 or 0x1000<=slot<0x1006:cds.append(signature[bloboffset:])
  assert cds, 'Missing CodeDirectory'
  for cd in cds:
   (cdmagic,length,version,flags,hashoff,identoff,specialslots,codeslots,limit)=struct.unpack_from('>9I',cd)
   hashsize,hashtype,platform,page=struct.unpack_from('>4B',cd,36)
   assert cdmagic==0xfade0c02 and flags&2, 'Expected ad hoc signature'
   algorithm={1:'sha1',2:'sha256',3:'sha256',4:'sha384'}[hashtype]
   pagesize=1<<page
   assert codeslots==(limit+pagesize-1)//pagesize
   for n in range(codeslots):
    actual=hashlib.new(algorithm,image[n*pagesize:min((n+1)*pagesize,limit)]).digest()[:hashsize]
    assert actual==cd[hashoff+n*hashsize:hashoff+(n+1)*hashsize], f'Code page mismatch {n}'
   assert specialslots>=3
   assert hashlib.new(algorithm,resource_manifest).digest()[:hashsize]==cd[hashoff-3*hashsize:hashoff-2*hashsize], 'CodeResources seal mismatch'
   assert hashlib.new(algorithm,(contents/'Info.plist').read_bytes()).digest()[:hashsize]==cd[hashoff-hashsize:hashoff], 'Info.plist seal mismatch'
  print(f'PASS architecture {hex(cpu)}: ad hoc signature, {codeslots} code pages, Info.plist and CodeResources seals')
 print(f'PASS {checked} sealed resource hashes; ZIP integrity; app version {info["CFBundleShortVersionString"]}')
