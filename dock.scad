// =====================================================================
// Bench dock for a Waveshare 10.1" DSI touch panel on a Raspberry Pi.
//
// Rev E. One piece. The panel drops into a pocket from the front and a
// surrounding lip rises BESIDE the glass - never over it - so the raw
// glass edge is hidden without the opening ever becoming smaller than the
// panel. That is what keeps it a single part: a frame that lapped onto
// the glass could not be assembled, because the panel cannot enter from
// the front and is far too big to pass through the Pi aperture behind.
//
// Assembly: VHB on the pocket floor, panel in face-up, done.
//
// MEASURE THE PANEL BLOCK BEFORE PRINTING. Waveshare publish no outline
// for WS-30052, only a DWG, so those numbers are estimates.
// =====================================================================

/* [Panel] 10.1-DSI-TOUCH-A (WS-30052), LANDSCAPE - rotated 90 from native.
   MEASURED, not estimated. Layer stack taken off Waveshare's own STEP
   (10_1-DSI-TOUCH-A-20250702.stp) and cross-checked against the drawing's
   side-view callouts, via kaushik1A1A1A's CadQuery enclosure project:

     glass       1.10 mm   239.00 x 147.00   outermost AND largest
     sub-bezel   1.70 mm   229.07 x 143.00
     flange      3.40 mm   230.70 x 145.10   widest thing behind the glass
     chamfer     0.40 mm
     metal back  4.30 mm   223.10 x 137.99
                 -------
     total      10.80 mm   glass front to chassis rear
*/
glass_w   = 239.00; // visible outer face, long edge
glass_h   = 147.00; // visible outer face, short edge
glass_t   = 1.10;   // the glass alone
flange_w  = 230.70; // widest thing that must pass through the opening
flange_h  = 145.10;
flange_dx = 2.78;   // flange centre sits THIS far off the glass centre, long axis
panel_t   = 10.80;  // glass front to chassis rear
lean      = 15;     // degrees back from vertical

/* [Mounting] the panel has its own tapped holes - screw it, do not tape it.
   Drawing calls out 8-M2.5; the STEP's tapped holes measure dia 2.04, the
   M2.5 tapping drill. M3 will NOT enter them. */
use_tabs  = true;
hole_dia  = 3.0;    // loose M2.5 clearance. I widened this to 3.4 for
                   // positional slop, then found kaushik1A1A1A's project -
                   // the source of these very hole coordinates, and printed -
                   // had gone the other way: "was 3.4 for M3, which passed an
                   // M2.5 screw but let it wander". A hole that does not
                   // locate the screw does not locate the panel, and the bezel
                   // gap goes uneven. Back to their tested value.
holes_dx  = [111.83, -106.27];  // asymmetric - they follow the flange offset
holes_dz  = [66.50, -66.50];
tab_t     = 3.5;
tab_xy    = [22.0, 18.0];
tab_gap   = 0.20;   // tab face sits this far behind the chassis rear

/* [Surround] */
frame_w   = 3.5;   // lip beside the glass. HARD FLOOR 3.15: below that the
                   // flange opening, which reaches +118.63 because of the
                   // 2.78 offset, breaks out through the side wall.
lip_proud = 0.0;   // 0 = glass finishes flush with the printed face
glass_clear = 0.5; // per side, around the glass in its recess
open_clear  = 0.5; // per side, around the flange opening, long axis
open_clear_h = 0.25; // per side, short axis - snug. Also reverted: the
                   // reference project tightened 0.5 -> 0.25 deliberately and
                   // printed it. Their front face prints at 5 deg and this one
                   // at 15, so the orientation differs and 0.25 is not proven
                   // HERE - which is exactly what the coupon is for. Print the
                   // coupon, try the panel corner, and only then change this.
corner_r  = 4.0;   // radius on the recess and opening

/* [Speakers] Waveshare 8-ohm 5 W, SKU WVSH0044, sold as a pair.
   100 x 45 x 21 mm, mounting holes 90.08 x 36.00 centre-to-centre -
   both measured off the real part by the reference project, not guessed.
   They are PASSIVE: they need an I2S amp, which is not in this model. */
