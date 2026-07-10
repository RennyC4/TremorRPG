//
// 3D Character portrait
//

void(entity ent, vector pos, vector canvas_size, float zoom) entdraw =
{
    vector pad = [UI(4), UI(4)];

    vector vp_min = pos + pad;
    vector vp_size = canvas_size - pad * 2;

    setviewprop(VF_MIN, vp_min);
    setviewprop(VF_SIZE, vp_size);

    setviewprop(VF_DRAWWORLD, FALSE);
    setviewprop(VF_ANGLES, '0 0 0');
    setviewprop(VF_AFOV, 25);
    setviewprop(VF_ORIGIN, [zoom, 0, 0]);

    addentity(ent);
};

entity doll;
string doll_weapon;
string doll_offhand;
string doll_armor;
string doll_helmet;

void() Doll_ObjectDraw =
{
	vector org, ang, offset;
	string gender = getstats(STAT_GENDER);
	if (!doll.skeletonindex)
	{
		doll.skeletonindex = skel_create(doll.modelindex);
		doll.frame = frameforname(doll.modelindex, "Idle");
	}
	skel_build(doll.skeletonindex, doll, doll.modelindex, 0, 0, 0, 1);

	//
	// draw weapon
	//

	if (doll_weapon != "" && doll_weapon != "Unarmed")
	{
		if (!doll.weapon_vfx)
		{
			doll.weapon_vfx = spawn();
			doll.weapon_vfx.owner = doll;
		}
		else
		{
			string lname = string_tolower(doll_weapon); // case insensitivity

			// Misc
			if (doll_weapon == "Hatchet")
				setmodel(doll.weapon_vfx, "models/hatchet0.glb");
			if (doll_weapon == "Mining Pick")
				setmodel(doll.weapon_vfx, "models/pick0.glb");
			if (doll_weapon == "Fishing Rod")
				setmodel(doll.weapon_vfx, "models/fishrod.glb");

			// Swords
			if (doll_weapon == "Broken Sword")
				setmodel(doll.weapon_vfx, "models/sword0.glb");
			if (doll_weapon == "Short Sword")
				setmodel(doll.weapon_vfx, "models/sword1.glb");

			// Daggers
			if (doll_weapon == "Rusty Dagger")
				setmodel(doll.weapon_vfx, "models/dagger0.glb");

			// Clubs
			if (doll_weapon == "Wood Club")
				setmodel(doll.weapon_vfx, "models/club0.glb");

			// Arrows
			if (strstrofs(lname, "arrow", 0) != -1) // check if this is an arrow-type item
				setmodel(doll.weapon_vfx, "models/quiver.glb");

			//
			// Draw it
			//
			if (strstrofs(lname, "arrow", 0) != -1) // check if this is an arrow-type item
				org = gettaginfo(doll, gettagindex(doll, "mixamorig:Spine1"));			
			else			
				org = gettaginfo(doll, gettagindex(doll, "mixamorig:RightHand"));

			if (strstrofs(lname, "arrow", 0) != -1) // check if this is an arrow-type item
				org = gettaginfo(doll, gettagindex(doll, "mixamorig:Spine1"));			
			else
				org = gettaginfo(doll, gettagindex(doll, "mixamorig:RightHand"));

			offset = '0 0 0';  // offset relative to the bone
			if (gender == "Female")
				offset = '0 10 0';

			// local offset into world space
			org += v_forward * offset_x;
			org += v_right   * offset_y;
			org += v_up      * offset_z;
			doll.weapon_vfx.origin = org;

			// angles
			ang = vectoangles(v_forward, v_up);
			doll.weapon_vfx.angles = ang;
		}
	}
	else
		setmodel(doll.weapon_vfx, __NULL__);

	//
	// draw offhand
	//

	if (doll_offhand != "" && doll_offhand != "Empty")
	{
		if (!doll.offhand_vfx)
		{
			doll.offhand_vfx = spawn();
			doll.offhand_vfx.owner = doll;
			doll.offhand_vfx.drawmask = MASK_VIEWMODEL;
		}
		else
		{
			//
			// Models to draw
			//

			// Shields
			if (doll_offhand == "Broken Buckler")
				setmodel(doll.offhand_vfx, "models/shield0.glb");
			if (doll_offhand == "Flimsy Buckler")
				setmodel(doll.offhand_vfx, "models/shield1.glb");

			// Bows
			if (doll_offhand == "Short Bow")
				setmodel(doll.offhand_vfx, "models/bow0.glb");

			org = gettaginfo(doll, gettagindex(doll, "mixamorig:LeftHand"));
			offset = '0 0 0';  // offset relative to the bone

			// local offset into world space
			org += v_forward * offset_x;
			org += v_right   * offset_y;
			org += v_up      * offset_z;

			doll.offhand_vfx.origin = org;

			// angles
			ang = vectoangles(v_forward, v_up);
			doll.offhand_vfx.angles = ang;
		}
	}
	else
		setmodel(doll.offhand_vfx, __NULL__);


	//
	// draw armor
	//
	
	if (!doll.armor_vfx)
	{
		doll.armor_vfx = spawn();
		doll.armor_vfx.owner = doll;
	}
	else
	{
		org = gettaginfo(doll, gettagindex(doll, "mixamorig:Spine2"));
		offset = '0 0 0';  // offset relative to the bone

		//
		// Models to draw
		//

		// Chest armor
		if (doll_armor == "Padded Armor")
		{
			setmodel(doll.armor_vfx, "models/armor0.glb");
			if (gender == "Female")
			{
				doll.armor_vfx.scale = 0.88;
				offset = '0 3 3';  // offset relative to the bone
			}
		}

		// local offset into world space
		org += v_forward * offset_x;
		org += v_right   * offset_y;
		org += v_up      * offset_z;

		doll.armor_vfx.origin = org;

		// angles
		ang = vectoangles(v_forward, v_up);
		doll.armor_vfx.angles = ang;
	}
		
	//
	// Draw helmet
	//

	if (doll_helmet != "")
	{
		if (!doll.helmet_vfx)
		{
			doll.helmet_vfx = spawn();
			doll.helmet_vfx.owner = doll;
			doll.helmet_vfx.worldlight = TRUE;
		}
		else
		{
			org = gettaginfo(doll, gettagindex(doll, "mixamorig:Head"));
			offset = '0 0 0';  // offset relative to the bone

			//
			// Models to draw
			//

			if (doll_helmet == "Bandit Hood")
			{
				setmodel(doll.helmet_vfx, "models/helmet0.glb");
				if (gender == "Female")
				{
					doll.helmet_vfx.scale = 0.935;
					offset = '0.95 0 -2.5';  // offset relative to the bone
				}
			}
			
			// local offset into world space
			org += v_forward * offset_x;
			org += v_right   * offset_y;
			org += v_up      * offset_z;

			doll.helmet_vfx.origin = org;

			// angles
			ang = vectoangles(v_forward, v_up);
			doll.helmet_vfx.angles = ang;
		}
	}
};

