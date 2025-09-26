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

	if (!self.attack_type)
	{
		print ("Yo\n");
		if (self.anim_count == 0) // unarmed comes out immediately
			DoAttack_Melee();
	}
	else
	{
		if (self.anim_count == 0.3)
			DoAttack_Melee();
	}	

	self.melee_finished = time + self.attack_speed;
	self.lockview_finished = time + self.attack_speed;

	self.anim_count += 0.1;
};