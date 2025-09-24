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

void() Camera_IdleOrbit =
{
    float health = getstatf(STAT_HEALTH);
    if (health <= 0)
        return;

    vector plyr_pos = getproperty(VF_ORIGIN);
    vector ang = [0, cltime * 16, 0];

    makevectors(ang);

    vector cam_offset = -v_forward * 64 - v_up * 16;
    vector cam_target = plyr_pos + cam_offset;

	tracebox(plyr_pos, [-4, -4, -4], [4, 4, 4], cam_target, MOVE_NORMAL, world);

	vector final_pos;
    if (trace_fraction < 1) // hit wall
        final_pos = trace_endpos + trace_plane_normal * 2;
	else
		final_pos = cam_target;

    setviewprop(VF_VIEWENTITY, 0);
    setviewprop(VF_ORIGIN, final_pos);
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
	
	float dist = vlen(trace_endpos - plyr_pos);
	if (dist < 24)
		setviewprop(VF_VIEWENTITY, 1); // Stop drawing player
	else
		setviewprop(VF_VIEWENTITY, 0.0);
};