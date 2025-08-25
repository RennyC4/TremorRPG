//
// Player HUD
//

//
// Reki's Code to draw 3D objects on the HUD
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

void() Draw_EventLog =
{
	vector pos = [0, -45];
	vector size = [230, 100];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	sui_push_frame(pos, size);
	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);
	sui_pop_frame();

	// Draw text
	pos = [(g_width * 0.0001), (g_height - 146)];
	size = [330, 100];
	if (drawfont != drawfont2)
		drawfont = drawfont2;
	con_draw("event", pos, size, 12);
	if (drawfont != drawfont1)
		drawfont = loadfont("", "Courier Prime Code", "12,16,24,32,64,72,128,256,512", -1, 0, 0); // set font back
};

void() Draw_InCombatorPVP =
{
	float incombat = getstatf(STAT_INCOMBAT);
	float pvp = getstatf(STAT_PVP);

	vector pos = [(g_width / 100 + 155), (g_height - 38)];
	vector size = [35, 35];

	if (!pvp || pvp == 2)
	{
		if (incombat) // only show when in combat or PVP flagged
			drawpic (pos, "progs/combat.png", size, '1 1 1', 1, 0);
	}
	else if (pvp == 1)
		drawpic (pos, "progs/combat.png", size, '1 .25 .25', 1, 0); // PVP Icon	
};

void() Draw_Health =
{
	float h = getstatf(STAT_HEALTH);
	float hmax = getstatf(STAT_MAXHEALTH);

	//
	// Draw Health
	//

	vector pos = [10, (g_height - 36)];

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

	vector pos = [10, (g_height - 36)];

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

	vector pos = [10, (g_height - 36)];

	// Bar
	vector sbar_size = '100 8 0';
	vector sbarpos = pos - '-50 -21 0';
	sbar_size_x = (s / smax) * sbar_size_x; // keep bar updated

	drawfill(sbarpos + '1 1 0', sbar_size, '0 1 0', 1, 0);

	// Text
	string s1 = ftos(s);
	string s2 = ftos(smax);	
	string dispfix_stamina = sprintf("%.1f", s); // cut down numbers

	drawstring (pos - '9 -23', "Stamina", '8 8 0', '0 0 0', 1, 0); // text shadow
	drawstring (pos - '10 -22', "^2Stamina", '8 8 0', '1 1 1', 1, 0);

	if (s < 100)
	{
		drawstring (pos + '57 23', dispfix_stamina, '8 8 0', '0 0 0', 1, 0); // text shadow
		drawstring (pos + '56 22', dispfix_stamina, '8 8 0', '1 1 1', 1, 0);
	}
	else
	{
		drawstring (pos + '57 23', s1, '8 8 0', '0 0 0', 1, 0); // text shadow
		drawstring (pos + '56 22', s1, '8 8 0', '1 1 1', 1, 0);
	}

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
	vector disp_bar = [0, g_width, 0];

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
	drawfill(pos + '1 1 0', disp_bar, '1 1 0', 0.08, 0); // Full bar display
};

//
// 3D Character portrait
//

entity doll;
void(vector pos) Draw_3DPDoll =
{
    if (!doll) // Call this one time so we're not spawning infinite head entities
    {
 
		doll = spawn();
        precache_model("models/player_m.glb");
		// TODO: Draw female player model
        setmodel(doll, "models/player_m.glb");
        setorigin(doll, '0 0 0');
		doll.angles_y -= 180;
		doll.origin_z -= 35;
    }
	doll.angles_y += 0.2;
	entdraw(doll, pos, '150 250', -245);
};

//
// Character stat screen + skill point distribution
//

