// =====================================================================
// Echo Show-style enclosure for an ALLDOCUBE iPlay 80 mini Turbo (8.8").
// The experimental fork of tab-panel (branch echo-style). The main branch
// keeps the tapered slide-in dock; this one is a block with a separate
// bezel, after the "Amazon Echo Show Enclosure" on Printables (model
// 1769972): drop the tablet in, press the bezel on.
//
// - The body is a soft-cornered block: 15 degree face, vertical back, flat
//   top. The tablet sits in a pocket in the face, glass level with a tenon
//   that stands round it.
// - The bezel is a frame that slides over the tenon along the face normal
//   and snaps on with two small bumps on each side skirt. Its lip laps the
//   glass by bz_lap, which is what holds the tablet in. Print it in a
//   second colour.
// - Beside each short edge, behind the bezel, is a chamber the tablet's
//   edge speakers fire into. The bezel has a grille over each.
// - Power is a sideways right-angle USB-C plug in the left chamber; the
//   cable runs down it and through a duct to an exit low on the back.
// - The base has four round recesses for TPU feet (part="foot", print four).
//
//   openscad -D 'part="body"'   -o echo-body.stl   enclosure.scad
//   openscad -D 'part="bezel"'  -o echo-bezel.stl  enclosure.scad
//   openscad -D 'part="foot"'   -o echo-foot.stl   enclosure.scad
//   openscad -D 'part="coupon"' -o echo-coupon.stl enclosure.scad
//   then check.py and printcheck.py on each.
// =====================================================================

/* [Tablet] ALLDOCUBE's figures: 208.2 x 129.2 x 6.95 mm, 295 g. Landscape
   with the USB-C on the LEFT: the keys are on a long edge near the camera
   end, and port-left puts them on top, out from under the tablet. */
tab_w     = 208.2;
tab_h     = 129.2;
tab_t     = 6.95;
tab_r     = 6.0;    // pocket corner radius; unmeasured
clear     = 0.4;    // per side, round the tablet
float     = 0.15;   // between the tablet's back and the rim: it is
                    // clamped by the bezel, not by the pocket floor

/* [Pocket floor] */
rim       = 12;
relief    = 1.0;

/* [Camera bar] NOT MEASURED: scaled off ALLDOCUBE's renders, as on main.
   At the right end seen from the screen. From the tablet's left end and
   top edge: */
cam_x0    = 208.2 - 7.6 - 29;
cam_x1    = 208.2 - 7.6;
cam_y0    = 5.6;
cam_y1    = 123.6;
cam_h     = 4.5;
cam_m     = 3;
cam_d     = cam_h + 0.7;
cam_rib   = 8;

/* [Bezel] */
bz_t      = 3.0;    // the front plate
bz_lap    = 1.5;    // how far its lip laps the glass
bz_r      = 4.5;    // the opening's corner radius
bz_ch     = 1.0;    // 45 degree chamfer round the opening, front edge
sk_t      = 2.0;    // the skirt round the sides and top
sk_l      = 6.0;    // how far it reaches back over the tenon
fit       = 0.15;   // skirt to tenon, per side
gap       = 0.1;    // plate to tenon face, and under the plate
fr_side   = 18;     // frame beyond the pocket at each short edge: covers
                    // the chamber and its wall
fr_tb     = 12;     // frame above and below the pocket

/* [Snap bumps] on the inside of each side skirt, into dimples in the
   tenon. Print the coupon and tune bump_h: 0.3 snaps in PLA, less if the
   bezel will not go on, more if it falls off. */
bump_d    = 2.4;
bump_h    = 0.3;
bump_u    = 40;     // above and below the pocket's centre line

/* [Chambers] */
bay_w     = 13;     // past the tablet's edge
bay_end   = 20;     // closed pocket wall kept at each corner
grille_d  = 1.8;
grille_p  = 3.2;    // hex pitch

/* [USB-C plug] A sideways ("left/right") right-angle plug: the cable leaves
   along the edge, downwards. Generic sizes; measure yours. */
port_side = -1;     // -1 = left chamber looking at the screen, +1 = right
port_y    = 0;      // the port along the short edge, from its middle
pl_up     = 4;      // the overmould above the port's centre line
pl_l      = 22;     // and below it
pl_w      = 11;     // off the tablet's edge
pl_t      = 6.5;    // front to back
duct_d    = 14;     // a USB-C plug's overmould goes through; USB-A needs 17

/* [Body] */
lean      = 15;
plinth_h  = 12;     // the band under the bezel
base_d    = 80;
soft_r    = 5;      // the flanks' edges
r_top     = 12;     // the top-back edge
r_small   = 1.5;    // every other edge of the profile

