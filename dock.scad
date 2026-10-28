// =====================================================================
// Bench dock for a Lenovo Legion Tab (8.8", Gen 3), forked from the
// pi-panel Rev N dock. Same body - soft flanks, tapered back and feet -
// with the panel's opening, tabs and Pi cavity replaced by a pocket the
// tablet sits in. (It was drawn for an 11" Tab P11 first; that was too big
// beside a 7" Nest Hub, and is in the git history.)
//
// Rev B, "one finished product": the tablet sits in a pocket on a 17 degree
// face, its glass a little below a bezel that runs all round. Behind the
// bezel at each short edge is a hidden chamber: the tablet's edge speakers
// fire into it and out through slots in each flank. Power is a magnetic
// right-angle USB-C adapter (Adafruit 5521) captive in the port-side
// chamber. The cable runs down that chamber and through a duct inside the
// body to an exit low on the back. Nothing shows from the front: the bezel
// is unbroken all round, so the nub, which stands off the tablet's edge,
// never passes through it. Instead the tablet slides:
//
//   in:  tuck the far end ~3 mm under the far bezel, lower the port end
//        (the nub clears the bezel), slide it across; the magnet snaps on
//   out: slide it back ~3 mm, which parts the magnet, then press the bottom
//        edge - the floor under the bottom strip is relieved, so the tablet
//        rocks on the ends of the side rims and its top tips out.
//
// It is ~246 mm wide and prints in one piece, base down, on the P2S's
// 256 mm bed.
//
//   openscad -D 'part="print"'  -o tab-dock.stl        dock.scad
//   openscad -D 'part="coupon"' -o tab-dock-coupon.stl dock.scad
//   then check.py and printcheck.py on both.
// =====================================================================

/* [Tablet] Lenovo PSREF, Legion Tab (8.8", 3): 208.54 x 129.46 x 7.79 mm,
   ~350 g. Landscape, power and volume buttons on the top edge, the
   charging USB-C (Hi-Speed) in the middle of the right-hand short edge -
   that is the port the magnetic nub goes in. The second USB-C, middle of
   the bottom edge, is covered by the pocket and not used. The rear camera
   bump's size and position are not published, so the pocket floor is
   relieved everywhere but a rim - the tablet rests on its edges. */
tab_w     = 208.54;
tab_h     = 129.46;
tab_t     = 7.79;
tab_r     = 6.0;    // pocket corner radius. Smaller than the tablet's own
                    // corner is safe; larger would hit it. Unmeasured.
clear     = 0.4;    // per side, round the tablet
flush     = 2.0;    // the bezel: the glass sits this far below the face
lean      = 17;     // degrees back from vertical

/* [Pocket floor relief] */
rim       = 12;     // width of the ledge the tablet's back rests on
relief    = 1.5;    // how much deeper the floor is inside the rim

/* [Push to release] The bottom rim is cut away: the tablet rests on the
   side and top rims only, its bottom strip over a well. Press that strip
   and the tablet pivots on the lower ends of the side rims; the top swings
   out by tilt_w * (tab_h - tilt_a) / tilt_a, about 15 mm. Taps on the
   screen above the pivot press it onto the rims and do nothing. */
tilt_a    = 12;     // pivot, up from the pocket's bottom edge
tilt_w    = 1.5;    // well depth below the rim

/* [Side chambers] Hidden behind the bezel beside each short edge, open to
   the tablet's edge below the bezel. The speakers fire into them and out
   of the flank grilles; the port side also holds the magnetic adapter and
   the cable. The pocket's corners stay closed (bay_end from each corner)
   so the tablet is still located. */
bay_w     = 15;     // past the tablet's edge
bay_end   = 20;     // closed pocket wall kept at each corner
skin_t    = 1.2;    // the bezel over the chambers: thinner than flush so
                    // an adapter thicker than the tablet still fits
slot_w    = 2.2;    // flank grille slots: width
slot_l    = 24;     // length of each, along the edge
slot_gap  = 6;      // the rib between one slot and the next