void() User_CharacterScreen =
{
	float get_h = getstatf(STAT_HEALTH);
	if (get_h <= 0)
		return;

	// darken screen
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	string displaystat;

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
	float disp_attacktype = getstatf(STAT_ATTACKTYPE);
	string disp_armorname = getstats(STAT_ARMORNAME);
	float disp_armorvalue = getstatf(STAT_ARMORVALUE);
	float disp_unarmed = getstatf(STAT_SKILL_UNARMED);
	float disp_slash = getstatf(STAT_SKILL_SLASH);
	float disp_pierce = getstatf(STAT_SKILL_PIERCE);
	float disp_bash = getstatf(STAT_SKILL_BASH);
	float disp_stealth = getstatf(STAT_SKILL_STEALTH);
	float disp_backstab = getstatf(STAT_SKILL_BACKSTAB);
	float disp_offensivemagic = getstatf(STAT_SKILL_OFFENSIVEMAGIC);
	float disp_defensivemagic = getstatf(STAT_SKILL_DEFENSIVEMAGIC);
	float disp_neutralmagic = getstatf(STAT_SKILL_NEUTRALMAGIC);
	float disp_endurance = getstatf(STAT_SKILL_ENDURANCE);
	float disp_spellresist = getstatf(STAT_SKILL_SPELLRESIST);
	float disp_archery = getstatf(STAT_SKILL_ARCHERY);
	float disp_healthregen = getstatf(STAT_SKILL_HEALTHREGEN);
	float disp_manaregen = getstatf(STAT_SKILL_MANAREGEN);
	float disp_haggle = getstatf(STAT_SKILL_HAGGLE);
	float disp_climb = getstatf(STAT_SKILL_CLIMB);
	float disp_swim = getstatf(STAT_SKILL_SWIM);
	float disp_acrobatic = getstatf(STAT_SKILL_ACROBATIC);
	float disp_reapermarks = getstatf(STAT_REAPERMARK);
	float disp_blocking = getstatf(STAT_BLOCKVALUE);

	vector pos = [25, 25];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	// Display name, gender
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	displaystat = strcat(disp_gender, " ^1", LOGIN_NAME);
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
	vector newpos = [2,30];

	displaystat = strcat("^5Level:^7", ftos(disp_level));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Exp:^7", ftos(disp_exp), " / ", ftos(disp_neededexp));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Gold:^7", ftos(disp_gold));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Skill Points:^7", ftos(disp_skillpoints));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 12.5;

	displaystat = strcat("^5Main Hand:");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;
	
	displaystat = strcat(disp_mainhand, " (^8", ftos(disp_attackmin), "-", ftos(disp_attackmax), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	float disp_dps = (disp_attackmin + disp_attackmax * 0.5) / disp_attackspeed; // calculate DPS
	
	// add skill calculation to DPS
	if (!disp_attacktype) // unarmed
		disp_dps = disp_dps + (disp_unarmed * 0.1);
	else if (disp_attacktype == 1) // slashing
		disp_dps = disp_dps + (disp_slash * 0.1);
	else if (disp_attacktype == 2) // piercing
		disp_dps = disp_dps + (disp_pierce * 0.1);
	else // bashing
		disp_dps = disp_dps + (disp_bash * 0.1);

	string dispfix_dps = ftos(disp_dps);
	dispfix_dps = sprintf("%.2f", disp_dps); // cut down numbers

	if (!disp_attacktype)			string displaystat2 = "Unarmed";
	else if (disp_attacktype == 1)  displaystat2 = "Slash";
	else if (disp_attacktype == 2)  displaystat2 = "Pierce";
	else if (disp_attacktype == 4)  displaystat2 = "Bash";
	else displaystat2 = "Unknown";

	displaystat = strcat("^1DPS:^7" , dispfix_dps, " (^8", displaystat2, "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 12.5;

	displaystat = "^5Off Hand:";
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;
	
	displaystat = disp_offhand;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^2Blocking:^7" , ftos(disp_blocking), "\n");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 22;

	displaystat = strcat("^5Armor:^7", disp_armorname, " (^2+", ftos(disp_armorvalue), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^1Reaper Marks:^7", ftos(disp_reapermarks));
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

	//
	// skill stats
	//

	// Draw skill point text
	newpos = [5, 5];

	displaystat = strcat("^5Unarmed:^7", ftos(disp_unarmed));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Slashing:^7", ftos(disp_slash));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Piercing:^7", ftos(disp_pierce));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Bashing:^7", ftos(disp_bash));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);
	
	newpos_y +=10;

	displaystat = strcat("^5Stealth:^7", ftos(disp_stealth));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);
	
	newpos_y +=10;

	displaystat = strcat("^5Backstab:^7", ftos(disp_backstab));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);
	
	newpos_y +=10;

	displaystat = strcat("^5Offensive Magic:^7", ftos(disp_offensivemagic));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Defensive Magic:^7", ftos(disp_defensivemagic));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Neutral Magic:^7", ftos(disp_neutralmagic));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Endurance:^7", ftos(disp_endurance));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Spell Resist:^7", ftos(disp_spellresist));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Archery:^7", ftos(disp_archery));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Health Regeneration:^7", ftos(disp_healthregen));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Mana Regeneration:^7", ftos(disp_manaregen));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Haggling:^7", ftos(disp_haggle));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Climbing:^7", ftos(disp_climb));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Swimming:^7", ftos(disp_swim));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y +=10;

	displaystat = strcat("^5Acrobatics:^7", ftos(disp_acrobatic));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	//
	// skill buttons for stat increases
	//

	newpos = [-5, 5]; // reset newpos

	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);

	my_button("skillpoint_unarmed", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 0) : 0;
	newpos_y +=10;
	my_button("skillpoint_slash", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 1) : 0;
	newpos_y +=10;
	my_button("skillpoint_pierce", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 2) : 0;
	newpos_y +=10;
	my_button("skillpoint_bash", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 3) : 0;
	newpos_y +=10;
	my_button("skillpoint_stealth", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 4) : 0;
	newpos_y +=10;
	my_button("skillpoint_backstab", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 5) : 0;
	newpos_y +=10;
	my_button("skillpoint_offensivemagic", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 6) : 0;
	newpos_y +=10;
	my_button("skillpoint_defensivemagic", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 7) : 0;
	newpos_y +=10;
	my_button("skillpoint_neutralmagic", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 8) : 0;
	newpos_y +=10;
	my_button("skillpoint_endurance", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 9) : 0;
	newpos_y +=10;
	my_button("skillpoint_spellresist", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 10) : 0;
	newpos_y +=10;
	my_button("skillpoint_archery", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 11) : 0;
	newpos_y +=10;
	my_button("skillpoint_healthregen", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 12) : 0;
	newpos_y +=10;
	my_button("skillpoint_manaregen", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 13) : 0;
	newpos_y +=10;
	my_button("skillpoint_haggling", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 14) : 0;
	newpos_y +=10;
	my_button("skillpoint_climbing", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 15) : 0;
	newpos_y +=10;
	my_button("skillpoint_swimming", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 16) : 0;
	newpos_y +=10;
	my_button("skillpoint_acrobatics", newpos, [25, 10], "+") ? sendevent("User_AddSkillPoint", "f", 17) : 0;

	// PVP button
	
	newpos = [2, -2]; // reset newpos

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);
	float disp_pvp = getstatf(STAT_PVP);
	if (!disp_pvp)
		string pvpcolor = "^8PVP";
	else if (disp_pvp == 1)
		pvpcolor = "^1PVP";
	else
		pvpcolor = "^2PVP";

	my_button("pvp_toggle", newpos, [25, 25], pvpcolor) ? sendevent("User_TogglePVP", "") : 0;

	newpos_x += 26;

	my_button("inventory_toggle", newpos, [72, 25], "Inventory") ? sendevent("PlayerShowInventory", "") : 0;

	sui_pop_frame();
};

