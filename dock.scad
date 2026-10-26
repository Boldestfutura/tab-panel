// =====================================================================
// Bench dock for a Waveshare 10.1" DSI touch panel on a Raspberry Pi.
//
// Rev N. Two parts, body and cover - see "two parts" near the end. The
// panel drops into a pocket from the front and a surrounding lip rises
// BESIDE the glass - never over it - so the raw glass edge is hidden
// without the opening ever becoming smaller than the panel.
//
// Assembly: cover off, panel and Pi in from the front, four M2.5 screws
// into the tabs from behind, cover on with four M3.
//
//   openscad -D 'part="body"' -o rev-n-body.stl dock.scad   (and "cover",
//   "coupon", "assembled") - then verify_dock.py and printcheck.py.
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
pi_shift  = 22.78; // Pi board centre, this far along the long axis from the glass centre
pi_len    = 85;    // Pi 4B board length, lying along the long axis

/* [Build] */
wall      = 2.4;   // shell thickness; the body is hollow
bulk      = 5;     // two internal bulkheads bracing the span
bulk_z    = 75;    // bulkhead centres, each side of the middle. Was 60.5, which
                   // put the right one 1.2 mm behind the panel straight through
                   // the Pi board (it reaches pi_shift + pi_len/2 = 65.3).
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
assert(bulk_z - bulk / 2 >= pi_shift + pi_len / 2 + 5,
       "bulkhead inside the Pi's footprint - the panel and Pi will not go in");
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
        // Bulkheads sit outboard of the Pi, and the cover screws into them.
        for (z = [-bulk_z, bulk_z])
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

// Half-height of the flange opening, measured up the face from its centre.
// The cover/body split runs along its top edge.
open_half_h = flange_h / 2 + open_clear_h;

