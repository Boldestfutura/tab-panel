#!/usr/bin/env python3
"""Check the dock's cuts actually cut. Run after every build.

check.py proves the mesh is watertight and manifold. That is necessary and
nowhere near sufficient: a cut that silently stops happening leaves a solid
that is still watertight, still manifold, still the right bounding box, and
check.py passes it. That exact failure happened on 2026-10-25 - a slice-based
edit deleted `pi_clear` and `pi_drop`, OpenSCAD substituted undef, the Pi
window vanished, and the only visible symptom was the volume going UP after
adding two cuts. The reference project lost a speaker grille hole the same
way and did not notice for months.

So: fire rays through the places that are supposed to be holes.

    python3 verify_dock.py dock-whole.stl
"""
import math
import os
import sys

from check import load

def scad(name, default=None):
    """Read a top-level parameter out of dock.scad.

    These were hardcoded here and it rotted the first time the geometry
    moved: base_d went 78 -> 120 and the verifier went on probing x=69 for a
    cable slot that had moved to x=111, then reported the MODEL as broken.
    A checker that has to be edited in step with the thing it checks is worse
    than no checker, because it fails loudly in the wrong direction.
    """
    import re
    src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
                            "dock.scad")).read()
    m = re.search(r'^%s\s*=\s*([-\d.]+)\s*;' % re.escape(name), src, re.M)
    if not m:
        if default is None:
            raise SystemExit("dock.scad has no %s" % name)
        return default
    return float(m.group(1))


LEAN = scad("lean")
LIP_H = scad("lip_h")
GLASS_H, FRAME_W = scad("glass_h"), scad("frame_w")
BASE_D = scad("base_d")
FACE_H = GLASS_H + 2 * FRAME_W
PI_SHIFT = scad("pi_shift")
BOARD_W, BOARD_H = scad("pi_len"), 56.0   # a Pi 4B
PANEL_T = scad("panel_t")              # glass front to chassis rear
PI_STACK = 22.4                        # 5 standoff + 1.4 PCB + ~16 USB-A
VENT_P, VENT_N = scad("vent_p"), int(scad("vent_n"))
CABLE_X, CABLE_W = scad("cable_x"), scad("cable_w")
TIE_X, TIE_Y, TIE_T = scad("tie_x"), scad("tie_y"), scad("tie_t")
HOLES_DX = (111.83, -106.27)            # dock.scad holes_dx - a list, scad() reads numbers
HOLES_DZ = (66.50, -66.50)
FLANGE_DX = scad("flange_dx")
TAB_END = PANEL_T + scad("tab_gap") + scad("tab_t")
BULK_Z, WALL_ = scad("bulk_z"), scad("wall")
BOSS_LEN, PILOT_D, CLEAR_D = scad("boss_len"), scad("pilot_d"), scad("clear_d")
COVER_Y = (28.0, 122.0)                 # dock.scad cover_screw_y
H_DOCK = LIP_H + (GLASS_H + 2 * FRAME_W) * math.cos(math.radians(LEAN))
GLASS_W = scad("glass_w")
WALL = scad("wall")
TAPER = scad("taper", 0.0)
TAPER_D = scad("taper_d", 0.0)
TAPER_RUN = scad("taper_run", 1.0)
DOCK_W = GLASS_W + 2 * FRAME_W
TH = math.radians(LEAN)


def face_point(d, ly, lz):
    """A point on the leaning front face, in world coords."""
    ca, sa = math.cos(-TH), math.sin(-TH)
    return (d * math.sin(TH) - ly * sa,
            LIP_H + d * math.cos(TH) + ly * ca,
            lz)


def hits(tris, origin, direction):
    ox, oy, oz = origin
    dx, dy, dz = direction
    out = []
    for a, b, c in tris:
        e1 = (b[0] - a[0], b[1] - a[1], b[2] - a[2])
        e2 = (c[0] - a[0], c[1] - a[1], c[2] - a[2])
        px = dy * e2[2] - dz * e2[1]
        py = dz * e2[0] - dx * e2[2]
        pz = dx * e2[1] - dy * e2[0]
        det = e1[0] * px + e1[1] * py + e1[2] * pz
        if abs(det) < 1e-9:
            continue
        inv = 1.0 / det
        tx, ty, tz = ox - a[0], oy - a[1], oz - a[2]
        u = (tx * px + ty * py + tz * pz) * inv
        if u < -1e-9 or u > 1 + 1e-9:
            continue
        qx = ty * e1[2] - tz * e1[1]
        qy = tz * e1[0] - tx * e1[2]
        qz = tx * e1[1] - ty * e1[0]
        v = (dx * qx + dy * qy + dz * qz) * inv
        if v < -1e-9 or u + v > 1 + 1e-9:
            continue
        t = (e2[0] * qx + e2[1] * qy + e2[2] * qz) * inv
        if t > 1e-6:
            out.append(round(t, 2))
    return sorted(set(out))


