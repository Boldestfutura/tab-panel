// =====================================================================
// Bench dock for a Lenovo Tab P11 (2nd Gen), forked from the pi-panel
// Rev N dock. Same body - the 15 degree lean, soft flanks, tapered back,
// base cable exit and feet - with the panel's opening, tabs and Pi cavity
// replaced by a pocket the tablet lifts in and out of.
//
// Rev B, "one finished product": the tablet sits in a pocket on a 17 degree
// face, its glass a little below a bezel that runs all round. Behind the
// bezel at each short edge is a hidden chamber: the tablet's edge speakers
// fire into it and out through a grille in each flank. Power is a magnetic
// right-angle USB-C adapter (Adafruit 5521) captive in the port-side
// chamber: drop the tablet in and its nub snaps on, lift it out and it lets
// go. The cable runs down that chamber and through a duct inside the body
// to an exit low on the back. Nothing shows from the front. Lift the
// tablet out by the scoop in the top edge.
//
// It is ~307 mm wide and the P2S bed is 256, so it prints as two halves,
// split down the middle, glued on a solid seam wall and located by pins.
// The split falls under the tablet; a fine reveal groove round the outside
// makes the line that does show read as a parting line, not a glue joint.
//
//   openscad -D 'part="left"'  -o tablet-dock-left.stl  dock.scad
//   openscad -D 'part="right"' -o tablet-dock-right.stl dock.scad
//   openscad -D 'part="coupon"' -o tablet-dock-coupon.stl dock.scad
//   then check.py and printcheck.py on all three.
// =====================================================================

/* [Tablet] Lenovo PSREF: 269.1 x 169.4 x 7.4 mm "without camera deco".
   Landscape. The rear camera bump is NOT in that 7.4 and its position is
   not published, so the pocket floor is relieved everywhere but a rim -
   the tablet rests on its edges and the bump can be anywhere. */
tab_w     = 269.1;
tab_h     = 169.4;
tab_t     = 7.4;
tab_r     = 6.0;    // pocket corner radius. Smaller than the tablet's own
                    // corner is safe; larger would hit it. Unmeasured.
clear     = 0.4;    // per side, round the tablet
flush     = 2.0;    // the bezel: the glass sits this far below the face
lean      = 17;     // degrees back from vertical

/* [Pocket floor relief] */
rim       = 12;     // width of the ledge the tablet's back rests on
relief    = 1.5;    // how much deeper the floor is inside the rim

/* [Side chambers] Hidden behind the bezel beside each short edge, open to
   the tablet's edge below the bezel. The speakers fire into them and out
   of the flank grilles; the port side also holds the magnetic adapter and
   the cable. The pocket's corners stay closed (bay_end from each corner)
   so the tablet is still located. */
bay_w     = 15;     // past the tablet's edge
bay_end   = 20;     // closed pocket wall kept at each corner
skin_t    = 1.2;    // the bezel over the chambers: thinner than flush so
                    // an adapter thicker than the tablet still fits
grille_d  = 3;      // flank grille holes
grille_p  = 6;      // their pitch, along the edge

/* [Magnetic adapter] Adafruit 5521. Its size is NOT published: these are
   estimates. Measure the real one, set these, print the coupon. */
port_side = 1;      // +1 = right-hand chamber (looking at the screen), -1 = left
port_y    = 0;      // the port's height along the short edge, from its middle
nub_proud = 2.0;    // how far the nub stands off the tablet's edge
nub_l     = 12;     // the nub's length along the edge
ad_l      = 26;     // adapter body: along the edge
ad_w      = 12;     // off the edge (the nub's face to the far side)
ad_t      = 8.0;    // thickness, front to back

/* [Cable] Down the chamber below the adapter, then a duct through the
   body to the back. The duct takes the cable's far plug: thread it from
   the chamber end before the adapter goes in. */
duct_d    = 14;     // fits a USB-C plug's overmold; USB-A needs 17
scoop_w   = 34;     // finger scoop in the top edge
reveal    = 0.8;    // the parting-line groove round the seam: width = depth

/* [Surround] */
frame_w   = 3.5;    // lip beyond the pocket and bays, as on Rev N

/* [Dock body] */
base_d    = 92;     // Rev N's 78 was for a 160 mm tall dock; this one is
                    // ~180, and a tablet's weight sits forward of the base
top_t     = 20;
lip_h     = 9;
flare     = 1.35;

