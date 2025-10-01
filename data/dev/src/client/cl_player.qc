void() Camera_IdleOrbit;
void() Compass_Draw;
void() Coords_Draw;
void() Player_Animate;
void() Draw_NameTag;

void() sParms_Read =
{
	string line;

	float v = fopen("sparms", FILE_READ); // read sParms
	if (v)
	{
		if (line = fgets(v)) // skip first line
		if (line = fgets(v))
			sparm1 = line;
		if (line = fgets(v))
			sparm2 = line;
		if (line = fgets(v))
			sparm3 = line;
		if (line = fgets(v))
			sparm4 = line;
		fclose(v);
	}
	sendevent("SSQC_ReadsParms", "ssss", sparm1, sparm2, sparm3, sparm4); // send sParms to SSQC
};

void() sParms_Write =
{
	sparm1 = getstats(STAT_MAINHAND);
	sparm2 = getstats(STAT_OFFHAND);
	sparm3 = getstats(STAT_ARMORNAME);
	sparm4 = getstats(STAT_SPELLEQUIPPED);

	float v = fopen("sparms", FILE_WRITE); // write sParm file
	if (v)
	{
		fputs(v, LOGIN_NAME, "\n");
		fputs(v, sparm1, "\n");
		fputs(v, sparm2, "\n");
		fputs(v, sparm3, "\n");
		fputs(v, sparm4, "\n");
		fclose(v);
	}
};

void() sParms_Wipe =
{
	float v = fopen("sparms", FILE_WRITE); // write and wipe sParm file
	if (v)
	{
		fputs(v, "");
		fclose(v);
	}
};


void() CSQC_Input_Frame =
{
	input_movevalues_x = bound(-350, input_movevalues_x, 350);
	input_movevalues_y = bound(-350, input_movevalues_y, 350);
	input_movevalues_z = bound(-350, input_movevalues_z, 350);
};

string nightskybox = "skyworld_star";
string dayskybox = "";
const float TIME_DAWN = 0;
const float TIME_DAY = 1;
const float TIME_DUSK = 2;
const float TIME_NIGHT = 3;

void() Player_DayNightHandler =
{
	if (timeofday == TIME_DAY) // day
	{
		if (cvar("r_shadow_realtime_world_lightmaps") != 1)
		{
			cvar_set("r_shadow_realtime_world_lightmaps", "1");
			cvar_set("r_skybox", dayskybox);
			localcmd("fog 0.02\n");
			cvar_set("r_skyfog", "0.5");
			cvar_set("v_cshift_empty", "0 0 0");
		}
	}
	else if (timeofday == TIME_NIGHT) // night
	{
		if (cvar("r_shadow_realtime_world_lightmaps") != 0.1)
		{
			cvar_set("r_shadow_realtime_world_lightmaps", "0.1");
			cvar_set("r_skybox", nightskybox);
			localcmd("fog 0.05 0\n");
			cvar_set("r_skyfog", "0");
			cvar_set("v_cshift_empty", "0 0 50 125");
		}
	}
	else if (timeofday == TIME_DAWN) // early morning (dawn)
	{
		if (cvar("r_shadow_realtime_world_lightmaps") != 0.5)
		{
			cvar_set("r_shadow_realtime_world_lightmaps", "0.5");
			cvar_set("r_skybox", dayskybox);
			localcmd("fog 0.035\n");
			cvar_set("r_skyfog", "0.25");
			cvar_set("v_cshift_empty", "0 0 0");
		}
	}
	else // sunset (dusk)
	{
		if (cvar("r_shadow_realtime_world_lightmaps") != 0.25)
		{
			cvar_set("r_shadow_realtime_world_lightmaps", "0.25");
			cvar_set("r_skybox", dayskybox);
			localcmd("fog 0.035 0.3 .15 0 1\n");
			cvar_set("r_skyfog", "0.8");
			cvar_set("v_cshift_empty", "130 25 0 32");
		}
	}
};

void() Player_Lantern =
{
	entity targ = find(world, classname, "player");
	while (targ)
	{
		if (targ.effects == EF_BRIGHTLIGHT)
		{
			vector laternangle = [0, targ.angles_y, 0];
			makevectors(laternangle);
			dynamiclight_add(targ.origin + v_up * 24 + v_right * 12, 800, [1,1,1], 1, "", PFLAGS_CORONA);
		}
		targ = find(targ, classname, "player");
	}
};

