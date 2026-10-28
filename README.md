# tab-panel

A 3D-printed bench dock for a **Lenovo Tab P11 (2nd Gen)** running a Home Assistant
dashboard. Drop the tablet in and it charges; lift it out and it lets go. From the front
there's no cable, no plug and no gap: just the tablet in an even bezel.

It's forked from [pi-panel](https://github.com/Boldestfutura/pi-panel), the dock for a
Waveshare 10.1" panel and a Raspberry Pi 4B. The body keeps that shape (soft flanks, a
tapered back, recessed feet) at a 17° lean, with a pocket the tablet drops into.

![front](render-front.png)
![back](render-back.png)
![empty dock](render-bare.png)

## How it works

- **Pocket and bezel.** The pocket is 0.4 mm clear of the tablet all round, and 2 mm
  deep past the glass, so the dock's face stands just proud of the screen as a bezel. The
  17° lean and the pocket walls hold the tablet, with nothing to clip.
- **Rim and relief.** The tablet's back rests on a 12 mm rim. Inside the rim the floor is
  1.5 mm deeper. Lenovo's 7.4 mm thickness excludes the rear camera bump, and the bump's
  position isn't published, so this lets it sit anywhere.
- **Hidden chambers.** Beside each short edge, behind a 1.2 mm skin of bezel, is a
  15 mm chamber that opens onto the tablet's edge below the glass. The edge speakers fire
  into it and out through a **grille of holes in each flank**. The corners stay solid, so
  the tablet is still located.
- **Lift-out scoop.** A finger scoop in the middle of the top edge.

### Power: magnetic, hidden

Power goes through an **[Adafruit 5521](https://www.adafruit.com/product/5521) magnetic
right-angle USB-C adapter** (120 W, data as well; Core Electronics stocks it as ADA5521).

- A small nub lives in the tablet's USB-C port. The adapter sits in the port-side chamber,
  its magnetic face against the tablet's edge. Drop the tablet in: the nub passes a small
  notch in the bezel and snaps onto the adapter. Lift it out and it lets go.
- Any **straight USB-C cable** plugs into the adapter's other end. It runs down the
  chamber, out of sight, and into a 14 mm duct through the body to an exit low on the
  back.
- **Fitting it:** before the adapter goes in, feed the cable's far plug in at the bottom of
  the chamber and out of the back. Then plug the adapter on and sit it in the chamber.
- The duct takes a USB-C plug. A USB-A plug needs `duct_d = 17`.
- `port_side` picks the chamber: +1 is the right-hand one as you look at the screen.

The adapter's size isn't published. `ad_l`, `ad_w`, `ad_t`, `nub_proud` and `nub_l` are
estimates. **Measure the real adapter and set them before printing the halves.** The
model checks the adapter clears the bezel (`part="adapter"` must come out empty), and
rejects one too thick to fit.

## Printing

It's ~307 mm wide and the P2S bed is 256 mm, so it **prints in two halves**, split down the
middle. Each half is 92 × 153 × 178 mm and prints base-down without supports. The worst
reach over air is 10.8 mm, measured by `printcheck.py`, against a 15 mm limit. A solid web
runs from the cable duct down to the floor so the duct has something under it.

- **Joining.** Each half has a 4 mm solid seam wall as the glue face, with three 4.2 mm pin
  holes, 4 mm deep each side. Use 4 mm steel dowels or printed pins, and glue the whole
  seam.
- **The seam.** It runs under the tablet. Where it does show (the lip, the top, the back),
  a 0.8 mm groove sits on it, so it reads as a parting line rather than a glue joint.
- **Weight.** About 310 g of PLA for the left half and 355 g for the right by volume. The
  slicer's infill brings that down.

| File | What |
|---|---|
| `tab-dock-left.stl`, `tab-dock-right.stl` | the two halves, print orientation |
| `tab-dock-coupon.stl` | the port-side chamber and bezel, ~15 g, prints flat. **Print this first** |

### Print the coupon first

No dimension here has been checked against a real tablet or adapter. The coupon is the
port side of the face, from the bottom of the chamber to past the port. Check that:

1. the adapter fits the chamber and the bezel hides it,
2. with a cable plugged into the adapter, the plug and cable fit down the chamber,
3. the tablet's edge drops in, the nub passes the notch and finds the adapter,
4. the glass sits just below the bezel.

### Check against the real tablet

These aren't published, and the design assumes them:

- **USB-C in the middle of a short edge** (`port_y = 0`). If it's off-centre, set `port_y`.
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
openscad -D 'part="fit"' -o fit.stl dock.scad       # must say "top level object is empty"
openscad -D 'part="adapter"' -o ad.stl dock.scad    # must say "top level object is empty"
```

`part="fit"` intersects the dock with a tablet-sized block in the pocket, and
`part="adapter"` with the adapter in its chamber. If anything comes out, plastic is in the
way. `part="bare"` and `part="tablet"` are for renders.

OpenSCAD 2021.01. `printcheck.py` needs numpy.