/* [Build] */
wall      = 2.4;
seam_t    = 4;      // solid wall each side of the split, the glue face
pin_d     = 4.2;    // alignment pin holes: 4 mm steel dowel or printed pin
pin_deep  = 4;      // into each half - inside the seam wall
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
        // seam wall, the glue face between the halves
        translate([-50, -50, -seam_t])
            cube([base_d + 100, h_dock + 100, 2 * seam_t]);
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
        // the nub's way in: it drops past the bezel beside the tablet's edge
        translate([skin_t / 2 - eps, port_y, port_side * (pocket_w / 2 + (nub_proud + 0.8) / 2 - 0.5)])
            rbox(skin_t + 4 * eps, nub_l + 2, nub_proud + 1.3, 0.8);
        // finger scoop, centred in the top edge
        translate([0, pocket_h / 2 - 2, 0])
            scale([1, 10 / (scoop_w / 2), 1])
                sphere(d = scoop_w, $fn = 48);
    }
}

// Flank grilles: rows of holes through each flank into its chamber, down
// the middle of its depth, spread over the chamber's length - the
// speakers' positions along the edge are not published.
module grilles() {
    on_face(face_h / 2)
        for (s = [-1, 1])
            for (y = [-bay_h / 2 + 10 : grille_p : bay_h / 2 - 10])
                for (x = [skin_t + 2.4, chamber_d - 2.4])
                    translate([x, y, s * (pocket_w / 2 + bay_w)])
                        cylinder(d = grille_d, h = 40, center = true, $fn = 16);
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

// The parting line: a shallow groove round the outside on the seam.
module reveal_cut() {
    difference() {
        translate([-50, -50, -reveal / 2]) cube([base_d + 100, h_dock + 100, reveal]);
        intersection() {
            translate([0, 0, -dock_w]) linear_extrude(height = 2 * dock_w)
                offset(delta = -reveal) polygon(profile);
            taper_block(reveal);
        }
    }
}

// ---- feet, pins ------------------------------------------------------
module feet() {
    for (x = [base_d * 0.22, base_d * 0.78])
        for (z = [-dock_w / 2 + 34, dock_w / 2 - 34])
            translate([x, -eps, z])
                rotate([-90, 0, 0])
                    cylinder(h = foot_deep + eps, d = foot_d);
}

// Three pins across the seam, in the solid seam wall: two just behind the
// front wall, one low at the back. The front wall itself is only 2.4 mm
// behind the pocket at the seam - no room for a pin there. 4 mm dowel or a
// printed pin, plus glue on the whole seam face.
function pin_pts() = [
    face_pt(face_h * 0.25, front_t + 5),
    face_pt(face_h * 0.75, front_t + 5),
    [base_d * 0.6, 14],
];

module pins() {
    for (p = pin_pts())
        translate([p[0], p[1], -pin_deep])
            cylinder(d = pin_d, h = 2 * pin_deep);
}

// ---- the dock --------------------------------------------------------
module dock() {
    difference() {
        union() {
            shell();
            intersection() { cable_jacket(); body(); taper_block(); }
        }
        pocket();
        grilles();
        cable_cut();
        feet();
        pins();
        reveal_cut();
    }
}

// The port side of the face, about 30 g: the front wall only, from the
// chamber's foot to past the port - the chamber, the nub's notch, the bezel
// and a run of grille. Put the adapter in, plug a cable into it, drop the
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
//        "left"/"right" one half each, print orientation, base on the plate
//        "coupon"     print orientation
part = "assembled";

module half(s) {
    intersection() {
        dock();
        translate([-50, -50, s > 0 ? 0 : -dock_w]) cube([base_d + 100, h_dock + 100, dock_w]);
    }
}

if (part == "left")        rotate([90, 0, 0]) half(-1);
// beside the left half, not over it: rotated, it spans y -150..0, and the
// first export (translated +120) overlapped the left half - Orca merged the
// two into one object. Side by side the pair takes 192 x 150 of the plate.
else if (part == "right")  translate([100, 150, 0]) rotate([90, 0, 0]) half(1);
else if (part == "coupon") coupon_print() intersection() { dock(); coupon_block(); }
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
if (part == "tablet") rotate([90, 0, 0]) tablet();
if (part == "show") rotate([90, 0, 0]) { color("#e4e5e9") dock(); color("#1a1f28") tablet(); }
if (part == "bare") rotate([90, 0, 0]) color("#e4e5e9") dock();
