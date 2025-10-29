//
// CSQC cameras
//

// death camera
void() Camera_DeathCam =
{
	vector plyr_pos = getproperty(VF_ORIGIN);
	vector ang = [90, cltime * 16, 0];

	makevectors(ang);

	if (deathcam_dist < 120)
		deathcam_dist += (35 * frametime);

	vector cam_start = plyr_pos;
	vector cam_end = plyr_pos - v_forward * deathcam_dist;

    tracebox(cam_start, '-8 -8 -8', '8 8 8', cam_end, MOVE_NOMONSTERS, self);

	vector cam_pos;
	if (trace_fraction <= 1) // hit wall
		cam_pos = trace_endpos;
	else
		cam_pos = cam_end;

	setviewprop(VF_VIEWENTITY, 0);
	setviewprop(VF_ORIGIN, cam_pos);
	setviewprop(VF_ANGLES, ang);
};

// idle + bonfire camera
void() Camera_IdleOrbit =
{
    float health = getstatf(STAT_HEALTH);
	float atbonfire = getstatf(STAT_BONFIRE);

    if (health <= 0)
        return;

    vector plyr_pos = getproperty(VF_ORIGIN);
	vector ang;
	if (!atbonfire)
		ang = [0, cltime * 16, 0];
	else
		ang = [16, cltime * 16, 0];

    makevectors(ang);

	vector cam_offset;
	if (!atbonfire)
		cam_offset = -v_forward * 64 - v_up * 16;
	else
		cam_offset = -v_forward * 128 + v_up * 32;
    vector cam_target = plyr_pos + cam_offset;

	tracebox(plyr_pos, [-4, -4, -4], [4, 4, 4], cam_target, MOVE_NORMAL, world);

	vector final_pos;
    if (trace_fraction <= 1) // hit wall
        final_pos = trace_endpos + trace_plane_normal * 2;
	else
		final_pos = cam_target;

    setviewprop(VF_VIEWENTITY, 0);
    setviewprop(VF_ORIGIN, final_pos);
    setviewprop(VF_ANGLES, ang);
};

// regular 3rd person camera
void() Camera_Third =
{
	float health = getstatf(STAT_HEALTH);
	if (health <= 0)
		return;

	vector plyr_pos = getproperty(VF_ORIGIN);
	vector ang = getproperty(VF_ANGLES);
	makevectors(ang);

    vector campos = getproperty(VF_ORIGIN) - v_forward * thirdcam_dist + v_up * thirdcam_distz;
    tracebox(plyr_pos, '-16 -16 -16', '16 16 16', campos, MOVE_NOMONSTERS, self);

	self.hitcontentsmaski = CONTENTBIT_BODY|CONTENTBIT_SOLID|CONTENTBIT_PLAYERCLIP|CONTENTBIT_SKY; // Do not go into clip brushes

	if (trace_fraction <= 1) // hit wall
		setproperty(VF_ORIGIN, trace_endpos);
	else
		setproperty(VF_ORIGIN, campos);

    setproperty(VF_AFOV, 90);

	// prevent player model intrusion
	float dist = vlen(trace_endpos - plyr_pos);
	if (dist < 24)
		setviewprop(VF_VIEWENTITY, 1);
	else
		setviewprop(VF_VIEWENTITY, 0.0);

	camera_gdist = dist;
};