/* [Build] */
wall      = 2.4;
foot_d    = 20;     // round feet: a recess across the whole base would be
                    // a 64 mm ceiling printed over air; 20 mm reaches 10
foot_in   = 16;     // centre in from the base's edge
foot_t    = 1.6;
foot_deep = 1.0;    // the recess; each foot stands 0.6 proud

$fn = 64;
eps = 0.01;

// ---- derived ---------------------------------------------------------
pocket_w = tab_w + 2 * clear;
pocket_h = tab_h + 2 * clear;
W        = pocket_w + 2 * fr_side;
H        = pocket_h + 2 * fr_tb;
u_c      = H / 2;                       // the pocket's centre, up the face
k_glass  = bz_t + gap;                  // depth of the glass behind the face
k_floor  = k_glass + tab_t + float;     // the rim
chamber_d = k_floor + relief + 1;
front_t  = k_floor + max(relief, cam_d) + wall;
bay_h    = pocket_h - 2 * bay_end;
bay_z    = port_side * (pocket_w / 2 + bay_w / 2);
rib_z    = -tab_w / 2 + cam_x0 - cam_m - cam_rib / 2;
top_y    = plinth_h + H * cos(lean);
top_fx   = H * sin(lean);

assert(W <= 256 - 6, "wider than the P2S bed");
assert(pl_w + 1.5 < bay_w, "plug does not fit the chamber");
assert(pl_t / 2 < tab_t / 2 + gap + 0.1 + (chamber_d - k_floor),
       "plug too thick for the chamber");
assert(fr_side >= bay_w + clear + sk_t + fit + 2, "frame too narrow for the chamber");
assert(cam_x0 - cam_m - cam_rib > tab_w / 2, "camera rib past the middle");
assert(base_d - top_fx > front_t + 15, "base too shallow for the face");

// ---- the profile -----------------------------------------------------
// Convex, counter-clockwise: front-bottom, back-bottom, back-top, top of
// the face, foot of the face. Each corner rounded by a circle touching both
// edges; the profile is their hull.
P  = [[0, 0], [base_d, 0], [base_d, top_y], [top_fx, top_y], [0, plinth_h]];
PR = [r_small, r_small, r_top, r_small, r_small];
function unit(v) = v / norm(v);
function lnorm(d) = unit([-d[1], d[0]]);          // inward, for a CCW polygon
function centre(i) =
    let (n = len(P), a = P[(i + n - 1) % n], b = P[i], c = P[(i + 1) % n],
         n1 = lnorm(b - a), n2 = lnorm(c - b))
    b + PR[i] * (n1 + n2) / (1 + n1 * n2);

module profile(inset = 0) {
    offset(r = -inset)
        hull() for (i = [0 : len(P) - 1]) translate(centre(i)) circle(r = PR[i]);
}

// The block, with its flank edges rounded by soft_r: a loft of profiles
// inset a little more at each step out to the flank. inset shrinks the
// whole block evenly, so body(t) is the block's skin t deep.
soft_n = 8;
module body(inset = 0) {
    w = W - 2 * inset;
    r = soft_r - inset;
    translate([0, 0, -(w / 2 - r)])
        linear_extrude(height = w - 2 * r) profile(inset);
    // Each slice extrudes outward from its own z, mirrored for the far
    // flank. Centred eps slices overlapped the middle by eps/2 and left
    // coplanar slivers on the face that broke the STL.
    for (m = [0, 1]) mirror([0, 0, m]) for (i = [0 : soft_n - 1]) {
        a0 = i * 90 / soft_n;
        a1 = (i + 1) * 90 / soft_n;
        hull() {
            translate([0, 0, w / 2 - r + r * sin(a0)])
                linear_extrude(height = eps) profile(inset + r * (1 - cos(a0)));
            translate([0, 0, w / 2 - r + r * sin(a1) - eps])
                linear_extrude(height = eps) profile(inset + r * (1 - cos(a1)));
        }
    }
}

// ---- the face frame --------------------------------------------------
// Origin at the foot of the face; x (k) is depth behind it, y (u) up it,
// z across. Everything on the front is placed in this frame.
module face() { translate([0, plinth_h, 0]) rotate([0, 0, -lean]) children(); }
module unface() { rotate([0, 0, lean]) translate([0, -plinth_h, 0]) children(); }

module slab(k0, k1, u0 = -400, u1 = 400) {
    face() translate([k0, u0, -400]) cube([k1 - k0, u1 - u0, 800]);
}

// a rounded box: len along k, h along u, w along z
module rbox(len, h, w, r) {
    hull() for (dy = [-1, 1]) for (dz = [-1, 1])
        translate([0, dy * (h / 2 - r), dz * (w / 2 - r)])
            rotate([0, 90, 0]) cylinder(h = len, r = r, center = true);
}