/* [Magnetic adapter] Adafruit 5521. Its size is NOT published: these are
   estimates. Measure the real one, set these, print the coupon. */
port_side = 1;      // +1 = right-hand chamber (looking at the screen), -1 = left
port_y    = 0;      // the port's height along the short edge, from its middle
nub_proud = 2.0;    // how far the nub stands off the tablet's edge
nub_l     = 12;     // the nub's length along the edge
nub_t     = 3.5;    // its thickness, front to back
slide_s   = nub_proud + 1.0;   // the slide: how far the tablet tucks under
                    // the far bezel, so the nub clears the near one
ad_l      = 26;     // adapter body: along the edge
ad_w      = 12;     // off the edge (the nub's face to the far side)
ad_t      = 8.0;    // thickness, front to back

/* [Cable] Down the chamber below the adapter, then a duct through the
   body to the back. The duct takes the cable's far plug: thread it from
   the chamber end before the adapter goes in. */
duct_d    = 14;     // fits a USB-C plug's overmold; USB-A needs 17

/* [Surround] */
frame_w   = 3.5;    // lip beyond the pocket and bays, as on Rev N

/* [Dock body] */
base_d    = 80;     // Rev N's 78 was for a 160 mm tall dock; this one is
                    // ~140, and the tablet's weight sits forward of the base
top_t     = 20;
lip_h     = 9;
flare     = 1.35;

/* [Build] */
wall      = 2.4;
foot_d    = 22;
foot_deep = 1.2;

$fn  = 96;
eps  = 0.01;

// ---- derived ---------------------------------------------------------
pocket_w = tab_w + 2 * clear;
pocket_h = tab_h + 2 * clear;
pocket_t = tab_t + flush;
front_t  = pocket_t + relief + wall;          // solid front wall behind the pocket
dock_w   = pocket_w + 2 * bay_w + 2 * frame_w;
face_h   = pocket_h + 2 * frame_w;
h_dock   = lip_h + face_h * cos(lean);
bay_h    = pocket_h - 2 * bay_end;

assert(bay_h > 60, "chambers too short to reach the port");
assert(ad_w + nub_proud + 0.4 < bay_w, "adapter does not fit the chamber");
assert(ad_t / 2 <= flush + tab_t / 2 - skin_t - 0.1, "adapter too thick: hits the bezel skin");
assert(rim * 2 < pocket_h, "rim wider than the pocket");

function front_x(y) = (y - lip_h) * tan(lean);
top_front = front_x(h_dock);
top_back  = top_front + top_t;
run       = base_d - top_back;
assert(run > 0, "base_d too small for the face height");

steps    = 48;
back_pts = [ for (i = [0 : steps])
               let (t = i / steps, y = h_dock * (1 - t))
               [ top_back + run * pow(t, flare), y ] ];

profile = concat(
    [[0, 0], [0, lip_h]],
    [[top_front, h_dock]],
    back_pts,
    [[base_d, 0]]
);

// ---- helpers (as Rev N) ---------------------------------------------
module on_face(d) {
    translate([d * sin(lean), lip_h + d * cos(lean), 0])
        rotate([0, 0, -lean])
            children();
}

module rbox(len, h, w, r) {
    hull()
        for (dy = [-1, 1]) for (dz = [-1, 1])
            translate([0, dy * (h / 2 - r), dz * (w / 2 - r)])
                rotate([0, 90, 0])
                    cylinder(h = len, r = r, center = true);
}

// ---- body: Rev N's soft-flanked loft, unchanged ---------------------
soft_r = 2.5;
soft_n = 7;
assert(soft_r <= frame_w - 1.0, "soft_r too big for frame_w");

