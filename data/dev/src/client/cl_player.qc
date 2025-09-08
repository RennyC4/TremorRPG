void() Camera_IdleOrbit;
void() Compass_Draw;
void() Coords_Draw;

void() CSQC_Input_Frame =
{
	input_movevalues_x = bound(-350, input_movevalues_x, 350);
	input_movevalues_y = bound(-350, input_movevalues_y, 350);
	input_movevalues_z = bound(-350, input_movevalues_z, 350);
};

string nightskybox = "skyworld_star";
string dayskybox = "";
void() Player_DayNightHandler =
{
	if (timeofday == 0) // day
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
	else if (timeofday == 1) // night
	{
		if (cvar("r_shadow_realtime_world_lightmaps") != 0.1)
		{
			cvar_set("r_shadow_realtime_world_lightmaps", "0.1");
			cvar_set("r_skybox", nightskybox);
			localcmd("fog 0.04 0\n");
			cvar_set("r_skyfog", "0");
			cvar_set("v_cshift_empty", "0 0 50 125");
		}
	}
	else // mid afternoon/early morning
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
			if (zonedisplay_finished > time)
				Draw_ZoneName(g_width, g_height);
			else
				ZoneName_alpha.doalpha = 0;

			if (!player_idle)
			{
				Draw_EventLog();
				Draw_Health();
				Draw_Mana();
				Draw_Stamina();
				Draw_Exp();
				Draw_InCombatorPVP();
				Compass_Draw();
				Coords_Draw();
				Draw_LockOnInfo();
			}

//			Draw_Nametags();
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
			runstandardplayerphysics( self );
		}
				
		// Smooth stair stepping, this has to be done manually!
		vPlayerOriginOld = vPlayerOrigin;

		if (( self.flags & FL_ONGROUND ) && (self.origin_z - vPlayerOriginOld_z > 0))
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

		// Set renderflag for mirrors!
		self.renderflags = RF_EXTERNALMODEL;
    }
	else
        addentity(self);

    return PREDRAW_NEXT;
};

void(float flIsNew) CSQC_Ent_Update =
{
	float flEntType = readbyte();
	
	if (flEntType == ENT_PLAYER)
	{
		if (flIsNew == TRUE)
		{
			self.classname = "player";
			self.solid = SOLID_SLIDEBOX;
			self.predraw = Player_PreDraw;
			self.drawmask = MASK_ENGINE;
			setmodel(self, "models/player_m.glb");
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

		setsize(self, '-16 -16 -24', '16 16 32');
		setorigin(self, self.origin);
	}
};