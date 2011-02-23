float g_znix_with_laser;

.float znix_nextchange;
.float znix_weapon;
.float znix_weapon_ammo;
.float znix_nextweapon;
.float znix_nextweapon_ammo;
.float znix_lastchange_id;
.float znix_lastinfotime;
.float znix_nextincr;

.float znix_save_cells;
.float znix_save_shells;
.float znix_save_nails;
.float znix_save_rockets;
.float znix_save_fuel;
.float znix_save_weapons;

float ZNIX_CanChooseWeapon(float wpn)
{
	entity e;
	e = get_weaponinfo(wpn);
	if(!e.weapons) // skip dummies
		return FALSE;
	if(g_weaponarena)
	{
		if not(g_weaponarena & e.weapons)
			return FALSE;
	}
	else
	{
		if(wpn == WEP_LASER) // && g_znix_with_laser) //fuck the laser
			return FALSE;
		if not(e.spawnflags & WEP_FLAG_NORMAL)
			return FALSE;
	}
	return TRUE;
}
void ZNIX_ChooseNextWeapon()
{
	float j;
	RandomSelection_Init();
	for(j = WEP_FIRST; j <= WEP_LAST; ++j)
		if(ZNIX_CanChooseWeapon(j))
			RandomSelection_Add(world, j, string_null, 1, (j != self.znix_weapon));
	self.znix_nextweapon = RandomSelection_chosen_float;
	self.znix_nextweapon_ammo = W_AmmoItemCode(self.znix_nextweapon);
}

void ZNIX_GiveCurrentWeapon()
{
	float dt;

	if(!self.znix_nextweapon)
		ZNIX_ChooseNextWeapon();

	dt = ceil(self.znix_nextchange - time);

	if(dt <= 0)
	{
		self.znix_weapon = self.znix_nextweapon;
		self.znix_weapon_ammo = self.znix_nextweapon_ammo;
		self.znix_nextweapon = 0;
		self.znix_nextchange = time + autocvar_g_balance_nix_roundtime;
		//weapon_action(self.znix_weapon, WR_PRECACHE); // forget it, too slow
	}
	
	if(self.znix_nextchange != self.znix_lastchange_id) // this shall only be called once per round!
	{
		self.znix_lastchange_id = self.znix_nextchange;
		if (self.items & IT_UNLIMITED_WEAPON_AMMO)
		{
			self.ammo_shells = (self.znix_weapon_ammo & IT_SHELLS) ?
				autocvar_g_pickup_shells_max : 0;
			self.ammo_nails = (self.znix_weapon_ammo & IT_NAILS) ?
				autocvar_g_pickup_nails_max : 0;
			self.ammo_rockets = (self.znix_weapon_ammo & IT_ROCKETS) ?
				autocvar_g_pickup_rockets_max : 0;
			self.ammo_cells = (self.znix_weapon_ammo & IT_CELLS) ?
				autocvar_g_pickup_cells_max : 0;
			self.ammo_fuel = (self.znix_weapon_ammo & IT_FUEL) ?
				autocvar_g_pickup_fuel_max : 100;
		}
		else
		{
			self.ammo_shells = (self.znix_weapon_ammo & IT_SHELLS) ?
				autocvar_g_balance_nix_ammo_shells : 0;
			self.ammo_nails = (self.znix_weapon_ammo & IT_NAILS) ?
				autocvar_g_balance_nix_ammo_nails : 0;
			self.ammo_rockets = (self.znix_weapon_ammo & IT_ROCKETS) ?
				autocvar_g_balance_nix_ammo_rockets : 0;
			self.ammo_cells = (self.znix_weapon_ammo & IT_CELLS) ?
				autocvar_g_balance_nix_ammo_cells : 0;
			self.ammo_fuel = (self.znix_weapon_ammo & IT_FUEL) ?
				autocvar_g_balance_nix_ammo_fuel : 100;
		}
		self.znix_nextincr = time + autocvar_g_balance_nix_incrtime;
		if(dt >= 1 && dt <= 5)
			self.znix_lastinfotime = -42;
		else
			centerprint(self, strcat("\n\n^2Active weapon: ^3", W_Name(self.znix_weapon)));
	}
	if(self.znix_lastinfotime != dt)
	{
		self.znix_lastinfotime = dt; // initial value 0 should count as "not seen"
		if(dt >= 1 && dt <= 5)
			centerprint(self, strcat("^3", ftos(dt), "^2 seconds until weapon change...\n\nNext weapon: ^3", W_Name(self.znix_nextweapon), "\n"));
	}

	if(!(self.items & IT_UNLIMITED_WEAPON_AMMO) && time > self.znix_nextincr)
	{
		if (self.znix_weapon_ammo & IT_SHELLS)
			self.ammo_shells = self.ammo_shells + autocvar_g_balance_nix_ammoincr_shells;
		else if (self.znix_weapon_ammo & IT_NAILS)
			self.ammo_nails = self.ammo_nails + autocvar_g_balance_nix_ammoincr_nails;
		else if (self.znix_weapon_ammo & IT_ROCKETS)
			self.ammo_rockets = self.ammo_rockets + autocvar_g_balance_nix_ammoincr_rockets;
		else if (self.znix_weapon_ammo & IT_CELLS)
			self.ammo_cells = self.ammo_cells + autocvar_g_balance_nix_ammoincr_cells;
		if (self.znix_weapon_ammo & IT_FUEL) // hook uses cells and fuel
			self.ammo_fuel = 100; //self.ammo_fuel + autocvar_g_balance_nix_ammoincr_fuel;
		self.znix_nextincr = time + autocvar_g_balance_nix_incrtime;
	}

	self.weapons = 0;
	if(g_znix_with_laser)
		self.weapons = self.weapons | WEPBIT_LASER;
	self.weapons = self.weapons | W_WeaponBit(self.znix_weapon);

	if(self.switchweapon != self.znix_weapon)
		if(!client_hasweapon(self, self.switchweapon, TRUE, FALSE))
			if(client_hasweapon(self, self.znix_weapon, TRUE, FALSE))
				W_SwitchWeapon(self.znix_weapon);
}

