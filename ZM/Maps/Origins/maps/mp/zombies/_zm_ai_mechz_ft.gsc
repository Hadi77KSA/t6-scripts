// T6 GSC SOURCE
// Generated by https://github.com/xensik/gsc-tool
#include maps\mp\zombies\_zm_zonemgr;
#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\zombies\_zm_net;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\animscripts\zm_utility;
#include maps\mp\zm_tomb_tank;
#include maps\mp\zombies\_zm_ai_mechz_dev;
#include maps\mp\zombies\_zm_ai_mechz;
#include maps\mp\animscripts\zm_shared;
#include maps\mp\_visionset_mgr;

init_flamethrower_triggers()
{
    flag_wait( "initial_players_connected" );
    level.flamethrower_trigger_array = getentarray( "flamethrower_trigger", "script_noteworthy" );
    assert( isdefined( level.flamethrower_trigger_array ) && level.flamethrower_trigger_array.size >= 4 );

    for ( i = 0; i < level.flamethrower_trigger_array.size; i++ )
        level.flamethrower_trigger_array[i] enablelinkto();
}

mechz_flamethrower_initial_setup()
{
    self endon( "death" );

    if ( isdefined( self.flamethrower_trigger ) )
        self release_flamethrower_trigger();

    self.flamethrower_trigger = get_flamethrower_trigger();

    if ( !isdefined( self.flamethrower_trigger ) )
    {
/#
        println( "Error: No free flamethrower triggers! Make sure you haven't spawned more than 4 mech zombies" );
#/
        return;
    }

    self.flamethrower_trigger.origin = self gettagorigin( "tag_flamethrower_FX" );
    self.flamethrower_trigger.angles = self gettagangles( "tag_flamethrower_FX" );
    self.flamethrower_trigger linkto( self, "tag_flamethrower_FX" );
    self thread mechz_watch_for_flamethrower_damage();
}

get_flamethrower_trigger()
{
    for ( i = 0; i < level.flamethrower_trigger_array.size; i++ )
    {
        if ( !( isdefined( level.flamethrower_trigger_array[i].in_use ) && level.flamethrower_trigger_array[i].in_use ) )
        {
            level.flamethrower_trigger_array[i].in_use = 1;
            level.flamethrower_trigger_array[i].original_position = level.flamethrower_trigger_array[i].origin;
            return level.flamethrower_trigger_array[i];
        }
    }

    return undefined;
}

release_flamethrower_trigger()
{
    if ( !isdefined( self.flamethrower_trigger ) )
        return;

    self.flamethrower_trigger.in_use = 0;
    self.flamethrower_trigger unlink();
    self.flamethrower_trigger.origin = self.flamethrower_trigger.original_position;
    self.flamethrower_linked = 0;
    self.flamethrower_trigger = undefined;
}

mechz_flamethrower_dist_watcher()
{
    self endon( "kill_ft" );
    wait 0.5;

    while ( true )
    {
        if ( !isdefined( self.favoriteenemy ) || !is_player_valid( self.favoriteenemy, 1, 1 ) || distancesquared( self.origin, self.favoriteenemy.origin ) > 50000 )
        {
            self notify( "stop_ft" );
            return;
        }

        wait 0.05;
    }
}

mechz_flamethrower_arc_watcher()
{
    self endon( "death" );
    self endon( "kill_ft" );
    self endon( "stop_ft" );
    aim_anim = undefined;

    while ( true )
    {
        old_anim = aim_anim;
        aim_anim = mechz_get_aim_anim( "zm_flamethrower", self.favoriteenemy.origin, 26 );
        self.curr_aim_anim = aim_anim;

        if ( !isdefined( aim_anim ) )
        {
            self notify( "stop_ft" );
            return;
        }

        if ( !isdefined( old_anim ) || old_anim != aim_anim )
            self notify( "arc_change" );

        wait 0.05;
    }
}

mechz_play_flamethrower_aim()
{
    self endon( "death" );
    self endon( "kill_ft" );
    self endon( "stop_ft" );
    self endon( "arc_change" );

    if ( isdefined( self.curr_aim_anim ) )
    {
        self stopanimscripted();
        self animscripted( self.origin, self.angles, self.curr_aim_anim );
        self maps\mp\animscripts\zm_shared::donotetracks( "flamethrower_anim" );
    }
    else
        wait 0.05;
}

