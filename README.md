# tab-panel

A 3D-printed bench dock for a **Lenovo Tab P11 (2nd Gen)** running a Home Assistant
dashboard. The tablet lifts in and out, and the USB-C cable stays plugged in.

It's forked from [pi-panel](https://github.com/Boldestfutura/pi-panel), the dock for a
Waveshare 10.1" panel and a Raspberry Pi 4B. The body is the same shape: a 15° lean, soft
flanks, a tapered back, and feet recessed into the base. The panel's opening, mounting tabs,
Pi cavity and removable cover are gone. In their place is a pocket the tablet drops into.

![front](render-front.png)
![empty dock](render-bare.png)

## How it holds the tablet

- **Pocket.** It's 0.4 mm clear of the tablet all round, so the glass sits 0.2 mm below the
  dock's face. The 15° lean and the pocket walls hold the tablet in place, with nothing to
  clip.
- **Rim and relief.** The tablet's back rests on a 12 mm rim. Inside the rim the floor is
  1.5 mm deeper. Lenovo's 7.4 mm thickness excludes the rear camera bump, and the bump's
  position isn't published, so this lets it sit anywhere.
- **Side bays.** These are 12 mm open slots beside each short edge, closed at the corners
  so the tablet is still located. They're where the USB-C plug sits, they leave the edge
  speakers open, and they're what you grip to lift the tablet out.
- **Cable.** Use a **sideways ("left/right") right-angle USB-C** cable, so the cable leaves
  parallel to the screen and runs along the tablet's edge. An up/down angle cable points
  backwards into the dock instead.
  - Plug it in and lay the cable down the bay. It drops through a slot in the front lip
    to the bench, then runs back along a groove under the base.
  - Every part of the path is open, so nothing has to be threaded.
  - `port_side` picks the bay: +1 is the right-hand one as you look at the screen.

## Printing

It's 301 mm wide and the P2S bed is 256 mm, so it **prints in two halves**, split down the
middle. Each half is 92 × 150 × 180 mm and prints base-down without supports. The worst
reach over air is 11.2 mm, measured by `printcheck.py`, against a 15 mm limit.

- **Joining.** Each half has a 4 mm solid seam wall as the glue face, with three 4.2 mm pin
  holes, 4 mm deep each side. Use 4 mm steel dowels or printed pins, and glue the whole
  seam.
- **Weight.** About 300 g of PLA a half by volume. The slicer's infill will bring that
  down.

| File | What |
|---|---|
| `tab-dock-left.stl`, `tab-dock-right.stl` | the two halves, print orientation |
| `tab-dock-coupon.stl` | the port-side bottom corner, ~44 g. **Print this first** |

### Print the coupon first

No dimension here has been checked against a real tablet. They all come from Lenovo's
published 269.1 × 169.4 × 7.4 mm and from arithmetic. The coupon is the bottom corner on
the port side. Check that:

1. the tablet's corner drops in and sits flush,
2. the right-angle plug fits the bay with the tablet seated,
3. the cable presses into the lip slot and stays.

### Check against the real tablet

These aren't published, and the design assumes them:

- **USB-C on a short edge,** within the middle 130 mm. If it's on a long edge, the bays
  are in the wrong place.
- **Corner radius ≥ 6 mm.** The pocket's corner is 6 mm. A tighter tablet corner would
  hit it.
- **Speakers on the short edges.** If any are on the long edges, they're muffled by the
  frame.

## Rebuilding

```
openscad -D 'part="left"'   -o tab-dock-left.stl   dock.scad
openscad -D 'part="right"'  -o tab-dock-right.stl  dock.scad
openscad -D 'part="coupon"' -o tab-dock-coupon.stl dock.scad
python3 check.py tab-dock-*.stl          # manifold, volume, bbox
python3 printcheck.py tab-dock-*.stl     # reach over air, layer by layer
openscad -D 'part="fit"' -o fit.stl dock.scad   # must say "top level object is empty"
```

`part="fit"` intersects the dock with a tablet-sized block in the pocket. If anything comes
out, plastic is inside the tablet. `part="show"` and `part="bare"` are for renders.

OpenSCAD 2021.01. `printcheck.py` needs numpy.
