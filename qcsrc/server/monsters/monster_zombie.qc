#define MONSTERS_ENABLED
#ifdef MONSTERS_ENABLED

void zombiehorde_ZombieDied(entity attacker);

#define zombie_anim_attackleap         0
#define zombie_anim_attackrun1         1
#define zombie_anim_attackrun2         2
#define zombie_anim_attackrun3         3
#define zombie_anim_attackstanding1    4
#define zombie_anim_attackstanding2    5
#define zombie_anim_attackstanding3    6
#define zombie_anim_blockend           7
#define zombie_anim_blockstart         8
#define zombie_anim_deathback1         9
#define zombie_anim_deathback2         10
#define zombie_anim_deathback3         11
#define zombie_anim_deathfront1        12
#define zombie_anim_deathfront2        13
#define zombie_anim_deathfront3        14
#define zombie_anim_deathleft1         15
#define zombie_anim_deathleft2         16
#define zombie_anim_deathright1        17
#define zombie_anim_deathright2        18
#define zombie_anim_idle               19
#define zombie_anim_painback1          20
#define zombie_anim_painback2          21
#define zombie_anim_painfront1         22
#define zombie_anim_painfront2         23
#define zombie_anim_runbackwards       24
#define zombie_anim_runbackwardsleft   25
#define zombie_anim_runbackwardsright  26
#define zombie_anim_runforward         27
#define zombie_anim_runforwardleft     28
#define zombie_anim_runforwardright    29
#define zombie_anim_spawn              30

#define ZOMBIE_MIN					 '-18 -18 -25'
#define ZOMBIE_MAX					 '18 18 47'

#define ZV_IDLE     10

#define ZV_PATH     100
#define ZV_HUNT     200

#define ZV_ATTACK_FIND  10
#define ZV_ATTACK_RUN   20
#define ZV_ATTACK_STAND 30

#define ZV_PATH2 10000

//.entity verbs_idle;
//.entity verbs_attack;
//.entity verbs_move;

//.float  state_timeout;
//.void() monster_state;
#define MONSTERFLAG_NORESPAWN 2

void zombie_spawn();

float zombie_scoretarget(entity trg)
{
    float  tmp;
    vector ang1;

    if (trg.takedamage == DAMAGE_AIM)
    if not (trg.flags & FL_NOTARGET)
    if (trg.deadflag == DEAD_NO)
    if (trg.team != self.team)
    {
        if(fabs(self.origin_z - trg.origin_z) < 128)
        {
            ang1 = normalize(self.origin - trg.origin);
            tmp = vlen(ang1 - v_forward);
            if(tmp > 1.5)
            {
                traceline(self.origin, trg.origin, MOVE_NORMAL, self);
                if(trace_ent != trg)
                    return 0;

                return (autocvar_g_monster_zombie_targetrange - vlen(self.origin - trg.origin)) * tmp;
            }
            else if(self.enemy == trg)
                return (autocvar_g_monster_zombie_targetrange - vlen(self.origin - trg.origin)) * tmp;
        }
    }

    return 0;
}

entity zombie_find_best_real_player()
{
	local entity e, best_trg;
	float trg_score, best_trg_score;

	FOR_EACH_REALPLAYER(e)
	{
		return e;

		trg_score = zombie_scoretarget(e);
		if (trg_score > best_trg_score)
		{
			best_trg = e;
			best_trg_score = trg_score;
		}
	}

	if(best_trg)
	{
		print("Selecting '", best_trg.netname, "' as best player target.");
		return best_trg;
	}

	return world;
}

void zombie_corpse_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{
    //dprint("zombie_corpse_damage\n");
    Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);

    self.health -= damage;

    if(self.health < 0)
    {
        Violence_GibSplash(self, 1, 1, attacker);
        remove(self);
    }
}

