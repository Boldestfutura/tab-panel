// =====================================================================
// Bench dock for a Lenovo Tab P11 (2nd Gen), forked from the pi-panel
// Rev N dock. Same body - the 15 degree lean, soft flanks, tapered back,
// base cable exit and feet - with the panel's opening, tabs and Pi cavity
// replaced by a pocket the tablet lifts in and out of.
//
// The tablet sits flush in a pocket on the leaning face and is held there
// by gravity: a 15 degree lean, a pocket wall all round, and nothing to
// unclip. Lift it out by the two side bays.
//
// It is 301 mm wide and the P2S bed is 256, so it prints as two halves,
// split down the middle, glued on a solid seam wall and located by pins.
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
flush     = 0.2;    // extra depth: the glass sits this far below the face
lean      = 15;     // degrees back from vertical

/* [Pocket floor relief] */
rim       = 12;     // width of the ledge the tablet's back rests on
relief    = 1.5;    // how much deeper the floor is inside the rim

/* [Side bays] Open slots beside each short edge, full depth. They are
   where the right-angle USB-C plug sits, where the edge speakers breathe,
   and what you grip to lift the tablet out. The pocket's corners stay
   closed (bay_end from each corner) so the tablet is still located. */
bay_w     = 12;     // past the tablet's edge. A sideways right-angle USB-C
                    // head stands ~9-10 mm off the port.
bay_end   = 20;     // closed pocket wall kept at each corner

/* [Cable] The plug's cable turns DOWN the bay, through the lip to the
   bench, and back along a groove under the base to the rear exit.
   Every part of that path is open to the front or to the bench, so the
   cable lays in; nothing has to be threaded. */
port_side = 1;      // +1 = right-hand bay (looking at the screen), -1 = left
cable_d   = 4.6;    // channel through the lip, round a ~3.5-4 mm cable
cable_neck = 3.6;   // pinch at the mouth of the channel, so it stays put
groove_d  = 5.0;    // groove under the base, depth = width

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

assert(bay_h > 60, "bays too short to reach the port");
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
module cable_jacket() {
    cable_path(cable_d + 2 * wall, groove_d + wall);
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

// ---- the front: pocket, relief, bays --------------------------------
module pocket() {
    on_face(face_h / 2) {
        translate([pocket_t / 2 - eps, 0, 0])
            rbox(pocket_t + 2 * eps, pocket_h, pocket_w, tab_r);
        // relief inside the rim, for the camera bump
        translate([pocket_t + relief / 2 - eps, 0, 0])
            rbox(relief + 2 * eps, pocket_h - 2 * rim, pocket_w - 2 * rim, tab_r);
        // side bays, open into the pocket along the short edges
        for (s = [-1, 1])
            translate([pocket_t / 2 - eps, 0, s * (pocket_w / 2 + bay_w / 2 - 1)])
                rbox(pocket_t + 2 * eps, bay_h, bay_w + 2, 3);
    }
}

// ---- cable path ------------------------------------------------------
// From the bottom of the port bay, straight down through the bottom frame
// and the lip to the bench, then a groove under the base to the back edge.
//
// In the face's frame the bay's lower end is at d = face_h/2 - bay_h/2;
// the channel runs from there down to below the bench, at the bay's centre
// across the dock and pocket_t/2 behind the face - the middle of the plug.
bay_z = port_side * (pocket_w / 2 + bay_w / 2);

back_z = port_side * (dock_w / 2 - taper - 24);

// world (x, y) of a point d up the face and k behind it
function face_pt(d, k) = [d * sin(lean) + k * cos(lean), lip_h + d * cos(lean) - k * sin(lean)];

module cable_path(d, gd) {
    p0 = face_pt(face_h / 2 - bay_h / 2 + 4, pocket_t / 2);   // inside the bay
    p1 = [p0[0], -5];                                         // straight down, past the bench
    // down through the frame and lip
    hull() {
        translate([p0[0], p0[1], bay_z]) sphere(d = d);
        translate([p1[0], p1[1], bay_z]) sphere(d = d);
    }
    // under the base, angled in to the rear edge: the flanks taper, so
    // the bay's own line would come out through the side of the back
    hull() {
        translate([p0[0], -eps, bay_z - gd / 2]) cube([gd, gd, gd]);
        translate([base_d - gd + 10, -eps, back_z - gd / 2]) cube([gd, gd, gd]);
    }
}

// The channel through the lip is open to the front: the cable presses in
// past a neck rather than being threaded down a hole.
module cable_cut() {
    cable_path(cable_d, groove_d);
    p0 = face_pt(face_h / 2 - bay_h / 2 + 4, pocket_t / 2);
    hull() {
        translate([p0[0] - 20, p0[1], bay_z]) rotate([0, 90, 0]) cylinder(d = cable_neck, h = 20);
        translate([p0[0] - 20, -5, bay_z]) rotate([0, 90, 0]) cylinder(d = cable_neck, h = 20);
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
        cable_cut();
        feet();
        pins();
    }
}

// A corner of the real thing, 30 minutes of filament: the bottom of the
// port-side bay with its pocket corner, the rim and the start of the cable
// channel. Drop the tablet's corner in and plug the cable in: does it sit
// flush, does the plug fit the bay, does the cable press into the channel.
module coupon_block() {
    on_face(face_h / 2 - pocket_h / 2 + 25)
        translate([-20, 0, port_side * (dock_w / 2 - 35)])
            cube([140, 70, 70], center = true);
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
else if (part == "coupon") rotate([90, 0, 0]) intersection() { dock(); coupon_block(); }
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
if (part == "show") rotate([90, 0, 0]) { color("#e4e5e9") dock(); color("#1a1f28") tablet(); }
if (part == "bare") rotate([90, 0, 0]) color("#e4e5e9") dock();