speakers  = false;  // Sonos Era 100 lives in the same room - no point duplicating it
spk_w     = 100.0;
spk_h     = 45.0;
spk_d     = 21.0;
spk_holes = [90.08, 36.00];   // centre-to-centre
spk_pitch = 118.0;            // centre spacing of the two drivers
spk_margin = 7.0;             // plastic above and below the driver
insert_d  = 4.0;              // heat-set insert bore
insert_deep = 6.0;
grille_d  = 3.4;              // grille hole diameter
grille_p  = 6.2;              // grille hole pitch
grille_wall = 2.2;            // wall left in front of the driver

/* [Dock body] */
base_d    = 78;    // front to the back of the feet
top_t     = 20;    // thickness across the top edge
lip_h     = 9;     // bottom of the front face, above the bench
flare     = 1.35;  // back curve: 1 = straight, higher flares later

/* [Raspberry Pi aperture] */
// Power: the panel takes 5 V and GND from the Pi's GPIO header on EVERY Pi,
// 15-pin and 22-pin alike -- Waveshare's wiki is not model-qualified, and the
// "powered over the DSI pogo pins" claim belongs to a different panel. It
// wants >= 0.8 A or it fails to start, so the Pi's own supply carries ~4 W
// extra: official 3 A USB-C minimum on a Pi 4B.
// The Pi bolts to the PANEL's back, not to this dock, on a 58.00 x 49.00
// pattern. It is fully enclosed now - the back is closed and there is no
// window - which works because it clears: 25.2 mm of air behind the panel at
// the Pi's top edge against a 22.4 mm stack, and 36.4 mm at the board centre.
//
// pi_h, pi_shift, pi_clear, pi_drop and ap_r all died with the window. They
// described where to cut it and how big; keeping them as "documentation"
// would just leave five numbers that no longer drive anything and read as if
// they do. The measurements they encoded are in the comment above and in
// verify_dock.py, which checks the clearance for real.
pi_w      = 101;   // still used: the bulkheads sit outboard of the Pi

/* [Build] */
wall      = 2.4;   // shell thickness; the body is hollow
bulk      = 5;     // two internal bulkheads bracing the span
split     = false; // true = one half only, for a bed narrower than dock_w
foot_d    = 22;    // adhesive foot recesses in the base
foot_deep = 1.2;

$fn  = 96;
eps  = 0.01;

// ---- derived ---------------------------------------------------------
front_t = 4.0;                          // solid front wall thickness
spk_zone = speakers ? spk_h + 2 * spk_margin : 0;   // band below the screen
dock_w  = glass_w + 2 * frame_w;        // outer width
face_h  = glass_h + 2 * frame_w;        // the display's share of the front face
total_face = spk_zone + face_h;         // speakers sit UNDER the screen
h_dock  = lip_h + total_face * cos(lean);  // it leans, so it only lifts cos(lean)

assert(!speakers || 2 * spk_w + 20 < dock_w, "two drivers do not fit across the dock");
tab_end = panel_t + tab_gap + tab_t;    // depth of the tab's rear face

assert(frame_w >= 3.15, "frame_w below 3.15 - the offset flange opening breaks out through the side wall");
assert(glass_t < front_t, "glass recess deeper than the front wall");

function front_x(y) = (y - lip_h) * tan(lean);
top_front = front_x(h_dock);
top_back  = top_front + top_t;
run       = base_d - top_back;

// Back curve sampled top to bottom.
//
// Back curve sampled top to bottom. x grows as y falls, so every layer is
// narrower than the one below - self-supporting printed base-down.
//
// Two alternatives were built and dropped, both worth not re-deriving. A
// half-sine bulge on top of the flare gave a proper Echo Show balloon and
// printed fine (24.8 degrees of lean at worst, against FDM's ~45), and a
// straight rake at flare 1.0 with base_d 120 scaled the real Echo Show 8's
// proportions. Both made the dock bigger - 344 g and 374 g against 314 - and
// this is the one that stayed.
steps    = 48;
back_pts = [ for (i = [0 : steps])
               let (t = i / steps, y = h_dock * (1 - t))
               [ top_back + run * pow(t, flare), y ] ];

profile = concat(
    [[0, 0], [0, lip_h]],          // toe, then the front face starts
    [[top_front, h_dock]],         // up the leaning front face
    back_pts,                      // over the top and down the back
    [[base_d, 0]]                  // land on the base
);

