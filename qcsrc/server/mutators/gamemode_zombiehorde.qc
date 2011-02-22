/*
 * TODO
 * ----
 * Zombies don't "see" the player if the player crouches
 * (FIXED) The numbers of zombies in play per round gets out of sync after round 1 (Seems worse with more people in the game..)
 * Zombies spawning over other zombies at the spawn locations
 * Zombies get stuck in wander mode and are not able to move
 * Add zombie kills to the player frags on the scoreboard
 * Zombies need better enemy detection and wander code that doesn't recalculate on every think
*/



float zhRoundNumber;
float zhRoundState;
entity zhRoundEntity;
float zhRoundDelay;
float zhZombiesToSpawn;
float zhZombiesAlive;

#define ROUND_WARMUP		1
#define ROUND_SETUP		2
#define ROUND_STARTING		4
#define	ROUND_STARTED		8
#define ROUND_ENDING		16

void zombiehorde_RoundThink();

void zombiehorde_Initialize()
{	
	zhRoundState = ROUND_WARMUP;
	zhRoundNumber = 0;
	zhRoundDelay = 0;
	zhZombiesToSpawn = 0;	
	zhZombiesAlive = 0;

	// Create the round entity used for logic
	zhRoundEntity = spawn();
	zhRoundEntity.think = zombiehorde_RoundThink;
	zhRoundEntity.nextthink = time + 1;
}

void zombiehorde_MysteryBoxThink()
{
	if not (self.enemy)
	{
		self.enemy = spawn();
		self.enemy.think = SUB_Null;
		self.enemy.touch = SUB_Null;
		self.enemy.event_damage = SUB_Null;
		self.enemy.takedamage = DAMAGE_NO;
		self.enemy.glow_color = 250;
		self.enemy.glow_size = 25;
		setsize(self.enemy, '-5 -5 -5', '5 5 5');
		setorigin(self.enemy, self.origin + '0 0 5');
	} 

	float w = W_GetCycleWeapon(self.enemy, weaponorder_byid, 1, -1, 0, FALSE);
	entity e = get_weaponinfo(w);
	setmodel(self.enemy, e.model);
	self.enemy.wframe = WFRAME_IDLE;
	self.enemy.frame = 0;
	self.enemy.velocity = '0 10 0';

	// Used for cycling the weapon
	self.enemy.cnt = e.switchweapon;
	self.enemy.switchweapon = w;
	self.enemy.selectweapon = w;

	self.nextthink = time + 1.5;
}

void zombiehorde_MysteryBoxTouch()
{
	self.think = zombiehorde_MysteryBoxThink;
	self.nextthink = time;
	self.touch = SUB_Null;
}

entity zombiehorde_SpawnMysteryBox()
{
	local entity mysterybox;

	mysterybox = spawn();
	mysterybox.classname = "item_mysterybox";
	mysterybox.origin = self.origin + v_forward * 10;
	mysterybox.think = SUB_Null;
	mysterybox.nextthink = 0;
	mysterybox.solid = SOLID_BBOX;
	mysterybox.takedamage = DAMAGE_NO;
	mysterybox.event_damage = SUB_Null;
	mysterybox.movetype = MOVETYPE_NONE;
	mysterybox.touch = zombiehorde_MysteryBoxTouch;

	setmodel(mysterybox, "models/turrets/terrainbase.md3");
	setsize(mysterybox, PL_MIN, PL_MAX);
	tracebox(mysterybox.origin + '0 0 100', PL_MIN, PL_MAX, mysterybox.origin - '0 0 1000', MOVE_WORLDONLY, mysterybox);
	setorigin(mysterybox, trace_endpos + '0 0 .5');

	pointparticles(particleeffectnum("teleport"), mysterybox.origin, '0 0 0', 1);
}


entity zombiehorde_SelectSpawnPoint()
{
	return SelectSpawnPoint(TRUE);
}

entity zombiehorde_SpawnZombie()
{
	local entity zombie, oldself, spawnpoint;

	spawnpoint = zombiehorde_SelectSpawnPoint();
	zombie = spawn();
	oldself = self;
	self = zombie;
	self.classname = "monster_zombie";
	self.spawnflags |= MONSTERFLAG_NORESPAWN;
	self.origin = spawnpoint.origin;

	self.scale = bound(1, random() * 4, 4);
	if (random() * 5 < 3)
		self.scale = bound(.5, random() * 1, 1);

	spawnfunc_monster_zombie();
	zhZombiesAlive++;
	self = oldself;

	return zombie;
}

