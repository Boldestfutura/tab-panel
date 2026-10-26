#!/usr/bin/env python3
"""Slice a print-oriented STL and find what would print in mid-air.

    python3 printcheck.py body.stl cover.stl coupon.stl

The STLs must be in print orientation, z up - which is how dock.scad exports
the parts. Layer by layer, it finds plastic that is not over the layer below
(grown by one cell, so a 45 degree slope counts as supported), then measures
how far that plastic has to reach across air from the nearest supported
point. That is the number that matters:

  ~7 mm    the zip-tie bar, a 13 mm bridge anchored at both ends
  ~11 mm   a 22 mm foot recess, bridged from its rim
  ~115 mm  Rev M's edge above the screen, 230 mm held only at the ends

  floating  nothing under it at all - always a failure
  REACH     further than MAX_REACH across air - a failure

This replaced overhang.py, which measured face angles and passed Rev M with
"nothing external overhangs". Rev M's edge above the screen was a 230 mm
ceiling with nothing under it. A face's angle cannot see that; a slice can.

Needs numpy.
"""
import heapq
import math
import sys
from collections import deque

import numpy as np

from check import load

LAYER = 0.3   # mm
CELL = 0.25   # mm, raster grid
REPORT = 15.0 # mm2: smaller unsupported patches are just the 45 degree slope
MAX_REACH = 15.0  # mm across air - a well-tuned bridge does more, a sag less


def section(tris, h, z, grid):
    """Rasterise the cross-section at height z by even-odd scanlines."""
    u0, v0, nu, nv = grid
    lo, hi = h.min(1), h.max(1)
    segs = []
    for t, hh in zip(tris[(lo < z) & (hi > z)], h[(lo < z) & (hi > z)]):
        p = []
        for i, j in ((0, 1), (1, 2), (2, 0)):
            if (hh[i] - z) * (hh[j] - z) < 0:
                f = (z - hh[i]) / (hh[j] - hh[i])
                p.append(t[i, :2] + f * (t[j, :2] - t[i, :2]))
        if len(p) == 2:
            segs.append(p)
    out = np.zeros((nu, nv), bool)
    if not segs:
        return out
    s = np.array(segs)
    a, b = s[:, 0], s[:, 1]
    for k in range(nv):
        v = v0 + (k + .5) * CELL
        c = (a[:, 1] - v) * (b[:, 1] - v) < 0
        if not c.any():
            continue
        f = (v - a[c, 1]) / (b[c, 1] - a[c, 1])
        x = np.sort(a[c, 0] + f * (b[c, 0] - a[c, 0]))
        for x0, x1 in zip(x[0::2], x[1::2]):
            i0 = int(np.ceil((x0 - u0) / CELL - .5))
            i1 = int(np.floor((x1 - u0) / CELL - .5))
            if i1 >= i0:
                out[max(i0, 0):i1 + 1, k] = True
    return out


def islands(g):
    lab = np.zeros(g.shape, int)
    n = 0
    for s in zip(*np.nonzero(g)):
        if lab[s]:
            continue
        n += 1
        lab[s] = n
        q = deque([s])
        while q:
            i, j = q.popleft()
            for a, b in ((i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)):
                if 0 <= a < g.shape[0] and 0 <= b < g.shape[1] and g[a, b] and not lab[a, b]:
                    lab[a, b] = n
                    q.append((a, b))
    return lab, n


def grow(g):
    o = g.copy()
    o[1:] |= g[:-1]; o[:-1] |= g[1:]; o[:, 1:] |= g[:, :-1]; o[:, :-1] |= g[:, 1:]
    return o


def reach(island, supported):
    """Furthest any cell of `island` is from a supported cell, in mm, going
    only through the island. None if nothing in it is supported."""
    src = np.argwhere(island & supported)
    if not len(src):
        return None
    dist = np.full(island.shape, np.inf)
    q = []
    for i, j in src:
        dist[i, j] = 0.0
        q.append((0.0, i, j))
    heapq.heapify(q)
    steps = [(a, b, math.hypot(a, b)) for a in (-1, 0, 1) for b in (-1, 0, 1) if a or b]
    while q:
        d, i, j = heapq.heappop(q)
        if d > dist[i, j]:
            continue
        for a, b, w in steps:
            x, y = i + a, j + b
            if 0 <= x < island.shape[0] and 0 <= y < island.shape[1] \
                    and island[x, y] and d + w < dist[x, y]:
                dist[x, y] = d + w
                heapq.heappush(q, (d + w, x, y))
    return dist[island].max() * CELL


def main(path):
    tris = np.array(load(path), dtype=float)
    h = tris[:, :, 2] - tris[:, :, 2].min()
    u0, v0 = tris[:, :, 0].min() - 1, tris[:, :, 1].min() - 1
    nu = int((tris[:, :, 0].max() - u0 + 1) / CELL) + 1
    nv = int((tris[:, :, 1].max() - v0 + 1) / CELL) + 1
    grid = (u0, v0, nu, nv)
    print("%s  (%.1f mm tall)" % (path, h.max()))
    bad, worst, prev, z = 0, 0.0, None, LAYER / 2
    while z < h.max():
        cur = section(tris, h, z, grid)
        if prev is not None:
            held = cur & grow(prev)
            loose = cur & ~held
            if loose.any():
                lab, n = islands(cur)
                for k in set(np.unique(lab[loose])) - {0}:
                    isl = lab == k
                    m = isl & loose
                    area = m.sum() * CELL * CELL
                    ii, jj = np.nonzero(m)
                    where = "x %.0f..%.0f  y %.0f..%.0f" % (
                        u0 + ii.min() * CELL, u0 + ii.max() * CELL,
                        v0 + jj.min() * CELL, v0 + jj.max() * CELL)
                    r = reach(isl, held)
                    if r is None:
                        bad += 1
                        print("   FLOATING  z=%5.1f  %7.1f mm2  %s" % (z, area, where))
                        continue
                    worst = max(worst, r)
                    if r > MAX_REACH:
                        bad += 1
                        print("   REACH     z=%5.1f  %5.1f mm over air  %s" % (z, r, where))
                    elif area >= REPORT:
                        print("   bridge    z=%5.1f  %5.1f mm over air  %s" % (z, r, where))
        prev = cur
        z += LAYER
    print("   %s - furthest reach over air %.1f mm (limit %.0f)\n"
          % ("ok" if not bad else "FAIL, %d layer(s)" % bad, worst, MAX_REACH))
    return bad


if __name__ == "__main__":
    sys.exit(1 if sum(main(p) for p in sys.argv[1:]) else 0)