// ---- helpers ---------------------------------------------------------
// Put children on the front face, d measured UP the face from its bottom.
// After the rotate, local +x runs into the dock, +y up the face, +z across.
module on_face(d) {
    translate([d * sin(lean), lip_h + d * cos(lean), 0])
        rotate([0, 0, -lean])
            children();
}

// Rounded rectangular prism, long axis along local x.
module rbox(len, h, w, r) {
    hull()
        for (dy = [-1, 1]) for (dz = [-1, 1])
            translate([0, dy * (h / 2 - r), dz * (w / 2 - r)])
                rotate([0, 90, 0])
                    cylinder(h = len, r = r, center = true);
}

// ---- dock body -------------------------------------------------------
// Side edges rounded rather than square-cut, for the soft Echo-Show mass
// instead of a sharp wedge.
//
// The radius has a hard ceiling and it is the bezel, not taste, that sets it.
// Rounding shrinks the profile by the full radius at the very side face, and
// that shrink eats the front face too. The glass recess runs out to z = +-120
// and the body only reaches +-123, so a radius over 3.0 pulls the front face
// back inside the recess and the recess breaks out through the rounded edge.
// 2.5 leaves 0.5 mm of margin. A properly round Echo Show flank needs a wider
// bezel first: frame_w 6 would buy 5 mm of radius at 251 mm overall.
//
// Built as a loft of profile slices stepped around a quarter circle, not a
// minkowski - a minkowski with a sphere is the textbook answer and takes
// minutes on a profile this size.
soft_r = 2.5;
soft_n = 7;    // slices per corner; 7 reads smooth and stays quick
assert(soft_r <= frame_w - 1.0,
       "soft_r too big for frame_w - the rounded edge eats into the glass recess");

module body() {
    // the straight middle
    translate([0, 0, -(dock_w / 2 - soft_r)])
        linear_extrude(height = dock_w - 2 * soft_r)
            polygon(profile);
    // a quarter-round cap on each side
    for (sgn = [-1, 1])
        for (i = [0 : soft_n - 1]) {
            a0 = i * 90 / soft_n;
            a1 = (i + 1) * 90 / soft_n;
            hull() {
                translate([0, 0, sgn * (dock_w / 2 - soft_r + soft_r * sin(a0))])
                    linear_extrude(height = eps)
                        offset(delta = -soft_r * (1 - cos(a0)))
                            polygon(profile);
                translate([0, 0, sgn * (dock_w / 2 - soft_r + soft_r * sin(a1))])
                    linear_extrude(height = eps)
                        offset(delta = -soft_r * (1 - cos(a1)))
                            polygon(profile);
            }
        }
}

// Hold the cavity back so the front wall is a real wall, not a 2.4 mm skin.
module front_backing() {
    on_face(spk_zone + face_h / 2)
        translate([front_t / 2, 0, 0])
            cube([front_t, face_h + 60, dock_w + 60], center = true);
}

module cavity() {
    difference() {
        translate([0, 0, -dock_w / 2 + wall])
            linear_extrude(height = dock_w - 2 * wall)
                offset(delta = -wall)
                    polygon(profile);
        // Bulkheads sit OUTBOARD of the Pi aperture; one on the centreline
        // would be cut in half by it, leaving two useless slivers.
        for (z = [-(pi_w / 2 + 10), pi_w / 2 + 10])
            translate([-50, -50, z - bulk / 2])
                cube([base_d + 100, h_dock + 100, bulk]);
        front_backing();
    }
}

// Front face, in two cuts.
//
// A STEPPED opening is impossible here and it is worth saying why: the
// sub-bezel (143.00) is NARROWER than the flange (145.10) sitting behind
// it, so the flange can never pass an intermediate step. The opening has
// to be flange-sized through the whole wall.
//
// The glass is the outermost AND largest layer, so it sits in a shallow
// recess on the outside and only the flange and chassis pass through.
module glass_recess() {
    on_face(spk_zone + face_h / 2)
        translate([glass_t / 2 - eps, 0, 0])
            rbox(glass_t + 2 * eps,
                 glass_h + 2 * glass_clear,
                 glass_w + 2 * glass_clear, corner_r);
}

module flange_opening() {
    // flange is NOT centred on the glass - it sits flange_dx off along the
    // long axis, and the mounting holes carry the same offset
    on_face(spk_zone + face_h / 2)
        translate([front_t, 0, flange_dx])
            rbox(front_t * 4,
                 flange_h + 2 * open_clear_h,
                 flange_w + 2 * open_clear, corner_r);
}