// world (x, y) of a point u up the face and k behind it
function face_pt(u, k) = [u * sin(lean) + k * cos(lean), plinth_h + u * cos(lean) - k * sin(lean)];

// ---- the bezel -------------------------------------------------------
module opening() {
    face() translate([0, u_c, 0]) {
        translate([bz_t / 2, 0, 0])
            rbox(bz_t + 2, tab_h - 2 * bz_lap, tab_w - 2 * bz_lap, bz_r);
        hull() {
            translate([-0.5, 0, 0])
                rbox(1, tab_h - 2 * bz_lap + 2 * bz_ch + 1, tab_w - 2 * bz_lap + 2 * bz_ch + 1, bz_r + bz_ch);
            translate([bz_ch, 0, 0])
                rbox(eps, tab_h - 2 * bz_lap, tab_w - 2 * bz_lap, bz_r);
        }
    }
}

// Hex grid over each chamber, clear of the opening by a 1.2 mm web.
g_z0 = pocket_w / 2 + 1.2 + grille_d / 2;
g_z1 = pocket_w / 2 + bay_w - 1.5 - grille_d / 2;
g_u  = bay_h / 2 - 4;
module grilles() {
    rows = floor(2 * g_u / (grille_p * sin(60)));
    cols = floor((g_z1 - g_z0) / grille_p);
    face() translate([0, u_c, 0])
        for (s = [-1, 1]) for (j = [0 : rows]) for (i = [0 : cols]) {
            u = -g_u + j * grille_p * sin(60);
            z = g_z0 + i * grille_p + (j % 2) * grille_p / 2;
            if (z <= g_z1)
                translate([bz_t / 2, u, s * z]) rotate([0, 90, 0])
                    cylinder(d = grille_d, h = bz_t + 2, center = true, $fn = 16);
        }
}

module bumps(d, h, inset) {
    // spheres whose caps stand h proud of the face at z = +-(W/2 - inset),
    // pointing inward; half way back along the skirt
    face() for (s = [-1, 1]) for (u = [u_c - bump_u, u_c + bump_u])
        translate([bz_t + sk_l / 2, u, s * (W / 2 - inset + d / 2 - h)])
            sphere(d = d, $fn = 24);
}

module bezel() {
    difference() {
        intersection() { body(0); slab(-50, bz_t + sk_l, 0, 400); }
        intersection() { body(sk_t); slab(bz_t, 400); }
        opening();
        grilles();
    }
    // the bumps, trimmed to what stands inside the skirt
    intersection() {
        bumps(bump_d, bump_h, sk_t);
        difference() { slab(bz_t, bz_t + sk_l, 0, 400); body(sk_t + fit + 0.6); }
        body(sk_t - eps);
    }
}

// ---- the body --------------------------------------------------------
module pocket() {
    face() translate([0, u_c, 0]) {
        // from in front of the tenon face to the rim
        translate([(bz_t + k_floor) / 2, 0, 0])
            rbox(k_floor - bz_t + 2 * eps, pocket_h, pocket_w, tab_r);
        difference() {
            translate([k_floor + relief / 2 - eps, 0, 0])
                rbox(relief + 2 * eps, pocket_h - 2 * rim, pocket_w - 2 * rim, tab_r);
            translate([k_floor, 0, rib_z])
                cube([2 * relief + 1, pocket_h, cam_rib], center = true);
        }
        translate([k_floor + cam_d / 2 - eps, 0, 0]) cam_box(cam_d + 2 * eps, cam_m);
        for (s = [-1, 1])
            translate([(bz_t + chamber_d) / 2, 0, s * (pocket_w / 2 + bay_w / 2 - 1)])
                rbox(chamber_d - bz_t, bay_h, bay_w + 2, 3);
    }
}

// the camera bar's footprint in the face frame, centred on the pocket,
// grown by m; len deep, centred on k = 0
module cam_box(len, m) {
    w = cam_x1 - cam_x0 + 2 * m;
    h = cam_y1 - cam_y0 + 2 * m;
    translate([0, tab_h / 2 - (cam_y0 + cam_y1) / 2, -tab_w / 2 + (cam_x0 + cam_x1) / 2])
        rbox(len, h, w, min(4, h / 2 - eps, w / 2 - eps));
}

