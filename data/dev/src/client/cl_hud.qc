// Player HUD
float MAX_CHATMSG = 6;
string messagestack[MAX_CHATMSG];
float messagestack_fade;
float msg_alpha;

void(float screenwidth, float screenheight) Draw_ZoneName =
{
	string zonename = getstats(STAT_ZONENAME);
	vector pos = [(screenwidth - stringwidth(zonename, TRUE, '18 18 0'))/2, (screenheight - 18)/3];

	if (ZoneName_alpha.doalpha < 7.8)
		ZoneName_alpha.doalpha += 0.01;
	else
		ZoneName_alpha.doalpha = 0;

	drawstring(pos - '1 1', zonename, '18 18', '0 0 0', (sin(ZoneName_alpha.doalpha*0.40)*1), 0); // shadow
	drawstring(pos + '1 1', zonename, '18 18', '0 0 0', (sin(ZoneName_alpha.doalpha*0.40)*1), 0); // shadow
	drawstring(pos, zonename, '18 18', '.9 .1 0', (sin(ZoneName_alpha.doalpha*0.40)*1), 0);
};

void() Draw_Health =
{
	float h = getstatf(STAT_HEALTH);
	float hmax = getstatf(STAT_MAXHEALTH);
	
	//
	// Draw Health
	//

	vector pos = [(g_width - stringwidth("", TRUE, '18 18 0'))/12-28, (g_height - 36)];

	// Bar
	vector hbar_size = '100 8 0';
	vector hbar_border_size = hbar_size + '1.6 1.5 0';
	vector hbarpos = pos - '-50 1 0';
	hbar_size_x = (h / hmax) * hbar_size_x; // keep bar updated

	drawfill(hbarpos + '1 1 0', hbar_size, '1 0 0', 1, 0);

	// Text
	string h1 = ftos(h);
	string h2 = ftos(hmax);

	drawstring (pos + '1 1', "Health ", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos, "^1Health ", '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '57 1', h1, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '56 0', h1, '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '96 1', "/", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '95 0', "/", '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '116 1', h2, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '115 0', h2, '8 8 0', '1 1 1', 1, 0);
};