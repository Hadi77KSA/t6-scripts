// T6 GSC SOURCE
// Generated by https://github.com/xensik/gsc-tool
#include clientscripts\mp\_utility;
#include clientscripts\mp\zombies\_zm_utility;

weapon_box_callback( localclientnum, set, newent )
{
/#
    println( "ZM >> weapon_box_callback - client scripts" );
#/

    if ( localclientnum != 0 )
        return;

    if ( set )
        self thread weapon_floats_up();
    else
    {
        self notify( "end_float" );
        cleanup_weapon_models();
    }
}

cleanup_weapon_models()
{
    if ( isdefined( self.weapon_models ) )
    {
        players = level.localplayers;

        for ( index = 0; index < players.size; index++ )
        {
            if ( isdefined( self.weapon_models[index] ) )
            {
                self.weapon_models[index].dw delete();
                self.weapon_models[index] delete();
            }
        }

        self.weapon_models = undefined;
    }
}

weapon_is_dual_wield( name )
{
    switch ( name )
    {
        case "cz75dw_upgraded_zm":
        case "cz75dw_zm":
        case "fivesevendw_upgraded_zm":
        case "fivesevendw_zm":
        case "hs10_upgraded_zm":
        case "m1911_upgraded_zm":
        case "microwavegundw_upgraded_zm":
        case "microwavegundw_zm":
        case "pm63_upgraded_zm":
            return true;
        default:
            return false;
    }
}

weapon_floats_up()
{
    self endon( "end_float" );
    cleanup_weapon_models();
    self.weapon_models = [];
    number_cycles = 39;
    floatheight = 64;
    rand = treasure_chest_chooserandomweapon();
    modelname = getweaponmodel( rand );
    level.localplayers = getlocalplayers();
    players = level.localplayers;
/#
    println( "ZM >> weapon_box_callback - players.size=" + players.size );
#/

    for ( i = 0; i < players.size; i++ )
    {
        self.weapon_models[i] = spawn_weapon_model( i, rand, modelname, self.origin, self.angles + vectorscale( ( 0, 1, 0 ), 180.0 ) );
        self.weapon_models[i].dw = spawn_weapon_model( i, rand, modelname, self.origin - vectorscale( ( 1, 1, 1 ), 3.0 ), self.angles + vectorscale( ( 0, 1, 0 ), 180.0 ) );
        self.weapon_models[i].dw hide();
        self.weapon_models[i] moveto( self.origin + ( 0, 0, floatheight ), 3, 2, 0.9 );
        self.weapon_models[i].dw moveto( self.origin + ( 0, 0, floatheight ) - vectorscale( ( 1, 1, 1 ), 3.0 ), 3, 2, 0.9 );
    }

    for ( i = 0; i < number_cycles; i++ )
    {
        if ( i < 20 )
            serverwait( 0, 0.05, 0.01 );
        else if ( i < 30 )
            serverwait( 0, 0.1, 0.01 );
        else if ( i < 35 )
            serverwait( 0, 0.2, 0.01 );
        else if ( i < 38 )
            serverwait( 0, 0.3, 0.01 );

        rand = treasure_chest_chooserandomweapon();
        modelname = getweaponmodel( rand );
        players = level.localplayers;

        for ( index = 0; index < players.size; index++ )
        {
            if ( isdefined( self.weapon_models[index] ) )
            {
                self.weapon_models[index] setmodel( modelname );
                self.weapon_models[index] useweaponhidetags( rand );

                if ( weapon_is_dual_wield( rand ) )
                {
                    self.weapon_models[index].dw setmodel( modelname );
                    self.weapon_models[index].dw useweaponhidetags( rand );
                    self.weapon_models[index].dw show();
                    continue;
                }

                self.weapon_models[index].dw hide();
            }
        }
    }

    cleanup_weapon_models();
}

is_weapon_included( weapon_name )
{
    if ( !isdefined( level._included_weapons ) )
        return false;

    for ( i = 0; i < level._included_weapons.size; i++ )
    {
        if ( weapon_name == level._included_weapons[i] )
            return true;
    }

    return false;
}

include_weapon( weapon, display_in_box, func )
{
    if ( !isdefined( level._included_weapons ) )
        level._included_weapons = [];

    level._included_weapons[level._included_weapons.size] = weapon;

    if ( !isdefined( level._display_box_weapons ) )
        level._display_box_weapons = [];

    if ( !isdefined( display_in_box ) )
        display_in_box = 1;

    if ( !display_in_box )
        return;

    if ( !isdefined( level._resetzombieboxweapons ) )
    {
        level._resetzombieboxweapons = 1;
        resetzombieboxweapons();
    }

    addzombieboxweapon( weapon, getweaponmodel( weapon ), weapon_is_dual_wield( weapon ) );
    level._display_box_weapons[level._display_box_weapons.size] = weapon;
}

