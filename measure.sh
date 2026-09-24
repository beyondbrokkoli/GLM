#!/bin/bash
# measure.sh <binary> [outfile] — wall time + exact child peak RSS
# (getrusage after wait: no polling race for short runs)
if [ -n "$2" ]; then python3 - "$1" "$2" <<'PY'
import subprocess, resource, sys, time
t = time.time()
with open(sys.argv[2], "w") as f:
    p = subprocess.run(["./" + sys.argv[1]], stdout=f)
r = resource.getrusage(resource.RUSAGE_CHILDREN)
print(f"STAT wall_s={time.time()-t:.3f} peak_rss_kB={r.ru_maxrss}")
PY
else
python3 - "$1" <<'PY'
import subprocess, resource, sys, time
t = time.time()
p = subprocess.run(["./" + sys.argv[1]])
r = resource.getrusage(resource.RUSAGE_CHILDREN)
print(f"STAT wall_s={time.time()-t:.3f} peak_rss_kB={r.ru_maxrss}")
PY
fi