//
// Character inventory screen + use/drop items
//

void() User_InventoryScreen =
{
	float get_h = getstatf(STAT_HEALTH);
	if (get_h <= 0)
		return;

	// darken screen
	vector scrsz = [g_width, g_height];
	drawfill('0 0', scrsz, '0 0 0', 0.65);

	string displaystat;

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
	float disp_attacktype = getstatf(STAT_ATTACKTYPE);
	string disp_armorname = getstats(STAT_ARMORNAME);
	float disp_armorvalue = getstatf(STAT_ARMORVALUE);
	float disp_unarmed = getstatf(STAT_SKILL_UNARMED);
	float disp_slash = getstatf(STAT_SKILL_SLASH);
	float disp_pierce = getstatf(STAT_SKILL_PIERCE);
	float disp_bash = getstatf(STAT_SKILL_BASH);
	float disp_reapermarks = getstatf(STAT_REAPERMARK);
	float disp_blocking = getstatf(STAT_BLOCKVALUE);

	vector pos = [25, 25];
	vector size = [450, 325];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	// Display name, gender
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
	displaystat = strcat(disp_gender, " ^1", LOGIN_NAME);
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
	vector newpos = [2,30];

	displaystat = strcat("^5Level:^7", ftos(disp_level));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Exp:^7", ftos(disp_exp), " / ", ftos(disp_neededexp));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Gold:^7", ftos(disp_gold));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^5Skill Points:^7", ftos(disp_skillpoints));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 12.5;

	displaystat = strcat("^5Main Hand:");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;
	
	displaystat = strcat(disp_mainhand, " (^8", ftos(disp_attackmin), "-", ftos(disp_attackmax), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	float disp_dps = (disp_attackmin + disp_attackmax * 0.5) / disp_attackspeed; // calculate DPS
	
	// add skill calculation to DPS
	if (!disp_attacktype) // unarmed
		disp_dps = disp_dps + (disp_unarmed * 0.1);
	else if (disp_attacktype == 1) // slashing
		disp_dps = disp_dps + (disp_slash * 0.1);
	else if (disp_attacktype == 2) // piercing
		disp_dps = disp_dps + (disp_pierce * 0.1);
	else // bashing
		disp_dps = disp_dps + (disp_bash * 0.1);

	string dispfix_dps = ftos(disp_dps);
	dispfix_dps = sprintf("%.2f", disp_dps); // cut down numbers

	if (!disp_attacktype)			string displaystat2 = "Unarmed";
	else if (disp_attacktype == 1)  displaystat2 = "Slash";
	else if (disp_attacktype == 2)  displaystat2 = "Pierce";
	else if (disp_attacktype == 4)  displaystat2 = "Bash";
	else displaystat2 = "Unknown";

	displaystat = strcat("^1DPS:^7" , dispfix_dps, " (^8", displaystat2, "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 12.5;

	displaystat = "^5Off Hand:";
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;
	
	displaystat = disp_offhand;
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^2Blocking:^7" , ftos(disp_blocking), "\n");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 22;

	displaystat = strcat("^5Armor:^7", disp_armorname, " (^2+", ftos(disp_armorvalue), "^7)");
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	newpos_y += 10;

	displaystat = strcat("^1Reaper Marks:^7", ftos(disp_reapermarks));
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_CENTER]);
	sui_text(newpos, MENU_TEXT_SMALL, displaystat, MENU_TEXT_1, 1, 0);

	// Draw inventory point box/frame/text
	pos = [75, 0];
	size = [250, 280];

	sui_set_align([SUI_ALIGN_CENTER, SUI_ALIGN_CENTER]);
	sui_push_frame(pos, size);

	sui_fill([0, 0], size, MENU_BG, 0.75, 0);
	sui_border_box([0, 0], size, 2, MENU_BORDER, 0.3, 0);

	pos = [0, -15];
	sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
	sui_text(pos, MENU_TEXT_MEDIUM, "^2Inventory", MENU_TEXT_1, 1, 0);

	//
	// inventory item display
	//

	newpos = [2.5, 2.5];
	vector buttonpos = [-2.5, 2.5];
	vector linepos = [2.5, 2.5];

	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);

	float i;
	string j = "";
	string d = "";
    for (i = 0; i < inv_count; i++)
    {
		string item_disp = strcat("^5", inventory[i], " ^7[^2", ftos(inventory_count[i]), "^7]");
		if (inventory_count[i] > 0)
		{
			float usebutton_count = 0;
			while (usebutton_count < inventory_count[i]) // setup use buttons
			{
				usebutton_count += 1;
				j = strcat("u_", inventory[i]);
				d = strcat("d_", inventory[i]);
			}
			sui_text(linepos, MENU_TEXT_SMALL, item_disp, MENU_TEXT_1, 1, 0);
			sui_set_align([SUI_ALIGN_END, SUI_ALIGN_START]);
			buttonpos_x = -2.5;
			my_button(j, buttonpos, [32, 10], "Use") ? sendevent("UseItem", "s", inventory[i]) : 0;
			buttonpos_x = -34;
			my_button(d, buttonpos, [32, 10], "Drop") ? sendevent("DropItem", "s", inventory[i]) : 0;
			sui_set_align([SUI_ALIGN_START, SUI_ALIGN_START]);
		}
		linepos_y += 10;
		buttonpos_y += 10;
    }

	//
	// Bottom button list
	//
	newpos = [2, -2]; // reset newpos

	// PVP button
	sui_set_align([SUI_ALIGN_START, SUI_ALIGN_END]);

	float disp_pvp = getstatf(STAT_PVP);
	if (!disp_pvp)
		string pvpcolor = "^8PVP";
	else if (disp_pvp == 1)
		pvpcolor = "^1PVP";
	else
		pvpcolor = "^2PVP";

	my_button("pvp_toggle", newpos, [25, 25], pvpcolor) ? sendevent("User_TogglePVP", "") : 0;

	newpos_x += 26;

	my_button("stats_toggle", newpos, [72, 25], "Skills") ? sendevent("PlayerShowStats", "") : 0;

	sui_pop_frame();
};