module body() {
    translate([0, 0, -(dock_w / 2 - soft_r)])
        linear_extrude(height = dock_w - 2 * soft_r)
            polygon(profile);
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

// Taper the flanks behind the face, measured perpendicular to it (Rev N).
// Nothing behind the front wall needs the full width now.
taper     = 12;
taper_d   = front_t + 4;
taper_run = 70;

module taper_block(inset = 0) {
    H  = 460;
    w0 = dock_w - 2 * inset;
    w1 = dock_w - 2 * taper - 2 * inset;
    translate([0, lip_h, 0])
        rotate([0, 0, -lean]) {
            translate([-200, -230, -w0 / 2])
                cube([200 + taper_d, H, w0]);
            hull() {
                translate([taper_d, -230, -w0 / 2])
                    cube([eps, H, w0]);
                translate([taper_d + taper_run, -230, -w1 / 2])
                    cube([eps, H, w1]);
            }
            // and on past the end of the taper. Rev N stopped here, at 88 mm
            // perpendicular to the face, which its 78 mm base never reached;
            // this base does, and the back was being sliced off.
            translate([taper_d + taper_run, -230, -w1 / 2])
                cube([200, H, w1]);
        }
}

module front_backing() {
    on_face(face_h / 2)
        translate([front_t / 2, 0, 0])
            cube([front_t, face_h + 60, dock_w + 60], center = true);
}

// The solid round the cable's way down: the channel cuts through the front
// wall and lip, and the cavity must not open into it.
// The solid round the duct, and a web from it down to the floor: the duct
// crosses the hollow body, and its underside would otherwise print on air.
module cable_jacket() {
    cable_path(duct_d + 2 * wall, down = true);
}

module cavity() {
    difference() {
        translate([0, 0, -dock_w / 2 + wall])
            linear_extrude(height = dock_w - 2 * wall)
                offset(delta = -wall)
                    polygon(profile);
        front_backing();
        cable_jacket();
    }
}

module shell() {
    difference() {
        intersection() { body(); taper_block(); }
        intersection() { cavity(); taper_block(wall); }
    }
}

// ---- the front: pocket, relief, hidden chambers ---------------------
// In the face frame (on_face): x is depth behind the face, y up the face,
// z across the dock.
chamber_d = flush + tab_t + relief;          // chamber floor, level with the relief
bay_z     = port_side * (pocket_w / 2 + bay_w / 2);

module pocket() {
    on_face(face_h / 2) {
        translate([pocket_t / 2 - eps, 0, 0])
            rbox(pocket_t + 2 * eps, pocket_h, pocket_w, tab_r);
        // relief inside the rim, for the camera bump
        translate([pocket_t + relief / 2 - eps, 0, 0])
            rbox(relief + 2 * eps, pocket_h - 2 * rim, pocket_w - 2 * rim, tab_r);
        // the chambers: behind the bezel skin, open to the pocket
        for (s = [-1, 1])
            translate([(skin_t + chamber_d) / 2, 0, s * (pocket_w / 2 + bay_w / 2 - 1)])
                rbox(chamber_d - skin_t, bay_h, bay_w + 2, 3);
        // the slide: the whole pocket again, shifted slide_s away from the
        // port, behind the bezel skin - room under the far bezel, full
        // height, for the tablet's far end while the nub clears the near one
        translate([(skin_t + pocket_t) / 2, 0, -port_side * slide_s])
            rbox(pocket_t - skin_t, pocket_h, pocket_w, tab_r);
        // the release well: the bottom rim, cut down below the rim's level
        translate([pocket_t + tilt_w / 2 - eps, -pocket_h / 2 + tilt_a / 2, 0])
            cube([tilt_w + 2 * eps, tilt_a + 2 * eps, pocket_w - 2 * tab_r], center = true);
    }
}

// Flank grilles: two columns of slots through each flank into its chamber,
// running up the face, spread over the chamber's length - the speakers'
// positions along the edge are not published. Slots, not holes: printed,
// each one's top bridges only slot_w.
slot_n = floor((bay_h - 16 + slot_gap) / (slot_l + slot_gap));
module grilles() {
    run = slot_n * slot_l + (slot_n - 1) * slot_gap;
    on_face(face_h / 2)
        for (s = [-1, 1])
            for (i = [0 : slot_n - 1])
                for (x = [skin_t + 2.4, chamber_d - 2.4]) {
                    y0 = -run / 2 + i * (slot_l + slot_gap) + slot_w / 2;
                    hull()
                        for (y = [y0, y0 + slot_l - slot_w])
                            translate([x, y, s * (pocket_w / 2 + bay_w)])
                                cylinder(d = slot_w, h = 40, center = true, $fn = 16);
                }
}

// ---- cable path ------------------------------------------------------
// The duct: from the floor of the port chamber, low down, through the body
// to an exit low on the back. It goes in from the chamber's floor so the
// cable's turn into it is out of sight behind the bezel. It runs straight
// back beside the pocket first, and only turns in once it is well behind
// the pocket floor - turning sooner opened it into the pocket.

// world (x, y) of a point d up the face and k behind it
function face_pt(d, k) = [d * sin(lean) + k * cos(lean), lip_h + d * cos(lean) - k * sin(lean)];

duct_z = port_side * (dock_w / 2 - taper - duct_d);
duct_up = face_h / 2 - bay_h / 2 + duct_d / 2 + 2;   // up the face, at the chamber's foot

module cable_path(d, down = false, $fn = 32) {
    // centre 1 mm behind the chamber floor: a ~14 mm mouth into the chamber
    p0 = face_pt(duct_up, chamber_d + duct_d / 2 - 6);
    p1 = face_pt(duct_up, chamber_d + duct_d / 2 + 12);  // clear of the pocket
    p2 = [base_d + 10, duct_d / 2 + 6];                  // out of the back
    hull() {
        translate([p0[0], p0[1], bay_z]) sphere(d = d);
        translate([p1[0], p1[1], bay_z]) sphere(d = d);
        if (down) for (p = [p0, p1]) translate([p[0], 0, bay_z]) cube([d, eps, d], center = true);
    }
    hull() {
        translate([p1[0], p1[1], bay_z]) sphere(d = d);
        translate([p1[0] + 10, p1[1], duct_z]) sphere(d = d);
        if (down) {
            translate([p1[0], 0, bay_z]) cube([d, eps, d], center = true);
            translate([p1[0] + 10, 0, duct_z]) cube([d, eps, d], center = true);
        }
    }
    hull() {
        translate([p1[0] + 10, p1[1], duct_z]) sphere(d = d);
        translate([p2[0], p2[1], duct_z]) sphere(d = d);
        if (down) for (x = [p1[0] + 10, p2[0]]) translate([x, 0, duct_z]) cube([d, eps, d], center = true);
    }
}

module cable_cut() {
    cable_path(duct_d);
}

// The adapter, as a block, for renders and the fit check: its magnetic
// face against the nub, centred on the port, the body running down the
// edge, front-to-back centred on the tablet's thickness.
module adapter() {
    on_face(face_h / 2)
        translate([flush + tab_t / 2, port_y - ad_l / 2 + nub_l / 2,
                   port_side * (pocket_w / 2 - clear + nub_proud + 0.2 + ad_w / 2)])
            cube([ad_t, ad_l, ad_w], center = true);
}

// ---- feet ------------------------------------------------------------
module feet() {
    for (x = [base_d * 0.22, base_d * 0.78])
        for (z = [-dock_w / 2 + 34, dock_w / 2 - 34])
            translate([x, -eps, z])
                rotate([-90, 0, 0])
                    cylinder(h = foot_deep + eps, d = foot_d);
}

// ---- the dock --------------------------------------------------------
// slots = false for the coupon: printed flat, each slot's roof would be a
// 24 mm bridge. In the dock, printed upright, it is only slot_w.
module dock(slots = true) {
    difference() {
        union() {
            shell();
            intersection() { cable_jacket(); body(); taper_block(); }
        }
        pocket();
        if (slots) grilles();
        cable_cut();
        feet();
    }
}

// The port side of the face, about 30 g: the front wall only, from the
// chamber's foot to past the port - the chamber and the bezel over it
// (no grille: see dock()). Put the adapter in, plug a cable into it, drop the
// tablet's edge in: does the nub find the adapter, does the bezel hide it,
// does the plug and its cable fit down the chamber. Printed face up, lying
// on the back of the front wall; it leaves out the duct.
coupon_lo = -bay_h / 2 - 4;
coupon_hi = port_y + nub_l / 2 + 14;
module coupon_block() {
    on_face(face_h / 2)
        // from in front of the face to 0.3 short of the wall's back: a cut
        // exactly on either surface left the STL non-manifold
        translate([(front_t - 0.3 - 2) / 2, (coupon_lo + coupon_hi) / 2, port_side * (dock_w / 2 - 17)])
            cube([front_t - 0.3 + 2, coupon_hi - coupon_lo, 36], center = true);
}
// the face frame laid flat: depth down, face at the top, back on the plate
module coupon_print() {
    translate([0, 0, front_t - 0.3]) rotate([0, 90, 0])
        rotate([0, 0, lean]) translate(-[(face_h / 2) * sin(lean), lip_h + (face_h / 2) * cos(lean), 0])
            children();
}

// part = "assembled"  the whole dock, y up - for checks and renders
//        "print"      the dock, print orientation, base on the plate
//        "coupon"     print orientation
part = "assembled";

bed = 256;   // Bambu P2S
assert(dock_w <= bed - 6, "dock wider than the bed");

if (part == "print")       rotate([90, 0, 0]) dock();
else if (part == "coupon") coupon_print() intersection() { dock(slots = false); coupon_block(); }
else if (part == "assembled") dock();

// The tablet as a block, for the fit check and renders: in the pocket,
// face `flush` below the dock's front, resting on the rim.
module tablet() {
    on_face(face_h / 2)
        translate([flush + tab_t / 2, 0, 0])
            rbox(tab_t, tab_h, tab_w, tab_r);
}
// "fit" must come out EMPTY: anything left is plastic inside the tablet.
// shrunk 0.05 mm all round: its back RESTS on the rim, and touching faces
// would otherwise show up as a zero-volume "interference"
if (part == "fit") intersection() { dock(); on_face(face_h / 2) translate([flush + tab_t / 2, 0, 0]) rbox(tab_t - 0.1, tab_h - 0.1, tab_w - 0.1, tab_r); }
if (part == "adapter") intersection() { dock(); adapter(); }

// The nub, standing off the tablet's port edge at the port.
module nub() {
    on_face(face_h / 2)
        translate([flush + tab_t / 2, port_y, port_side * (pocket_w / 2 - clear + nub_proud / 2)])
            cube([nub_t, nub_l, nub_proud], center = true);
}
// "slide" must come out EMPTY too: the tablet seated but slid slide_s away
// from the port, its far end under the far bezel, and the nub's path
// straight down to there from in front of the dock. If anything is left,
// the bezel or a wall is in the way of docking.
module face_shift(dz, dx = 0) {
    // move along the dock's width and along the face normal (dx < 0 is
    // out of the face)
    translate([dx * cos(lean), -dx * sin(lean), dz]) children();
}
if (part == "slide") intersection() {
    dock();
    union() {
        face_shift(-port_side * (slide_s - 0.05))
            on_face(face_h / 2) translate([flush + tab_t / 2, 0, 0])
                rbox(tab_t - 0.1, tab_h - 0.1, tab_w - 0.1, tab_r);
        hull() for (dx = [0, -30])
            face_shift(-port_side * (slide_s - 0.05), dx) nub();
    }
}
// and with the tablet home, the nub sits in the chamber: "nubfit" empty
if (part == "nubfit") intersection() { dock(); nub(); }
if (part == "tablet") rotate([90, 0, 0]) tablet();
if (part == "show") rotate([90, 0, 0]) { color("#e4e5e9") dock(); color("#1a1f28") tablet(); }
if (part == "bare") rotate([90, 0, 0]) color("#e4e5e9") dock();
