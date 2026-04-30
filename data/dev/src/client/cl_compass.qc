// -------------------------
// CSQC compass, coordinates
// -------------------------

float compass_radius = 60;

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
	// =========================================================
	// runtime-scaled radius (SAFE)
	// =========================================================
	float radius = compass_radius * UI_Scale();

	// fixed anchor
	vector center;
	center_x = g_width - (UI_Scale() * 65);
	center_y = UI_Scale() * 65;

	// camera yaw
	vector vang = getproperty(VF_ANGLES);
	float yaw = angle_normalize360(vang_y);

	// =========================================================
	// draw ring
	// =========================================================
	float step = 45;
	float ang;

	for (ang = 0; ang < 360; ang += step)
	{
		string lbl = heading_to_cardinal(ang);

		float rad = radius - (UI_Scale() * 14);
		float radAng = (ang - yaw) * M_PI / 180;

		vector p;
		p_x = center_x + cos(radAng) * rad;
		p_y = center_y - sin(radAng) * rad;

		vector txtsize = [UI_Scale() * 10, UI_Scale() * 10];

		float tw = stringwidth(lbl, txtsize_x, 0);

		drawstring(
			[p_x - tw * 0.5,
			 p_y - (UI_Scale() * 5)],
			lbl,
			txtsize,
			(ang == 0 ? COMPASS_HI : COMPASS_FG),
			1,
			0
		);
	}
};

// -----------
// coordinates
// -----------
void() Coords_Draw =
{
	vector org = [
		getstatf(STAT_PLAYER_X),
		getstatf(STAT_PLAYER_Y)
	];

	string txt = strcat(
		"X: ", ftoa_prec(org_x, 0),
		" Y: ", ftoa_prec(org_y, 0)
	);

	vector scale = [UI_Scale() * 10, UI_Scale() * 10];

	float tw = stringwidth(txt, scale_x, 0);

	// =========================================================
	// FIXED COMPASS-RELATIVE ANCHOR (NOT SCREEN EDGE CALC)
	// =========================================================
	vector base;
	base_x = g_width - (UI_Scale() * 90);   // locked HUD column
	base_y = UI_Scale() * 125;                // aligned under compass

	vector pos;
	pos_x = base_x;
	pos_y = base_y;

	// =========================================================
	// BACKGROUND (stable box, not text-driven width shift)
	// =========================================================
	drawfill(
		[pos_x - (UI_Scale() * 8),
		 pos_y - (UI_Scale() * 4)],
		[UI_Scale() * 90, UI_Scale() * 16],
		'0 0 0',
		0.35,
		0
	);

	// TEXT (no longer used for positioning math)
	drawstring(pos, txt, scale, COMPASS_FG, 1, 0);
};