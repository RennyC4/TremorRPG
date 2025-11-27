//
// CSQC cameras
//

// death camera
void() Camera_DeathCam =
{
	if (cvar("developer") > 0)
		return;

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
	if (cvar("developer") > 0)
		return;

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
	if (cvar("developer") > 0)
		return;

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

void(vector targetOrigin) CSQC_UpdateCameraZ =
{
    if (vCameraSmoothOrigin == '0 0 0')
        vCameraSmoothOrigin = targetOrigin;

    float zDiff = targetOrigin_z - vCameraSmoothOrigin_z;

    // Always instantly sync when airborne
    if (!(self.flags & FL_ONGROUND))
    {
        vCameraSmoothOrigin = targetOrigin;
        vCameraZVelocity = 0;
        return;
    }

    // If camera falls far behind, force faster catch-up
    if (zDiff > 8)
    {
        vCameraSmoothOrigin_z += zDiff * min(1, frametime * 10);
        vCameraZVelocity = 0;
    }
    else if (fabs(zDiff) < 0.25)
    {
        vCameraSmoothOrigin_z = targetOrigin_z;
        vCameraZVelocity = 0;
    }
    else
    {
        float stiffness = 1.8;  // MUCH faster response
        float damping   = 0.85;

        vCameraZVelocity += zDiff * stiffness * frametime;
        vCameraZVelocity *= damping;

        vCameraSmoothOrigin_z += vCameraZVelocity;
    }

    vCameraSmoothOrigin_x = targetOrigin_x;
    vCameraSmoothOrigin_y = targetOrigin_y;
};

//
// camera smoothing
vector cam_smoothorg;
vector cam_smoothang;

float(float start, float end) angle_diff =
{
    // result = how much to turn to go from 'start' to 'end'
    // result ranges from -180 to +180

    local float D = anglemod(end) - anglemod(start);

    if (D >  180) D = D - 360;
    if (D < -180) D = D + 360;

    return D;
};

void() Camera_Smooth =
{
    local vector cam_trueorg = getproperty(VF_ORIGIN);
    local vector cam_trueang = getproperty(VF_ANGLES);
    
    if (time < 2 || frametime > 0.025 || vlen(cam_smoothorg - cam_trueorg) > 64)
    {
        cam_smoothorg = cam_trueorg;
        cam_smoothang = cam_trueang;
        
        return;
    }
    
    if (vlen(cam_smoothorg - cam_trueorg) > 32)
        cam_smoothorg = cam_trueorg + (normalize(cam_trueorg - cam_smoothorg)*32);
    
    
    local float smoothing_value = 40;
    
    cam_smoothorg += (cam_trueorg - cam_smoothorg) * frametime * smoothing_value;
    
    cam_smoothang_x += angle_diff(cam_smoothang_x, cam_trueang_x) * frametime * smoothing_value;
    cam_smoothang_y += angle_diff(cam_smoothang_y, cam_trueang_y) * frametime * smoothing_value;
    cam_smoothang_z += angle_diff(cam_smoothang_z, cam_trueang_z) * frametime * smoothing_value;
    
    setproperty(VF_ORIGIN, cam_smoothorg);
    setproperty(VF_ANGLES, cam_smoothang);
};