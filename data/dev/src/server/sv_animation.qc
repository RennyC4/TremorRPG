//
// Animation for players etc
//
$frame 0 1 2 3

//
// Male player model
//

void() player_move_m;
void() player_stand_m;

void() player_climb_m = [$0, player_climb_m]
{
//	print ("WTF2\n");

	if (self.flags & FL_ONGROUND || self.flags & FL_PARTIALGROUND || self.climbing == FALSE)
	{
		player_move_m();
		return;
	}
};

void() player_jump_m = [$2, player_jump_m]
{
	if (self.climbing)
	{
		player_climb_m();
		return;
	}
	if (self.flags & FL_ONGROUND)
	{
		player_move_m();
		return;
	}
};

void() player_move_m = [$3, player_move_m]
{
	if (!self.velocity_x && !self.velocity_y)
	{
		player_stand_m();
		return;
	}
};

void() player_stand_m = [$1, player_stand_m]
{
	if (self.velocity_x || self.velocity_y)
	{
		player_move_m();
		return;
	}
};

//
// Female player model
//

void() player_move_f;
void() player_stand_f;

void() player_climb_f = [$0, player_climb_f]
{
	if (self.flags & FL_ONGROUND || self.flags & FL_PARTIALGROUND || self.climbing == FALSE)
	{
		player_move_f();
		return;
	}
};

void() player_jump_f = [$2, player_jump_f]
{
	if (self.climbing)
	{
		player_climb_f();
		return;
	}
	if (self.flags & FL_ONGROUND)
	{
		player_move_f();
		return;
	}
};

void() player_move_f = [$3, player_move_f]
{
	if (!self.velocity_x && !self.velocity_y)
	{
		player_stand_f();
		return;
	}
};

void() player_stand_f = [$1, player_stand_f]
{
	if (self.velocity_x || self.velocity_y)
	{
		player_move_f();
		return;
	}
};