void(vector pos) Draw_3DPDoll =
{
	vector size = [150, 250];
	sui_transform_box(pos, size);

	string gender = getstats(STAT_GENDER);

    if (!doll) // Call this one time so we're not spawning infinite entities
    {
 		doll = spawn();

        precache_model("models/player_m.glb");
        precache_model("models/player_f.glb");

		if (gender == "Male")
		{
			setmodel(doll, "models/player_m.glb");
			modelindex_player_m = doll.modelindex;
		}
		else
		{
			setmodel(doll, "models/player_f.glb");
			modelindex_player_f = doll.modelindex;
		}

		doll.drawflags = 7; // override engine lighting
		doll.abslight = 500; // new lighting level

        setorigin(doll, '0 0 0');
		doll.angles_y -= 180;
	}

	Doll_ObjectDraw();

	doll.angles_y += 50 * frametime;
	if (gender == "Female")
		doll.frame1time += frametime / 2;
	else
		doll.frame1time += frametime;

	vector size = [UI(175), UI(275)];

	// Draw equippables
	clearscene();
	if (doll.weapon_vfx)
	{
		doll.weapon_vfx.drawflags = 7; // override engine lighting
		doll.weapon_vfx.abslight = 500; // new lighting level
		entdraw(doll.weapon_vfx, pos, size, -245);
		addentity(doll.weapon_vfx);
	}

	if (doll.offhand_vfx)
	{
		doll.offhand_vfx.drawflags = 7; // override engine lighting
		doll.offhand_vfx.abslight = 500; // new lighting level
		entdraw(doll.offhand_vfx, pos, size, -245);
		addentity(doll.offhand_vfx);
	}

	if (doll.armor_vfx)
	{
		doll.armor_vfx.drawflags = 7; // override engine lighting
		doll.armor_vfx.abslight = 500; // new lighting level
		entdraw(doll.armor_vfx, pos, size, -245);
		addentity(doll.armor_vfx);
	}
	
	if (doll.helmet_vfx)
	{
		doll.helmet_vfx.drawflags = 7; // override engine lighting
		doll.helmet_vfx.abslight = 500; // new lighting level
		entdraw(doll.helmet_vfx, pos, size, -245);
		addentity(doll.helmet_vfx);
	}
	
	entdraw(doll, pos, size, -245); // draw main character
	addentity(doll);

	renderscene();
};
