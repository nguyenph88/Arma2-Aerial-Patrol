// *********************************
// Airpatrol.sqf
// Author: Donnavan
// Creates Airbourne convoys
// Modifications:
// Random Weapon selection by Tang0 - redacted
// Random crew skins by Albertus Smythe - redacted
// Random convoy selection by Albertus Smythe
// Bigger spawn area radius by Albertus Smythe
// Below modifications are done by salival
// Full credit for the AI gear/pack/skin/weapon selection goes to WAI, I used this system because it works amazingly and it gives me a single configuration to make loot changes to. - salival
// Random gear selection (ai_gear_random from WAI - WAI MUST BE INSTALLED)
// Random weapon selection (ai_wep_random from WAI - WAI MUST BE INSTALLED)
// Random backpack selection (ai_packs from WAI - WAI MUST BE INSTALLED)
// Random skill selection (ai_skill_random from WAI - WAI MUST BE INSTALLED) 
// Random skin selection (variable: _aiskins contains arrays from WAI (ai_hero_skin,ai_bandit_skin) - WAI MUST BE INSTALLED)
// Enemy will now pull parachute 100% of the time to stop players from getting free loot. Make the buggers work for it!
// Enemies will now share information about players to other AI when a unit is killed (variable _aisharedistance)
// Humanity is now given/lost dependant on alignment, - humanity if player is bandit, + humanity if player is hero
// Chopper will now correctly spawn at the right height based on _spawn (setPosATL)
// Chopper will now fly at a height of (_fh_lower + random(_fh_random). 
// Chopper will randomly select a speed from _convoyspeeds. You can sway the chance of a particular speed being selected by upping the number in the second field. Make sure it all adds up to 100.
// *********************************

//diag_log format ["Heli Convoy: debug: %1 ",_debugvariable]; //place holder for debugging.


