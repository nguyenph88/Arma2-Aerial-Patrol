# Arma2-Aerial-Patrol
Aerial (helicopters) Patrol scripts for Arma 2 Dayz

The script was originally created by Donnavan, it was improved by "Salival" and "Albertus Smythe". I just put all the pieces together and add some custom settings. 

To install:

1. Copy dayz_server/aerialPatrol from this repo to your dayz_server.

2. Copy scripts/ from "mission" folder to your actual mission folder.

3. Go to your dayz_server/system, open server_monitor.sqf

4. Find:

```
[] spawn server_spawnEvents;
```

Put this line right below it:

```
// Aerial Patrol
execVM "\z\addons\dayz_server\AerialPatrol\Airpatrol.sqf";
```

5. Go to your mission folder/dayz_code/compile/, open fn_selfActions.sqf (if you don't have this you should create one yourself)

6. Find:

```
//Repairing Vehicles
```

Put these above it:

```
_donn_cursorTarget = cursorTarget;
_objVar = _donn_cursorTarget getVariable ["dnishpq",0];

if  ((player distance _donn_cursorTarget < ((sizeOf typeOf _donn_cursorTarget)/2 + 4)) && (!isNil "_objVar") && _objVar > 0) then {
	if (s_collect_heli < 0) then {
		_heliTxt = "Search wreckage for loot";
		if (alive _donn_cursorTarget) then {_heliTxt = "Search helicopter for loot";};
		s_collect_heli = player addaction[("<t color=""#0096ff"">" + _heliTxt + "</t>"),"scripts\andre_heliConvoy_items.sqf",_donn_cursorTarget,5,false,true,"",""];
	};
} else {
	player removeAction s_collect_heli;
	s_collect_heli = -1;
};
```

6. Scroll down to the bottom and find:

```
player removeAction s_player_unlockvault;
```

Put these above it:

```
player removeAction s_collect_heli;
s_collect_heli = -1;	
```

7. Go to your mission folder/dayz_code/init/, open variables.sqf (if you don't have this you should create one yourself)

8. Find:

```
s_player_lockUnlock_crtl = -1;
```

Put this below it:

```
s_collect_heli = -1;
```
9. Repack both mission and dayz_server and upload them back to your server

