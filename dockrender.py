#!/usr/bin/env python3
"""Render the dock. Z-buffered flat shading to PNG, stdlib only."""
import struct, zlib, math, sys
from check import load as load_stl

LEAN = math.radians(15)
S, C = math.sin(LEAN), math.cos(LEAN)
PANEL_W, PANEL_H, PANEL_T = 239.0, 147.0, 11.0
FRAME_W, LIP_PROUD, VHB_T = 3.0, 0.8, 1.1
LIP_H = 9.0
BASE_D = 78.0

COLOUR = {'pla': (228, 229, 233), 'case': (58, 63, 74),
          'screen': (20, 25, 34), 'floor': (236, 233, 227)}

def panel_tris():
    """The display, bonded to the front face and sitting on the lip."""
    up, fwd = (S, C), (-C, S)
    # pocket floor is lip_proud+vhb behind the outer face; panel starts
    # frame_w up the face
    d0 = FRAME_W
    back = LIP_PROUD + VHB_T
    bx = d0 * S - back * (-C)
    by = LIP_H + d0 * C - back * S
    def P(u, v, z):
        return (bx + up[0]*u + fwd[0]*v, by + up[1]*u + fwd[1]*v, z)
    pv = {}
    for a, u in ((0, 0.0), (1, PANEL_H)):
        for b, v in ((0, 0.0), (1, PANEL_T)):
            for c, z in ((0, -PANEL_W/2), (1, PANEL_W/2)):
                pv[(a, b, c)] = P(u, v, z)
    def q(p, r, s, t, tag):
        # Emit both windings. The dock comes from a verified-manifold STL, but
        # hand-written quads are easy to wind inconsistently, and with backface
        # culling on a wrong-wound face disappears entirely. The z-buffer keeps
        # whichever copy faces the camera.
        a, b, c, d = pv[p], pv[r], pv[s], pv[t]
        return [((a, b, c), tag), ((a, c, d), tag),
                ((c, b, a), tag), ((d, c, a), tag)]
    out  = q((0,1,0),(1,1,0),(1,1,1),(0,1,1), 'screen')   # the glass
    out += q((0,0,0),(0,0,1),(1,0,1),(1,0,0), 'case')     # bonded face
    out += q((0,0,0),(1,0,0),(1,1,0),(0,1,0), 'case')
    out += q((0,0,1),(0,1,1),(1,1,1),(1,0,1), 'case')
    out += q((0,0,0),(0,1,0),(0,1,1),(0,0,1), 'case')     # bottom edge
    out += q((1,0,0),(1,0,1),(1,1,1),(1,1,0), 'case')     # top edge
    return out

def ground(y=0.0, ext=1100):
    v = [(-ext, y, -ext), (ext, y, -ext), (ext, y, ext), (-ext, y, ext)]
    return [((v[0], v[2], v[1]), 'floor'), ((v[0], v[3], v[2]), 'floor')]

def look(p, yaw, pitch, dist, t):
    x, y, z = p[0]-t[0], p[1]-t[1], p[2]-t[2]
    cy, sy = math.cos(yaw), math.sin(yaw);  x, z = x*cy + z*sy, -x*sy + z*cy
    cp, sp = math.cos(-pitch), math.sin(-pitch);  y, z = y*cp - z*sp, y*sp + z*cp
    return (x, y, z + dist)

