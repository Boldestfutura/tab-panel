"""Load an STL (ascii or binary), report manifold-ness, volume and bbox."""
import struct, collections, sys

def load(p):
    raw = open(p, 'rb').read(512)
    if raw[:5] == b'solid' and b'facet' in raw:
        tris, cur = [], []
        for ln in open(p, encoding='utf-8', errors='replace'):
            ln = ln.strip()
            if ln.startswith('vertex'):
                cur.append(tuple(float(v) for v in ln.split()[1:4]))
                if len(cur) == 3:
                    tris.append(cur); cur = []
        return tris
    with open(p, 'rb') as f:
        f.read(80); n = struct.unpack('<I', f.read(4))[0]; t = []
        for _ in range(n):
            f.read(12)
            t.append([struct.unpack('<3f', f.read(12)) for _ in range(3)])
            f.read(2)
    return t

def report(p):
    tris = load(p)
    # 3dp merged genuinely distinct vertices on dense meshes and reported
    # false non-manifold edges. 4dp is below any real print tolerance and
    # still well inside STL float precision.
    k = lambda q: tuple(round(c, 4) for c in q)
    e = collections.Counter()
    for t in tris:
        for i in range(3):
            e[frozenset((k(t[i]), k(t[(i + 1) % 3])))] += 1
    bad = [x for x, c in e.items() if c != 2]
    vol = sum((a[0]*(b[1]*c[2]-b[2]*c[1]) - a[1]*(b[0]*c[2]-b[2]*c[0])
               + a[2]*(b[0]*c[1]-b[1]*c[0])) / 6 for a, b, c in tris)
    xs = [q[0] for t in tris for q in t]
    ys = [q[1] for t in tris for q in t]
    zs = [q[2] for t in tris for q in t]
    print('%-22s tri=%-6d manifold=%-4s vol=%7.1f cm3  bbox %.0f x %.0f x %.0f mm'
          % (p, len(tris), 'yes' if not bad else 'NO', vol / 1000,
             max(xs)-min(xs), max(ys)-min(ys), max(zs)-min(zs)))
    return vol / 1000

if __name__ == '__main__':
    for p in sys.argv[1:]:
        v = report(p)
        print('%-22s a 2.4 mm shell prints near-solid: ~%.0f g of PLA' % ('', v * 1.24))
