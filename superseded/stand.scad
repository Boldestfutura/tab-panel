// Bench stand for a 10.1" Raspberry Pi DSI touch panel.
// Two identical feet. Print 2. No supports - it lies flat on its side.
//
// MEASURE edge_t WITH CALIPERS FIRST. Everything else can stay as-is.

edge_t     = 11.0;  // thickness of the display assembly at its bottom edge
clearance  =  1.2;  // slop so it drops in rather than needing a push

lean       = 15;    // degrees back from vertical
depth      = 100;   // front-to-back footprint
height     =  58;   // height at the back
width      =  50;   // width of each foot
slot_floor =  14;   // slot floor height above the bench
front_x    =  30;   // where the slot's front wall meets the lip
lip_h      =  32;   // front lip height - deliberately below `height`
toe_h      =   6;   // thickness at the very front edge

slot_w   = edge_t + clearance;
rise     = height - slot_floor;
lip_rise = lip_h  - slot_floor;
dx       = rise     * tan(lean);
lip_dx   = lip_rise * tan(lean);
horiz    = slot_w / cos(lean);

fx_top = front_x;
fx_bot = fx_top + lip_dx;
bx_top = fx_top + horiz;
bx_bot = bx_top + dx;

assert(bx_bot < depth - 6, "slot runs out the back - raise depth or drop front_x");
assert(fx_top > 6,         "slot too close to the front edge");

module foot() {
    linear_extrude(height = width)
        polygon([[0, 0], [depth, 0], [depth, height],
                 [bx_top, height], [bx_bot, slot_floor],
                 [fx_bot, slot_floor], [fx_top, lip_h],
                 [0, toe_h]]);
}

foot();
// Both feet are identical - the profile is uniform across the width, so there
// is no left or right hand to it. Mirroring would only flip it front-to-back.
