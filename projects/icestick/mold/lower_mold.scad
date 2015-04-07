ox=32;oy=98;oz=12;
moldWallWidth=10;
mx=ox+2*moldWallWidth;
my=oy+moldWallWidth;
mz=oz+2*moldWallWidth;
roundingRadius=4;

module roundedBox(x,y,z,roundingRadius) {
	rr=roundingRadius;
	//% cube([x,y,z]);
	intersection() {
		hull() {
		translate([rr,0,rr]) rotate([-90,0,0]) cylinder(h=y,r=rr);
		translate([rr,0,z-rr]) rotate([-90,0,0]) cylinder(h=y,r=rr);
		translate([x-rr,0,rr]) rotate([-90,0,0]) cylinder(h=y,r=rr);
		translate([x-rr,0,z-rr]) rotate([-90,0,0]) cylinder(h=y,r=rr);
		}
		hull() {
		translate([0,rr,rr]) rotate([0,90,0]) cylinder(h=x,r=rr);
		translate([0,rr,z-rr]) rotate([0,90,0]) cylinder(h=x,r=rr);
		translate([0,y-rr,rr]) rotate([0,90,0]) cylinder(h=x,r=rr);
		translate([0,y-rr,z-rr]) rotate([0,90,0]) cylinder(h=x,r=rr);
		}
		hull() {
		translate([rr,rr,0]) cylinder(h=z,r=rr);
		translate([rr,y-rr,0]) cylinder(h=z,r=rr);
		translate([x-rr,rr,0]) cylinder(h=z,r=rr);
		translate([x-rr,y-rr,0]) cylinder(h=z,r=rr);
		}
	}
}

difference() {
	union() {
		cube([mx,my,mz]);//molde dimensions
		translate([0,my-10,-(50-mz)/2]) cube([mx,10,50]);//base
	}
	translate([moldWallWidth,-roundingRadius,moldWallWidth]) //empty space for the object
		roundedBox(ox,oy+roundingRadius,oz,roundingRadius);
}