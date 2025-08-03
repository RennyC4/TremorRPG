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

//	con_printf("eventlog", "some test text\n"); // push message csqc
//	con_draw("evenlog", pos, size, 8); // draw on screen
//  conecho foo "text" // push message ssqc
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

void() Draw_Exp = 
{
	float e = getstatf(STAT_EXP);
	float e2 = getstatf(STAT_EXPNEEDED);
	float e3 = getstatf(STAT_EXPOLDNEEDED);

	float disp = e - e3;
	float disp_max = e2 - e3;

	//
	// Draw Experience
	//

	vector pos;
	pos_x = g_width * 0.0001;
	pos_y = g_height * 0.99;
	pos_z = 0;

	// Bar
	vector ebar_size, ebar_size_max;
	ebar_size_x = (disp / disp_max) * g_width; // keep bar updated
	ebar_size_y = 8;
	ebar_size_z = 0;

	drawfill(pos + '1 1 0', ebar_size, '1 1 0', 0.25, 0);
	drawfill(pos + '1 1 0', g_width, '1 1 0', 0.08, 0); // Full bar display
};

//
// Reki's Code to draw 3D Objects properly on the HUD
//

void(entity ent, vector pos, vector canvas_size, float zoom) entdraw =
{
    clearscene();
    setviewprop(VF_MIN, pos);
    setviewprop(VF_SIZE, canvas_size);
 
    setviewprop(VF_AFOV, 25);
    setviewprop(VF_DRAWWORLD, FALSE);
 
    setviewprop(VF_ORIGIN, [zoom, 0, 0]);
    setviewprop(VF_ANGLES, '0 0 0');
 
    addentity(ent);
    renderscene();
};

//
// 3D Character portrait
//

float Draw_3DDoll_Once;
entity doll;
void(vector pos) Draw_3DPDoll =
{
    if (!Draw_3DDoll_Once) // Call this one time so we're not spawning infinite head entities
    {
        Draw_3DDoll_Once = 1;
 
		doll = spawn();
        precache_model("models/player_m.iqm");
		// TODO: Draw female player model
        setmodel(doll, "models/player_m.iqm");
        setorigin(doll, '0 0 0');
		doll.angles_y -= 180;
		doll.origin_z -= 35;
    }
	doll.angles_y += 0.1;
	//entdraw(doll, pos, '150 250', -225);
	entdraw(doll, pos, '150 250', -245);
};

//
// Character stat screen + Skill point distribution
//

void() User_CharacterScreen =
{
	string disp_gender = getstats(STAT_GENDER);
	float disp_level = getstatf(STAT_LEVEL);
	float disp_exp =  getstatf(STAT_EXP);
	float disp_neededexp =  getstatf(STAT_EXPNEEDED);
	float disp_gold =  getstatf(STAT_GOLD);
	float disp_skillpoints =  getstatf(STAT_SKILLPOINTS);
	string disp_mainhand = getstats(STAT_MAINHAND);
	string disp_offhand = getstats(STAT_OFFHAND);

	float disp_attackmin = getstatf(STAT_ATTACKMIN);
	float disp_attackmax = getstatf(STAT_ATTACKMAX);
	float disp_attackspeed = getstatf(STAT_ATTACKSPEED);

	string disp_armorname = getstats(STAT_ARMORNAME);
	float disp_armorvalue = getstatf(STAT_ARMORVALUE);

	vector pos = [25, 25];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	// Display name, gender
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	string displaystat = strcat(disp_gender, " ^1", LOGIN_NAME);
	sui_text([0, 4], MENU_TEXT_MEDIUM, displaystat, MENU_TEXT_1, 1, 0);

	// 3D Character box
	pos_y += 10;
	size = [125, 150];
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_border_box(pos, size, 2, MENU_BORDER, 0.3, 0);
	sui_fill(pos, size, MENU_BG_DARK, 0.75, 0);

	// Draw 3D doll model
	pos = [37, -10];
	Draw_3DPDoll(pos);

	//Level, Experience, Next Experience
	vector newpos = [25,30];

	displaystat = strcat("^5Level: ^7", ftos(disp_level));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Exp: ^7", ftos(disp_exp));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Needed: ^7", ftos(disp_neededexp));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Gold: ^7", ftos(disp_gold));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Skill Points: ^7", ftos(disp_skillpoints));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 15;

	displaystat = strcat("^5Main Hand ");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;
	
	displaystat = strcat(disp_mainhand, " (^8", ftos(disp_attackmin), "-", ftos(disp_attackmax), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	float disp_dps = (disp_attackmin + disp_attackmax * 0.5) / disp_attackspeed; // calculate DPS
	displaystat = strcat("^1DPS: ^7" , ftos(disp_dps));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 15;

	displaystat = "^5Off Hand";
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;
	
	displaystat = disp_offhand;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = "^2Blocking: ^70";
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 15;

	displaystat = strcat("^5Armor: ^7", disp_armorname, " (^2", ftos(disp_armorvalue), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	// Draw skill point box/frame/text
	pos = [75, 0];
	size = [250, 280];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	pos = [0, -15];
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_text(pos, MENU_TEXT_MEDIUM, "^2Skills", MENU_TEXT_1, 1, 0);
};