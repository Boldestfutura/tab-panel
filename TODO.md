# To do

tab-panel is on hold until the tablet arrives. Every dimension below the headline size comes from
ALLDOCUBE's product photos, not the tablet. This is the list for when it's here.

## 1. Measure the tablet

Calipers are best; a steel rule will do for most of it. Measure with the tablet landscape, screen
facing you, **USB-C on the left**. "Top" is the long edge away from you on a desk.

| # | Measure | How | Why it matters | Setting in `tab-panel.scad` | Now |
|---|---|---|---|---|---|
| 1 | Length, height, thickness | across the body, not the camera | the pocket | `tab_w`, `tab_h`, `tab_t` | 208.2 × 129.2 × 6.95 (maker's) |
| 2 | Corner radius | see [Measuring the corner radius](#measuring-the-corner-radius) below | the pocket's corners must not be tighter than the tablet's | `tab_r` | 6 |
| 3 | Edge profile | flat sides, or rounded into the glass and back? | how the bezel lip seats on the glass | `bz_lap`, `clear` | assumed flat |
| 4 | **Black border round the screen**, each side | from the glass edge to the first lit pixel, with the screen on white | **how far the bezel can shrink** without covering the display | `fr_side`, `fr_tb`, `bz_lap` | lap 1.5; frame 18 sides / 12 top and bottom |
| 5 | Screen centred in the glass? | compare the borders left and right, top and bottom | the bezel opening assumes it is | `bz_lap` (or an offset) | assumed centred |
| 6 | Front camera and light sensor | position from the nearest corner, and size | the bezel must not cover them | `bz_lap`, `fr_side` | right end of the glass |
| 7 | **USB-C port** | port centre from the top edge | where the plug sits in the left chamber | `port_y` | centred (0) |
| 8 | **Speaker grilles**, each short edge | where each grille starts and ends, from the top edge | the chambers and front grilles can shrink to just these, which helps the bezel | `bay_end`, grille span (`g_u`) | anywhere 20–110 mm along |
| 9 | **Microphone holes** | position of each, edges and face | for voice, a chamber wall or the bezel mustn't block a mic | chamber and grille layout | one seen on a short edge |
| 10 | Buttons | which edge, start and end along it, how far they stand proud | they must land on top, not bear the tablet's weight, and clear the pocket wall | `port_side`, `clear` | top edge near the right end |
| 11 | **Camera bar** | length, width, distance from the right end and from top and bottom, height of the bar and of the lens rings | sizes its recess and the rib beside it; the guess has a generous margin | `cam_x0`, `cam_x1`, `cam_y0`, `cam_y1`, `cam_h`, `cam_rib` | ~118 × 29 mm, 7.6 from the end, 4.5 proud |
| 12 | Back flat? | lay it face up on glass and look for rock | it rests on the rim and rib | `float`, `relief` | assumed flat |

### Measuring the corner radius

Calipers can't read a radius directly. Use any of these; doing two and comparing is best.
Measure two or three corners and average them. If the answer falls between two values, take
the **smaller**: a pocket corner tighter than the tablet's would stop it seating.

1. **Calipers and a square (no extra kit).** Push the corner into something with a true 90°
   inside corner (a set square, a steel square, the corner of a sturdy box) so both edges
   sit flush. With the depth rod, measure the gap from the square's inside corner to the
   tablet's curve, along the diagonal. Call it **d**. Then **radius = d × 2.414**. A 2.5 mm
   gap means a 6 mm radius. d gets multiplied by 2.4, so expect about ±0.5 mm.
2. **Radius gauge set (about $15).** Steel blades, each cut to a known radius. Find the one
   that sits on the corner with no light showing. Get the **7.5–15 mm** set (or a combined
   one): a 1–7 mm set alone may stop short of this tablet.
3. **Photo (free).** Tablet face down on white paper, a ruler right beside the corner, phone
   held square to it directly above. Send it to Claude to fit the radius from the photo.

## 2. Measure the cable and charger

| # | Measure | Why it matters | Setting | Now |
|---|---|---|---|---|
| 13 | Right-angle plug head: length along the edge, above and below the port, depth off the edge, thickness | the chamber must hold it, with the bezel clear of it | `pl_up`, `pl_l`, `pl_w`, `pl_t` | 4 + 22, 11, 6.5 (generic) |
| 14 | Cable diameter, and its far plug's overmould | it threads down the chamber and through the duct | `duct_d` | 14 (USB-C plug); USB-A needs 17 |
| 15 | Cable length you want to the wall | buy the right length | – | – |
| 16 | Charger: USB-PD, 20 W or more | it charges at 20 W | – | – |

## 3. Then

- [ ] Put the measurements into `tab-panel.scad`.
- [ ] Shrink the bezel if the black border allows (item 4), and the chambers to the real speaker
      span (item 8).
- [ ] Re-render, then run `check.py`, `printcheck.py`, and the three checks (`fit`, `plugfit`,
      `mate`), which must come out empty. Commands are in the README.
- [ ] Print **`tab-panel-coupon.stl`** and check:
  - [ ] the bezel snaps on and stays on. Tune `bump_h`: lower it if the bezel won't go on, raise
        it if it falls off;
  - [ ] the plug, in the tablet, drops into the chamber with its cable;
  - [ ] the tablet's corner fits the pocket and the bezel clears the screen.
- [ ] Choose colours: body light, bezel dark, as in the renders?
- [ ] Print the body (base down) and the bezel (face down), then four feet in TPU.
- [ ] Fit it, then check the speakers sound clear through the grilles and the mics still hear.
- [ ] Update the README's figures and renders, and clear this list.