// Bosses the panel screws back into. A boss projecting straight back off
// the wall is a horizontal cantilever and will not print, so each one is
// hulled from a tall plate at the wall to a small pad at the tip - the
// underside then slopes at roughly 45 degrees and self-supports.
module tabs() {
    // Bite into the wall. Starting flush with its back face is a TANGENT
    // contact, not a volumetric overlap, and the union comes out
    // non-manifold - 60 edges shared by 4 faces when I tried it.
    bite  = 1.0;
    reach = tab_end - front_t + bite;
    for (dz = holes_dx) for (dy = holes_dz)
        on_face(spk_zone + face_h / 2)
            translate([0, dy, dz + flange_dx])
                difference() {
                    hull() {
                        translate([front_t - bite, -reach / 2, 0])
                            cube([eps * 2, tab_xy[1] + reach, tab_xy[0]], center = true);
                        translate([tab_end - tab_t / 2, 0, 0])
                            cube([tab_t, tab_xy[1], tab_xy[0]], center = true);
                    }
                    translate([tab_end - tab_t - 1, 0, 0])
                        rotate([0, 90, 0])
                            cylinder(h = tab_t + 2, d = hole_dia);
                }
}

// Adhesive foot recesses in the base, so the pads sit flush instead of
// lifting the dock onto four bumps.
module feet() {
    for (x = [base_d * 0.22, base_d * 0.78])
        for (z = [-dock_w / 2 + 34, dock_w / 2 - 34])
            translate([x, -eps, z])
                rotate([-90, 0, 0])
                    cylinder(h = foot_deep + eps, d = foot_d);
}

// Base vents. The back is closed now, so this is the only airflow there is.
//
// Sealing the back was the point - no window to look at - and it is possible
// only because the Pi clears it: 25.2 mm of air behind the panel at the Pi's
// top edge against a 22.4 mm stack (5 standoff + 1.4 PCB + ~16 USB), and
// 36.4 mm at the board's centre where the SoC and any heatsink sit. Measured
// by ray-casting the sealed solid, 2026-10-25.
//
// The cost is thermal. A Pi 4B driving a Chromium dashboard in a closed PLA
// shell will run hot, and these slots are an inlet with no high outlet, so
// they ventilate by leakage rather than by any real convection loop. They sit
// in the base where nothing sees them. If it throttles, the fix is a heatsink
// on the Pi - there is 14 mm spare over the SoC - not more holes in the back.
vent_w    = 4.0;    // slot width
vent_l    = 46.0;   // slot length, across the dock
vent_p    = 10.0;   // pitch, front to back
vent_n    = 4;      // how many

module base_vents() {
    for (i = [0 : vent_n - 1])
        translate([base_d * 0.30 + i * vent_p, -eps, 0])
            rotate([-90, 0, 0])
                hull()
                    for (dz = [-1, 1])
                        translate([0, dz * (vent_l / 2 - vent_w / 2), 0])
                            cylinder(h = wall + 2 * eps, d = vent_w);
}

// Power out the back, low, the way an Echo Show does it.
//
// The panel wants 5 V / >=0.8 A off the Pi's GPIO header and the Pi wants its
// own USB-C, so two leads leave the cavity, not one. They exit through the
// base near the back edge and run out rearward, so nothing is pinched under
// the dock and the bench hides the exit.
//
// Shaped as a slot that opens through the back edge rather than a closed
// hole: a closed hole means threading a moulded USB-C plug through it, and a
// right-angle plug will not go at all. Open at the back, the cable drops in.
//
// The 6 mm neck is the strain relief. A 3.4 mm cable pushed past it stays
// where it is put, and the cable cannot be pulled straight out of the dock
// without first being worked back through the neck.
cable_w    = 11.0;   // slot width - clears a USB-C overmould
cable_neck = 6.0;    // pinch at the mouth; push past it and the cable stays
cable_x    = 9.0;    // slot centre this far forward of the back edge

