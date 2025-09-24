//
// CSQC 3rd person camera
//

// Death camera
void() Camera_DeathCam =
{
	vector plyr_pos = getproperty(VF_ORIGIN);
	vector ang = [90, cltime * 16, 0];

	makevectors(ang);
	setviewprop(VF_VIEWENTITY, 0.0);
	setviewprop(VF_ORIGIN, plyr_pos - v_forward * 120);
	setviewprop(VF_ANGLES, ang);
};

// Turn on when player is idle for awhile
void() Camera_IdleOrbit =
{
	float health = getstatf(STAT_HEALTH);
	if (health <= 0)
		return;

	vector plyr_pos = getproperty(VF_ORIGIN);
	vector ang = [0, cltime * 16, 0];

	makevectors(ang);
	setviewprop(VF_VIEWENTITY, 0.0);
	setviewprop(VF_ORIGIN, plyr_pos - v_forward*64 - v_up * 16);
	setviewprop(VF_ANGLES, ang);
};

// Regular 3rd person
void() Camera_Third =
{
	float health = getstatf(STAT_HEALTH);
	if (health <= 0)
		return;

	vector plyr_pos = getproperty(VF_ORIGIN);

	// Regular 3rd person camera
	camang = getproperty(VF_ANGLES);
	makevectors(camang);

    campos = getproperty(VF_ORIGIN) - v_forward * 100 + v_up * 20;
    plyr_pos = getproperty(VF_ORIGIN);

    tracebox(plyr_pos, '-16 -16 -16', '16 16 16', campos, MOVE_NOMONSTERS, self);

    setproperty(VF_ORIGIN, trace_endpos);
    setproperty(VF_AFOV, 90);
	// TODO: dist check
	setviewprop(VF_VIEWENTITY, 0); // Show player in world
};