void zombie_die(vector dir, entity attacker)
{
    vector v;
    float f;

    entity dummy;

    dummy = spawn();
    setmodel(dummy,"models/monsters/zombie.dpm");
    setorigin(dummy, self.origin);
    dummy.velocity  = self.velocity;
    dummy.movetype  = MOVETYPE_BOUNCE;
    dummy.think     = SUB_Remove;
    dummy.nextthink = time + 3;
    dummy.health    = 50;
    dummy.takedamage = DAMAGE_YES;
    dummy.event_damage = zombie_corpse_damage;
    dummy.solid      = SOLID_CORPSE;
    dummy.scale = self.scale;
    setsize(dummy,ZOMBIE_MIN * self.scale,ZOMBIE_MAX * self.scale);

    SUB_SetFade(dummy,time + 5,2);


    v = normalize(self.origin - dir);
    f = vlen(v_forward - v) - 1;
    if(f > 0.5)
        dummy.frame = zombie_anim_deathfront1 + rint(random() * 2);
    else if(f < 0.5)
        dummy.frame = zombie_anim_deathback1 + rint(random() * 2);
    else
    {
        f = vlen(v_right - v) - 1;
        if(f > 0.5)
            dummy.frame = zombie_anim_deathright1 + rint(random() * 2);
        else if(f < 0.5)
            dummy.frame = zombie_anim_deathleft1 + rint(random() * 2);
    }

    if (g_zombiehorde)
        zombiehorde_ZombieDied(attacker);

    if(self.spawnflags & MONSTERFLAG_NORESPAWN)
    {
        self.think = SUB_Remove;
        self.nextthink = time;
    } else {
        setmodel(self,"");
        self.solid          = SOLID_NOT;
        self.takedamage     = DAMAGE_NO;
        self.event_damage   = SUB_Null;
        self.enemy          = world;
        self.think          = zombie_spawn;
        self.nextthink      = time + autocvar_g_monster_zombie_respawntime;
        self.pain_finished  = self.nextthink;
    }
}

void zombie_damage(entity inflictor, entity attacker, float damage, float deathtype, vector hitloc, vector force)
{

    vector v;
    float f;

    v = normalize(self.origin - hitloc);
    f = vlen(v_forward - v) - 1;


    self.health -= damage;
    self.velocity = self.velocity + force;
    if(self.health <= 0)
    {
        if (self.deadflag == DEAD_NO)
        {
            self.deadflag = DEAD_DEAD;
            zombie_die(hitloc, attacker);
        }
     
        return;
    }


    Violence_GibSplash_At(hitloc, force, 2, bound(0, damage, 200) / 16, self, attacker);

	if (damage > 50)
		Violence_GibSplash_At(hitloc, force * -0.1, 3, 1, self, attacker);
	if (damage > 100)
		Violence_GibSplash_At(hitloc, force * -0.2, 3, 1, self, attacker);

    if (time > self.pain_finished)
    {
        if(f < 0.5)
        {
            if(random() < 0.5)
                self.frame = zombie_anim_painback1;
            else
                self.frame = zombie_anim_painback2;
        }
        else
        {
            if(random() < 0.5)
                self.frame = zombie_anim_painfront1;
            else
                self.frame = zombie_anim_painfront2;
        }

        self.pain_finished = time + (0.10 + (random() * 0.36));
    }
}

.vector bvec;
.float bvec_time;

void zombie_move()
{
	if (self.pathgoal == world)
	{
		self.velocity = '0 0 0';
		self.frame = zombie_anim_idle;
		self.zoomstate = time;
		return;
	}

	self.moveto = self.pathgoal.origin;
	self.frame = zombie_anim_runforward + rint(random() * 3);

	vector real_angle;
	float vz, tdiff, tspeed;

	tdiff = time - self.zoomstate;
	tspeed = tdiff * autocvar_g_monster_zombie_turnspeed;
	vz = self.velocity_z;
	self.zoomstate = time;

	self.steerto = normalize(steerlib_attract2(self.origin+steerlib_traceavoid(0.25, 512), 0.5, 500, 0.95));

	self.angles_y = safeangle(self.angles_y);
	real_angle = vectoangles(self.steerto) - self.angles;
	self.angles_y += bound(-25, shortangle_f(real_angle_y, self.angles_y), 25);

	if (vlen(self.origin - self.moveto) < 60)
	{
		self.pathgoal = world;
		self.velocity = '0 0 0';
		self.frame = zombie_anim_idle;			
	}

	movelib_move_simple(v_forward, autocvar_g_monster_zombie_movespeed, 0.6);
	self.velocity_z = vz;
}

