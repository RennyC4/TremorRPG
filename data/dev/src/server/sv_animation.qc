//
// Animation for players etc
//
$frame 0 1

// Female player model

void() player_stand_f;
void() player_move_f = [$0, player_move_f]
{
	if (!self.velocity_x && !self.velocity_y)
	{
		//self.walkframe = 0;
		player_stand_f();
		return;
	}
	self.frame = 1; // walk cycle
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