// =======================================
// BANK SYSTEM
// =======================================

// Player fields:
// .float gold;        // player's carried gold
// .float bank_gold;   // gold stored in bank

// Deposit
void(string input) CSEv_User_BankDeposit_s =
{
	string clean = String_StripNonNumeric(input);
	
	if (clean == "" || stof(clean) <= 0)
	{
		sprint(self, PRINT_HIGH, "Invalid amount!\n");
		return;
	}
	
	float amount = stof(clean);

	if (amount <= 0)
	{
		sprint(self, PRINT_HIGH, "Invalid deposit amount!\n");
		return;
	}

	if (self.gold < amount)
	{
		sprint(self, PRINT_HIGH, "You don't have enough gold!\n");
		return;
	}
	
	self.gold -= amount;
	self.gold_bank += amount;

	stuffcmd (self, sprintf("play %s\n", "menu/menu_buysell.wav")); // sound
	sprint(self, PRINT_HIGH, sprintf("Deposited %g gold.\n", amount));
};

// Withdraw
void(string input) CSEv_User_BankWithdraw_s =
{
	string clean = String_StripNonNumeric(input);
	
	if (clean == "" || stof(clean) <= 0)
	{
		sprint(self, PRINT_HIGH, "Invalid amount!\n");
		return;
	}
	
	float amount = stof(clean);

	if (amount <= 0)
	{
		sprint(self, PRINT_HIGH, "Invalid withdrawal amount!\n");
		return;
	}

	if (self.gold_bank < amount)
	{
		sprint(self, PRINT_HIGH, "You don't have enough gold in the bank!\n");
		return;
	}
	
	self.gold_bank -= amount;
	self.gold += amount;
	
	stuffcmd (self, sprintf("play %s\n", "menu/menu_buysell.wav")); // sound
	sprint(self, PRINT_HIGH, sprintf("Withdrew %g gold.\n", amount));
};