treasure_chest_chooserandomweapon()
{
    if ( !isdefined( level._display_box_weapons ) )
        level._display_box_weapons = array( "python_zm", "g11_lps_zm", "famas_zm" );

    return level._display_box_weapons[randomint( level._display_box_weapons.size )];
}

init()
{
    spawn_list = [];
    spawnable_weapon_spawns = getstructarray( "weapon_upgrade", "targetname" );
    spawnable_weapon_spawns = arraycombine( spawnable_weapon_spawns, getstructarray( "bowie_upgrade", "targetname" ), 1, 0 );
    spawnable_weapon_spawns = arraycombine( spawnable_weapon_spawns, getstructarray( "sickle_upgrade", "targetname" ), 1, 0 );
    spawnable_weapon_spawns = arraycombine( spawnable_weapon_spawns, getstructarray( "tazer_upgrade", "targetname" ), 1, 0 );
    spawnable_weapon_spawns = arraycombine( spawnable_weapon_spawns, getstructarray( "buildable_wallbuy", "targetname" ), 1, 0 );

    if ( !level.headshots_only )
        spawnable_weapon_spawns = arraycombine( spawnable_weapon_spawns, getstructarray( "claymore_purchase", "targetname" ), 1, 0 );

    location = level.scr_zm_map_start_location;

    if ( ( location == "default" || location == "" ) && isdefined( level.default_start_location ) )
        location = level.default_start_location;

    match_string = level.scr_zm_ui_gametype + "_" + location;
    match_string_plus_space = " " + match_string;

    for ( i = 0; i < spawnable_weapon_spawns.size; i++ )
    {
        spawnable_weapon = spawnable_weapon_spawns[i];

        if ( isdefined( spawnable_weapon.zombie_weapon_upgrade ) && spawnable_weapon.zombie_weapon_upgrade == "sticky_grenade_zm" && is_true( level.headshots_only ) )
            continue;

        if ( !isdefined( spawnable_weapon.script_noteworthy ) || spawnable_weapon.script_noteworthy == "" )
        {
            spawn_list[spawn_list.size] = spawnable_weapon;
            continue;
        }

        matches = strtok( spawnable_weapon.script_noteworthy, "," );

        for ( j = 0; j < matches.size; j++ )
        {
            if ( matches[j] == match_string || matches[j] == match_string_plus_space )
                spawn_list[spawn_list.size] = spawnable_weapon;
        }
    }

    level._active_wallbuys = [];

    for ( i = 0; i < spawn_list.size; i++ )
    {
        spawn_list[i].script_label = spawn_list[i].zombie_weapon_upgrade + "_" + spawn_list[i].origin;
        level._active_wallbuys[spawn_list[i].script_label] = spawn_list[i];
        numbits = 2;

        if ( isdefined( level._wallbuy_override_num_bits ) )
            numbits = level._wallbuy_override_num_bits;

        registerclientfield( "world", spawn_list[i].script_label, 1, numbits, "int", ::wallbuy_callback, 0 );
        target_struct = getstruct( spawn_list[i].target, "targetname" );

        if ( spawn_list[i].targetname == "buildable_wallbuy" )
        {
            bits = 4;

            if ( isdefined( level.buildable_wallbuy_weapons ) )
                bits = getminbitcountfornum( level.buildable_wallbuy_weapons.size + 1 );

            registerclientfield( "world", spawn_list[i].script_label + "_idx", 12000, bits, "int", ::wallbuy_callback_idx, 0 );
        }
    }

    onplayerconnect_callback( ::wallbuy_player_connect );
}

wallbuy_player_connect( localclientnum )
{
    keys = getarraykeys( level._active_wallbuys );
/#
    println( "Wallbuy connect cb : " + localclientnum );
#/

    if ( isdefined( level.createfx_enabled ) && level.createfx_enabled )
        return;

    for ( i = 0; i < keys.size; i++ )
    {
        wallbuy = level._active_wallbuys[keys[i]];
        fx = level._effect["m14_zm_fx"];

        if ( wallbuy.targetname == "buildable_wallbuy" )
            fx = level._effect["dynamic_wallbuy_fx"];
        else if ( isdefined( level._effect[wallbuy.zombie_weapon_upgrade + "_fx"] ) )
            fx = level._effect[wallbuy.zombie_weapon_upgrade + "_fx"];

        wallbuy.fx[localclientnum] = playfx( localclientnum, fx, wallbuy.origin, anglestoforward( wallbuy.angles ), anglestoup( wallbuy.angles ), 0.1 );
        target_struct = getstruct( wallbuy.target, "targetname" );

        if ( wallbuy.targetname == "buildable_wallbuy" )
            continue;

        target_model = spawn_weapon_model( localclientnum, wallbuy.zombie_weapon_upgrade, target_struct.model, target_struct.origin, target_struct.angles );
        target_model hide();
        target_model.parent_struct = target_struct;
        wallbuy.models[localclientnum] = target_model;
    }
}

