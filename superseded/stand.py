#!/usr/bin/env python3
"""Bench stand for a 10.1in Raspberry Pi touch panel.

Two mirrored end feet, each a slotted wedge the panel's bottom edge drops into.
End feet (rather than one wide cradle) because the Pi bolts to the centre of the
display's back - the feet stay clear of it, and each part fits a 180mm bed.

Geometry is a single concave 2D profile extruded along the foot width, so the
whole thing is one prism: trivial to print flat-on-the-bed with no supports.

Writes binary STL. No dependencies.
"""
import math, struct

# ---- panel ---------------------------------------------------------------
# Waveshare 10.1in DSI LCD (C). MEASURE EDGE_T WITH CALIPERS BEFORE PRINTING -
# the published outline is 239 x 147 x 5 mm but that 5 mm is the bare panel,
# not the display board behind it.
EDGE_T   = 11.0   # thickness of the display assembly at its bottom edge
CLEAR    = 1.2    # slop so it drops in without forcing

# ---- stand ---------------------------------------------------------------
LEAN     = 15.0   # degrees back from vertical
DEPTH    = 100.0  # front-to-back footprint
HEIGHT   = 58.0   # height at the back
WIDTH    = 50.0   # how wide each foot is
SLOT_FLOOR = 14.0 # height of the slot floor above the bench
FRONT_X  = 30.0   # where the slot's front wall meets the lip
LIP_H    = 32.0   # height of the front lip (lower than HEIGHT, so it wedges)
TOE_H    = 6.0    # thickness at the very front edge
LIP_FLAT = 3.0    # flat on top of the lip - a knife edge would chip
REAR_H   = 12.0   # height at the back; the top tapers down to it

SLOT_W = EDGE_T + CLEAR


def profile():
    """Side-view outline, counter-clockwise, as (x=depth, y=height)."""
    th = math.radians(LEAN)
    rise = HEIGHT - SLOT_FLOOR
    lip_rise = LIP_H - SLOT_FLOOR
    dx = rise * math.tan(th)        # how far back the slot drifts over its depth
    horiz = SLOT_W / math.cos(th)   # slot width measured horizontally

    # Both slot walls are parallel lines leaning BACK at `th`, so x grows with
    # height. Going down from the lip the wall moves forward, hence the minus.
    fx_top = FRONT_X
    fx_bot = fx_top - lip_rise * math.tan(th)
    bx_bot = fx_bot + horiz
    bx_top = bx_bot + dx
    assert bx_bot < DEPTH - 6, 'slot runs out the back: %.1f' % bx_bot
    assert fx_top > 6, 'slot too close to the front'

    return [(0.0, 0.0), (DEPTH, 0.0), (DEPTH, REAR_H),
            (bx_top, HEIGHT), (bx_bot, SLOT_FLOOR),
            (fx_bot, SLOT_FLOOR), (fx_top, LIP_H), (fx_top - LIP_FLAT, LIP_H),
            (0.0, TOE_H)]


# ---- ear-clipping triangulation for a simple concave polygon -------------
def _area2(a, b, c):
    return (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0])

def _inside(p, a, b, c):
    d1, d2, d3 = _area2(p,a,b), _area2(p,b,c), _area2(p,c,a)
    neg = (d1 < 0) or (d2 < 0) or (d3 < 0)
    pos = (d1 > 0) or (d2 > 0) or (d3 > 0)
    return not (neg and pos)

def ensure_ccw(poly):
    s = sum((poly[(i+1) % len(poly)][0]-poly[i][0]) *
            (poly[(i+1) % len(poly)][1]+poly[i][1]) for i in range(len(poly)))
    return poly[::-1] if s > 0 else poly


def triangulate(poly):
    idx = list(range(len(poly)))
    tris, guard = [], 0
    while len(idx) > 2 and guard < 5000:
        guard += 1
        for k in range(len(idx)):
            i0, i1, i2 = idx[k-1], idx[k], idx[(k+1) % len(idx)]
            a, b, c = poly[i0], poly[i1], poly[i2]
            if _area2(a, b, c) <= 0:
                continue                      # reflex corner, not an ear
            if any(_inside(poly[j], a, b, c)
                   for j in idx if j not in (i0, i1, i2)):
                continue                      # another vertex is inside it
            tris.append((i0, i1, i2))
            idx.pop(k)
            break
        else:
            raise RuntimeError('triangulation stalled')
    return tris


def prism(poly, w):
    """Extrude the profile by w along +Z. Returns a list of triangles.

    Both feet are the same part - the prism is uniform across its width, so
    there is no left/right hand to it. Print two.
    """
    poly = ensure_ccw(poly)
    lo = [(x, y, 0.0) for (x, y) in poly]
    hi = [(x, y, w) for (x, y) in poly]
    tris = []
    for (i, j, k) in triangulate(poly):
        tris.append((hi[i], hi[j], hi[k]))      # top face, +Z
        tris.append((lo[k], lo[j], lo[i]))      # bottom face, -Z
    n = len(poly)
    for i in range(n):                           # side walls
        j = (i + 1) % n
        tris.append((lo[i], lo[j], hi[j]))
        tris.append((lo[i], hi[j], hi[i]))
    return tris


def write_stl(path, tris, name='stand'):
    with open(path, 'wb') as f:
        f.write(name.encode()[:80].ljust(80, b'\0'))
        f.write(struct.pack('<I', len(tris)))
        for (a, b, c) in tris:
            ux, uy, uz = (b[0]-a[0], b[1]-a[1], b[2]-a[2])
            vx, vy, vz = (c[0]-a[0], c[1]-a[1], c[2]-a[2])
            nx, ny, nz = (uy*vz-uz*vy, uz*vx-ux*vz, ux*vy-uy*vx)
            m = math.sqrt(nx*nx + ny*ny + nz*nz) or 1.0
            f.write(struct.pack('<3f', nx/m, ny/m, nz/m))
            for p in (a, b, c):
                f.write(struct.pack('<3f', *p))
            f.write(b'\0\0')
    return len(tris)


if __name__ == '__main__':
    p = profile()
    t = prism(p, WIDTH)
    path = '/home/cameron/pi-panel-stand/panel-stand-foot.stl'
    n = write_stl(path, t, 'pi-panel-stand-foot')
    print('%s  %d triangles  (print 2)' % (path, n))
    xs = [x for x, _ in p]; ys = [y for _, y in p]
    print('\nprofile bbox: %.1f x %.1f mm, extruded %.1f mm' %
          (max(xs)-min(xs), max(ys)-min(ys), WIDTH))
    print('slot: %.1f mm wide, %.0f deg lean, floor %.1f mm up'
          % (SLOT_W, LEAN, SLOT_FLOOR))
