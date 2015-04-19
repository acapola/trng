objectWallWidth=3;
ox=25+2*objectWallWidth;
oy=77+2*objectWallWidth;
oz=6+2*objectWallWidth;
roundingRadius=4;


moldWallWidth=5;
mx=ox+2*moldWallWidth;
my=12+oy+2*moldWallWidth;
mz=oz/2+moldWallWidth;

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

module object() {
	union(){
		translate([-ox/2,12,-oz/2]) roundedBox(ox,oy,oz,roundingRadius);
		translate([-12.5/2,0,-5/2]) cube([12.5,12.1,5]);
	}
}

module feedhole(){
	union(){
		translate([0,-moldWallWidth/2,0]) rotate([90,0,0]) cylinder(h=moldWallWidth,r=2);
		rotate([90,0,0]) cylinder(h=moldWallWidth/2,r=4);
	}
}

module halfmold() {
	difference(){
		translate([-mx/2,0,0]) cube([mx,my,mz]);
		translate([0,moldWallWidth,0]) object();
		translate([6,my,0]) feedhole();
		translate([-6,my,0]) feedhole();
	}
}

union() {
	halfmold();
	translate([0,-moldWallWidth,-mz]) cube([mx/2,moldWallWidth,2*mz]);
	translate([mx/2,-moldWallWidth,-mz]) cube([moldWallWidth,my+moldWallWidth,2*mz]);
}