wallbuy_callback( localclientnum, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump )
{
    if ( binitialsnap )
    {
        while ( !isdefined( level._active_wallbuys ) || !isdefined( level._active_wallbuys[fieldname] ) )
            wait 0.05;
    }

    struct = level._active_wallbuys[fieldname];
/#
    println( "wallbuy callback " + localclientnum );
#/

    switch ( newval )
    {
        case 0:
            struct.models[localclientnum].origin = struct.models[localclientnum].parent_struct.origin;
            struct.models[localclientnum].angles = struct.models[localclientnum].parent_struct.angles;
            struct.models[localclientnum] hide();
            break;
        case 1:
            if ( binitialsnap )
            {
                if ( !isdefined( struct.models ) )
                {
                    while ( !isdefined( struct.models ) )
                        wait 0.05;

                    while ( !isdefined( struct.models[localclientnum] ) )
                        wait 0.05;
                }

                struct.models[localclientnum] show();
                struct.models[localclientnum].origin = struct.models[localclientnum].parent_struct.origin;
            }
            else
            {
                wait 0.05;

                if ( localclientnum == 0 )
                    playsound( 0, "zmb_weap_wall", struct.origin );

                vec_offset = ( 0, 0, 0 );

                if ( isdefined( struct.models[localclientnum].parent_struct.script_vector ) )
                    vec_offset = struct.models[localclientnum].parent_struct.script_vector;

                struct.models[localclientnum].origin = struct.models[localclientnum].parent_struct.origin + anglestoright( struct.models[localclientnum].angles + vec_offset ) * 8;
                struct.models[localclientnum] show();
                struct.models[localclientnum] moveto( struct.models[localclientnum].parent_struct.origin, 1 );
            }

            break;
        case 2:
            if ( isdefined( level.wallbuy_callback_hack_override ) )
                struct.models[localclientnum] [[ level.wallbuy_callback_hack_override ]]();

            break;
    }
}

wallbuy_callback_idx( localclientnum, oldval, newval, bnewent, binitialsnap, fieldname, bwasdemojump )
{
    basefield = getsubstr( fieldname, 0, fieldname.size - 4 );
    struct = level._active_wallbuys[basefield];

    if ( newval == 0 )
    {
        if ( isdefined( struct.models[localclientnum] ) )
            struct.models[localclientnum] hide();
    }
    else if ( newval > 0 )
    {
        weaponname = level.buildable_wallbuy_weapons[newval - 1];

        if ( !isdefined( struct.models ) )
            struct.models = [];

        if ( !isdefined( struct.models[localclientnum] ) )
        {
            target_struct = getstruct( struct.target, "targetname" );
            model = undefined;

            if ( isdefined( level.buildable_wallbuy_weapon_models[weaponname] ) )
                model = level.buildable_wallbuy_weapon_models[weaponname];

            angles = target_struct.angles;

            if ( isdefined( level.buildable_wallbuy_weapon_angles[weaponname] ) )
            {
                switch ( level.buildable_wallbuy_weapon_angles[weaponname] )
                {
                    case 90:
                        angles = vectortoangles( anglestoright( angles ) );
                        break;
                    case 180:
                        angles = vectortoangles( anglestoforward( angles ) * -1 );
                        break;
                    case 270:
                        angles = vectortoangles( anglestoright( angles ) * -1 );
                        break;
                }
            }

            target_model = spawn_weapon_model( localclientnum, weaponname, model, target_struct.origin, angles );
            target_model hide();
            target_model.parent_struct = target_struct;
            struct.models[localclientnum] = target_model;

            if ( isdefined( struct.fx[localclientnum] ) )
            {
                stopfx( localclientnum, struct.fx[localclientnum] );
                struct.fx[localclientnum] = undefined;
            }

            fx = level._effect["m14_zm_fx"];

            if ( isdefined( level._effect[weaponname + "_fx"] ) )
                fx = level._effect[weaponname + "_fx"];

            struct.fx[localclientnum] = playfx( localclientnum, fx, struct.origin, anglestoforward( struct.angles ), anglestoup( struct.angles ), 0.1 );
            level notify( "wallbuy_updated" );
        }
    }
}
