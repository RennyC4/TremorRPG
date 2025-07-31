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


float MAX_EVENTLOG = 6;
string messagestack[MAX_CHATMSG];

void(string msg) push_message =
{
	float i = MAX_EVENTLOG - 1;
	while (i > 0)
	{
		messagestack[i] = messagestack[i-1];
		i--;
	}
	if (messagestack[MAX_CHATMSG - 1])
		strunzone(messagestack[MAX_CHATMSG - 1]);

	messagestack[i] = msg;
};

const float PRINT_LOW = 0;
const float PRINT_MEDIUM = 1;
const float PRINT_HIGH = 2;
const float PRINT_CHAT = 3;

/*
noref void(string printmsg, float printlvl) CSQC_Parse_Print =
{
//	push_message(printmsg);
};
*/

void() Draw_EventLog =
{
	vector pos = [0, -45];
	vector size = [230, 100];
	vector text_pos = pos + [2, 46];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	float i;
	for(i=0; i <MAX_EVENTLOG; i++)
	{
		if (messagestack[i] != "")
		{
			sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
			sui_text(text_pos, MENU_TEXT_SMALL, messagestack[i], MENU_TEXT_1, 1, 0);
			text_pos_y += 8;
		}
	}
	sui_pop_frame();
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
	vector hbarpos = pos - '-50 1 0';
	hbar_size_x = (h / hmax) * hbar_size_x; // keep bar updated

	drawfill(hbarpos + '1 1 0', hbar_size, '1 0 0', 1, 0);

	// Text
	string h1 = ftos(h);
	string h2 = ftos(hmax);

	drawstring (pos - '9 -1', "Health", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos - '10 0 0', "^1Health", '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '57 1', h1, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '56 0', h1, '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '96 1', "/", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '95 0', "/", '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '116 1', h2, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '115 0', h2, '8 8 0', '1 1 1', 1, 0);
};

void() Draw_Mana =
{
	float m = getstatf(STAT_MANA);
	float mmax = getstatf(STAT_MAXMANA);

	//
	// Draw Mana
	//

	vector pos = [(g_width - stringwidth("", TRUE, '18 18 0'))/12-28, (g_height - 36)];

	// Bar
	vector mbar_size = '100 8 0';
	vector mbarpos = pos - '-50 -10 0';
	mbar_size_x = (m / mmax) * mbar_size_x; // keep bar updated

	drawfill(mbarpos + '1 1 0', mbar_size, '0 0 1', 1, 0);

	// Text
	string m1 = ftos(m);
	string m2 = ftos(mmax);

	drawstring (pos - '9 -12', "Mana", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos - '10 -11', "^4Mana", '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '57 12', m1, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '56 11', m1, '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '96 12', "/", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '95 11', "/", '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '116 12', m2, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '115 11', m2, '8 8 0', '1 1 1', 1, 0);
};

void() Draw_Stamina =
{
	float s = getstatf(STAT_STAMINA);
	float smax = 100;

	//
	// Draw Stamina
	//

	vector pos = [(g_width - stringwidth("", TRUE, '18 18 0'))/12-28, (g_height - 36)];

	// Bar
	vector sbar_size = '100 8 0';
	vector sbarpos = pos - '-50 -21 0';
	sbar_size_x = (s / smax) * sbar_size_x; // keep bar updated

	drawfill(sbarpos + '1 1 0', sbar_size, '0 1 0', 1, 0);

	// Text
	string s1 = ftos(s);
	string s2 = ftos(smax);

	drawstring (pos - '9 -23', "Stamina", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos - '10 -22', "^2Stamina", '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '57 23', s1, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '56 22', s1, '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '96 23', "/", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '95 22', "/", '8 8 0', '1 1 1', 1, 0);

	drawstring (pos + '116 23', s2, '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos + '115 22', s2, '8 8 0', '1 1 1', 1, 0);
};

void() Draw_Exp = {};