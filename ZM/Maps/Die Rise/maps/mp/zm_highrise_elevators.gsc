// T6 GSC SOURCE
// Decompiled by https://github.com/xensik/gsc-tool
#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hostmigration;
#include maps\mp\zm_highrise_utility;
#include maps\mp\zm_highrise_distance_tracking;
#include maps\mp\animscripts\zm_shared;
#include maps\mp\zombies\_zm_ai_basic;
#include maps\mp\zombies\_zm_ai_leaper;

#using_animtree("zombie_perk_elevator");

init_perk_elvators_animtree()
{
    scriptmodelsuseanimtree( #animtree );
}

init_elevators()
{
    level thread init_perk_elevators_anims();
/#
    init_elevator_devgui();
#/
}

quick_revive_solo_watch()
{
    if ( flag( "solo_game" ) )
        self.body perkelevatordoor( 1 );

    machine_triggers = getentarray( "vending_revive", "target" );
    machine_trigger = machine_triggers[0];
    triggeroffset = machine_trigger.origin - self.body.origin;
    machineoffset = level.quick_revive_machine.origin - self.body.origin;

    while ( true )
    {
        level waittill_any( "revive_off", "revive_hide" );
        self.body.lock_doors = 1;
        self.body perkelevatordoor( 0 );
        machine_trigger unlink();
        wait 1;
        machine_trigger.origin += vectorscale( ( 0, 0, -1 ), 10000.0 );

        level waittill( "revive_on" );

        wait 1;
        machine_trigger.origin = self.body.origin + triggeroffset;
        machine_trigger linkto( self.body );
        level.quick_revive_machine.origin = self.body.origin + machineoffset;
        level.quick_revive_machine linkto( self.body );
        level.quick_revive_machine show();
        self.body.lock_doors = 0;
        self.body perkelevatordoor( 1 );
    }
}

init_perk_elevators_anims()
{
    level.perk_elevators_door_open_state = %v_zombie_elevator_doors_open;
    level.perk_elevators_door_close_state = %v_zombie_elevator_doors_close;
    level.perk_elevators_door_movement_state = %v_zombie_elevator_doors_idle_movement;
    level.perk_elevators_anims = [];
    level.perk_elevators_anims["vending_chugabud"][0] = %v_zombie_elevator_doors_whoswho_banging_before_leaving;
    level.perk_elevators_anims["vending_chugabud"][1] = %v_zombie_elevator_doors_whoswho_trying_to_close;
    level.perk_elevators_anims["vending_doubletap"][0] = %v_zombie_elevator_doors_doubletap_banging_before_leaving;
    level.perk_elevators_anims["vending_doubletap"][1] = %v_zombie_elevator_doors_doubletap_trying_to_close;
    level.perk_elevators_anims["vending_jugg"][0] = %v_zombie_elevator_doors_jugg_banging_before_leaving;
    level.perk_elevators_anims["vending_jugg"][1] = %v_zombie_elevator_doors_jugg_trying_to_close;
    level.perk_elevators_anims["vending_revive"][0] = %v_zombie_elevator_doors_marathon_banging_before_leaving;
    level.perk_elevators_anims["vending_revive"][1] = %v_zombie_elevator_doors_marathon_trying_to_close;
    level.perk_elevators_anims["vending_additionalprimaryweapon"][0] = %v_zombie_elevator_doors_mulekick_banging_before_leaving;
    level.perk_elevators_anims["vending_additionalprimaryweapon"][1] = %v_zombie_elevator_doors_mulekick_trying_to_close;
    level.perk_elevators_anims["specialty_weapupgrade"][0] = %v_zombie_elevator_doors_pap_banging_before_leaving;
    level.perk_elevators_anims["specialty_weapupgrade"][1] = %v_zombie_elevator_doors_pap_trying_to_close;
    level.perk_elevators_anims["vending_sleight"][0] = %v_zombie_elevator_doors_speed_banging_before_leaving;
    level.perk_elevators_anims["vending_sleight"][1] = %v_zombie_elevator_doors_speed_trying_to_close;
}

perkelevatoruseanimtree()
{
    self useanimtree( #animtree );
}

perkelevatordoor( set )
{
    self endon( "death" );
    animtime = 1.0;

    if ( is_true( set ) )
    {
        self.door_state = set;
        self setanim( level.perk_elevators_door_open_state, 1, animtime, 1 );
        wait( getanimlength( level.perk_elevators_door_open_state ) );
    }
    else
    {
        self.door_state = set;
        self setanim( level.perk_elevators_door_close_state, 1, animtime, 1 );
        wait( getanimlength( level.perk_elevators_door_close_state ) );
    }

    self notify( "PerkElevatorDoor" );
}

get_link_entity_for_host_migration()
{
    foreach ( elevator in level.elevators )
    {
        if ( isdefined( elevator.body.trig ) )
        {
            if ( self istouching( elevator.body.trig ) )
                return elevator.body;
        }
    }

    escape_pod = getent( "elevator_bldg1a_body", "targetname" );

    if ( self istouching( escape_pod ) )
        return escape_pod;

    if ( distance( escape_pod.origin, self.origin ) < 128 )
        return escape_pod;

    return undefined;
}

escape_pod_host_migration_respawn_check( escape_pod )
{
    wait 0.2;
    dif = self.origin[2] - escape_pod.origin[2];
/#
    println( "Escape_pod_host_migration_respawn_check :" );
#/
/#
    println( "dif : " + dif );
#/
    if ( dif > 100 )
    {
/#
        println( "Finding a better place for the player to be." );
#/
        self maps\mp\gametypes_zm\_hostmigration::hostmigration_put_player_in_better_place();
    }
    else
    {
/#
        println( "Taking no action." );
#/
    }
}

is_self_on_elevator()
{
    elevator_volumes = [];
    elevator_volumes[elevator_volumes.size] = getent( "elevator_1b", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_1c", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_1d", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3a", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3b", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3c", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3d", "targetname" );

    foreach ( zone in elevator_volumes )
    {
        if ( self istouching( zone ) )
            return true;
    }

    foreach ( elevator in level.elevators )
    {
        if ( isdefined( elevator.body.trig ) )
        {
            if ( self istouching( elevator.body.trig ) )
                return true;
        }
    }

    escape_pod = getent( "elevator_bldg1a_body", "targetname" );

    if ( self istouching( escape_pod ) )
        return true;

    if ( distance( escape_pod.origin, self.origin ) < 128 )
        return true;

    return false;
}

object_is_on_elevator()
{
    ground_ent = self getgroundent();

    for ( depth = 0; isdefined( ground_ent ) && depth < 2; depth++ )
    {
        if ( isdefined( ground_ent.is_elevator ) && ground_ent.is_elevator )
        {
            self.elevator_parent = ground_ent;
            return true;
        }

        new_ground_ent = ground_ent getgroundent();

        if ( !isdefined( new_ground_ent ) || new_ground_ent == ground_ent )
            break;

        ground_ent = new_ground_ent;
    }

    return false;
}

elevator_level_for_floor( floor )
{
    flevel = "0";

    if ( isdefined( self.floors["" + ( floor + 1 )] ) )
        flevel = "" + ( floor + 1 );
    else
        flevel = "0";

    return flevel;
}

elevator_is_on_floor( floor )
{
    if ( self.body.current_level == floor )
        return true;

    if ( self.floors[self.body.current_level].script_location == self.floors[floor].script_location )
        return true;

    return false;
}

elevator_path_nodes( elevatorname, floorname )
{
    name = "elevator_" + elevatorname + "_" + floorname;
    epaths = getnodearray( name, "script_noteworthy" );
    return epaths;
}

elevator_paths_onoff( onoff, target )
{
    if ( isdefined( self ) && self.size > 0 )
    {
        foreach ( node in self )
        {
            if ( isdefined( node.script_parameters ) && node.script_parameters == "roof_connect" )
            {
                foreach ( tnode in target )
                {
                    if ( onoff )
                    {
                        maps\mp\zm_highrise_utility::highrise_link_nodes( node, tnode );
                        maps\mp\zm_highrise_utility::highrise_link_nodes( tnode, node );
                        continue;
                    }

                    maps\mp\zm_highrise_utility::highrise_unlink_nodes( node, tnode );
                    maps\mp\zm_highrise_utility::highrise_unlink_nodes( tnode, node );
                }
            }
        }
    }
}

elevator_enable_paths( floor )
{
    self elevator_disable_paths( floor );
    paths = undefined;

    if ( !isdefined( floor ) || !isdefined( self.floors[floor].paths ) )
        return;
    else
        paths = self.floors[floor].paths;

    self.current_paths = paths;
    self.current_paths elevator_paths_onoff( 1, self.roof_paths );
}

elevator_disable_paths( floor )
{
    if ( isdefined( self.current_paths ) )
        self.current_paths elevator_paths_onoff( 0, self.roof_paths );

    self.current_paths = undefined;
}

init_elevator( elevatorname, force_starting_floor, force_starting_origin )
{
    if ( !isdefined( level.elevators ) )
        level.elevators = [];

    elevator = spawnstruct();
    elevator.name = elevatorname;
    elevator.body = undefined;
    level.elevators["bldg" + elevatorname] = elevator;
    piece = getent( "elevator_bldg" + elevatorname + "_body", "targetname" );
    piece setmovingplatformenabled( 1 );
    piece.is_moving = 0;

    if ( !isdefined( piece ) )
    {
/#
        iprintlnbold( "Elevator with name: bldg" + elevatorname + " not found." );
#/
        return;
    }

    trig = getent( "elevator_bldg" + elevatorname + "_trigger", "targetname" );

    if ( isdefined( trig ) )
    {
        trig enablelinkto();
        trig linkto( piece );
        trig setmovingplatformenabled( 1 );
        piece.trig = trig;
        piece thread elevator_roof_watcher();
    }

    elevator.body = piece;
    piece.is_elevator = 1;
    elevator.body perkelevatoruseanimtree();
    assert( isdefined( piece.script_location ) );
    elevator.body.current_level = piece.script_location;
    elevator.body.starting_floor = piece.script_location;
    elevator.roof_paths = elevator_path_nodes( "bldg" + elevatorname, "moving" );
    elevator.floors = [];
    elevator.floors[piece.script_location] = piece;
    elevator.floors[piece.script_location].starting_position = piece.origin;
    elevator.floors[piece.script_location].paths = elevator_path_nodes( "bldg" + elevatorname, "floor" + piece.script_location );

    while ( isdefined( piece.target ) )
    {
        piece = getstruct( piece.target, "targetname" );
        piece.is_elevator = 1;

        if ( !isdefined( elevator.floors[piece.script_location] ) )
        {
            elevator.floors[piece.script_location] = piece;
            elevator.floors[piece.script_location].paths = elevator_path_nodes( "bldg" + elevatorname, "floor" + piece.script_location );
        }
    }

    if ( elevatorname != "3c" )
        elevator.floors["" + elevator.floors.size] = elevator.floors["1"];

    if ( isdefined( force_starting_floor ) )
        elevator.body.force_starting_floor = force_starting_floor;

    if ( isdefined( force_starting_origin ) )
        elevator.body.force_starting_origin_offset = force_starting_origin;

    level thread elevator_think( elevator );
    level thread elevator_depart_early( elevator );
    level thread elevator_sparks_fx( elevator );
/#
    init_elevator_devgui( "bldg" + elevatorname, elevator );
#/
}

elevator_roof_watcher()
{
    level endon( "end_game" );

    while ( true )
    {
        self.trig waittill( "trigger", who );

        if ( isdefined( who ) && isplayer( who ) )
        {
            while ( isdefined( who ) && who istouching( self.trig ) )
            {
                if ( self.is_moving )
                    self waittill_any( "movedone", "forcego" );

                zombies = getaiarray( level.zombie_team );

                if ( isdefined( zombies ) && zombies.size > 0 )
                {
                    foreach ( zombie in zombies )
                    {
                        climber = zombie zombie_for_elevator_unseen();

                        if ( isdefined( climber ) )
                            continue;
                    }

                    if ( isdefined( climber ) )
                    {
                        zombie zombie_climb_elevator( self );
                        wait( randomint( 30 ) );
                    }
                }

                wait 0.5;
            }
        }

        wait 0.5;
    }
}

zombie_for_elevator_unseen()
{
    how_close = 600;
    distance_squared_check = how_close * how_close;
    zombie_seen = 0;
    players = get_players();

    for ( i = 0; i < players.size; i++ )
    {
        can_be_seen = self maps\mp\zm_highrise_distance_tracking::player_can_see_me( players[i] );

        if ( can_be_seen || distancesquared( self.origin, players[i].origin ) < distance_squared_check )
            return undefined;
    }

    return self;
}

zombie_climb_elevator( elev )
{
    self endon( "death" );
    self endon( "removed" );
    self endon( "sonicBoom" );
    level endon( "intermission" );
    self notify( "stop_find_flesh" );
    self.dont_throw_gib = 1;
    self.forcemovementscriptstate = 1;
    self.attachent = elev;
    self linkto( self.attachent, "tag_origin" );
    self.jumpingtoelev = 1;
    animstate = "zm_traverse_elevator";
    anim_name = "zm_zombie_climb_elevator";
    tag_origin = self.attachent gettagorigin( "tag_origin" );
    tag_angles = self.attachent gettagangles( "tag_origin" );
    self animmode( "noclip" );
    self animscripted( tag_origin, tag_angles, animstate, anim_name );
    self maps\mp\animscripts\zm_shared::donotetracks( "traverse_anim" );
    self animmode( "gravity" );
    self.dont_throw_gib = 0;
    self.jumpingtoelev = 0;
    self.forcemovementscriptstate = 0;
    self unlink();
    self setgoalpos( self.origin );
    self thread maps\mp\zombies\_zm_ai_basic::find_flesh();
}

elev_clean_up_corpses()
{
    corpses = getcorpsearray();
    zombies = getaiarray( level.zombie_team );

    if ( isdefined( corpses ) )
    {
        for ( i = 0; i < corpses.size; i++ )
        {
            if ( corpses[i] istouching( self.trig ) )
                corpses[i] thread elev_remove_corpses();
        }
    }

    if ( isdefined( zombies ) )
    {
        foreach ( zombie in zombies )
        {
            if ( zombie istouching( self.trig ) && zombie.health <= 0 )
                zombie thread elev_remove_corpses();
        }
    }
}

elev_remove_corpses()
{
    playfx( level._effect["zomb_gib"], self.origin );
    self delete();
}

elevator_next_floor( elevator, last, justchecking )
{
    if ( isdefined( elevator.body.force_starting_floor ) )
    {
        floor = elevator.body.force_starting_floor;

        if ( !justchecking )
            elevator.body.force_starting_floor = undefined;

        return floor;
    }

    if ( !isdefined( last ) )
        return 0;

    if ( last + 1 < elevator.floors.size )
        return last + 1;

    return 0;
}

elevator_initial_wait( elevator, minwait, maxwait, delaybeforeleaving )
{
    elevator.body endon( "forcego" );
    elevator.body waittill_any_or_timeout( randomintrange( minwait, maxwait ), "depart_early" );

    if ( !is_true( elevator.body.lock_doors ) )
        elevator.body setanim( level.perk_elevators_anims[elevator.body.perk_type][0] );

    if ( !is_true( elevator.body.departing_early ) )
        wait( delaybeforeleaving );

    if ( elevator.body.perk_type == "specialty_weapupgrade" )
    {
        while ( flag( "pack_machine_in_use" ) )
            wait 0.5;

        wait( randomintrange( 1, 3 ) );
    }

    while ( isdefined( level.elevators_stop ) && level.elevators_stop || isdefined( elevator.body.elevator_stop ) && elevator.body.elevator_stop )
        wait 0.05;
}

elevator_set_moving( moving )
{
    self.body.is_moving = moving;

    if ( self.body is_pap() )
        level.pap_moving = moving;
}

predict_floor( elevator, next, speed )
{
    next = elevator_next_floor( elevator, next, 1 );

    if ( isdefined( elevator.floors["" + ( next + 1 )] ) )
        elevator.body.next_level = "" + ( next + 1 );
    else
    {
        start_location = 1;
        elevator.body.next_level = "0";
    }

    floor_stop = elevator.floors[elevator.body.next_level];
    floor_goal = undefined;
    cur_level_start_pos = elevator.floors[elevator.body.next_level].starting_position;
    start_level_start_pos = elevator.floors[elevator.body.starting_floor].starting_position;

    if ( elevator.body.next_level == elevator.body.starting_floor || isdefined( cur_level_start_pos ) && isdefined( start_level_start_pos ) && cur_level_start_pos == start_level_start_pos )
        floor_goal = cur_level_start_pos;
    else
        floor_goal = floor_stop.origin;

    dist = distance( elevator.body.origin, floor_goal );
    time = dist / speed;

    if ( dist > 0 )
    {
        if ( elevator.body.origin[2] > floor_goal[2] )
            clientnotify( elevator.name + "_d" );
        else
            clientnotify( elevator.name + "_u" );
    }
}

elevator_think( elevator )
{
    current_floor = elevator.body.current_location;
    delaybeforeleaving = 5;
    skipinitialwait = 0;
    speed = 100;
    minwait = 5;
    maxwait = 20;
    flag_wait( "perks_ready" );

    if ( isdefined( elevator.body.force_starting_floor ) )
    {
        elevator.body.current_level = "" + elevator.body.force_starting_floor;
        elevator.body.origin = elevator.floors[elevator.body.current_level].origin;

        if ( isdefined( elevator.body.force_starting_origin_offset ) )
            elevator.body.origin += ( 0, 0, elevator.body.force_starting_origin_offset );
    }

    elevator.body.can_move = 1;
    elevator elevator_set_moving( 0 );
    elevator elevator_enable_paths( elevator.body.current_level );

    if ( elevator.body.perk_type == "vending_revive" )
    {
        minwait = level.packapunch_timeout;
        maxwait = minwait + 10;
        elevator thread quick_revive_solo_watch();
    }

    if ( elevator.body.perk_type == "vending_revive" && flag( "solo_game" ) )
    {

    }
    else
        flag_wait( "power_on" );

    elevator.body perkelevatordoor( 1 );
    next = undefined;

    while ( true )
    {
        start_location = 0;

        if ( isdefined( elevator.body.force_starting_floor ) )
            skipinitialwait = 1;

        elevator.body.departing = 1;

        if ( !is_true( elevator.body.lock_doors ) )
            elevator.body setanim( level.perk_elevators_anims[elevator.body.perk_type][1] );

        predict_floor( elevator, next, speed );

        if ( !is_true( skipinitialwait ) )
        {
            elevator_initial_wait( elevator, minwait, maxwait, delaybeforeleaving );

            if ( !is_true( elevator.body.lock_doors ) )
                elevator.body setanim( level.perk_elevators_anims[elevator.body.perk_type][1] );
        }

        next = elevator_next_floor( elevator, next, 0 );

        if ( isdefined( elevator.floors["" + ( next + 1 )] ) )
            elevator.body.next_level = "" + ( next + 1 );
        else
        {
            start_location = 1;
            elevator.body.next_level = "0";
        }

        floor_stop = elevator.floors[elevator.body.next_level];
        floor_goal = undefined;
        cur_level_start_pos = elevator.floors[elevator.body.next_level].starting_position;
        start_level_start_pos = elevator.floors[elevator.body.starting_floor].starting_position;

        if ( elevator.body.next_level == elevator.body.starting_floor || isdefined( cur_level_start_pos ) && isdefined( start_level_start_pos ) && cur_level_start_pos == start_level_start_pos )
            floor_goal = cur_level_start_pos;
        else
            floor_goal = floor_stop.origin;

        dist = distance( elevator.body.origin, floor_goal );
        time = dist / speed;

        if ( dist > 0 )
        {
            if ( elevator.body.origin[2] > floor_goal[2] )
                clientnotify( elevator.name + "_d" );
            else
                clientnotify( elevator.name + "_u" );
        }

        if ( is_true( start_location ) )
        {
            elevator.body thread squashed_death_alarm();

            if ( !skipinitialwait )
                wait 3;
        }

        skipinitialwait = 0;
        elevator.body.current_level = elevator.body.next_level;
        elevator notify( "floor_changed" );
        elevator elevator_disable_paths( elevator.body.current_level );
        elevator.body.departing = 0;
        elevator elevator_set_moving( 1 );

        if ( dist > 0 )
        {
            elevator.body moveto( floor_goal, time, time * 0.25, time * 0.25 );

            if ( isdefined( elevator.body.trig ) )
                elevator.body thread elev_clean_up_corpses();

            elevator.body thread elevator_move_sound();
            elevator.body waittill_any( "movedone", "forcego" );
        }

        elevator elevator_set_moving( 0 );
        elevator elevator_enable_paths( elevator.body.current_level );

        if ( elevator.body.perk_type == "vending_revive" && !flag( "solo_game" ) && !flag( "power_on" ) )
            flag_wait( "power_on" );
    }
}

is_pap()
{
    return self.perk_type == "specialty_weapupgrade";
}

squashed_death_alarm()
{
    if ( !is_true( self.squashed_death_alarm ) )
    {
        self.squashed_death_alarm = 1;
        alarm_origin = spawn( "script_origin", self squashed_death_alarm_nearest_point() );
        alarm_origin playloopsound( "amb_alarm_bell", 0.1 );
        self waittill_any( "movedone", "forcego" );
        alarm_origin delete();
        self.squashed_death_alarm = 0;
    }
}

squashed_death_alarm_nearest_point()
{
    positions = array( ( 1653, 2267, 3527 ), ( 1962, 1803, 3575 ), ( 1379, 1224, 3356 ), ( 3161, -35, 3032 ), ( 2745, -672, 3014 ), ( 2404, -754, 3019 ), ( 1381, -660, 2842 ) );
    closest = vectorscale( ( 1, 1, 1 ), 999999.0 );

    foreach ( vector in positions )
    {
        if ( distance2dsquared( self.origin, vector ) < distance2dsquared( self.origin, closest ) )
            closest = vector;
    }

    return closest;
}

elevator_move_sound()
{
    self playsound( "zmb_elevator_ding" );
    wait 0.4;
    self playsound( "zmb_elevator_ding" );
    self playsound( "zmb_elevator_run_start" );
    self playloopsound( "zmb_elevator_run", 0.5 );

    self waittill( "movedone" );

    self stoploopsound( 0.5 );
    self playsound( "zmb_elevator_run_stop" );
    self playsound( "zmb_elevator_ding" );
}

init_elevator_perks()
{
    level.elevator_perks = [];
    level.elevator_perks_building = [];
    level.elevator_perks_building["green"] = [];
    level.elevator_perks_building["blue"] = [];
    level.elevator_perks_building["green"][0] = spawnstruct();
    level.elevator_perks_building["green"][0].model = "zombie_vending_revive";
    level.elevator_perks_building["green"][0].script_noteworthy = "specialty_quickrevive";
    level.elevator_perks_building["green"][0].turn_on_notify = "revive_on";
    a = 1;
    b = 2;

    if ( randomint( 100 ) > 50 )
    {
        a = 2;
        b = 1;
    }

    level.elevator_perks_building["green"][a] = spawnstruct();
    level.elevator_perks_building["green"][a].model = "p6_zm_vending_chugabud";
    level.elevator_perks_building["green"][a].script_noteworthy = "specialty_finalstand";
    level.elevator_perks_building["green"][a].turn_on_notify = "chugabud_on";
    level.elevator_perks_building["green"][b] = spawnstruct();
    level.elevator_perks_building["green"][b].model = "zombie_vending_sleight";
    level.elevator_perks_building["green"][b].script_noteworthy = "specialty_fastreload";
    level.elevator_perks_building["green"][b].turn_on_notify = "sleight_on";
    level.elevator_perks_building["blue"][0] = spawnstruct();
    level.elevator_perks_building["blue"][0].model = "zombie_vending_three_gun";
    level.elevator_perks_building["blue"][0].script_noteworthy = "specialty_additionalprimaryweapon";
    level.elevator_perks_building["blue"][0].turn_on_notify = "specialty_additionalprimaryweapon_power_on";
    level.elevator_perks_building["blue"][1] = spawnstruct();
    level.elevator_perks_building["blue"][1].model = "zombie_vending_jugg";
    level.elevator_perks_building["blue"][1].script_noteworthy = "specialty_armorvest";
    level.elevator_perks_building["blue"][1].turn_on_notify = "juggernog_on";
    level.elevator_perks_building["blue"][2] = spawnstruct();
    level.elevator_perks_building["blue"][2].model = "zombie_vending_doubletap2";
    level.elevator_perks_building["blue"][2].script_noteworthy = "specialty_rof";
    level.elevator_perks_building["blue"][2].turn_on_notify = "doubletap_on";
    level.elevator_perks_building["blue"][3] = spawnstruct();
    level.elevator_perks_building["blue"][3].model = "p6_anim_zm_buildable_pap";
    level.elevator_perks_building["blue"][3].script_noteworthy = "specialty_weapupgrade";
    level.elevator_perks_building["blue"][3].turn_on_notify = "Pack_A_Punch_on";
    players_expected = getnumexpectedplayers();
    level.override_perk_targetname = "zm_perk_machine_override";
    level.elevator_perks_building["blue"] = array_randomize( level.elevator_perks_building["blue"] );
    level.elevator_perks = arraycombine( level.elevator_perks_building["green"], level.elevator_perks_building["blue"], 0, 0 );
    random_perk_structs = [];
    revive_perk_struct = getstruct( "force_quick_revive", "targetname" );
    revive_perk_struct = getstruct( revive_perk_struct.target, "targetname" );
    perk_structs = getstructarray( "zm_random_machine", "script_noteworthy" );

    for ( i = 0; i < perk_structs.size; i++ )
    {
        random_perk_structs[i] = getstruct( perk_structs[i].target, "targetname" );
        random_perk_structs[i].script_parameters = perk_structs[i].script_parameters;
        random_perk_structs[i].script_linkent = getent( "elevator_" + perk_structs[i].script_parameters + "_body", "targetname" );
    }

    green_structs = [];
    blue_structs = [];

    foreach ( perk_struct in random_perk_structs )
    {
        if ( isdefined( perk_struct.script_parameters ) )
        {
            if ( issubstr( perk_struct.script_parameters, "bldg1" ) )
            {
                green_structs[green_structs.size] = perk_struct;
                continue;
            }

            blue_structs[blue_structs.size] = perk_struct;
        }
    }

    green_structs = array_exclude( green_structs, revive_perk_struct );
    green_structs = array_randomize( green_structs );
    blue_structs = array_randomize( blue_structs );
    level.random_perk_structs = array( revive_perk_struct );
    level.random_perk_structs = arraycombine( level.random_perk_structs, green_structs, 0, 0 );
    level.random_perk_structs = arraycombine( level.random_perk_structs, blue_structs, 0, 0 );

    for ( i = 0; i < level.elevator_perks.size; i++ )
    {
        if ( !isdefined( level.random_perk_structs[i] ) )
            continue;

        level.random_perk_structs[i].targetname = "zm_perk_machine_override";
        level.random_perk_structs[i].model = level.elevator_perks[i].model;
        level.random_perk_structs[i].script_noteworthy = level.elevator_perks[i].script_noteworthy;
        level.random_perk_structs[i].turn_on_notify = level.elevator_perks[i].turn_on_notify;

        if ( !isdefined( level.struct_class_names["targetname"]["zm_perk_machine_override"] ) )
            level.struct_class_names["targetname"]["zm_perk_machine_override"] = [];

        level.struct_class_names["targetname"]["zm_perk_machine_override"][level.struct_class_names["targetname"]["zm_perk_machine_override"].size] = level.random_perk_structs[i];
    }
}

random_elevator_perks()
{
    perks = array( "vending_additionalprimaryweapon", "vending_revive", "vending_chugabud", "vending_jugg", "vending_doubletap", "vending_sleight" );

    foreach ( perk in perks )
    {
        machine = getent( perk, "targetname" );
        trigger = getent( perk, "target" );

        if ( !isdefined( machine ) || !isdefined( trigger ) )
            continue;

        elevator = machine get_perk_elevator();
        trigger enablelinkto();
        trigger linkto( machine );

        if ( isdefined( trigger.clip ) )
            trigger.clip delete();

        if ( isdefined( trigger.bump ) )
        {
            trigger.bump enablelinkto();
            trigger.bump linkto( machine );
        }

        if ( isdefined( elevator ) )
        {
            elevator.perk_type = perk;

            if ( issubstr( elevator.targetname, "3b" ) )
                machine.origin += vectorscale( ( 0, 0, 1 ), 8.0 );

            elevator elevator_perk_offset( machine, perk );
            machine linkto( elevator );
            machine._linked_ent = elevator;
            machine._linked_ent_moves = 1;
            machine._linked_ent_offset = machine.origin - elevator.origin;

            if ( perk == "vending_revive" )
            {
                level.quick_revive_linked_ent = elevator;
                level.quick_revive_linked_ent_moves = 1;
                level.quick_revive_linked_ent_offset = machine._linked_ent_offset;
            }

            level thread debugline( machine, elevator );
        }
    }

    trigger = getent( "specialty_weapupgrade", "script_noteworthy" );

    if ( isdefined( trigger ) )
    {
        machine = getent( trigger.target, "targetname" );
        elevator = machine get_perk_elevator();
        fwdvec = anglestoright( machine.angles );
        fwdvec = vectornormalize( fwdvec ) * 20;
        trigger.origin += ( fwdvec[0], fwdvec[1], 8 );
        trigger enablelinkto();
        trigger linkto( machine );

        if ( isdefined( trigger.clip ) )
            trigger.clip delete();

        if ( isdefined( elevator ) )
        {
            elevator.perk_type = "specialty_weapupgrade";
            machine linkto( elevator );
            level thread debugline( machine, elevator );
        }
    }

    flag_set( "perks_ready" );
}

elevator_perk_offset( machine, perk )
{
    scale = 14;

    switch ( perk )
    {
        case "vending_revive":
            scale = 10;
            break;
        case "vending_additionalprimaryweapon":
            scale = 8;
            break;
        case "vending_jugg":
            scale = 6;
            break;
        case "vending_doubletap":
            scale = 5;
            break;
        case "vending_chugabud":
            scale = -3;
            break;
        case "vending_packapunch":
            scale = 0;
            break;
    }

    if ( scale == 0 )
        return;

    forward = anglestoforward( self.angles );
    machine.origin -= forward * scale;
}

debugline( ent1, ent2 )
{
/#
    org = ent2.origin;

    while ( true )
    {
        if ( !isdefined( ent1 ) )
            return;

        line( ent1.origin, org, ( 0, 0, 1 ) );
        wait 0.05;
    }
#/
}

get_perk_elevator()
{
    arraylist = level.random_perk_structs;

    for ( x = 0; x < arraylist.size; x++ )
    {
        struct = arraylist[x];

        if ( isdefined( struct.script_noteworthy ) && isdefined( self.targetname ) )
        {
            nw = struct.script_noteworthy;
            tn = self.targetname;

            if ( nw == "specialty_quickrevive" && tn == "vending_revive" || nw == "specialty_fastreload" && tn == "vending_sleight" || nw == "specialty_rof" && tn == "vending_doubletap" || nw == "specialty_armorvest" && tn == "vending_jugg" || nw == "specialty_finalstand" && tn == "vending_chugabud" || nw == "specialty_additionalprimaryweapon" && tn == "vending_additionalprimaryweapon" || nw == "specialty_weapupgrade" && tn == "vending_packapunch" )
            {
                if ( isdefined( struct.script_linkent ) )
                    return struct.script_linkent;
            }
        }
    }

    return undefined;
}

elevator_depart_early( elevator )
{
    touchent = elevator.body;

    if ( isdefined( elevator.body.trig ) )
        touchent = elevator.body.trig;

    while ( true )
    {
        while ( is_true( elevator.body.is_moving ) )
            wait 0.5;

        someone_touching_elevator = 0;
        players = get_players();

        foreach ( player in players )
        {
            if ( player istouching( touchent ) )
                someone_touching_elevator = 1;
        }

        if ( is_true( someone_touching_elevator ) )
        {
            someone_still_touching_elevator = 0;
            wait 5;
            players = get_players();

            foreach ( player in players )
            {
                if ( player istouching( touchent ) )
                    someone_still_touching_elevator = 1;
            }

            if ( is_true( someone_still_touching_elevator ) )
            {
                elevator.body.departing_early = 1;
                elevator.body notify( "depart_early" );
                wait 3;
                elevator.body.departing_early = 0;
            }
        }

        wait 1;
    }
}

elevator_sparks_fx( elevator )
{
    while ( true )
    {
        while ( !is_true( elevator.body.door_state ) )
            wait 1;

        if ( is_true( elevator.body.departing ) )
            playfxontag( level._effect["perk_elevator_departing"], elevator.body, "tag_origin" );
        else
            playfxontag( level._effect["perk_elevator_idle"], elevator.body, "tag_origin" );

        wait 0.5;
    }
}

faller_location_logic()
{
    wait 1;
    faller_spawn_points = getstructarray( "faller_location", "script_noteworthy" );
    leaper_spawn_points = getstructarray( "leaper_location", "script_noteworthy" );
    spawn_points = arraycombine( faller_spawn_points, leaper_spawn_points, 1, 0 );
    dist_check = 16384;
    elevator_names = getarraykeys( level.elevators );
    elevators = [];

    for ( i = 0; i < elevator_names.size; i++ )
        elevators[i] = getent( "elevator_" + elevator_names[i] + "_body", "targetname" );

    elevator_volumes = [];
    elevator_volumes[elevator_volumes.size] = getent( "elevator_1b", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_1c", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_1d", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3a", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3b", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3c", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3d", "targetname" );
    level.elevator_volumes = elevator_volumes;

    while ( true )
    {
        foreach ( point in spawn_points )
        {
            should_block = 0;

            foreach ( elevator in elevators )
            {
                if ( distancesquared( elevator.origin, point.origin ) <= dist_check )
                    should_block = 1;
            }

            if ( should_block )
            {
                point.is_enabled = 0;
                point.is_blocked = 1;
                continue;
            }

            if ( isdefined( point.is_blocked ) && point.is_blocked )
                point.is_blocked = 0;

            if ( !isdefined( point.zone_name ) )
                continue;

            zone = level.zones[point.zone_name];

            if ( zone.is_enabled && zone.is_active && zone.is_spawning_allowed )
                point.is_enabled = 1;
        }

        players = get_players();

        foreach ( volume in elevator_volumes )
        {
            should_disable = 0;

            foreach ( player in players )
            {
                if ( is_player_valid( player ) )
                {
                    if ( player istouching( volume ) )
                        should_disable = 1;
                }
            }

            if ( should_disable )
                disable_elevator_spawners( volume, spawn_points );
        }

        wait 0.5;
    }
}

disable_elevator_spawners( volume, spawn_points )
{
    foreach ( point in spawn_points )
    {
        if ( isdefined( point.name ) && point.name == volume.targetname )
            point.is_enabled = 0;
    }
}

shouldsuppressgibs()
{
    elevator_volumes = [];
    elevator_volumes[elevator_volumes.size] = getent( "elevator_1b", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_1c", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_1d", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3a", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3b", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3c", "targetname" );
    elevator_volumes[elevator_volumes.size] = getent( "elevator_3d", "targetname" );

    while ( true )
    {
        zombies = get_round_enemy_array();

        if ( isdefined( zombies ) )
        {
            foreach ( zombie in zombies )
            {
                shouldnotgib = 0;

                foreach ( zone in elevator_volumes )
                {
                    if ( is_true( shouldnotgib ) )
                        continue;

                    if ( zombie istouching( zone ) )
                        shouldnotgib = 1;
                }

                zombie.dont_throw_gib = shouldnotgib;
            }
        }

        wait( randomfloatrange( 0.5, 1.5 ) );
    }
}

watch_for_elevator_during_faller_spawn()
{
    self endon( "death" );
    self endon( "risen" );
    self endon( "spawn_anim" );

    while ( true )
    {
        should_gib = 0;

        foreach ( elevator in level.elevators )
        {
            if ( self istouching( elevator.body ) )
                should_gib = 1;
        }

        if ( should_gib )
        {
            playfx( level._effect["zomb_gib"], self.origin );

            if ( !( isdefined( self.has_been_damaged_by_player ) && self.has_been_damaged_by_player ) && !( isdefined( self.is_leaper ) && self.is_leaper ) )
                level.zombie_total++;

            if ( isdefined( self.is_leaper ) && self.is_leaper )
            {
                self maps\mp\zombies\_zm_ai_leaper::leaper_cleanup();
                self dodamage( self.health + 100, self.origin );
            }
            else
                self delete();

            break;
        }

        wait 0.1;
    }
}

init_elevator_devgui( elevatorname, elevator )
{
/#
    if ( !isdefined( elevatorname ) )
    {
        adddebugcommand( "devgui_cmd \"Zombies:1/Highrise:15/Elevators:1/Stop All:1\" \"set zombie_devgui_hrelevatorstop all\" \\n" );
        adddebugcommand( "devgui_cmd \"Zombies:1/Highrise:15/Elevators:1/Unstop All:2\" \"set zombie_devgui_hrelevatorgo all\" \\n" );
        level thread watch_elevator_devgui( "all", 1 );
    }
    else
    {
        adddebugcommand( "devgui_cmd \"Zombies:1/Highrise:15/Elevators:1/" + elevatorname + "/Stop:1\" \"set zombie_devgui_hrelevatorstop " + elevatorname + "\" \\n" );
        adddebugcommand( "devgui_cmd \"Zombies:1/Highrise:15/Elevators:1/" + elevatorname + "/Go:2\" \"set zombie_devgui_hrelevatorgo " + elevatorname + "\" \\n" );

        for ( i = 0; i < elevator.floors.size; i++ )
        {
            fname = elevator.floors["" + i].script_location;
            adddebugcommand( "devgui_cmd \"Zombies:1/Highrise:15/Elevators:1/" + elevatorname + "/stop " + i + " [floor " + fname + "]\" \"set zombie_devgui_hrelevatorfloor " + i + "; set zombie_devgui_hrelevatorgo " + elevatorname + "\" \\n" );
        }

        elevator thread watch_elevator_devgui( elevatorname, 0 );
        elevator thread show_elevator_floor( elevatorname );
    }
#/
}

watch_elevator_devgui( name, global )
{
/#
    while ( true )
    {
        stopcmd = getdvar( _hash_7844BB8F );

        if ( isdefined( stopcmd ) && stopcmd == name )
        {
            if ( global )
                level.elevators_stop = 1;
            else if ( isdefined( self ) )
                self.body.elevator_stop = 1;

            setdvar( "zombie_devgui_hrelevatorstop", "" );
        }

        gofloor = getdvarint( _hash_7FEC8C2B );
        gocmd = getdvar( _hash_8693373F );

        if ( isdefined( gocmd ) && gocmd == name )
        {
            if ( global )
                level.elevators_stop = 0;
            else if ( isdefined( self ) )
            {
                self.body.elevator_stop = 0;

                if ( gofloor >= 0 )
                    self.body.force_starting_floor = gofloor;

                self.body notify( "forcego" );
            }

            setdvar( "zombie_devgui_hrelevatorfloor", "-1" );
            setdvar( "zombie_devgui_hrelevatorgo", "" );
        }

        wait 1.0;
    }
#/
}

show_elevator_floor( name )
{
/#
    while ( true )
    {
        if ( getdvarint( _hash_B67910B4 ) )
        {
            floor = 0;
            forced = isdefined( self.body.force_starting_floor );
            color = vectorscale( ( 1, 1, 0 ), 0.7 );

            if ( forced )
                color = ( 0.7, 0.3, 0.0 );

            if ( isdefined( level.elevators_stop ) && level.elevators_stop || isdefined( self.body.elevator_stop ) && self.body.elevator_stop )
            {
                if ( forced )
                    color = vectorscale( ( 1, 0, 1 ), 0.7 );
                else
                    color = vectorscale( ( 1, 0, 0 ), 0.7 );
            }
            else if ( self.body.is_moving )
            {
                if ( forced )
                    color = vectorscale( ( 0, 0, 1 ), 0.7 );
                else
                    color = vectorscale( ( 0, 1, 0 ), 0.7 );
            }

            if ( isdefined( self.body.current_level ) )
                floor = self.body.current_level;

            text = "elv " + name + " stop " + self.body.current_level + " floor " + self.floors[self.body.current_level].script_location;
            pos = self.body.origin;
            print3d( pos, text, color, 1, 0.75, 1 );
        }

        wait 0.05;
    }
#/
}