float zombie_verb_idle_roam(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:

        if(self.enemy)
            return VS_CALL_NO;

        return verb.verb_static_value;

    case VCM_DO:

        //self.moveto = v_forward * 128;
        //self.steerto = v_forward; //steerlib_beamsteer(v_forward,512,32,34,64);

 	self.moveto = v_forward * 128;
	if ((random() * 1) < 0.5)
	        self.steerto = v_forward * (random() * 25);
	else
	        self.steerto = v_forward * (random() * -25);

        return VS_CALL_YES_DOING;
    }

    return VS_CALL_YES_DONE;
}

float zombie_verb_idle_stand(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:

        if(self.enemy)
            return VS_CALL_NO;

        return verb.verb_static_value;

    case VCM_DO:

        self.moveto   = self.origin;
        self.frame    = zombie_anim_idle;
        self.velocity = '0 0 0';

        return VS_CALL_YES_DOING;
    }

    return VS_CALL_YES_DONE;
}

float zombie_verb_idle(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:

        if(self.enemy)
            return VS_CALL_NO;

        return verb.verb_static_value;

    case VCM_DO:
        float t;

        t = autocvar_g_monster_zombie_idle_timer_max -  autocvar_g_monster_zombie_idle_timer_min;
        t = autocvar_g_monster_zombie_idle_timer_min + (random() * t);

        if(random() < 0.5)
            verbstack_push(self.verbs_idle, zombie_verb_idle_roam,  ZV_IDLE + 1, t, self);
        else
            verbstack_push(self.verbs_idle, zombie_verb_idle_stand, ZV_IDLE + 1, 0.1, self);

        return VS_CALL_YES_DOING;
    }

    return VS_CALL_YES_DONE;
}

float zombie_verb_attack_findtarget(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:
        if(self.enemy)
            return VS_CALL_NO;

        return verb.verb_static_value;

    case VCM_DO:

        entity trg, best_trg;
        float trg_score, best_trg_score;

        trg = findradius(self.origin, autocvar_g_monster_zombie_targetrange);
        while(trg)
        {
            trg_score = zombie_scoretarget(trg);
            if(trg_score > best_trg_score)
            {
                best_trg = trg;
                best_trg_score = trg_score;
            }

            trg = trg.chain;
        }

        if(best_trg)
        {
            self.enemy = best_trg;
            //print("Selected: ",best_trg.netname, " as target.\n");

            // Roar to other nearby zombies!
            if(clienttype(self.enemy) == CLIENTTYPE_REAL)
            for(trg = findradius(self.origin, 1800); trg; trg = trg.chain)
            if(trg.classname == "monster_zombie" && trg.deadflag != DEAD_DEAD && trg.enemy == world)
            {
                trg.enemy = self.enemy;
                trg.steerto = self.enemy.origin;
            }
        }

        return VS_CALL_YES_DOING;
    }

    return VS_CALL_YES_DONE;
}

void zombie_runattack_damage()
{
    entity oldself;
    oldself = self;
    self = self.owner;

    if(vlen(self.origin - self.enemy.origin) > autocvar_g_monster_zombie_attack_run_hitrange)
        return;

    //if(vlen(normalize(self.origin - self.enemy.origin) - v_forward) < 1.6)
    //    return;

    Damage(self.enemy, self, self, autocvar_g_monster_zombie_attack_run_damage, DEATH_TURRET, self.enemy.origin, normalize(self.enemy.origin - self.origin)  * autocvar_g_monster_zombie_attack_run_force);

    self = oldself;
    self.think = SUB_Remove;
    self.nextthink = time;
}

float zombie_verb_attack_run(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:
        if not (self.enemy)
            return VS_CALL_NO;

        if(self.attack_finished_single > time)
            return VS_CALL_NO;

        if(vlen(self.origin - self.enemy.origin) > autocvar_g_monster_zombie_attack_run_range)
            return VS_CALL_NO;

//        if(vlen(normalize(self.origin - self.enemy.origin) - v_forward) < 1.6)
//            return VS_CALL_NO;

        return verb.verb_static_value;

    case VCM_DO:
        entity pain;
        pain = spawn();
        pain.owner = self;
        pain.think = zombie_runattack_damage;
        pain.nextthink = time + (autocvar_g_monster_zombie_attack_run_delay * self.scale);

        self.attack_finished_single = time + 0.7;
        self.frame = zombie_anim_attackrun1 + rint(random() * 2);

        return VS_CALL_YES_DOING;
    }

    return VS_CALL_YES_DONE;
}