void zombiehorde_RoundThink() 
{
	switch (zhRoundState)
	{
		case ROUND_WARMUP:
		{
			local entity e;
			FOR_EACH_REALPLAYER(e)
				centerprint(e, "-- WAITING FOR PLAYERS --\n");

			self.nextthink = time + 1.0;
			break;
		}
		case ROUND_SETUP:
		{
			zhRoundNumber++;
			zhRoundDelay = 5;
			zhZombiesToSpawn = floor(zhRoundNumber / .3);
			print("ZOMBIES ALIVE: ", ftos(zhZombiesAlive), "\n");
			zhRoundState = ROUND_STARTING;

			self.nextthink = time + 1.0;
			break;
		}
		case ROUND_STARTING:
		{
			local entity e;
			FOR_EACH_REALPLAYER(e)
				if (zhRoundDelay > 1)
					centerprint(e, strcat("-- ROUND ", ftos(zhRoundNumber), " STARTS IN ", ftos(zhRoundDelay), " SECONDS --\n"));
				else
					centerprint(e, strcat("-- ROUND ", ftos(zhRoundNumber), " STARTS IN ", ftos(zhRoundDelay), " SECOND --\n"));

			zhRoundDelay--;
			if (zhRoundDelay == 0)
				zhRoundState = ROUND_STARTED;

			self.nextthink = time + 1.0;
			break;
		}
		case ROUND_STARTED:
		{
			if (cvar("g_zombiehorde_increasezombies") > 0)
			{
				local entity e;
				FOR_EACH_REALPLAYER(e)
					centerprint(e, strcat("-- INCREASING ZOMBIES BY ", ftos(cvar("g_zombiehorde_increasezombies")), " --\n"));

				zhZombiesToSpawn += cvar("g_zombiehorde_increasezombies");
				cvar_set("g_zombiehorde_increasezombies", "0");
			}

			// Stagger the spawning of zombies slightly
			if (zhZombiesToSpawn > 0)
			if (random() * 5 < bound(0, cvar("g_zombiehorde_staggerspawn"), 5))
			{
				zombiehorde_SpawnZombie();
				zhZombiesToSpawn--;
			}

			// If all the zombies that needed to be killed for the round are dead,
			// setup the next round!
			if (zhZombiesAlive + zhZombiesToSpawn <= 0)
				zhRoundState = ROUND_ENDING;

			self.nextthink = time + 1.0;
			break;
		}
		case ROUND_ENDING:
		{
			// Placeholder state
			zhRoundState = ROUND_SETUP;
			self.nextthink = time;
			break;
		}
		default:
		{
			dprint("Unknown Zombie Horde round state: ", ftos(zhRoundState), "\n");
			self.nextthink = time + 1.0;
		}
	}
}

void zombiehorde_WaypointThink()
{
	self.think = SUB_Remove;
	self.nextthink = time;
}

void zombiehorde_ZombieDied(entity attacker)
{
	// Zombies count as a kill!
	attacker.totalfrags += PlayerScore_Add(attacker, SP_KILLS, 1);
	UpdateFrags(attacker, attacker.totalfrags);
	PlayerScore_Clear(attacker);

	// Zombies create spawn points as they die
//	entity wp = waypoint_spawn(self.origin, self.origin, WAYPOINTFLAG_GENERATED | WAYPOINTFLAG_ITEM);
//	wp.think = zombiehorde_WaypointThink;
//	wp.nextthink = time + 60 + (random() * 80);

	zhZombiesAlive--;

	print("ZOMBIES ALIVE: ", ftos(zhZombiesAlive), "\n");
	print("ZOMBIES TO SPAWN: ", ftos(zhZombiesToSpawn), "\n");

	local entity e;
	if (zhZombiesAlive + zhZombiesToSpawn > 0)
		FOR_EACH_REALPLAYER(e)
			if (zhZombiesToSpawn + zhZombiesAlive > 1)
				centerprint(e, strcat("-- There are ", ftos(zhZombiesToSpawn + zhZombiesAlive), " zombies to go --\n"));
			else
				centerprint(e, "-- There is just 1 zombie to go --\n");

}

MUTATOR_HOOKFUNCTION(zombiehorde_PlayerSpawn)
{
	if(clienttype(self) == CLIENTTYPE_BOT)
	{
		// allow BOTs to be targets
		self.takedamage |= DAMAGE_AIM;
	} else if (clienttype(self) == CLIENTTYPE_REAL) {
		// For now, game play begins after the first person spawns
		if (zhRoundState == ROUND_WARMUP)
			zhRoundState = ROUND_SETUP;
	}

	return 1;
}

MUTATOR_HOOKFUNCTION(zombiehorde_PlayerDies)
{
	print("DEBUG: I saw the death of ", self.netname);
	return 0;
}

MUTATOR_DEFINITION(gamemode_zombiehorde)
{
	MUTATOR_HOOK(PlayerSpawn, zombiehorde_PlayerSpawn, CBC_ORDER_LAST);
	MUTATOR_HOOK(PlayerDies, zombiehorde_PlayerDies, CBC_ORDER_FIRST);

	MUTATOR_ONADD
	{
		if(time > 1) // game loads at time 1
			error("This is a game type and it cannot be added at runtime.");

		g_zombiehorde = 1;
		cvar_set("g_monsters", "1");
		cvar_set("g_monster_zombie_attack_run_damage", "10");
		cvar_set("g_monster_zombie_attack_run_delay", "100");
		cvar_set("g_monster_zombie_attack_run_range", "75");
		cvar_set("g_monster_zombie_attack_run_delay", "0.5");
		cvar_set("g_monster_zombie_attack_run_hitrange", "65");
		cvar_set("g_monster_zombie_attack_stand_damage", "10");
		cvar_set("g_monster_zombie_attack_stand_range", "65");
		cvar_set("g_monster_zombie_attack_stand_delay", "0.5");
		cvar_set("g_monster_zombie_attack_stand_hitrange", "65");
		cvar_set("g_monster_zombie_targetrange", "1000");
		cvar_set("g_monster_zombie_turnspeed", "5");
		cvar_set("g_monster_zombie_movespeed", "100");
		cvar_set("g_monster_zombie_stopspeed", "100");
		cvar_set("g_monster_zombie_health", "150");

		cvar_set("g_zombiehorde_increasezombies", "0");
		cvar_set("g_zombiehorde_staggerspawn", "3");
		cvar_set("g_zombiehorde_tracezombies", "0");

		zombiehorde_Initialize();
	}

	MUTATOR_ONREMOVE
	{
		g_zombiehorde = 0;
		error("This is a game type and it cannot be removed at runtime.");
	}

	return 0;
}
