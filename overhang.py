#!/usr/bin/env python3
"""Measure real overhang angles off the mesh, for the base-down print.

The dock prints with its base on the plate, so the build direction is the
model's +y. A face's overhang is how far it tilts off vertical: a vertical
wall is 0 degrees and needs nothing, a flat downward-facing ceiling is 90 and
needs support under all of it. Slicers start struggling past about 45.

Claiming "the taper is free because it lies in the horizontal plane" is an
argument, not a measurement. This is the measurement.
"""
import math
import sys

from check import load

PLATE = 0.5        # anything at or below this is plate contact, not overhang


def main(path):
    tris = load(path)
    buckets = {}
    total = worst = 0.0
    bad_area = 0.0
    for a, b, c in tris:
        u = (b[0]-a[0], b[1]-a[1], b[2]-a[2])
        v = (c[0]-a[0], c[1]-a[1], c[2]-a[2])
        n = (u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0])
        mag = math.sqrt(sum(t*t for t in n))
        if mag < 1e-12:
            continue
        area = mag / 2.0
        total += area
        ny = n[1] / mag
        if ny >= 0:
            continue                      # faces up or sideways: no overhang
        # The base faces straight down but RESTS ON THE PLATE. Counting it as
        # an overhang put 208.9 cm2 - more than the whole rest of the model -
        # in the "needs support" column and made a fine print look unprintable.
        if max(a[1], b[1], c[1]) <= PLATE:
            continue
        ang = math.degrees(math.asin(min(1.0, -ny)))
        worst = max(worst, ang)
        if ang > 45.0:
            bad_area += area
        k = int(ang // 15) * 15
        buckets[k] = buckets.get(k, 0.0) + area

    print("%s" % path)
    print("  steepest downward face : %.1f deg off vertical" % worst)
    print("  area needing support   : %.1f cm2 of %.1f (%.2f%%)"
          % (bad_area/100, total/100, 100*bad_area/total if total else 0))
    print("  downward-facing area by angle band:")
    for k in sorted(buckets):
        flag = "  <-- past 45, wants support" if k >= 45 else ""
        print("     %2d-%2d deg  %7.1f cm2%s" % (k, k+15, buckets[k]/100, flag))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "rev-m-dock.stl"))