mechz_flamethrower_aim()
{
    self endon( "death" );
    self endon( "kill_ft" );
    self endon( "stop_ft" );
    self waittillmatch( "flamethrower_anim", "end" );
    self thread mechz_flamethrower_dist_watcher();
    self thread mechz_flamethrower_arc_watcher();
    aim_anim = undefined;

    while ( true )
        self mechz_play_flamethrower_aim();
}

mechz_flamethrower_tank_sweep()
{
    self endon( "death" );
    self endon( "kill_ft" );
    self endon( "stop_ft" );

    while ( true )
    {
        self stopanimscripted();
        self.angles = vectortoangles( level.vh_tank.origin - self.origin );
        self animscripted( self.origin, self.angles, "zm_flamethrower_sweep_up" );
        self maps\mp\animscripts\zm_shared::donotetracks( "flamethrower_anim" );

        if ( level.vh_tank ent_flag( "tank_moving" ) )
            break;

        a_players_on_tank = get_players_on_tank( 1 );

        if ( !a_players_on_tank.size )
            break;
    }

    self notify( "stop_ft" );
}

mechz_stop_firing_watcher()
{
    self endon( "death" );
    self endon( "kill_ft" );
    self endon( "flamethrower_complete" );
    self waittillmatch( "flamethrower_anim", "stop_ft" );
    self.firing = 0;
}

mechz_watch_for_flamethrower_damage()
{
    self endon( "death" );

    while ( true )
    {
        self waittillmatch( "flamethrower_anim", "start_ft" );
        self.firing = 1;
        self thread mechz_stop_firing_watcher();

        while ( isdefined( self.firing ) && self.firing )
        {
            do_tank_sweep_auto_damage = isdefined( self.doing_tank_sweep ) && self.doing_tank_sweep && !level.vh_tank ent_flag( "tank_moving" );
            players = getplayers();

            for ( i = 0; i < players.size; i++ )
            {
                if ( !( isdefined( players[i].is_burning ) && players[i].is_burning ) )
                {
                    if ( do_tank_sweep_auto_damage && players[i] entity_on_tank() || players[i] istouching( self.flamethrower_trigger ) )
                        players[i] thread player_flame_damage();
                }
            }

            zombies = getaispeciesarray( "axis", "all" );

            for ( i = 0; i < zombies.size; i++ )
            {
                if ( isdefined( zombies[i].is_mechz ) && zombies[i].is_mechz )
                    continue;

                if ( isdefined( zombies[i].on_fire ) && zombies[i].on_fire )
                    continue;

                if ( do_tank_sweep_auto_damage && zombies[i] entity_on_tank() || zombies[i] istouching( self.flamethrower_trigger ) )
                {
                    zombies[i].on_fire = 1;
                    zombies[i] promote_to_explosive();
                }
            }

            wait 0.1;
        }
    }
}

player_flame_damage()
{
    self endon( "zombified" );
    self endon( "death" );
    self endon( "disconnect" );
    n_player_dmg = 30;
    n_jugga_dmg = 45;
    n_burn_time = 1.5;

    if ( isdefined( self.is_zombie ) && self.is_zombie )
        return;

    self thread player_stop_burning();

    if ( !isdefined( self.is_burning ) && is_player_valid( self, 1, 0 ) )
    {
        self.is_burning = 1;
        maps\mp\_visionset_mgr::vsmgr_activate( "overlay", "zm_transit_burn", self, n_burn_time, level.zm_transit_burn_max_duration );
        self notify( "burned" );

        if ( !self hasperk( "specialty_armorvest" ) )
            self dodamage( n_player_dmg, self.origin );
        else
            self dodamage( n_jugga_dmg, self.origin );

        wait 0.5;
        self.is_burning = undefined;
    }
}

player_stop_burning()
{
    self notify( "player_stop_burning" );
    self endon( "player_stop_burning" );
    self endon( "death_or_disconnect" );
    self waittill( "zombified" );
    self notify( "stop_flame_damage" );
    maps\mp\_visionset_mgr::vsmgr_deactivate( "overlay", "zm_transit_burn", self );
}