void ZNIX_precache()
{
	float i;
	for (i = WEP_FIRST; i <= WEP_LAST; ++i)
		if (ZNIX_CanChooseWeapon(i))
			weapon_action(i, WR_PRECACHE);
}

MUTATOR_HOOKFUNCTION(znix_ForbidThrowCurrentWeapon)
{
	return 1; // no throwing in NIX
}

MUTATOR_HOOKFUNCTION(znix_SetStartItems)
{
	ZNIX_precache();
	// we do NOT change the start weapons any more, so we can later turn off the mutator!
	//   start_weapons = 0; // will be done later, when player spawns
	//   warmup_start_weapons = 0; // will be done later, when player spawns
	return 0;
}

MUTATOR_HOOKFUNCTION(znix_BuildMutatorsString)
{
	ret_string = strcat(ret_string, ":zNIX");
	return 0;
}

MUTATOR_HOOKFUNCTION(znix_BuildMutatorsPrettyString)
{
	ret_string = strcat(ret_string, ", zNIX");
	return 0;
}

MUTATOR_HOOKFUNCTION(znix_FilterItem)
{
	switch (self.items)
	{
		case IT_HEALTH:
		case IT_5HP:
		case IT_25HP:
		case IT_ARMOR:
		case IT_ARMOR_SHARD:
			if (autocvar_g_nix_with_healtharmor)
				return 0;
			break;
		case IT_STRENGTH:
		case IT_INVINCIBLE:
			if (autocvar_g_nix_with_powerups)
				return 0;
			break;
	}

	return 1; // delete all other items
}

MUTATOR_HOOKFUNCTION(znix_OnEntityPreSpawn)
{
	if(self.classname == "target_items") // items triggers cannot work in nixnex (as they change weapons/ammo)
		return 1;
	return 0;
}

MUTATOR_HOOKFUNCTION(znix_PlayerPreThink)
{
	if(!intermission_running)
	if(self.deadflag == DEAD_NO)
	if(self.classname == "player")
		ZNIX_GiveCurrentWeapon();
	return 0;
}

MUTATOR_HOOKFUNCTION(znix_PlayerSpawn)
{
	self.znix_lastchange_id = -1;
	ZNIX_GiveCurrentWeapon(); // overrides the weapons you got when spawning
	return 0;
}

MUTATOR_DEFINITION(mutator_znix)
{
	entity e;

	MUTATOR_HOOK(ForbidThrowCurrentWeapon, znix_ForbidThrowCurrentWeapon, CBC_ORDER_ANY);
	MUTATOR_HOOK(SetStartItems, znix_SetStartItems, CBC_ORDER_EXCLUSIVE);
	MUTATOR_HOOK(BuildMutatorsString, znix_BuildMutatorsString, CBC_ORDER_ANY);
	MUTATOR_HOOK(BuildMutatorsPrettyString, znix_BuildMutatorsPrettyString, CBC_ORDER_ANY);
	MUTATOR_HOOK(FilterItem, znix_FilterItem, CBC_ORDER_ANY);
	MUTATOR_HOOK(OnEntityPreSpawn, znix_OnEntityPreSpawn, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerPreThink, znix_PlayerPreThink, CBC_ORDER_ANY);
	MUTATOR_HOOK(PlayerSpawn, znix_PlayerSpawn, CBC_ORDER_ANY);

	MUTATOR_ONADD
	{
		g_znix_with_laser = autocvar_g_znix_with_laser;

		ZNIX_precache();

		FOR_EACH_PLAYER(e)
		{
			e.znix_nextchange = time;
			e.znix_nextweapon = 0;

			if(e.deadflag == DEAD_NO)
			{
				e.znix_save_cells = e.ammo_cells;
				e.znix_save_shells = e.ammo_shells;
				e.znix_save_nails = e.ammo_nails;
				e.znix_save_rockets = e.ammo_rockets;
				e.znix_save_fuel = e.ammo_fuel;
				e.znix_save_weapons = e.weapons;
			}
			else
			{
				e.znix_save_cells = 0;
				e.znix_save_shells = 0;
				e.znix_save_nails = 0;
				e.znix_save_rockets = 0;
				e.znix_save_fuel = 0;
				e.znix_save_weapons = 0;
			}
		}
	}

	MUTATOR_ONREMOVE
	{
		// as the PlayerSpawn hook will no longer run, NIX is turned off by this!

		FOR_EACH_PLAYER(e) if(e.deadflag == DEAD_NO)
		{
			e.ammo_cells = max(start_ammo_cells, e.znix_save_cells);
			e.ammo_shells = max(start_ammo_shells, e.znix_save_shells);
			e.ammo_nails = max(start_ammo_nails, e.znix_save_nails);
			e.ammo_rockets = max(start_ammo_rockets, e.znix_save_rockets);
			e.ammo_fuel = max(start_ammo_fuel, e.znix_save_fuel);
			e.weapons = (start_weapons | e.znix_save_weapons);
			if(!client_hasweapon(e, e.weapon, TRUE, FALSE))
				e.switchweapon = w_getbestweapon(self);
		}
	}

	return 0;
}
