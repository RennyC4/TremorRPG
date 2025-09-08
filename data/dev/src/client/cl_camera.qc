//
// CSQC 3rd person camera
//

vector plyr_pos;

// Turn on when player is idle for awhile
void() Camera_IdleOrbit =
{
	vector plyr_pos = getproperty(VF_ORIGIN);
	vector ang = [0, cltime * 16, 0];

	makevectors(ang);
	setviewprop(VF_VIEWENTITY, 0.0);
	setviewprop(VF_ORIGIN, plyr_pos - v_forward*64 - v_up * 16);
	setviewprop(VF_ANGLES, ang);
};

void() Camera_Third =
{
	vector plyr_pos = getproperty(VF_ORIGIN);

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