zombie_burning_fx()
{
    self endon( "death" );
    self endon( "stop_flame_damage" );

    while ( true )
    {
        if ( isdefined( level._effect ) && isdefined( level._effect["character_fire_death_torso"] ) )
        {
            if ( !self.isdog )
                playfxontag( level._effect["character_fire_death_torso"], self, "J_SpineLower" );
        }

        if ( isdefined( level._effect ) && isdefined( level._effect["character_fire_death_sm"] ) )
        {
            wait 1;
            tagarray = [];

            if ( randomint( 2 ) == 0 )
            {
                tagarray[0] = "J_Elbow_LE";
                tagarray[1] = "J_Elbow_RI";
                tagarray[2] = "J_HEAD";
            }
            else
            {
                tagarray[0] = "J_Wrist_RI";
                tagarray[1] = "J_Wrist_LE";
                tagarray[2] = "J_HEAD";
            }

            tagarray = array_randomize( tagarray );
            self thread network_safe_play_fx_on_tag( "flamethrower", 2, level._effect["character_fire_death_sm"], self, tagarray[0] );
        }

        wait 12;
    }
}

zombie_burning_audio()
{
    self playloopsound( "zmb_fire_loop" );
    self waittill_any( "death", "stop_flame_damage" );

    if ( isdefined( self ) && isalive( self ) )
        self stoploopsound( 0.25 );
}

zombie_burning_dmg()
{
    self endon( "death" );
    self endon( "stop_flame_damage" );
    damageradius = 25;
    damage = 2;

    while ( true )
    {
        eyeorigin = self geteye();
        players = get_players();

        for ( i = 0; i < players.size; i++ )
        {
            if ( is_player_valid( players[i], 1, 0 ) )
            {
                playereye = players[i] geteye();

                if ( distancesquared( eyeorigin, playereye ) < damageradius * damageradius )
                {
                    players[i] dodamage( damage, self.origin, self );
                    players[i] notify( "burned" );
                }
            }
        }

        wait 1.0;
    }
}

promote_to_explosive()
{
    self endon( "death" );
    self thread zombie_burning_audio();
    self thread zombie_burning_fx();
    self thread explode_on_death();
    self thread zombie_burning_dmg();
    self thread on_fire_timeout();
}

explode_on_death()
{
    self endon( "stop_flame_damage" );
    self waittill( "death" );

    if ( !isdefined( self ) )
        return;

    tag = "J_SpineLower";

    if ( isdefined( self.animname ) && self.animname == "zombie_dog" )
        tag = "tag_origin";

    if ( is_mature() )
    {
        if ( isdefined( level._effect["zomb_gib"] ) )
            playfx( level._effect["zomb_gib"], self gettagorigin( tag ) );
    }
    else if ( isdefined( level._effect["spawn_cloud"] ) )
        playfx( level._effect["spawn_cloud"], self gettagorigin( tag ) );

    self radiusdamage( self.origin, 128, 30, 15, undefined, "MOD_EXPLOSIVE" );
    self ghost();

    if ( isdefined( self.isdog ) && self.isdog )
        self hide();
    else
        self delay_thread( 1, ::self_delete );
}

on_fire_timeout()
{
    self endon( "death" );
    wait 12;

    if ( isdefined( self ) && isalive( self ) )
    {
        self.is_on_fire = 0;
        self notify( "stop_flame_damage" );
    }
}

