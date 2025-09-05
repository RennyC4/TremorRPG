//
// Animation for players etc
//
$frame 0 1 2

//
// Male player model
//

void() player_stand_m;

void() player_jump_m = [$2, player_jump_m]
{
	if (self.flags & FL_ONGROUND)
	{
		player_stand_m();
		return;
	}
	self.frame = 1; // jump, needs a loop / landing
};

void() player_move_m = [$0, player_move_f]
{
	if (!self.velocity_x && !self.velocity_y)
	{
		//self.walkframe = 0;
		player_stand_m();
		return;
	}
	self.frame = 2; // walk cycle
};

void() player_stand_m = [$1, player_stand_f]
{
	if (self.velocity_x || self.velocity_y)
	{
		//self.walkframe = 0;
		player_move_m();
		return;
	}
	self.frame = 0; // stand cycle
};

//
// Female player model
//

void() player_stand_f;

void() player_jump_f = [$2, player_jump_f]
{
	if (self.flags & FL_ONGROUND)
	{
		player_stand_f();
		return;
	}
	self.frame = 1; // jump, needs a loop / landing
};

void() player_move_f = [$0, player_move_f]
{
	if (!self.velocity_x && !self.velocity_y)
	{
		//self.walkframe = 0;
		player_stand_f();
		return;
	}
	self.frame = 2; // walk cycle
};

void() player_stand_f = [$1, player_stand_f]
{
	if (self.velocity_x || self.velocity_y)
	{
		//self.walkframe = 0;
		player_move_f();
		return;
	}
	self.frame = 0; // stand cycle
};