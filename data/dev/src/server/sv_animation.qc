//
// Animation for players etc - Slowly being removed for CSQC animations
//

$frame climb death stand jump move slash

void() player_slash = [$slash, player_slash]
{
	if (self.anim_count > 0.6)
	{
		self.anim_count = 0;
		self.think = info_null;
		return;
	}

	if (self.anim_count < 0.1)
		self.pushforward_finished = time + (self.attack_speed / 6);

	if (self.anim_count == 0.3)
		DoAttack_Melee();

	self.melee_finished = time + self.attack_speed;
	self.lockview_finished = time + self.attack_speed;

	self.anim_count += 0.1;
};

void() player_climb = [$climb, player_climb]
{
	if (self.flags & FL_ONGROUND || self.flags & FL_PARTIALGROUND || self.climbing == FALSE)
	{
		self.anim_count = 0;
		//player_move();
		return;
	}
};

void() player_jump = [$jump, player_jump]
{
	if (self.climbing)
	{
		self.anim_count = 0;
		player_climb();
		return;
	}
	if (self.flags & FL_ONGROUND)
	{
		self.anim_count = 0;
		//player_move();
		return;
	}

	if (self.anim_count < 0.4)
		self.anim_count += 0.1;
	else
	{
		self.anim_count = 0;
		//player_move(); // TODO: Falling animation
	}
};

void() player_death = [$death, player_death] {};

// Unneeded?
/*
//
// Female player model
//
void() player_move_f;
void() player_stand_f;

void() player_slash_f = [$slash, player_slash_f]
{
	if (self.anim_count > 10)
	{
		self.anim_count = 0;
		player_move_m();
		return;
	}
	self.anim_count += 1;
};

void() player_climb_f = [$climb, player_climb_f]
{
	if (self.flags & FL_ONGROUND || self.flags & FL_PARTIALGROUND || self.climbing == FALSE)
	{
		player_move_f();
		return;
	}
};

void() player_jump_f = [$jump, player_jump_f]
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

void() player_move_f = [$move, player_move_f]
{
	if (!self.velocity_x && !self.velocity_y)
	{
		player_stand_f();
		return;
	}
};

void() player_stand_f = [$stand, player_stand_f]
{
	if (self.velocity_x || self.velocity_y)
	{
		player_move_f();
		return;
	}
};

//
// Functions for both
//

void() player_slash =
{
	if (self.gender == "Male")
		player_slash_m();
	else
		player_slash_f();
};
*/