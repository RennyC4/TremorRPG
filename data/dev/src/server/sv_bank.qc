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

// Deposit all carried gold
void(string input) CSEv_User_BankDepositAll_s =
{
	if (self.gold <= 0)
	{
		sprint(self, PRINT_HIGH, "You have no gold to deposit!\n");
		return;
	}

	float amount = self.gold;

	self.gold = 0;
	self.gold_bank += amount;

	stuffcmd(self, sprintf("play %s\n", "menu/menu_buysell.wav")); // sound
	sprint(self, PRINT_HIGH, sprintf("Deposited all gold: %g\n", amount));
};

// Withdraw all bank gold
void(string input) CSEv_User_BankWithdrawAll_s =
{
	if (self.gold_bank <= 0)
	{
		sprint(self, PRINT_HIGH, "You have no gold in the bank!\n");
		return;
	}

	float amount = self.gold_bank;

	self.gold_bank = 0;
	self.gold += amount;

	stuffcmd(self, sprintf("play %s\n", "menu/menu_buysell.wav")); // sound
	sprint(self, PRINT_HIGH, sprintf("Withdrew all bank gold: %g\n", amount));
};