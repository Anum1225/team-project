"""Read-only inventory: records folder sizes and static Dart reachability.

Does not remove files. Unreachable modules are review candidates, not proof that
they are obsolete: role export entry points and tooling may be intentional.
"""
from pathlib import Path
import hashlib
import json
import os
import re
import zipfile

ROOT = Path(__file__).resolve().parents[2]
APK = Path('C:/Users/pc/Downloads/base.apk')
lib = ROOT/'lib'
edges = re.compile(r"\b(?:import|export|part)\s+['\"]([^'\"]+)['\"]")
seen=set()
def visit(p):
    p=p.resolve()
    if p in seen or not p.is_file() or not p.is_relative_to(lib): return
    seen.add(p)
    for uri in edges.findall(p.read_text(encoding='utf-8')):
        if uri.startswith('package:untitled/'):
            visit(lib/uri[len('package:untitled/'):])
        elif ':' not in uri:
            visit(p.parent/uri)
visit(lib/'main.dart')
unreachable=[p.relative_to(ROOT).as_posix() for p in lib.rglob('*.dart') if p.resolve() not in seen]
def size(p):
    if p.is_file(): return {'files':1,'bytes':p.stat().st_size}
    count=total=0
    for parent, dirs, files in os.walk(p,followlinks=False):
        dirs[:]=[d for d in dirs if not (Path(parent)/d).is_symlink()]
        for f in files:
            try:
                item=Path(parent)/f
                if not item.is_symlink(): total+=item.stat().st_size; count+=1
            except OSError: pass
    return {'files':count,'bytes':total}
items={p.name:size(p) for p in sorted(ROOT.iterdir())}
with zipfile.ZipFile(APK) as z:
    packaged=sorted(n.removeprefix('assets/flutter_assets/') for n in z.namelist() if n.startswith('assets/flutter_assets/assets/'))
result={'root':str(ROOT),'apk':{'path':str(APK),'sha256':hashlib.file_digest(APK.open('rb'),'sha256').hexdigest(),'packaged_assets':packaged},'inventory':items,'reachable_dart_files':len(seen),'not_reached_from_main':unreachable,'deleted':False}
out=ROOT/'docs/audits/project-file-inventory-2026-09-27.json'
out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'inventory':items,'reachable':len(seen),'unreachable':unreachable,'apkHash':result['apk']['sha256'],'assetsInApk':len(packaged)},indent=2))