void zombie_standattack_damage()
{
    //entity oldself;
    //oldself = self;
    //self = self.owner;

    setorigin(self,self.owner.origin + v_forward);
    //RadiusDamage(self, self.owner, autocvar_g_monster_zombie_attack_stand_damage,autocvar_g_monster_zombie_attack_stand_damage,16,self, autocvar_g_monster_zombie_attack_stand_force,DEATH_TURRET,world);
    RadiusDamage(self, self.owner, autocvar_g_monster_zombie_attack_stand_damage,autocvar_g_monster_zombie_attack_stand_damage,70,self, autocvar_g_monster_zombie_attack_stand_force,DEATH_TURRET,world);
    //float RadiusDamage (entity inflictor, entity attacker, float coredamage, float edgedamage, float rad, entity ignore, float forceintensity, float deathtype, entity directhitentity)

    //self = oldself;
    self.think = SUB_Remove;
    self.nextthink = time;
}

float zombie_verb_attack_stand(float eval)
{
    switch (eval)
    {
    case VCM_EVAL:
        if not (self.enemy)
            return VS_CALL_NO;

        if(self.attack_finished_single > time)
            return VS_CALL_NO;

        if(vlen(self.origin - self.enemy.origin) > autocvar_g_monster_zombie_attack_stand_range)
            return VS_CALL_NO;

//        if(vlen(normalize(self.origin - self.enemy.origin) - v_forward) < 1.8)
//            return VS_CALL_NO;

        return verb.verb_static_value;

    case VCM_DO:
        entity pain;
        pain = spawn();
        pain.owner = self;
        pain.think = zombie_runattack_damage;
        pain.nextthink = time + (autocvar_g_monster_zombie_attack_stand_delay * self.scale);

        self.attack_finished_single = time + 0.7 + (random() * 0.5);
        self.frame = zombie_anim_attackstanding1 + rint(random() * 1);
        dprint("frame:",ftos(self.frame),"\n");

        return VS_CALL_YES_DOING;
    }

    return VS_CALL_YES_DONE;
}

void zombie_think()
{
	//self.angles_x *= -1;
	makevectors(self.angles);
	//self.angles_x *= -1;

	if (cvar("g_zombiehorde_tracezombies") == 1) 
	{
		local entity player;
		FOR_EACH_REALCLIENT(player)
			te_lightning1(world, self.origin, player.origin);
	}

	if (self.enemy)
	if (zombie_scoretarget(self.enemy) == 0)
	{
		self.enemy = world;
	} 

	zombie_move();

	self.nextthink = time + 0.5;
}

void zombie_spawn()
{
	setmodel(self,"models/monsters/zombie.dpm");

	self.solid          = SOLID_BBOX;
	self.takedamage     = DAMAGE_AIM;
	self.event_damage   = zombie_damage;
	self.enemy          = world;
	self.frame          = zombie_anim_spawn;
	self.think          = zombie_think;
	self.nextthink      = time + 2.1;
	self.pain_finished  = self.nextthink;
	self.movetype       = MOVETYPE_WALK;
	self.health         = autocvar_g_monster_zombie_health;
	self.velocity       = '0 0 0';
	self.angles         = self.pos2;
	self.moveto         = self.origin;
	self.flags          = FL_MONSTER;
	self.deadflag       = DEAD_NO;

	self.pathgoal = zombie_find_best_real_player();
	self.enemy = self.pathgoal;

	setsize(self, ZOMBIE_MIN * self.scale, ZOMBIE_MAX * self.scale);
}


void spawnfunc_monster_zombie()
{
	if not(g_zombiehorde)
	if not(autocvar_g_monsters)
	{
		remove(self);
		return;
	}

	precache_model("models/monsters/zombie.dpm");

	self.think      = zombie_spawn;
	self.nextthink  = time + 2;
	self.classname = "monster_zombie";

	tracebox(self.origin + '0 0 100', ZOMBIE_MIN * self.scale, ZOMBIE_MAX * self.scale, self.origin - '0 0 1000', MOVE_WORLDONLY, self);
	setorigin(self, trace_endpos + '0 0 .5');

	self.pos1 = trace_endpos + '0 0 .5';
	self.pos2 = self.angles;
	self.team = MAX_SHOT_DISTANCE -1;
}

#endif // MONSTERS_ENABLED