void() Player_Hud =
{
	if (cvar("developer") == 0)
	{
		float player_loggedin = getstatf(STAT_LOGGEDIN);
		float player_menu = getstatf(STAT_MENU);
		if (player_menu > 0)
		{
			setcursormode(TRUE,"gfx/xhair", [5, 5], cvar("vid_conautoscale")); // enable mouse cursor when menus are active

			if (player_menu == MENU_LOGIN)
				User_LoginScreen();
			else
			{
				Draw_Health();
				Draw_Mana();
				Draw_Stamina();
				Draw_Exp();
				Draw_InCombatorPVP();
			}

			if (player_menu == MENU_CHARACTER)
				User_CharacterScreen();
			if (player_menu == MENU_INVENTORY)
			{
				User_InventoryScreen();
				Draw_ToolTip();
			}
			if (player_menu == MENU_MAGIC)
			{
				User_MagicScreen();
				Draw_ToolTip();
			}
			if (player_menu == MENU_DIALOGUE)
				User_NPCDialogue();
			if (player_menu == MENU_BUYSELL)
			{
				User_NPCBuySell();
				Draw_ToolTip();
			}
		}
		else // Regular gameplay
		{
			float zonedisplay_finished = getstatf(STAT_ZONENAME_TIME);
			float health = getstatf(STAT_HEALTH);
			float casting = getstatf(STAT_CASTING);

			if (zonedisplay_finished > time)
				Draw_ZoneName(g_width, g_height);
			else
				ZoneName_alpha.doalpha = 0;

			Draw_NameTag();
			if (!player_idle && health > 0)
			{
				Draw_EventLog();
				Draw_Health();
				Draw_Mana();
				Draw_Stamina();
				Draw_Exp();
				Draw_InCombatorPVP();
				Draw_LockOnInfo();
				if (autocvar_minimap != "off" && autocvar_minimap != "")
				{
					if (substring(world.model, -3, 3) == "hmp") // mini-map only on over world
						WorldMap_Draw([g_width - 112.5, 0], 112.5);
				}
				Compass_Draw();
				Coords_Draw();
				if (casting > time)
					Draw_CastingStat();
			}

			if (time - last_input_time > idle_threshold)
				player_idle = TRUE; // turn on camera orbit

			setcursormode(FALSE,"", 0, 0);
		}
		Player_DayNightHandler();
	}
};

float(void) Player_PreDraw =
{
    if (self.entnum == player_localentnum)
	{
		self.movetype = MOVETYPE_WALK;
		
		// Prepare rollback
		vector vOldOrigin = self.origin;
		vector vOldVelocity = self.velocity;
		float fOldPMoveFlags = self.pmove_flags;

		// Apply physics for every single input-frame that has not yet been
		// acknowledged by the server (servercommandframe = last acknowledged frame)
		for (int i = servercommandframe + 1; i <= clientcommandframe; i++)
		{
		   float flSuccess = getinputstate(i);

			if (flSuccess == FALSE)
				continue;

			if (input_timelength == 0) // Partial frames are the worst
				break;

			runstandardplayerphysics(self);
		}
				
		vPlayerOriginOld = vPlayerOrigin; // Smooth stair stepping, this has to be done manually!

		if ((self.flags & FL_ONGROUND) && (self.origin_z - vPlayerOriginOld_z > 0))
		{
			vPlayerOriginOld_z += frametime * 150;

			if (vPlayerOriginOld_z > self.origin_z)
				vPlayerOriginOld_z = self.origin_z;
			if (self.origin_z - vPlayerOriginOld_z > 18)
				vPlayerOriginOld_z = self.origin_z - 18;

			vPlayerOrigin_z += vPlayerOriginOld_z - self.origin_z;
		}
		else
			vPlayerOriginOld_z = self.origin_z;
			
		vPlayerOrigin = [self.origin_x, self.origin_y, vPlayerOriginOld_z];
		vPlayerVelocity = self.velocity;
		addentity(self);

		// Time to roll back
		self.origin = vOldOrigin;
		setorigin(self, self.origin);
		self.velocity = vOldVelocity;
		self.pmove_flags = fOldPMoveFlags;
		self.movetype = MOVETYPE_NONE;

		self.renderflags = RF_EXTERNALMODEL; // Set renderflag for mirrors!

		Player_Animate();
    }
	else
	{
		Player_Animate(); // animate other players
        addentity(self);
	}

    return PREDRAW_NEXT;
};

.float jump;
.float jump_released;
.float attack_released;
.float attack;
void() Player_Think =
{
	float player_menu = getstatf(STAT_MENU);
	float health = getstatf(STAT_HEALTH);
	if (!player_menu)
	{
		// Get attack speed, tie it to animation speed
		// Stamina check
		if (input_buttons & 1) // Attack
		{
//			if (self.attack_released)
//				self.frame1time = 0; // start from beginning timestamp
			self.attack_released = FALSE;
		}
		else
			self.attack_released = TRUE;

		if (input_buttons & 2) // Jump
		{
//			if (self.jump_released)
//				self.frame1time = 0; // start from beginning timestamp
			self.jump_released = FALSE;
		}
		else
			self.jump_released = TRUE;
	}
	if (health > 0 && deathcam_dist != 45)
		deathcam_dist = 45; // initial z start org for death camera

	// hasn’t been updated, probably gone
    //if (cltime - self.last_update > 1 && self.entnum != player_localentnum)
	//	CSQC_Ent_Remove();
};

void(float flIsNew) CSQC_Ent_Update =
{
	float flEntType = readbyte();
	
	if (flEntType == ENT_PLAYER)
	{
		if (flIsNew == TRUE)
		{
			self.classname = "player";
			self.solid = SOLID_TRIGGER;
			self.predraw = Player_PreDraw;
			self.drawmask = MASK_ENGINE;
		}

		self.origin_x = readcoord();
		self.origin_y = readcoord();
		self.origin_z = readcoord();
		self.angles_x = readcoord();
		self.angles_y = readcoord();
		self.angles_z = readcoord();
		self.velocity_x = readshort();
		self.velocity_y = readshort();
		self.velocity_z = readshort();
		self.flags = readfloat();
		self.effects = readfloat();
		self.modelindex = readshort();
		self.netname = readstring();
		self.climbing = readshort();
		self.health = readshort();

		self.colormod_x = readcoord();
		self.colormod_y = readcoord();
		self.colormod_z = readcoord();

		self.pvp = readbyte();
		self.loggedin = readbyte();
		//self.last_update = cltime;

		setsize(self, [-16, -16, 0], [16, 16, 56]);
		setorigin(self, self.origin);

		self.think = Player_Think;
		self.nextthink = cltime;
	}
};