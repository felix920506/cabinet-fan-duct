// Cabinet fan shroud for a 120x120x25 mm fan, with a bolt-on flat fan plate.
//
// Rebuilt from source.obj in its ORIGINAL coordinate system (it overlays the
// downloaded model exactly):
//   X = fan axis. The fan box is open on +X (rim face at X = 22.14).
//   Y = long axis. The fan box runs Y -63.37..60.63, then the duct runs out to Y 172.5
//       and exhausts through a slot in the back face (X = -27.6).
//   Z = height.
//
// Changes vs. the original:
//   * The internal 2 mm fan-mount wall (110 mm hole spacing, screws unreachable)
//     is removed.
//   * The fan screws to a separate, completely flat plate that closes the open
//     +X face. The fan sits where it did before (X -2.86..22.14).
//   * Eight bolt ears around the rim, each with a hole and a captive hex-nut
//     pocket on the back. The plate has matching holes. M4 bolts + nuts.
//   * Optional extra clearance around the fan in the sleeve (fan_clearance).
//
// Printing: the shroud is meant to print standing on its -Y end face (the closed
// end of the fan box). That face stays perfectly flat. The four ears next to it
// sit flush on the bed for extra adhesion, and every other ear overhang is
// chamfered (< 45 deg), so no supports are needed. The plate prints flat.
//
// Render a part with:   openscad -D 'part="shroud"' -o shroud.stl fan_shroud.scad
//                       openscad -D 'part="plate"'  -o plate.stl  fan_shroud.scad

part = "assembly";      // "assembly" | "shroud" | "plate" | "shroud_print" (stood up for slicing)

/* [Fan] */
fan_size       = 120;
fan_hole_pitch = 105;    // standard 120 mm fan
fan_hole_d     = 4.5;    // M4 bolt or standard fan screw
fan_opening_d  = 116;    // air opening in the plate
fan_center     = [-1.37, -1.86];   // [Y, Z] of the fan axis in the original model
fan_clearance  = 0.4;    // extra room per side around the fan inside the sleeve (0 = original)

/* [Bolts: M4] */
bolt_d        = 4.6;     // clearance hole
nut_af        = 7.3;     // M4 nut is 7.0 mm across flats, plus clearance
nut_depth     = 3.6;     // M4 nut is 3.2 mm thick
ear_thick     = 8;       // ear thickness along the bolt axis (X)
ear_r         = 7;       // ear tip radius; bolt centre is ear_r from the wall

/* [Plate] */
plate_t       = 4;
plate_round   = 4;

$fn = 64;
eps = 0.01;

// ---------------------------------------------------------------- original geometry
rim_x  = 22.14;          // open face of the fan box
z_bot  = -63.86;  z_top  = 60.16;    // outside of the bottom/top caps
zi_bot = -61.86;  zi_top = 58.14;    // inside of the caps
y_end  = -63.37;         // outside of the closed fan-box end (print bed face)
y_far  = 60.63;          // outside of the other fan-box end wall
yi_end = -61.37;  yi_far = 58.63;

// Outer outline (XY), extruded over the full Z height.
outer_xy = [
  [rim_x, y_end], [rim_x, y_far], [-2.86, y_far], [-9.5, 106.93], [-16.55, 156.08],
  [-16.9, 157.28], [-17.28, 158.55], [-18.15, 160.98], [-18.63, 162.13], [-19.15, 163.35],
  [-19.7, 164.47], [-20.48, 166.03], [-21.13, 167.06], [-21.83, 168.15], [-22.62, 169.02],
  [-23.47, 169.94], [-24.41, 170.64], [-25.4, 171.39], [-26.48, 171.94], [-27.63, 172.51],
  [-27.63, 60.63], [-27.78, -33.37], [-7.86, y_end]
];

// Inner cavity (XY), cut between the caps. It runs out through the open +X face and
// through the exhaust slot in the back face (Y 163.0..171.8).
inner_xy = [
  [rim_x + 1, yi_end], [-6.79, yi_end], [-25.86, -32.77], [-25.86, yi_far],
  [-26.33, 147.6], [-26.75, 159.91], [-27.27, 162.92], [-29, 163.01],
  [-29, 171.8], [-27.63, 171.8], [-26.55, 170.91], [-25.53, 170.05], [-24.71, 169.17],
  [-23.8, 168.21], [-22.31, 166.18], [-21.04, 163.96], [-20.12, 162.09], [-19.11, 160.05],
  [-18.28, 156.32], [-17.38, 152.24], [-11.4, 107.56], [-4.86, yi_far], [rim_x + 1, yi_far]
];

// Slots in the closed end wall (open toward the rim; e.g. for the fan cable).
// [x_start, z_low, z_high] with 2 mm rounded edges at the rim.
end_slots = [[2.14, 28.14, 36.14], [3.64, -39.86, -31.86]];

module end_slot_2d(xs, z0, z1) {        // 2D in (X, Z)
  translate([xs, z0]) square([rim_x + 2 - xs, z1 - z0]);
  difference() {
    translate([rim_x - 2, z0 - 2]) square([4, z1 - z0 + 4]);
    translate([rim_x - 2, z0 - 2]) circle(2);
    translate([rim_x - 2, z1 + 2]) circle(2);
  }
}