module cable_exit() {
    h = 60;                                   // taller than the base is thick
    translate([0, -eps, 0]) rotate([-90, 0, 0]) {
        // the pocket the cable sits in
        hull() {
            translate([base_d - cable_x, 0, 0]) cylinder(h = h, d = cable_w);
            translate([base_d - cable_x - 14, 0, 0]) cylinder(h = h, d = cable_w);
        }
        // the mouth, out through the back edge, narrowed to grip
        hull() {
            translate([base_d - cable_x, 0, 0]) cylinder(h = h, d = cable_neck);
            translate([base_d + 20, 0, 0]) cylinder(h = h, d = cable_neck);
        }
    }
}

// A corner of the real thing, for 20 minutes of filament instead of 15 hours.
//
// Nothing here has ever been test-fitted: there are no calipers in the house,
// so the recess depth, the opening clearance and the tab hole position are all
// arithmetic. They are also the three things you cannot fix after printing.
// This cuts the top-right corner out of the finished model - same recess, same
// opening edge, same tab and hole - so the panel's own corner either drops in
// or it does not.
//
//   openscad -D coupon=true -o coupon.stl dock.scad
//
// What it tells you, in the order worth checking:
//   1. does the panel corner sit into the recess and finish flush
//   2. does the flange pass the opening without forcing
//   3. does an M2.5 screw line up with the tab hole
// If 1 and 2 pass and 3 is close, print the body.
coupon_at = [holes_dx[0], holes_dz[0]];   // the top-right mounting hole
coupon_xy = 56;                            // how much face to keep, square

module coupon_block() {
    on_face(spk_zone + face_h / 2)
        translate([-20, coupon_at[1], coupon_at[0] + flange_dx])
            cube([120, coupon_xy, coupon_xy], center = true);
}

// Sides drawn in toward the back, starting right behind the screen.
//
// The first version measured the taper in world x and started it at 50, well
// behind the display, so the edge beside the screen stayed square and the
// taper only appeared halfway down the body. It should begin at the angled
// edge beside the screen instead.
//
// It can, because the taper is measured PERPENDICULAR TO THE LEANING FACE
// rather than along world x, and because very little behind the glass
// actually needs the full width:
//
//     0.0 - 1.1 mm   glass recess                 needs 120.00 half-width
//     1.1 - 4.0 mm   front wall, flange opening   needs 118.63
//    10.8 - 14.5 mm  the four mounting tabs       needs 123 (clipped to body)
//    beyond 14.5     nothing                      free
//
// So taper_d sits at 18, three millimetres clear of the tabs, and from there
// back the flanks draw in. The whole block is built in the face's own frame -
// translate to the foot of the face, rotate by -lean - so its start plane is
// parallel to the screen instead of vertical.
//
// `inset` shrinks the envelope per side so the cavity can be tapered too, one
// wall further in. Without that the taper slices the side walls off the shell
// and leaves the cavity open along both flanks.
taper     = 10;    // how far each flank comes in by the back: 246 -> 226
taper_d   = 18;    // start, measured straight back from the glass
taper_run = 70;    // depth over which it reaches the full taper
assert(taper_d >= tab_end + 3,
       "taper starts in front of the mounting tabs - it would cut them off");

module taper_block(inset = 0) {
    H  = 420;
    w0 = dock_w - 2 * inset;
    w1 = dock_w - 2 * taper - 2 * inset;
    translate([0, lip_h, 0])
        rotate([0, 0, -lean]) {
            translate([-200, -210, -w0 / 2])
                cube([200 + taper_d, H, w0]);
            hull() {
                translate([taper_d, -210, -w0 / 2])
                    cube([eps, H, w0]);
                translate([taper_d + taper_run, -210, -w1 / 2])
                    cube([eps, H, w1]);
            }
        }
}

module dock() {
    difference() {
        union() {
            // Outer solid tapered, and the cavity tapered with it a wall
            // further in - so the flank stays a wall, not an opening.
            difference() {
                intersection() { body(); taper_block(); }
                intersection() { cavity(); taper_block(wall); }
            }
            if (use_tabs)
                intersection() { tabs(); body(); taper_block(); }
        }
        glass_recess();
        flange_opening();
        if (speakers) speaker_cut();
        cable_exit();
        base_vents();
        feet();
        if (split)
            translate([-50, -50, -dock_w / 2 - eps])
                cube([base_d + 100, h_dock + 100, dock_w / 2 + eps]);
    }
}

coupon = false;   // -D coupon=true for the corner test piece

if (coupon) intersection() { dock(); coupon_block(); }
else dock();
