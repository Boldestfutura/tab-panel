# WS-23450 (10.1inch DSI LCD (C)) — measured, not estimated

> **THIS IS NOT THE PANEL THE DOCK IS BUILT FOR.** Kept only as a worked
> example of the measuring method, and because the (C) panel was the first
> candidate. `dock.scad` targets the **(A) / WS-30052** and takes its numbers
> from `10_1-DSI-TOUCH-A-20250702.stp`, a different file describing a
> different product. Do not reconcile the two — they genuinely disagree, and
> the disagreement is real rather than an error in either.
>
> The clearest symptom: **(C) requires a stepped pocket and (A) makes one
> impossible.** On (A) the sub-bezel behind the glass is 143.00 and the flange
> behind *it* is 145.10 — wider — so the flange could never clear an
> intermediate step, and the opening has to be flange-sized through the whole
> wall. The "What this changed in the dock" section below describes the (C)
> design and no longer reflects anything that is built.

Source: `10_1inch-dsi-lcd_c_New.stp`, the Creo STEP assembly from Waveshare's
own resources (FILE_NAME `10_1INCH-DSI-LCD_C_ASM`, 2024-05-30). Numbers below
come from parsing 28,190 CARTESIAN_POINTs out of that file, excluding drawing
annotation (|x| > 130 mm).

**This is the (C) landscape panel. It is NOT the (A) / WS-30052**, which is a
different product — portrait native, optical bonding, different PCB. None of
these numbers transfer to it.

## Outline

    239.000 x 147.000 mm      exact, to the micron in the model

## Depth profile, measured down from the glass face

| depth below glass | clearance needed (short x long) |
|-------------------|---------------------------------|
| 0 – 1.0 mm        | 147.0 x 239.0   cover glass     |
| 1.0 – 4.0 mm      | 143.0 x 229.3   display module  |
| 4.0 – 7.0 mm      |  80   x 187.5   driver PCB      |
| 7.0 – 9.0 mm      |  76   x 113                     |
| 9 – 15 mm         |  67   x 100     connectors      |

The full 239 x 147 outline exists only over **1.10 mm** — a cover glass sitting
proud of a 143 x 229.3 module behind it.

## What this changed in the dock — (C) ONLY, SUPERSEDED

The Pi aperture was 92 x 64 mm. **The display's own driver PCB needs
187.5 x 80 mm** of clearance behind the glass. With a solid front backing the
panel would have fouled before seating. The pocket has to be stepped:

    pocket A  239.6 x 147.6, 4.5 deep     glass + module
    pocket B  190   x  80,   6 further    driver PCB
    aperture  through                      Pi, ports, cables

Nothing on the product page or the wiki says any of this. Parse the STEP.

To do the same for another panel: unzip the vendor's STEP, regex out
`CARTESIAN_POINT('...',(x,y,z))`, drop annotation geometry by bounding box,
then histogram the extents per Z band.
