//
// CSQC 3rd person camera
//

/*
vector ang = [0, cltime, 0];
makevectors(ang);
setviewprop(VF_VIEWENTITY, 0.0);
setviewprop(VF_ORIGIN, pmove_org - v_forward*64 + v_up*24);
setviewprop(VF_ANGLES, ang);
*/

vector plyr_pos;
void() Camera_Third =
{
	plyr_pos = getproperty(VF_ORIGIN);

	// Enable this after player sits still for awhile, morrowind-style
	/*
	vector ang = [0, cltime*16, 0];
	makevectors(ang);
	setviewprop(VF_VIEWENTITY, 0.0);
	setviewprop(VF_ORIGIN, plyr_pos - v_forward*64);
	setviewprop(VF_ANGLES, ang);
	*/

	// Regular 3rd person camera
	camang = getproperty(VF_ANGLES);
	makevectors(camang);

    campos = getproperty(VF_ORIGIN) - v_forward * 100 + v_up * 20;
    plyr_pos = getproperty(VF_ORIGIN);

    tracebox(plyr_pos, '-16 -16 -16', '16 16 16', campos, MOVE_NOMONSTERS, self);

    setproperty(VF_ORIGIN, trace_endpos);
    setproperty(VF_AFOV, 90);
	setviewprop(VF_VIEWENTITY, 0); // Show player in world
};