// The duct: from the floor of the plug's chamber, low, straight back past
// the pocket, then down and out of the back. `down` adds a web under it,
// for the jacket: inside the hollow body its underside would print on air.
duct_u = u_c - bay_h / 2 + duct_d / 2 + 2;
module cable_path(d, down = false, $fn = 32) {
    p0 = face_pt(duct_u, chamber_d + duct_d / 2 - 6);
    p1 = face_pt(duct_u, chamber_d + duct_d / 2 + 12);
    p2 = [base_d + 10, duct_d / 2 + 6];
    for (seg = [[p0, p1], [p1, p2]])
        hull() for (p = seg) {
            translate([p[0], p[1], bay_z]) sphere(d = d);
            if (down) translate([p[0], 0, bay_z]) cube([d, eps, d], center = true);
        }
}

// the hollow: the block's inside, behind the solid front wall, with a 45
// degree gable for a roof - a flat one would be a long bridge
x_ftop = top_fx + front_t / cos(lean);
x_mid  = (x_ftop + base_d - wall) / 2;
module cavity() {
    difference() {
        intersection() {
            body(wall);
            translate([0, 0, -400]) linear_extrude(height = 800)
                polygon([[x_mid - 600, top_y - wall - 600], [x_mid, top_y - wall],
                         [x_mid + 600, top_y - wall - 600]]);
        }
        slab(-50, front_t);
        cable_path(duct_d + 2 * wall, down = true);
    }
}

module feet(d, h) {
    for (x = [foot_in, base_d - foot_in]) for (z = [-1, 1])
        translate([x, -eps, z * (W / 2 - foot_in)])
            rotate([-90, 0, 0]) cylinder(d = d, h = h + eps);
}

module enclosure() {
    difference() {
        body(0);
        // the bezel's room: in front of the tenon face, and the skirt's
        // ring round the sides and top
        slab(-50, k_glass, -gap, 400);
        // (its floor 0.05 below the plate's: level, the two cuts' outlines
        // crossed and left the STL non-manifold)
        difference() { slab(bz_t - 1, bz_t + sk_l + gap, -gap - 0.05, 400); body(sk_t + fit); }
        bumps(bump_d + 0.2, bump_h + fit + 0.15, sk_t + fit);   // the dimples
        pocket();
        cavity();
        cable_path(duct_d);
        feet(foot_d + 0.4, foot_deep);
    }
}

// ---- the tablet and the plug, for the checks and renders ------------
module tablet(s = 0) {
    face() translate([0, u_c, 0]) {
        translate([k_glass + tab_t / 2, 0, 0])
            rbox(tab_t - 2 * s, tab_h - 2 * s, tab_w - 2 * s, tab_r);
        translate([k_glass + tab_t + cam_h / 2 - s, 0, 0]) cam_box(cam_h, -s);
    }
}
module plug() {
    face() translate([k_glass + tab_t / 2, u_c + port_y + (pl_up - pl_l) / 2,
                      port_side * (tab_w / 2 + pl_w / 2)])
        cube([pl_t, pl_up + pl_l, pl_w], center = true);
}

// ---- parts -----------------------------------------------------------
// body:   base down.  bezel: face down.  coupon: the port-end 48 mm of the
// face - tenon, chamber, plug and one side skirt with its bumps - body piece
// lying on its back, bezel piece face down beside it.
module body_print()  { rotate([90, 0, 0]) enclosure(); }
module bezel_print() { rotate([0, -90, 0]) unface() children(); }

cz = port_side * (W / 2 - 24);
module coupon_cut() { translate([-200, -200, cz - 25]) cube([400, 400, 50]); }
module coupon() {
    // body: the front wall only, lying on its back
    translate([-cz - 32, 0, front_t - 0.3]) rotate([0, 90, 0]) unface()
        intersection() { enclosure(); coupon_cut(); slab(-50, front_t - 0.3, -3, H + 6); }
    translate([cz + 32, 0, 0]) bezel_print() intersection() { bezel(); coupon_cut(); }
}

part = "show";

if (part == "body")   body_print();
if (part == "bezel")  bezel_print() bezel();
if (part == "foot")   cylinder(d = foot_d, h = foot_t);
if (part == "coupon") coupon();

// each of these must come out EMPTY
if (part == "fit")   intersection() { union() { enclosure(); bezel(); } tablet(0.05); }
if (part == "plugfit") intersection() { union() { enclosure(); bezel(); } plug(); }
if (part == "mate")  intersection() { enclosure(); bezel(); }

// renders, y up turned z up
if (part == "show") rotate([90, 0, 0]) {
    color("#e4e5e9") enclosure();
    color("#2a2d33") bezel();
    color("#111418") tablet();
}
if (part == "open") rotate([90, 0, 0]) {
    color("#e4e5e9") enclosure();
    color("#111418") tablet();
    color("#c05030") plug();
    translate(face_pt(0, -60) - face_pt(0, 0)) color("#2a2d33") bezel();
}