should_do_flamethrower_attack()
{
    assert( isdefined( self.favoriteenemy ) );
/#
    if ( getdvarint( #"mechz_debug" ) > 1 )
        println( "\\n\\tMZ: Checking should flame\\n" );
#/

    if ( isdefined( self.disable_complex_behaviors ) && self.disable_complex_behaviors )
    {
/#
        if ( getdvarint( #"mechz_debug" ) > 1 )
            println( "\\n\\t\\tMZ: Not doing flamethrower because doing force aggro\\n" );
#/
        return false;
    }

    if ( isdefined( self.not_interruptable ) && self.not_interruptable )
    {
/#
        if ( getdvarint( #"mechz_debug" ) > 1 )
            println( "\\n\\t\\tMZ: Not doing flamethrower because another behavior has set not_interruptable\\n" );
#/
        return false;
    }

    if ( !self mechz_check_in_arc( 26 ) )
    {
/#
        if ( getdvarint( #"mechz_debug" ) > 1 )
            println( "\\n\\t\\tMZ: Not doing flamethrower because target is not in front arc\\n" );
#/
        return false;
    }

    if ( isdefined( self.last_flamethrower_time ) && gettime() - self.last_flamethrower_time < level.mechz_flamethrower_cooldown_time )
    {
/#
        if ( getdvarint( #"mechz_debug" ) > 1 )
            println( "\\n\\t\\tMZ: Not doing flamethrower because it is still on cooldown\\n" );
#/
        return false;
    }

    n_dist_sq = distancesquared( self.origin, self.favoriteenemy.origin );

    if ( n_dist_sq < 10000 || n_dist_sq > 50000 )
    {
/#
        if ( getdvarint( #"mechz_debug" ) > 1 )
            println( "\\n\\t\\tMZ: Not doing flamethrower because target is not in range\\n" );
#/
        return false;
    }

    b_cansee = bullettracepassed( self.origin + vectorscale( ( 0, 0, 1 ), 36.0 ), self.favoriteenemy.origin + vectorscale( ( 0, 0, 1 ), 36.0 ), 0, undefined );

    if ( !b_cansee )
    {
/#
        if ( getdvarint( #"mechz_debug" ) > 1 )
            println( "\\n\\t\\tMZ: Not doing flamethrower because cannot see target\\n" );
#/
        return false;
    }

    return true;
}

#using_animtree("mechz_claw");

mechz_do_flamethrower_attack( tank_sweep )
{
    self endon( "death" );
    self endon( "kill_ft" );
/#
    if ( getdvarint( #"mechz_debug" ) > 0 )
        println( "\\n\\tMZ: Doing Flamethrower Attack\\n" );
#/
    self thread mechz_stop_basic_find_flesh();
    self.ai_state = "flamethrower_attack";
    self setgoalpos( self.origin );
    self clearanim( %root, 0.2 );
    self.last_flamethrower_time = gettime();
    self thread mechz_kill_flamethrower_watcher();

    if ( !isdefined( self.flamethrower_trigger ) )
        self mechz_flamethrower_initial_setup();

    n_nearby_enemies = 0;
    a_players = getplayers();

    foreach ( player in a_players )
    {
        if ( distance2dsquared( player.origin, self.favoriteenemy.origin ) < 10000 )
            n_nearby_enemies++;
    }

    if ( isdefined( tank_sweep ) && tank_sweep )
    {
        self.doing_tank_sweep = 1;
        self thread mechz_flamethrower_tank_sweep();
    }
    else if ( randomint( 100 ) < level.mechz_ft_sweep_chance && n_nearby_enemies > 1 )
    {
        self.doing_ft_sweep = 1;
        self animscripted( self.origin, self.angles, "zm_flamethrower_sweep" );
        self maps\mp\animscripts\zm_shared::donotetracks( "flamethrower_anim" );
    }
    else
    {
        self animscripted( self.origin, self.angles, "zm_flamethrower_aim_start" );
        self thread mechz_flamethrower_aim();
        self maps\mp\animscripts\zm_shared::donotetracks( "flamethrower_anim" );
    }

    self orientmode( "face default" );

    if ( isdefined( self.doing_ft_sweep ) && self.doing_ft_sweep )
        self.doing_ft_sweep = 0;
    else
    {
        self.cant_melee = 1;
        self waittill( "stop_ft" );
        self mechz_flamethrower_cleanup();
        wait 0.5;
        self stopanimscripted();
        return;
    }

    self mechz_flamethrower_cleanup();
}

mechz_kill_flamethrower_watcher()
{
    self endon( "flamethrower_complete" );
    self waittill_either( "kill_ft", "death" );
    self mechz_flamethrower_cleanup();
}

mechz_flamethrower_cleanup()
{
    self.fx_field = self.fx_field & ~64;
    self setclientfield( "mechz_fx", self.fx_field );
    self.firing = 0;
    self.doing_tank_sweep = 0;
    self.cant_melee = 0;
    self notify( "flamethrower_complete" );
}