def main(path, body_path=None):
    tris = load(path)
    fails = []
    d_c = FACE_H / 2   # the Pi centres on the glass centre
    axis = (math.cos(-TH), math.sin(-TH), 0.0)

    # 1. The Pi has to FIT. Fire rays from the panel's rear face straight
    # back and see where the shell stops them.
    #
    # Every 5 mm across the board plus 3 mm either side, not just its two
    # ends and middle: three columns let a bulkhead sit 1.2 mm behind the
    # panel, right through the board, and report 25 mm of clearance.
    print("Pi clearance - the board must fit inside:")
    worst = 1e9
    cols = []
    lz = PI_SHIFT - BOARD_W / 2 - 3
    while lz <= PI_SHIFT + BOARD_W / 2 + 3 + 1e-6:
        cols.append(lz)
        lz += 5.0
    for ly in (-BOARD_H / 2, 0.0, BOARD_H / 2):
        row = []
        for lz in cols:
            h = hits(tris, face_point(d_c, ly, lz), axis)
            if not h:
                row.append("OPEN")
                fails.append("shell is open at the Pi (y=%+.1f z=%+.1f) - the "
                             "back is meant to be closed" % (ly, lz))
                continue
            clear = h[0] - PANEL_T
            worst = min(worst, clear)
            row.append("%.1f" % clear)
        print("   y=%+6.1f  %s" % (ly, " ".join("%5s" % x for x in row)))
    print("   worst %.1f mm against a %.1f mm Pi 4B stack -> %+.1f mm margin"
          % (worst, PI_STACK, worst - PI_STACK))
    if worst < PI_STACK:
        fails.append("Pi does not fit: %.1f mm clear, %.1f mm needed"
                     % (worst, PI_STACK))

    # 1b. The rounded side edge must not eat the glass recess. Rounding pulls
    # the front face back by the full radius at the very side, and the recess
    # runs to +-120 against a 123 half-width - so there is only 3 mm of slack
    # and a radius over it breaks the recess out through the flank.
    print("\nRecess vs the rounded flank - solid just outside the glass:")
    for lz in (GLASS_W / 2 + 1.1, GLASS_W / 2 + 2.0, GLASS_W / 2 + 2.9):
        h = hits(tris, face_point(d_c, 0.0, lz), axis)
        ok = bool(h)
        print("   z=%6.1f  %s" % (lz, "solid" if ok else "BROKEN OUT"))
        if not ok:
            fails.append("glass recess breaks out through the rounded edge at z=%.1f" % lz)

    # 1b-ii. The tapered flank must still be a WALL, not an opening.
    #
    # The taper was first intersected with the finished shell, which sliced
    # both side walls off and left the hollow cavity open along the flanks.
    # Nothing caught it: the mesh stayed watertight and manifold, because an
    # open-sided shell is still a closed surface.
    #
    # Counting crossings is not enough either - the first version of this
    # check did that and PASSED the broken model, because the two internal
    # bulkheads supply four crossings on their own. So measure the outermost
    # pair: it has to sit at the tapered half-width and be a wall thick.
    print("\nTapered flank is a wall, not an opening:")
    ca, sa = math.cos(TH), math.sin(TH)
    # Sample depths have to stay INSIDE the body. The dock is 78 mm deep in
    # world x but the back curve slopes, so perpendicular depth behind the
    # glass runs out well before that at mid-height: 52 mm back is already
    # 2 mm outside the shell, which the first version of this check read as
    # a missing flank.
    for d in (TAPER_D + 8.0, TAPER_D + 20.0):
        # a point d mm straight back from the glass, mid-way up the face
        wx = d * ca + (FACE_H / 2) * sa
        wy = LIP_H + (FACE_H / 2) * ca - d * sa
        frac = min(1.0, max(0.0, d - TAPER_D) / TAPER_RUN)
        want = DOCK_W / 2 - TAPER * frac
        h = hits(tris, (wx, wy, -300.0), (0.0, 0.0, 1.0))
        z = [v - 300.0 for v in h]
        if len(z) < 2:
            print("   %.0f mm back: nothing there" % d)
            fails.append("no flank %.0f mm behind the glass" % d)
            continue
        outer, thick = z[0], z[1] - z[0]
        ok = abs(abs(outer) - want) < 1.2 and thick > WALL * 0.75
        print("   %5.0f mm back  outer %.1f (want %.1f)  wall %.1f mm  %s"
              % (d, abs(outer), want, thick,
                 "ok" if ok else "SLICED - cavity open on the flank"))
        if not ok:
            fails.append("flank %.0f mm back: outer %.1f vs %.1f, wall %.1f"
                         % (d, abs(outer), want, thick))

    # 1c. The vents have to be there.
    print("\nBase vents:")
    n_open = 0
    for i in range(VENT_N):
        x = BASE_D * 0.30 + i * VENT_P
        h = [t for t in hits(tris, (x, -5.0, 0.0), (0.0, 1.0, 0.0)) if t < 25.0]
        if not h:
            n_open += 1
    print("   %d of %d slots clear at the centreline" % (n_open, VENT_N))
    if n_open < VENT_N:
        fails.append("only %d of %d base vents are open" % (n_open, VENT_N))

    # 2. The cable exit. A slot that is fully open gives ZERO crossings, not
    # two - the first version of this check asserted two and failed a model
    # that was correct. The real test is differential: nothing in the slot,
    # something just outside it, so the slot is present AND the right width.
    print("\nCable exit - open in the slot, solid either side of it:")
    for dx in (BASE_D - CABLE_X, BASE_D - CABLE_X - 7.0):
        inside = hits(tris, (dx, -5.0, 0.0), (0.0, 1.0, 0.0))
        low_in = [t for t in inside if t < 25.0]          # near the bench
        beside = []
        for lz in (-(CABLE_W / 2 + 4), CABLE_W / 2 + 4):
            h = [t for t in hits(tris, (dx, -5.0, lz), (0.0, 1.0, 0.0)) if t < 25.0]
            beside.append(len(h))
        ok = not low_in and all(n >= 2 for n in beside)
        print("   x=%5.1f  in-slot=%-10s  beside=%s  %s"
              % (dx, low_in or "clear", beside, "ok" if ok else "WRONG"))
        if ok:
            continue
        fails.append("cable exit wrong at x=%.1f (in-slot %s, beside %s)"
                     % (dx, low_in, beside))

    # 3. The zip-tie bar. It spans the pocket, and the pocket cut is told to
    # spare it - if that ever stops working the bar vanishes and the mesh is
    # still perfectly valid. So: open below the bar, a bar-thick solid at
    # the right height, and open above it.
    print("\nZip-tie bar over the pocket:")
    x = BASE_D - TIE_X
    h = [t - 5.0 for t in hits(tris, (x, -5.0, 0.0), (0.0, 1.0, 0.0)) if t < 25.0]
    ok = (len(h) == 2 and abs(h[0] - TIE_Y) < 0.3
          and abs(h[1] - h[0] - TIE_T) < 0.3)
    print("   x=%5.1f  crossings at y=%s  %s"
          % (x, ["%.1f" % v for v in h], "ok" if ok else "WRONG"))
    if not ok:
        fails.append("tie bar wrong at x=%.1f (crossings %s)" % (x, h))

    # 4. The cover screws: clearance through the cover, pilot into a boss.
    # On the axis a ray goes through the cover and down the pilot; 1.5 mm
    # off it - inside the clearance hole, outside the pilot - it must pass
    # the cover and stop on the boss.
    print("\nCover screws - through the cover, into a boss:")
    for z in (-BULK_Z, BULK_Z):
        for y in COVER_Y:
            on = hits(tris, (BASE_D + 5.0, y, z), (-1.0, 0.0, 0.0))
            off = hits(tris, (BASE_D + 5.0, y + 1.5, z), (-1.0, 0.0, 0.0))
            first_on = on[0] if on else None
            first_off = off[0] if off else None
            ok = (first_on is not None and first_off is not None
                  and first_on > first_off + BOSS_LEN - 2.0)
            print("   y=%5.1f z=%+6.1f  on-axis first hit %s, beside it %s  %s"
                  % (y, z, "%.1f" % first_on if on else "none",
                     "%.1f" % first_off if off else "none", "ok" if ok else "WRONG"))
            if not ok:
                fails.append("cover screw y=%.0f z=%+.0f: hole or boss missing" % (y, z))

    # 5. With the cover off, a driver has to reach every tab screw. Rev M
    # passed every check above and still could not be assembled: the back
    # was closed and the top two screws had 7 mm of air behind them.
    #
    # Needs the BODY alone - with the cover on, the screws are meant to be
    # shut in. Coaxial room behind the tab: open air, or >= 40 mm for a
    # stubby driver.
    if body_path:
        print("\nTab screws, cover off - room for a driver behind each:")
        btris = load(body_path)
        for dz in HOLES_DX:
            for dy in HOLES_DZ:
                p = face_point(d_c, dy, dz + FLANGE_DX)
                o = tuple(p[i] + axis[i] * (TAB_END + 0.3) for i in range(3))
                # body STL is in print orientation: y-up x,y,z -> x,-z,y
                o2 = (o[0], -o[2], o[1])
                a2 = (axis[0], -axis[2], axis[1])
                h = hits(btris, o2, a2)
                room = h[0] if h else None
                ok = room is None or room >= 40.0
                print("   hole y=%+5.1f z=%+6.1f  %s  %s"
                      % (dy, dz + FLANGE_DX,
                         "open" if room is None else "%.1f mm" % room,
                         "ok" if ok else "BLOCKED"))
                if not ok:
                    fails.append("tab screw y=%+.0f z=%+.0f: only %.1f mm for a driver"
                                 % (dy, dz + FLANGE_DX, room))

    print()
    if fails:
        print("FAIL - %d problem(s):" % len(fails))
        for f in fails:
            print("   %s" % f)
        return 1
    print("All cuts present.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "dock-assembled.stl",
                  sys.argv[2] if len(sys.argv) > 2 else None))