if (isServer) then {
    // Add 5min delay to alow DZAI etc to sort itself out otherwise 1st heli seems to be created without a pilot
    // so it immedietly crashes and then there are no waypoints set for the convoy so it just hovers above
    // the create point
    uiSleep (60*5);
    
    _convoyspeed = [];
    _flyspeed = "";
    
    _fh_random = 80; // This number here gets randomized and then added to the below number to form the _flyheight variable.
    _fh_lower = 70; // This is the lowest number that flyheight can be, the above number gets randomized and added to it to form the _flyheight variable.
    _aisharedistance = 600;
    _aiskins = ai_hero_skin + ai_bandit_skin;
    _spawn = [50,50,300]; // Spawn location of chopper, x, y and z for height.
    //_spawn = [100,1500,0]; //debug spawn location for testing

    _gridN = 15;
    _mapSize = 15360; //CHERNARUS

    // ["SPEED",% chance of picking this speed], Make sure the chances add up to 100 or it will not be an accurate percentage.
    _convoyspeeds           = [ 
    ["LIMITED",10],
    ["NORMAL",50],
    ["FULL",40]
    ];
    
    _heliFormation =[
    [5,0],
    [10,6],
    [4,3], 
    [0,4], 
    [8,1,7],
    [0], 
    [1],
    [2],  
    [3],
    [4],
    [5],
    [6],
    [7],
    [8], 
    [10]
    ];
    
    // define a list of heli's to make up convoys from.
    // [ Vehicle_name,Passenger count,[ammo for each gunpoint],number of Loot points]
    // Passenger count is in addition to the pilot and gunners on the heli's gun points.
    // Empty ammo array means the Heli is unarmed and won't shoot but will land and disembark crew.
    donn_heliConvy = [
    /*0*/["UH1H_DZ",0,["100Rnd_762x51_M240","100Rnd_762x51_M240"],3],
    /*1*/["UH1H_DZ",4,[],4],
    /*2*/["Mi17_UN_CDF_EP1",5,["100Rnd_762x54_PK","100Rnd_762x54_PK"],5],
    /*3*/["CH_47F_EP1_DZE",6,["100Rnd_762x51_M240","4000Rnd_762x51_M134","4000Rnd_762x51_M134"],6],
    /*4*/["AH6J_EP1_DZ",1,[],2],        //ARMED (PILOT)
    /*5*/["UH60M_EP1_DZE",0,["2000Rnd_762x51_M134","2000Rnd_762x51_M134"],3],
    /*6*/["UH1Y_DZE",0,["2000Rnd_762x51_M134","2000Rnd_762x51_M134"],3],
    /*7*/["UH1H_TK_EP1",0,["100Rnd_762x51_M240","100Rnd_762x51_M240"],3],
    /*8*/["BAF_Merlin_DZE",4,[],4],
    /*9*/["pook_H13_amphib_CIV",1,[],1],
    /*10*/["pook_H13_transport_UNO",2,["100Rnd_762x51_M240"],2]
    ];

    {
        for "_i" from 1 to (_x select 1) do {
            _convoyspeed set [count _convoyspeed, _x select 0];
        };
    } count _convoyspeeds;
    
    donn_hwps = [];

    for "_i" from 1 to (_gridN - 1) do {
        _wpx = (_i/_gridN)*_mapSize;
        for "_y" from 1 to (_gridN - 1) do {
            _wpy = (_y/_gridN)*_mapSize;
            if !(surfaceIsWater [_wpx,_wpy]) then {donn_hwps = donn_hwps + [[_wpx,_wpy,0]];};
        };
    };

    _heliGroupTot  = count _heliFormation;
    
    donn_heli_HD = {
        _heliHurt = _this select 0;
        _damage   = _this select 2;

        if !(canMove _heliHurt) then {
            if (_heliHurt getVariable "dncmv") then {
                _heliHurt setVariable ["dncmv",false,false];
                { 
                    _x action ["Eject",_heliHurt]; 
                } forEach crew _heliHurt;
            };
        };
        _damage
    };

    donn_heli_unit_HD = {
        // Put group into combat RED mode if heli damaged by player
        _hurtedOne = _this select 0;
        _damage    = _this select 2;
        _ofender   = _this select 3;
        _grp       = group _hurtedOne;

        if (combatMode _grp != "RED" && isPlayer _ofender) then {
            {_x enableAi "TARGET";} forEach units _grp;
            {_x enableAi "AUTOTARGET";} forEach units _grp;
            _grp reveal [_ofender,4];
            _grp setCombatMode "RED";_grp setBehaviour "COMBAT";
        };
        _damage
    };

    donn_heli_unitKill = {
        _unit = _this select 0;
        _player = _this select 1;
        _humanity = _player getVariable["humanity",0];  //Reads the player's current humanity count
        _gain = _unit getVariable ["humanity",50];  //Sets Humanity reward value. 50 humanity per AI kill.
        _role = assignedVehicleRole _unit;

        if ((assignedVehicleRole _unit) select 0 == "Driver") then {
            // If driver is killed eject the crew.
            _vehEject = assignedVehicle _unit;
            { 
                _x action ["Eject",_vehEject]; 
            } forEach crew _vehEject;
        };

        if ({alive _x} count units group _unit == 0) then {donn_heliGrps = donn_heliGrps - [group _unit];};
        //coins reward
        //_unit setVariable ["cashMoney",12500 + (round random 5) * 1000,true];
        //Humanity Reward - this gives - humanity for bandit player and + humanity for hero player
        if (_humanity < 0) then { _player setVariable ["humanity",(_humanity - _gain),true]; } else { _player setVariable ["humanity",(_humanity + _gain),true]; }; 
        {
            if (((position _x) distance (position _unit)) <= _aisharedistance) then {
                _x reveal [_player, 4.0];
            }
        } forEach allUnits;
    };

    donn_makeAeroRoute = {
        // Set route for convoy
        _origin     = _this select 0;
        _heli_group = _this select 1;
        _speed      = _this select 2;
        _posBefore  = _origin;
        _posNow     = _origin;
        _wp         = _heli_group addWaypoint [_posNow,0,0];
        _wp setWaypointCompletionRadius 65;
        _wp setWaypointType "MOVE";
        _wp setWaypointSpeed _speed;
        _posNext = [0,0,0];

        for "_c" from 1 to 5 do {
            _distToBefore = 0;
            _distToNext   = 0;
            _found        = false;

            for "_x" from 1 to 200 do {
                _posNext        = donn_hwps call BIS_fnc_selectRandom;
                _distToNext     = _posNow distance _posNext;
                _distToBefore   = _posNext distance _posBefore;
                if (_distToNext > 3000 && _distToBefore > 4000) exitWith {};
                uiSleep 0.001;
            };

            if (!_found) then {_posNext = donn_hwps call BIS_fnc_selectRandom;};
            _wp = _heli_group addWaypoint [_posNext,0,_c];
            _wp setWaypointCompletionRadius 65;
            _wp setWaypointType "MOVE";
            _wp setWaypointSpeed _speed;
            _posNow = _posNext;
        };

        _wp = _heli_group addWaypoint [_origin,0,6];
        _wp setWaypointCompletionRadius 65;
        _wp setWaypointType "CYCLE";
        _wp setWaypointSpeed _speed;
    };

    donn_heliGrps = [];

    [] spawn {

        while {{!isNull _x} count donn_heliGrps > 0} do {
            {
                _grp     = _x;
                _forceIn = true;
                {if (_grp knowsAbout _x >= 1.5) then {_grp reveal [_x,4];_forceIn = false;};} forEach playableUnits;
                if (_forceIn) then {
                    if (combatMode _grp != "BLUE") then {
                        {_x disableAi "TARGET";uiSleep 0.001;} forEach units _grp;
                        {_x disableAi "AUTOTARGET";uiSleep 0.001;} forEach units _grp;
                        _grp setCombatMode "BLUE";_grp setBehaviour "CARELESS";
                    };
                    {if (vehicle _x == _x) then {[_x] orderGetIn true;uiSleep 0.001;};} forEach units _grp;
                };
            } forEach donn_heliGrps;
            uiSleep 10;
        };
        diag_log "[HELI CONVOY] Finished convoy rotation.";
    };

    while {1 == 1}  do {
        _cs = floor( random _heliGroupTot);
        diag_log ("[HELI CONVOY] Initialized Spawn! " + str _cs);
        _flyheight = round(_fh_lower + random(_fh_random)); 

        _heli_group     = createGroup EAST;
        donn_heliGrps   = donn_heliGrps + [_heli_group];
        _convoy         = _heliFormation select (_cs);
        _qtd            = count _convoy;
        _helis = [];

        {_helis = _helis + [donn_heliConvy select _x];} forEach _convoy;

        for "_n" from 1 to _qtd do {
            _heli       = _helis    select (_n-1);
            _motor      = createVehicle [_heli select 0,_spawn,[],150,"FLY"];
            _motor setPosATL _spawn;
            _crew       =[];

            _motor removeAllEventHandlers "handleDamage";
            _motor addEventHandler ["handleDamage",{_this call donn_heli_HD}];
            _motor setVariable ["dncmv",true,false];
            _motor setVariable ["dnishp",true,true];
            _motor setVariable ["dnishpq",_heli select 3,true];
            _motor setFuel 1;
            _motor setVehicleLock "LOCKED";
            _motor flyInHeight _flyHeight;

            _ammos = _heli select 2;
            {_ammo = _x;for "_a" from 1 to 8 do {_motor addMagazineTurret [_ammo,[_forEachIndex]];};} forEach _ammos;
            _driverCount    = 1;
            _turreterCount  = count _ammos;
            _cargorsCount   = _heli select 1;
            _crewCount      = _driverCount + _turreterCount + _cargorsCount;
            _gunnerPos      = 0;

            for "_y" from 1 to _crewCount do {
                private "_unit","_aiweapon","_weapon","_magazine","_aipack","_aigear","_gearmagazines","_geartools","aicskill","aiskin";
                _aiweapon           = [];
                _aigear             = [];
                _aipack             = "";
                _aiskin             = "";
                _aicskill           = [];
                
                if (_y == 1) then {
                    //Skin for pilot
                    _aiskin = _aiskins      call BIS_fnc_selectRandom;
                    _unit = _heli_group createUnit [_aiskin,_spawn,[],50,"PRIVATE"];
                };

                if (_y > 1) then {
                    // Selection of skins for other crew.
                    _aiskin = _aiskins      call BIS_fnc_selectRandom;
                    _unit = _heli_group createUnit [_aiskin,_spawn,[],50,"PRIVATE"];
                };
                
                _unit removeAllEventHandlers "killed";
                _unit removeAllEventHandlers "handleDamage";
                _unit addEventHandler ["killed",{_this call donn_heli_unitKill;}];
                _unit addEventHandler ["handleDamage",{_this call donn_heli_unit_HD}];
                [_unit] joinSilent _heli_group;
                _unit setSkill 0.85;

                // remove default gear/weapons from crew man
                removeAllWeapons _unit;
                removeAllItems _unit;

                _aigear = ai_gear_random call BIS_fnc_selectRandom;
                _gearmagazines  = _aigear select 0;
                _geartools      = _aigear select 1;
                
                _aiweapon = ai_wep_random call BIS_fnc_selectRandom;
                _weapon     = _aiweapon call BIS_fnc_selectRandom;
                _magazine   = _weapon   call find_suitable_ammunition;

                _aipack = ai_packs call BIS_fnc_selectRandom; 
                
                for "_i" from 1 to 4 do {
                    _unit addMagazine _magazine;
                };
                
                _unit addweapon _weapon;
                _unit selectWeapon _weapon;
                _unit addBackpack _aipack;
                
                {
                    _unit addMagazine _x
                } count _gearmagazines;

                {
                    _unit addweapon _x
                } count _geartools;
                
                _crew set [_y-1,_unit];
            };
            
            {deleteVehicle _x;} forEach crew _motor;  // moved in order to delete any default crew immediatly before adding the new crew.

            for "_y" from 1 to _crewCount do {
                _unit = _crew select (_y-1);
                
                if (_y == 1) then {
                    //First crewman is pilot
                    _unit assignAsDriver _motor;
                    _unit moveInDriver _motor;
                    _aicskill = ai_skill_random call BIS_fnc_selectRandom;
                    {
                        _unit setSkill [(_x select 0),(_x select 1)]
                    } count _aicskill;
                };

                if (_y > 1 && _y <= 1 + _turreterCount) then {
                    // Assign a crewman to each turret.
                    _unit assignAsGunner _motor;
                    _unit moveInTurret [_motor,[_gunnerPos]];
                    _gunnerPos = _gunnerPos + 1;
                    _aicskill = ai_skill_random call BIS_fnc_selectRandom;
                    {
                        _unit setSkill [(_x select 0),(_x select 1)]
                    } count _aicskill;
                };

                if (_y > 1 + _turreterCount) then {
                    //Assign the rest of the crew as passengers
                    _unit assignAsCargo _motor;
                    _unit moveInCargo _motor;
                    _aicskill = ai_skill_random call BIS_fnc_selectRandom;
                    {
                        _unit setSkill [(_x select 0),(_x select 1)]
                    } count _aicskill;
                };
            };
            {_x disableAi "TARGET";uiSleep 0.001;} forEach units _heli_group;
            {_x disableAi "AUTOTARGET";uiSleep 0.001;} forEach units _heli_group;
            _heli_group setCombatMode "BLUE";_heli_group setBehaviour "CARELESS";
        };
        _flyspeed           = _convoyspeed call BIS_fnc_selectRandom;
        [donn_hwps call BIS_fnc_selectRandom,_heli_group,_flyspeed] call donn_makeAeroRoute;
        
        uiSleep (60*15);
    };
};