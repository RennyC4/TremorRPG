// -------------------------
// CSQC compass, coordinates
// -------------------------

float compass_radius = 60; // radius size of compass rose

// colors
vector COMPASS_FG   = '1 1 1';
vector COMPASS_HI   = '1 0.8 0.25';

// ----------------
// helper functions
// ----------------

float(float a) angle_normalize360 =
{
	while (a < 0) a += 360;
	while (a >= 360) a -= 360;
	return a;
};

string(float hdg) heading_to_cardinal =
{
	float idx = floor(((hdg + 22.5) % 360) / 45);
	if (idx == 0) return "N";
	if (idx == 1) return "NE";
	if (idx == 2) return "E";
	if (idx == 3) return "SE";
	if (idx == 4) return "S";
	if (idx == 5) return "SW";
	if (idx == 6) return "W";
	return "NW";
};

string(float v, float prec) ftoa_prec =
{
	if (prec <= 0) return ftos(floor(v));
	float p = pow(10, prec);
	return ftos(floor(v * p + 0.5) / p);
};

// ---------------
// compass drawing
// ---------------

void() Compass_Draw =
{
	vector center = [g_width - compass_radius, 0 + compass_radius];

	// camera yaw
	vector vang = getproperty(VF_ANGLES);
	float yaw = angle_normalize360(vang_y);

	// draw 8 cardinal directions around circle
	float step = 45;
	float ang;
	for (ang = 0; ang < 360; ang += step)
	{
		string lbl = heading_to_cardinal(ang);
		vector s = [10, 10, 0];
		float rad = compass_radius - 14;
		float radAng = (ang - yaw) * M_PI / 180;
		float x = center_x + cos(radAng) * rad;
		float y = center_y - sin(radAng) * rad;
		vector sz = [stringwidth(lbl, 10, 0), 10];
		vector col = (ang == 0 ? COMPASS_HI : COMPASS_FG);
		drawstring([x - sz_x*0.5+1, y - 5+1], lbl, s, '0 0 0', 1, 0); // shadow
		drawstring([x - sz_x*0.5, y - 5, 0], lbl, s, '1 1 1', 1, 0);
	}
};

// -----------
// coordinates
// -----------
void() Coords_Draw =
{
	vector org = [getstatf(STAT_PLAYER_X), getstatf(STAT_PLAYER_Y)];	

	float prec = 0;
	string sx = ftoa_prec(org_x, prec);
	string sy = ftoa_prec(org_y, prec);
	string txt = strcat("X: ", sx, " Y: ", sy);

	vector scale = [10, 10];
	float tw = stringwidth(txt, 1, 10);
	vector pos = [g_width - tw - (compass_radius /4), compass_radius * 2];

	// backdrop
	drawfill(pos + [-8,-4], [tw+16, 16], '0,0,0', 0.35, 0);
	drawstring(pos, txt, scale, COMPASS_FG, 1, 0);
};