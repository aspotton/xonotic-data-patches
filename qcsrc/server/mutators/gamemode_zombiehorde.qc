void zombiehorde_Initialize()
{
	precache_model("models/monsters/zombie.dpm");
}

MUTATOR_HOOKFUNCTION(zombiehorde_PlayerSpawn)
{
	if(clienttype(self) == CLIENTTYPE_BOT)
	{
		setmodel(self, "models/monsters/zombie.dpm");
	}

	return 1;
}

MUTATOR_DEFINITION(gamemode_zombiehorde)
{
	MUTATOR_HOOK(PlayerSpawn, zombiehorde_PlayerSpawn, CBC_ORDER_LAST);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");
		g_zombiehorde = 1;
		zombiehorde_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		g_zombiehorde = 0;
		error("This is a game type and it cannot be removed at runtime.");
	}

	return 0;
}
