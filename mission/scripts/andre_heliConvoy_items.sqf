//Original by Donnavan
//Modified by salival for better loot control
//find_suitable_ammunition from WAI, uses the same variables (but in this file instead since these are clientside)
//Edit the variables to suit your needs, the crate will spawn behind the player.

find_suitable_ammunition = {

	private["_weapon","_result","_ammoArray"];

	_result 	= false;
	_weapon 	= _this;
	_ammoArray 	= getArray (configFile >> "cfgWeapons" >> _weapon >> "magazines");

	if (count _ammoArray > 0) then {
		_result = _ammoArray select 0;
		call {
			if(_result == "20Rnd_556x45_Stanag") 	exitWith { _result = "30Rnd_556x45_Stanag"; };
			if(_result == "30Rnd_556x45_G36") 		exitWith { _result = "30Rnd_556x45_Stanag"; };
			if(_result == "30Rnd_556x45_G36SD") 	exitWith { _result = "30Rnd_556x45_StanagSD"; };
		};
	};
	_result
};

private ["_crate_type","_crate","_num_weapons","_weapon","_ammo"];
if (dayz_actionInProgress) exitWith {"You are already performing an action, wait for the current action to finish." call dayz_rollingMessages;};
dayz_actionInProgress = true;
//Edit the variables below to suit your needs
_crate_type 	= "USOrdnanceBox"; //this needs to be whitelisted in your battleye filters (createvehicle.txt) - you can do so by adding !="USOrdnanceBox" to a line that starts with 5. i.e 5 !="USOrdnanceBox"
_crate_items					= ["FoodMRE","ItemSodaOrangeSherbet","ItemSodaPepsi","ItemBandage","ItemSodaCoke","FoodCanBakedBeans","FoodCanPasta","ItemAntibiotic","ItemBloodbag","ItemEpinephrine","ItemHeatPack","ItemMorphine","CinderBlocks","ItemComboLock","ItemLightBulb","ItemLockbox","ItemSandbag","ItemTankTrap","ItemWire","MortarBucket","PartGeneric","PartGlass","PartPlankPack","ItemBriefcase100oz","ItemBriefcase100oz","ItemBriefcase100oz","ItemBriefcase100oz"];

_ai_wep_assault				= ["M16A4_ACG","Sa58V_RCO_EP1","SCAR_L_STD_Mk4CQT","M8_sharpshooter","M4A1_HWS_GL_camo","SCAR_L_STD_HOLO","M4A3_CCO_EP1","M4A3_CCO_EP1","M4A1_AIM_SD_camo","M16A4","m8_carbine","BAF_L85A2_RIS_Holo","Sa58V_CCO_EP1"];	// Assault
_ai_wep_machine				= ["Mk48_CCO_DZ","M249_EP1_DZ","Pecheneg_DZ","M240_DZ"];	// Light machine guns
_ai_wep_sniper				= ["M14_EP1","HUNTINGRIFLE","M4SPR","M24","M24_DES_EP1","SCAR_H_LNG_Sniper_SD","M110_NVG_EP1","SVD_CAMO","VSS_Vintorez","DMR_DZ","M40A3","KSVK_DZE","BAF_LRR_SCOPED"];	// Sniper rifles
_ai_wep_random				= _ai_wep_assault + _ai_wep_assault + _ai_wep_sniper + _ai_wep_machine;	

_motor = _this select 3;

player playActionNow "Medic";
uisleep 8;

_position = [(position player select 0) - (sin(getdir player)*2), (position player select 1) - (cos(getdir player)*2), (position player select 2)];
_dir = getDir player;

_crate 			= createVehicle [_crate_type,_position,[],0,"CAN_COLLIDE"];

_crate setVariable ["ObjectID","1",true];
_crate setVariable ["permaLoot",true];

_num_weapons	= 6;
_num_items	= 14;
_item_array	= _crate_items;

dayz_serverObjectMonitor set [count dayz_serverObjectMonitor,_crate];

clearWeaponCargoGlobal _crate;
clearMagazineCargoGlobal _crate;

if(_num_weapons > 0) then {

	_num_weapons = (ceil((_num_weapons) / 2) + floor(random (_num_weapons / 2)));

	for "_i" from 1 to _num_weapons do {
		_weapon = _ai_wep_random call BIS_fnc_selectRandom;
		_ammo = _weapon call find_suitable_ammunition;
		_crate addWeaponCargoGlobal [_weapon,1];
		_crate addMagazineCargoGlobal [_ammo, (1 + floor(random 5))];
	};
};

if(_num_items > 0) then {
	_num_items	= (ceil((_num_items) / 2) + floor(random (_num_items / 2)));
	for "_i" from 1 to _num_items do {
		_item = _item_array call BIS_fnc_selectRandom;
		if(typeName (_item) == "ARRAY") then {
			_crate addMagazineCargoGlobal [_item select 0,_item select 1];
		} else {
			_crate addMagazineCargoGlobal [_item,1];
		};
	};
};

_motor setVariable ["dnishpq",0,true];

if (alive _motor) then { systemChat "You manage to find a loot crate in the cargo hold";
} else { 
	systemChat "You manage to find a loot crate in the wreckage of the chopper"; 
};
dayz_actionInProgress = false;