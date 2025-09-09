//
// CSQC Lock On
//

float(float cur, float target, float speed, float dt) ApproachAngle =
{
    float delta;

    delta = anglemod(target - cur); // shortest direction
    if (delta > 180)
        delta -= 360;

    if (delta > speed * dt)
        cur += speed * dt;
    else if (delta < -speed * dt)
        cur -= speed * dt;
    else
        cur = target;

    return anglemod(cur);
};

void() FaceTarget =
{
    vector player_pos = [getstatf(STAT_PLAYER_X), getstatf(STAT_PLAYER_Y), getstatf(STAT_PLAYER_Z)];
    vector lockon_pos = [LOCKON_COORD_X, LOCKON_COORD_Y, LOCKON_COORD_Z];
    vector player_ang = getproperty(VF_ANGLES);

    vector dir = normalize(lockon_pos - player_pos);
    vector ang = vectoangles(dir);

    float dt = frametime * 2;   // frame delta time
    float turn_speed = 360; // degrees per second

    // Smoothly approach target yaw/pitch *broken / crap*
    //player_ang[0] = ApproachAngle(player_ang[0], ang_x, turn_speed, dt);
    //player_ang[1] = ApproachAngle(player_ang[1], ang_y, turn_speed, dt);

	player_ang[0] = ang_x;
	player_ang[1] = ang_y;

    // apply
    makevectors(player_ang);
    setproperty(VF_ANGLES, player_ang);

    sendevent("PlayerUpdateAngles", "v", player_ang); // update angles on SSQC
};

void() Draw_LockOnInfo =
{
	float lockon = getstatf(STAT_LOCKEDON);

	if (lockon)
	{
		vector player_pos = [getstatf(STAT_PLAYER_X), getstatf(STAT_PLAYER_Y), getstatf(STAT_PLAYER_Z)];
		vector lockon_pos = [LOCKON_COORD_X, LOCKON_COORD_Y, LOCKON_COORD_Z];

		//
		// Monster plates
		//

		vector plaque_coord = project(lockon_pos);

		if (plaque_coord_y > g_height / 2) // snap plaque
			plaque_coord_y = g_height / 2;

		plaque_coord_x -= 16; // center it
		plaque_coord_y -= 16;

		if (plaque_coord_z > 0)
		{
			drawstring(plaque_coord+[1,1], LOCKON_NAME, [10, 10], [0, 0, 0], 1, 0); // shadow
			drawstring(plaque_coord, LOCKON_NAME, [10, 10], [1, 1, 1], 1, 0);
		}

		// Draw bar + level
		plaque_coord_x -= 12;
		plaque_coord_y += 8;

		vector hbar_size = '50 4 0';
		hbar_size_x = (LOCKON_HEALTH / LOCKON_MAXHEALTH) * hbar_size_x; // keep bar updated
		if (plaque_coord_z > 0)
		{
			drawfill(plaque_coord + [1 , 3], hbar_size, '0 0 0', 1, 0); // shadow
			drawfill(plaque_coord + [0 , 2], hbar_size, '0.5 0 0', 1, 0);
		}

		plaque_coord_x += 28;
		string lvl = ftos(LOCKON_LEVEL);
		if (plaque_coord_z > 0)
		{
			drawstring(plaque_coord + [25, -1], lvl, [10, 10], [0, 0, 0], 1, 0); // shadow
			drawstring(plaque_coord + [24, -2], lvl, [10, 10], [1, .8, 0], 1, 0);
		}
		//
		//

		// Crosshair on target
		vector target_coord = project(lockon_pos);
		target_coord_x -= 32;
		target_coord_y -= 32;

		if (target_coord_y > g_height / 1.75) // snap target crosshair
			target_coord_y = g_height / 1.75;
		
		if (target_coord_z > 0)
			drawpic(target_coord, "progs/targetdot.spr_0", [64, 64], '1 1 1', 1, 0);
	}
};