module shroud_body() {
  difference() {
    translate([0, 0, z_bot]) linear_extrude(z_top - z_bot) polygon(outer_xy);
    translate([0, 0, zi_bot]) linear_extrude(zi_top - zi_bot) polygon(inner_xy);
    // fan sleeve clearance
    if (fan_clearance > 0)
      translate([-3.5, yi_end - fan_clearance, zi_bot - fan_clearance])
        cube([rim_x + 5, yi_far - yi_end + 2 * fan_clearance, zi_top - zi_bot + 2 * fan_clearance]);
    // end-wall slots
    for (s = end_slots)
      translate([0, y_end + 3, 0]) rotate([90, 0, 0])
        linear_extrude(4) end_slot_2d(s[0], s[1], s[2]);
  }
}

// ---------------------------------------------------------------- ears
// Ears are 2D profiles in (u, v): u runs along the wall, v points outward from it, and the
// bolt centre is at (0, ear_r). The profile is extruded along X, back from the rim face.
//   "bed"     : flat bottom at u = -ear_r, sits on the print bed
//   "chamfer" : underside (-u) slopes back to the wall, about 37 deg from vertical, prints without support
//   "plain"   : sits on top of a wall when printed, so it needs no chamfer
module ear_2d(type) {
  hull() {
    translate([0, ear_r]) circle(ear_r);
    if (type == "bed")     translate([-ear_r, -1]) square([2 * ear_r, 1 + ear_r]);
    if (type == "chamfer") translate([-3 * ear_r, -1]) square([4 * ear_r, 1]);
    if (type == "plain")   translate([-ear_r - 3, -1]) square([2 * ear_r + 6, 1]);
  }
}

// Ear list: [placement, along-wall coordinate of bolt, profile type]
//   "top"/"bot": on the Z caps, u = Y.   "far": on the +Y end wall, u = Z.
ears = [
  ["top", y_end + ear_r, "bed"], ["top", -5, "chamfer"], ["top", 46, "chamfer"],
  ["bot", y_end + ear_r, "bed"], ["bot", -5, "chamfer"], ["bot", 46, "chamfer"],
  ["far", fan_center[1] + 38, "plain"], ["far", fan_center[1] - 38, "plain"],
];

// Transform (u, v, w) to world space. w runs along -X from the rim face.
module ear_frame(e) {
  if (e[0] == "top") multmatrix([[0,0,-1,rim_x],[1,0,0,e[1]],[0,1,0,z_top],[0,0,0,1]]) children();
  if (e[0] == "bot") multmatrix([[0,0,-1,rim_x],[1,0,0,e[1]],[0,-1,0,z_bot],[0,0,0,1]]) children();
  if (e[0] == "far") multmatrix([[0,0,-1,rim_x],[0,1,0,y_far],[1,0,0,e[1]],[0,0,0,1]]) children();
}

// Bolt centre (Y, Z) of an ear, used by the plate
function ear_yz(e) =
  e[0] == "top" ? [e[1], z_top + ear_r] :
  e[0] == "bot" ? [e[1], z_bot - ear_r] :
                  [y_far + ear_r, e[1]];

module ear(e) {
  ear_frame(e) difference() {
    linear_extrude(ear_thick) ear_2d(e[2]);
    translate([0, ear_r, -1]) cylinder(d = bolt_d, h = ear_thick + 2, $fn = 32);
    // Captive nut pocket, open on the back. A hex corner points along the print direction
    // (+Y), so the roof of the pocket prints without support.
    translate([0, ear_r, ear_thick - nut_depth])
      rotate([0, 0, (e[0] == "far") ? 90 : 0])
        cylinder(r = nut_af / sqrt(3), h = nut_depth + 1, $fn = 6);
  }
}

module shroud() {
  difference() {
    union() { shroud_body(); for (e = ears) ear(e); }
    // re-drill the bolt holes in case an ear base overlaps a wall
    for (e = ears) let(p = ear_yz(e))
      translate([rim_x - ear_thick - 1, p[0], p[1]]) rotate([0, 90, 0]) cylinder(d = bolt_d, h = ear_thick + 2, $fn = 32);
  }
}

// ---------------------------------------------------------------- plate
// 2D in (Y, Z). Completely flat slab that bolts against the rim face.
module plate_2d() {
  difference() {
    hull() {
      translate([y_end, z_bot]) square([y_far - y_end, z_top - z_bot]);
      for (e = ears) translate(ear_yz(e)) circle(ear_r);
    }
    translate(fan_center) circle(d = fan_opening_d, $fn = 180);
    for (sy = [-1, 1], sz = [-1, 1])
      translate(fan_center + [sy, sz] * fan_hole_pitch / 2) circle(d = fan_hole_d, $fn = 32);
    for (e = ears) translate(ear_yz(e)) circle(d = bolt_d, $fn = 32);
  }
}

module plate() {   // in place, on the rim face
  translate([rim_x, 0, 0]) rotate([90, 0, 90]) linear_extrude(plate_t) plate_2d();
}

// ---------------------------------------------------------------- fan (visual only)
module fan_ghost() {
  translate([rim_x - 25, fan_center[0], fan_center[1]]) rotate([0, 90, 0])
    difference() {
      translate([-fan_size/2, -fan_size/2, 0]) cube([fan_size, fan_size, 25]);
      translate([0, 0, -1]) cylinder(d = 114, h = 27);
    }
}

if (part == "assembly") {
  color("SteelBlue") shroud();
  color("Orange", 0.8) plate();
  %fan_ghost();
}
if (part == "shroud") shroud();
// Stood on its -Y end face (Y = y_end lands on Z = 0) for slicing.
if (part == "shroud_print") translate([0, 0, -y_end]) rotate([90, 0, 0]) shroud();
if (part == "plate") linear_extrude(plate_t) plate_2d();
