#include <YSI\YSI_coding\y_hooks>

hook OnGameModeInit() {
    // 关键：启用手动引擎和灯光控制
    // 调用后，玩家上车引擎默认是关闭的，且不会自动启动
    ManualVehicleEngineAndLights();
    return 1;
}
hook OnPlayerStateChange(playerid, newstate, oldstate) {
    if (newstate == PLAYER_STATE_DRIVER) {
        new vehicleid = GetPlayerVehicleID(playerid);
        new engine, lights, alarm, doors, bonnet, boot, objective;
        
        GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
        
        // 确保新进入车辆时引擎是关闭的（除非之前已经有人发动了它）
        if (engine != VEHICLE_PARAMS_ON) {
            SetVehicleParamsEx(vehicleid, VEHICLE_PARAMS_OFF, lights, alarm, doors, bonnet, boot, objective);
            SendClientMessage(playerid, -1, "提示：请使用 /engine 或 H + 空格 启动车辆。");
        }
    }
    return 1;
}

// 封装一个简单的引擎切换函数
stock ToggleVehicleEngine(vehicleid, bool:status) {
    new 
        engine, lights, alarm, doors, bonnet, boot, objective;
    
    // 先获取当前所有参数，防止修改引擎时覆盖了其他状态（如车门锁）
    GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
    
    // 设置新状态
    SetVehicleParamsEx(vehicleid, status, lights, alarm, doors, bonnet, boot, objective);
}
// 处理引擎命令
// /engine 
YCMD:engine(playerid, params[]) {
     new vehicleid = GetPlayerVehicleID(playerid);
        
        if (vehicleid == INVALID_VEHICLE_ID) {
            return SendClientMessage(playerid, -1, "错误：你不在车内。");
        }
        
        if (GetPlayerVehicleSeat(playerid) != 0) {
            return SendClientMessage(playerid, -1, "错误：只有驾驶员可以操作引擎。");
        }

        new engine, lights, alarm, doors, bonnet, boot, objective;
        GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);

        if (engine == VEHICLE_PARAMS_ON) {
            ToggleVehicleEngine(vehicleid, false);
            GameTextForPlayer(playerid, "~r~车辆引擎已关闭", 3000, 3);
        } else {
            ToggleVehicleEngine(vehicleid, true);
            GameTextForPlayer(playerid, "~g~车辆引擎已启动", 3000, 3);
        }
}

// 处理按键状态变化
hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    // 检查是否在车内且是驾驶员
    new vehicleid = GetPlayerVehicleID(playerid);
    if (vehicleid != INVALID_VEHICLE_ID && GetPlayerVehicleSeat(playerid) == 0) {
        // 检测 H 键（KEY_CROUCH）和空格键（KEY_HANDBRAKE）同时按下
        // 使用正确的多键检测方法，避免按键时间差异导致的检测失败
        if ((newkeys & (KEY_CROUCH | KEY_HANDBRAKE)) == (KEY_CROUCH | KEY_HANDBRAKE) && 
            (oldkeys & (KEY_CROUCH | KEY_HANDBRAKE)) != (KEY_CROUCH | KEY_HANDBRAKE)) {
            new engine, lights, alarm, doors, bonnet, boot, objective;
            GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);

            if (engine == VEHICLE_PARAMS_ON) {
                ToggleVehicleEngine(vehicleid, false);
                GameTextForPlayer(playerid, "~r~车辆引擎已关闭", 3000, 3);
            } else {
                ToggleVehicleEngine(vehicleid, true);
                GameTextForPlayer(playerid, "~g~车辆引擎已启动", 3000, 3);
            }
        }
    }
    return 1;
}