def render(path, scene, yaw, pitch, dist, target, W=1000, Hh=720, ortho=None, f=1200.0, ss=2, cull=True):
    w, h = W*ss, Hh*ss
    bg = (248, 247, 244)
    fb = [list(bg)*w for _ in range(h)]
    zb = [[1e18]*w for _ in range(h)]
    def unit(v):
        n = math.sqrt(sum(c*c for c in v)) or 1
        return tuple(c/n for c in v)
    L, L2 = unit((-0.42, 0.80, 0.44)), unit((0.60, 0.22, -0.55))
    def proj(p):
        if ortho: return (w/2 + p[0]*ortho*ss, h/2 - p[1]*ortho*ss, p[2])
        if p[2] <= 1: return None
        return (w/2 + p[0]*f*ss/p[2], h/2 - p[1]*f*ss/p[2], p[2])
    for tri, tag in scene:
        v = [look(p, yaw, pitch, dist, target) for p in tri]
        pr = [proj(p) for p in v]
        if any(p is None for p in pr): continue
        ux, uy, uz = (v[1][i]-v[0][i] for i in range(3))
        vx, vy, vz = (v[2][i]-v[0][i] for i in range(3))
        nx, ny, nz = uy*vz-uz*vy, uz*vx-ux*vz, ux*vy-uy*vx
        nl = math.sqrt(nx*nx+ny*ny+nz*nz) or 1
        nx, ny, nz = nx/nl, ny/nl, nz/nl
        # Backface cull. The mesh is closed with outward normals, so a face
        # pointing away is interior; drawing it makes the cavity wall z-fight
        # with the 2.4 mm skin in front of it.
        if cull and nz > 0:
            continue
        k = max(0.0, nx*L[0]+ny*L[1]+nz*L[2])
        fi = max(0.0, nx*L2[0]+ny*L2[1]+nz*L2[2])
        shade = 0.36 + 0.54*k + 0.16*fi
        col = tuple(min(255, int(c*shade)) for c in COLOUR[tag])
        xs = [p[0] for p in pr]; ys = [p[1] for p in pr]
        x0, x1 = max(0, int(min(xs))), min(w-1, int(max(xs))+1)
        y0, y1 = max(0, int(min(ys))), min(h-1, int(max(ys))+1)
        (ax, ay, az), (bx, by, bz), (cx, cy, cz) = pr
        den = (by-cy)*(ax-cx) + (cx-bx)*(ay-cy)
        if abs(den) < 1e-9: continue
        for py in range(y0, y1+1):
            row, zrow = fb[py], zb[py]
            for px in range(x0, x1+1):
                w0 = ((by-cy)*(px-cx) + (cx-bx)*(py-cy)) / den
                if w0 < 0: continue
                w1 = ((cy-ay)*(px-cx) + (ax-cx)*(py-cy)) / den
                if w1 < 0: continue
                w2 = 1 - w0 - w1
                if w2 < 0: continue
                zz = w0*az + w1*bz + w2*cz
                if zz < zrow[px]:
                    zrow[px] = zz; row[px*3:px*3+3] = col
    out = []
    for y in range(Hh):
        r = bytearray()
        for x in range(W):
            acc = [0, 0, 0]
            for dy in range(ss):
                src = fb[y*ss+dy]
                for dx in range(ss):
                    i = (x*ss+dx)*3
                    acc[0] += src[i]; acc[1] += src[i+1]; acc[2] += src[i+2]
            n = ss*ss
            r += bytes((acc[0]//n, acc[1]//n, acc[2]//n))
        out.append(bytes(r))
    raw = b''.join(b'\x00' + r for r in out)
    def ch(t, d):
        c = struct.pack('>I', len(d)) + t + d
        return c + struct.pack('>I', zlib.crc32(t + d) & 0xffffffff)
    open(path, 'wb').write(b'\x89PNG\r\n\x1a\n'
        + ch(b'IHDR', struct.pack('>IIBBBBB', W, Hh, 8, 2, 0, 0, 0))
        + ch(b'IDAT', zlib.compress(raw, 9)) + ch(b'IEND', b''))
    print('wrote', path)

if __name__ == '__main__':
    dock = [(t, 'pla') for t in load_stl('dock-whole.stl')]
    tgt_full = (BASE_D/2, 78, 0)
    render('dock-01-hero.png', ground() + dock + panel_tris(),
           math.radians(-38), math.radians(14), 640, tgt_full)
    render('dock-02-back.png', ground() + dock + panel_tris(),
           math.radians(160), math.radians(18), 620, tgt_full)
    render('dock-03-side.png', ground() + dock + panel_tris(),
           0.0, 0.0, 2600, (BASE_D/2, 76, 0), ortho=3.4)
    render('dock-04-bare.png', ground() + dock,
           math.radians(-46), math.radians(16), 620, tgt_full)