module flange_opening() {
    // flange is NOT centred on the glass - it sits flange_dx off along the
    // long axis, and the mounting holes carry the same offset.
    //
    // It stops at the tab faces. It used to run 12 mm deep, past them, and
    // shaved every tab down to 2.5 mm with a 1.2 mm gap to the panel.
    depth = panel_t + tab_gap;
    on_face(spk_zone + face_h / 2)
        translate([(depth - front_t) / 2, 0, flange_dx])
            rbox(depth + front_t,
                 2 * open_half_h,
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
    on_face(spk_zone + face_h / 2)
        difference() {
            union() {
                // Bottom tabs: hulled down to the wall below the opening.
                for (dz = holes_dx)
                    translate([0, holes_dz[1], dz + flange_dx])
                        hull() {
                            translate([front_t - bite, -reach / 2, 0])
                                cube([eps * 2, tab_xy[1] + reach, tab_xy[0]], center = true);
                            translate([tab_end - tab_t / 2, 0, 0])
                                cube([tab_t, tab_xy[1], tab_xy[0]], center = true);
                        }
                // Top tabs: the wall above the opening is the cover's now, so
                // there is nothing to hull to - the webs carry them instead.
                tab_webs();
            }
            for (dz = holes_dx) for (dy = holes_dz)
                translate([tab_end - tab_t - 1, dy, dz + flange_dx])
                    rotate([0, 90, 0])
                        cylinder(h = tab_t + 2, d = hole_dia);
        }
}

// The top tabs hang behind the opening, and the opening is where the panel
// goes, so nothing can stand under them. Printed base-down, each one started
// as a sliver in mid-air - Orca's "floating cantilever". A web runs from each
// top tab out to the side wall with a 45 degree underside, so every layer of
// the tab sits on the one below. It is behind the panel's rear face, in the
// same plane as the tab, so it touches nothing the tab did not.
module tab_webs() {
    for (dz = holes_dx) {
        zc   = dz + flange_dx;
        side = sign(zc);
        zw   = side * (dock_w / 2 - wall + 1);         // 1 mm into the side wall
        run  = abs(zw - (zc - side * tab_xy[0] / 2));  // tab's inner edge to wall
        y0   = holes_dz[0] - tab_xy[1] / 2;            // bottom of the top tab
        hull() {
            translate([tab_end - tab_t, y0, zc - tab_xy[0] / 2])
                cube([tab_t, tab_xy[1], tab_xy[0]]);
            translate([tab_end - tab_t, y0 - run, zw - eps])
                cube([tab_t, tab_xy[1] + run, 2 * eps]);
        }
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
cable_h    = 20.0;   // how far up the back the slot runs. Was 60, which split
                     // the back curve most of the way up for no reason - a
                     // cable lying on the bench needs a few mm. The base pocket
                     // and the neck are untouched.

module cable_exit() {
    h = cable_h;
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

// Zip-tie anchor: a bar arched over the pocket, just ahead of the neck.
//
// The neck alone holds the cable against a nudge, not a yank - a pull goes
// straight through to the Pi's USB-C socket. Tied to this bar, the pull ends
// at the dock.
//
// The cable lies across the top of the bar. The pocket under it is open to
// the bench, so the tie feeds up from underneath, over the cable and back
// down - it can be fitted or redone with the panel already screwed in.
// Printed base-down the bar is a 14 mm bridge, which needs no support.
tie_x   = 19.5;   // bar centre this far forward of the back edge
tie_l   = 4.0;    // bar depth, front to back - a 4.8 mm tie wraps it
tie_y   = 6.0;    // underside of the bar above the bench
tie_t   = 3.0;    // bar thickness
tie_leg = 4.0;    // pillar width, each side of the pocket

assert(base_d - tie_x - tie_l / 2 > base_d * 0.30 + (vent_n - 1) * vent_p + vent_w / 2,
       "tie anchor sits on the last base vent");
assert(tie_y + tie_t + 4 < cable_h,
       "cable over the tie bar sits higher than the slot through the back");

module tie_anchor() {
    z_in = cable_w / 2 + 1.5;                 // leave floor between pocket and leg
    translate([base_d - tie_x - tie_l / 2, 0, 0]) {
        for (s = [-1, 1])
            translate([0, wall - 1, s > 0 ? z_in : -z_in - tie_leg])
                cube([tie_l, tie_y + tie_t - wall + 1, tie_leg]);
        translate([0, tie_y, -z_in - tie_leg])
            cube([tie_l, tie_t, 2 * (z_in + tie_leg)]);
    }
}

// A corner of the real thing, for 20 minutes of filament instead of 15 hours.
//
// Nothing here has ever been test-fitted: there are no calipers in the house,
// so the recess depth, the opening clearance and the tab hole position are all
// arithmetic. They are also the three things you cannot fix after printing.
// This cuts the bottom-right corner out of the body - same recess, same
// opening edge, same tab and hole - so the panel's own corner either drops in
// or it does not. It was the top-right corner until the top edge moved into
// the cover; the bottom corner is all one part and stands on the real base.
//
// What it tells you, in the order worth checking:
//   1. does the panel corner sit into the recess and finish flush
//   2. does the flange pass the opening without forcing
//   3. does an M2.5 screw line up with the tab hole
// If 1 and 2 pass and 3 is close, print the body.
coupon_at = [holes_dx[0], holes_dz[1]];   // the bottom-right mounting hole
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

// ---- two parts: body and cover ---------------------------------------
// Rev M was one closed piece, and it could not be built or assembled:
//
//   - The panel screws to its tabs from BEHIND, and with the back closed
//     nothing could reach them. The top two had 7 mm of air behind them.
//   - Printed base-down, the edge above the screen was a ceiling 230 mm wide
//     with nothing under it but the opening the panel goes into.
//
// So the back comes off. The cover is the curved back, the top, and the strip
// of front face above the screen; the body is everything else - base, the
// front below that strip, both side walls, the bulkheads and all four tabs.
//
//   body   prints base-down. The front is now a U, open at the top, so it has
//          no ceiling anywhere except short bridges.
//   cover  prints upside-down on its flat top. Every face then leans the
//          right way, and the strip above the screen grows straight up off
//          the plate.
//
// The cover sits between the two side walls, on the bulkhead edges and the
// base, and four M3 screws hold it to bosses on the bulkheads. Off, the
// whole back of the panel is open: tab screws, Pi, cables.
fit       = 0.25;   // gap between cover and body, every face they share
cover_screw_y = [28, 122];   // heights of the two screws on each bulkhead
boss_d    = 8;      // boss around each screw
boss_len  = 10;     // how far the boss reaches into the bulkhead
pilot_d   = 2.5;    // M3 thread-forming pilot - the screw cuts its own thread
clear_d   = 3.4;    // M3 clearance through the cover

// The face's own frame, in 2D: x into the dock, y up the face.
module on_face2d(d) {
    translate([d * sin(lean), lip_h + d * cos(lean)])
        rotate(-lean)
            children();
}

// What the cover is, as a cross-section: the outer skin over the back and
// top, plus the full-thickness front wall above the opening - minus the base
// slab and the front wall below the opening, which stay with the body.
module cover2d() {
    difference() {
        union() {
            difference() {
                polygon(profile);
                offset(delta = -wall) polygon(profile);
            }
            intersection() {
                polygon(profile);
                on_face2d(spk_zone + face_h / 2)
                    translate([0, open_half_h]) square([front_t, 100]);
            }
        }
        translate([-100, -100]) square([base_d + 200, 100 + wall]);
        // front_t + wall deep, not front_t: the toe's skin, below the face,
        // reaches 4.03 in the face's frame and was left behind as a sliver
        on_face2d(spk_zone + face_h / 2)
            translate([-100, -400]) square([100 + front_t + wall, 400 + open_half_h]);
    }
}

// The cover region in 3D, between the side walls. `grow` swells it into the
// body, `inset` holds it off the side walls - so the body subtracts a grown
// one and the cover keeps an inset one, and `fit` is left between them.
module cover_zone(grow, inset) {
    intersection() {
        translate([0, 0, -dock_w / 2])
            linear_extrude(height = dock_w)
                offset(delta = grow) cover2d();
        taper_block(inset);
    }
}

function back_x(y) = top_back + run * pow(1 - y / h_dock, flare);

module boss_axes() {
    for (z = [-bulk_z, bulk_z]) for (y = cover_screw_y)
        translate([back_x(y) - wall - boss_len, y, z])
            children();
}

// Teardrop in section, point down, so it prints base-down without support.
module cover_bosses() {
    boss_axes()
        hull() {
            rotate([0, 90, 0]) cylinder(d = boss_d, h = boss_len + wall + 5);
            translate([0, -boss_d / 2 * sqrt(2), -eps])
                cube([boss_len + wall + 5, eps, 2 * eps]);
        }
}

module cover_holes(d) {
    boss_axes()
        translate([-1, 0, 0])
            rotate([0, 90, 0]) cylinder(d = d, h = boss_len + wall + 20);
}

module shell() {
    // Outer solid tapered, and the cavity tapered with it a wall further
    // in - so the flank stays a wall, not an opening.
    difference() {
        intersection() { body(); taper_block(); }
        intersection() { cavity(); taper_block(wall); }
    }
}

module dock_body() {
    difference() {
        union() {
            shell();
            intersection() {
                union() { if (use_tabs) tabs(); cover_bosses(); }
                body(); taper_block();
            }
            tie_anchor();
        }
        cover_zone(fit, wall);
        glass_recess();
        flange_opening();
        if (speakers) speaker_cut();
        // the bar spans the pocket, so the pocket must not cut it away
        difference() { cable_exit(); tie_anchor(); }
        base_vents();
        feet();
        cover_holes(pilot_d);
    }
}

module dock_cover() {
    difference() {
        intersection() { shell(); cover_zone(0, wall + fit); }
        glass_recess();
        flange_opening();
        cable_exit();
        cover_holes(clear_d);
    }
}

// part = "assembled"  both parts in place, y up - for the checks and renders
//        "body"       print orientation, base on the plate
//        "cover"      print orientation, top on the plate
//        "coupon"     print orientation, base on the plate
part = "assembled";

if (part == "body")        rotate([90, 0, 0]) dock_body();
// The cover is placed beside the body on the plate, not just turned over:
// opened together, Orca merges the two files into one object at their
// exported positions, and an unshifted cover sat under the bed.
else if (part == "cover")  translate([base_d - 15, 0, h_dock]) rotate([-90, 0, 0]) dock_cover();
else if (part == "coupon") rotate([90, 0, 0]) intersection() { dock_body(); coupon_block(); }
else if (part == "assembled") { dock_body(); dock_cover(); }
