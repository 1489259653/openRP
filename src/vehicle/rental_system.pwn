#if !defined _rental_system_included
#define _rental_system_included

#include <YSI\YSI_coding\y_hooks>

// 定义对话框ID
#define DIALOG_RENTAL_CONFIRM 1000

// 定义租车信息结构体
enum RentalCarInfo {
    RentalID,
    RentalModel,
    RentalPrice,
    Float:RentalPosX,
    Float:RentalPosY,
    Float:RentalPosZ,
    Float:RentalRotate,
    RentalVehicleID
};

// 定义玩家租车信息结构体
enum PlayerRentalInfo {
    PlayerRentalVehicleID,
    PlayerRentalCarID
};

// 全局变量
new RentalCars[MAX_VEHICLES][RentalCarInfo];
new PlayerRentals[MAX_PLAYERS][PlayerRentalInfo];
new RentalCarCount = 0;
new PlayerRentalIndex[MAX_PLAYERS]; // 存储玩家当前选择的租车索引

// 加载租车信息
stock LoadRentalCars() {
    new query[100];
    mysql_format(ConnectSQL, query, sizeof(query), "SELECT * FROM `rental_cars`");
    mysql_tquery(ConnectSQL, query, "OnLoadRentalCars", "");
}

// 加载租车信息回调
forward OnLoadRentalCars();
public OnLoadRentalCars() {
    RentalCarCount = 0;
    
    for(new i = 0; i < cache_num_rows(); i++) {
        if(RentalCarCount >= MAX_VEHICLES) break;
        
         cache_get_value_int(i, "id",RentalCars[RentalCarCount][RentalID]);
        cache_get_value_int(i, "model",RentalCars[RentalCarCount][RentalModel]);   
        cache_get_value_int(i, "price",RentalCars[RentalCarCount][RentalPrice]);
         cache_get_value_float(i, "pos_x",RentalCars[RentalCarCount][RentalPosX]);
        cache_get_value_float(i, "pos_y",RentalCars[RentalCarCount][RentalPosY]);
        cache_get_value_float(i, "pos_z",RentalCars[RentalCarCount][RentalPosZ]);
        cache_get_value_float(i, "rotate",RentalCars[RentalCarCount][RentalRotate]);
        
        // 生成车辆
        new vehicleid = CreateVehicle(RentalCars[RentalCarCount][RentalModel], 
            RentalCars[RentalCarCount][RentalPosX], 
            RentalCars[RentalCarCount][RentalPosY], 
            RentalCars[RentalCarCount][RentalPosZ], 
            RentalCars[RentalCarCount][RentalRotate], 
            -1, -1, 100000);
        
        RentalCars[RentalCarCount][RentalVehicleID] = vehicleid;
        RentalCarCount++;
    }
    
    printf("[租车系统] 加载了 %d 辆租车", RentalCarCount);
}

// 检查车辆是否为租车
stock bool:IsRentalVehicle(vehicleid) {
    for(new i = 0; i < RentalCarCount; i++) {
        if(RentalCars[i][RentalVehicleID] == vehicleid) {
            return true;
        }
    }
    return false;
}

// 获取租车索引
stock GetRentalIndex(vehicleid) {
    for(new i = 0; i < RentalCarCount; i++) {
        if(RentalCars[i][RentalVehicleID] == vehicleid) {
            return i;
        }
    }
    return -1;
}

// 检查玩家是否已租车
stock bool:HasPlayerRentedCar(playerid) {
    return PlayerRentals[playerid][PlayerRentalVehicleID] != 0;
}

// 获取租车玩家
stock GetRentalVehicleOwner(vehicleid) {
    for(new i = 0; i < MAX_PLAYERS; i++) {
        if(PlayerRentals[i][PlayerRentalVehicleID] == vehicleid) {
            return i;
        }
    }
    return -1;
}

// 租车函数
stock RentCar(playerid, rentalIndex) {
    // 检查玩家是否已租车
    if(HasPlayerRentedCar(playerid)) {
        SendClientMessage(playerid, 0xFF0000AA, "[租车系统] 您已租用车辆，请先退租");
        return false;
    }
    
    // 检查车辆是否可用
    new vehicleid = RentalCars[rentalIndex][RentalVehicleID];
    if(GetRentalVehicleOwner(vehicleid) != -1) {
        // 强制玩家下车
        RemovePlayerFromVehicle(playerid);
        return false;
    }
    
    // 检查玩家金钱
    new price = RentalCars[rentalIndex][RentalPrice];
    if(GetPlayerMoney(playerid) < price) {
        SendClientMessage(playerid, 0xFF0000AA, "[租车系统] 您的金钱不足");
        return false;
    }
    
    // 扣除金钱
    GivePlayerMoney(playerid, -price);
    
    // 记录租车信息
    PlayerRentals[playerid][PlayerRentalVehicleID] = vehicleid;
    PlayerRentals[playerid][PlayerRentalCarID] = rentalIndex;
    
    SendClientMessage(playerid, 0x00FF00AA, "[租车系统] 租车成功！");
    return true;
}

// 退租函数
stock ReturnCar(playerid) {
    if(!HasPlayerRentedCar(playerid)) {
        SendClientMessage(playerid, 0xFF0000AA, "[租车系统] 您未租用车辆");
        return false;
    }
    
    new vehicleid = PlayerRentals[playerid][PlayerRentalVehicleID];
    new rentalIndex = PlayerRentals[playerid][PlayerRentalCarID];
    
    // 重置玩家租车信息
    PlayerRentals[playerid][PlayerRentalVehicleID] = 0;
    PlayerRentals[playerid][PlayerRentalCarID] = -1;
    
    // 检查车辆是否存在
    if(IsValidVehicle(vehicleid)) {
        // 移除车辆
        DestroyVehicle(vehicleid);
    }
    
    // 重新生成车辆
    new newVehicleid = CreateVehicle(RentalCars[rentalIndex][RentalModel], 
        RentalCars[rentalIndex][RentalPosX], 
        RentalCars[rentalIndex][RentalPosY], 
        RentalCars[rentalIndex][RentalPosZ], 
        RentalCars[rentalIndex][RentalRotate], 
        -1, -1, 100000);
    
    RentalCars[rentalIndex][RentalVehicleID] = newVehicleid;
    
    SendClientMessage(playerid, 0x00FF00AA, "[租车系统] 退租成功！");
    return true;
}

// 处理租车确认对话框
forward OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]);
hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    if(dialogid == DIALOG_RENTAL_CONFIRM) {
        if(response) {
            // 确认租车
            // 使用存储的租车索引
            new rentalIndex = PlayerRentalIndex[playerid];
            if(rentalIndex >= 0 && rentalIndex < RentalCarCount) {
                RentCar(playerid, rentalIndex);
            }
        }
        return true;
    }
    return 1;
}

// 处理玩家进入车辆
hook OnPlayerEnterVehicle(playerid, vehicleid, ispassenger) {
    if(!ispassenger) {
        // 检查是否为租车
        if(IsRentalVehicle(vehicleid)) {
            new rentalIndex = GetRentalIndex(vehicleid);
            
            // 检查rentalIndex是否有效
            if(rentalIndex == -1) {
                RemovePlayerFromVehicle(playerid);
                return true;
            }
            
            // 检查车辆是否已被租用
            new owner = GetRentalVehicleOwner(vehicleid);
            if(owner != -1 && owner != playerid) {
                // 强制玩家下车
                RemovePlayerFromVehicle(playerid);
                return true;
            }
            
            // 检查玩家是否已租车
            if(HasPlayerRentedCar(playerid)) {
                SendClientMessage(playerid, 0xFF0000AA, "[租车系统] 您已租用车辆，请先退租");
                RemovePlayerFromVehicle(playerid);
                return true;
            }
            
            // 存储租车索引
            PlayerRentalIndex[playerid] = rentalIndex;
            
            // 显示租车确认对话框
            new dialogText[100];
            format(dialogText, sizeof(dialogText), "车型: %d\n价格: %d\n\n确定租用此车辆吗？", 
                RentalCars[rentalIndex][RentalModel], RentalCars[rentalIndex][RentalPrice]);
            
            ShowPlayerDialog(playerid, DIALOG_RENTAL_CONFIRM, DIALOG_STYLE_MSGBOX, "租车确认", dialogText, "确定", "取消");
        }
    }
    return 1;
}

// 处理车辆死亡
hook OnVehicleDeath(vehicleid, killerid) {
    if(IsRentalVehicle(vehicleid)) {
        new owner = GetRentalVehicleOwner(vehicleid);
        if(owner != -1) {
            ReturnCar(owner);
        }
    }
    return 1;
}

// 处理玩家离开
hook OnPlayerDisconnect(playerid, reason) {
    if(HasPlayerRentedCar(playerid)) {
        ReturnCar(playerid);
    }
    return 1;
}


// 退租命令
YCMD:tuizu(playerid, params[], help) {
    if(help) {
        SendClientMessage(playerid, 0xFFFFFFAA, "[租车系统] /tuizu - 退租当前车辆");
        return 1;
    }
    
    ReturnCar(playerid);
    return 1;
}

// 设置租车命令（管理员专用）
YCMD:setrent(playerid, params[], help) {
    if(help) {
        SendClientMessage(playerid, 0xFFFFFFAA, "[租车系统] /setrent modelid price - 设置租车信息");
        return 1;
    }
    
    // 权限检查
    if(!isPlayerRPAdmin(playerid)) {
        SendClientMessage(playerid, 0xFF0000AA, "[租车系统] 权限不足，只有管理员可以使用此命令");
        return 1;
    }
    
    // 参数解析
    new modelid, price;
    if(sscanf(params, "ii", modelid, price)) {
        SendClientMessage(playerid, 0xFF0000AA, "[租车系统] 语法错误，请使用: /setrent modelid price");
        return 1;
    }
    
    // 参数验证
    if(modelid < 400 || modelid > 611) {
        SendClientMessage(playerid, 0xFF0000AA, "[租车系统] 无效的车辆模型ID");
        return 1;
    }
    
    if(price <= 0) {
        SendClientMessage(playerid, 0xFF0000AA, "[租车系统] 价格必须大于0");
        return 1;
    }
    
    // 获取管理员当前位置和朝向
    new Float:x, Float:y, Float:z, Float:angle;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);
    
    // 插入数据库
    new query[200];
    mysql_format(ConnectSQL, query, sizeof(query), "INSERT INTO `rental_cars`(`model`, `price`, `pos_x`, `pos_y`, `pos_z`, `rotate`) VALUES ('%d', '%d', '%f', '%f', '%f', '%f')", modelid, price, x, y, z, angle);
    mysql_tquery(ConnectSQL, query, "OnSetRentComplete", "i", playerid);
    
    return 1;
}

// 设置租车完成回调
forward OnSetRentComplete(playerid);
public OnSetRentComplete(playerid) {
    if(cache_affected_rows() > 0) {
        SendClientMessage(playerid, 0x00FF00AA, "[租车系统] 租车信息设置成功！");
        printf("[租车系统] 管理员 %s 设置了新的租车信息", GetPlayerNameEx(playerid));
    } else {
        SendClientMessage(playerid, 0xFF0000AA, "[租车系统] 租车信息设置失败");
    }
    return 1;
}

// 刷新租车命令（管理员专用）
YCMD:refreshrent(playerid, params[], help) {
    if(help) {
        SendClientMessage(playerid, 0xFFFFFFAA, "[租车系统] /refreshrent - 刷新租车数据");
        return 1;
    }
    
    // 权限检查
    if(!isPlayerRPAdmin(playerid)) {
        SendClientMessage(playerid, 0xFF0000AA, "[租车系统] 权限不足，只有管理员可以使用此命令");
        return 1;
    }
    
    // 清空已租车辆
    for(new i = 0; i < MAX_PLAYERS; i++) {
        if(HasPlayerRentedCar(i)) {
            ReturnCar(i);
        }
    }
    
    // 销毁所有租车
    for(new i = 0; i < RentalCarCount; i++) {
        new vehicleid = RentalCars[i][RentalVehicleID];
        if(IsValidVehicle(vehicleid)) {
            DestroyVehicle(vehicleid);
        }
    }
    
    // 重新加载租车数据
    LoadRentalCars();
    
    SendClientMessage(playerid, 0x00FF00AA, "[租车系统] 租车数据刷新成功！");
    printf("[租车系统] 管理员 %s 刷新了租车数据", GetPlayerNameEx(playerid));
    
    return 1;
}

// 初始化租车系统
hook OnGameModeInit() {
    print("[租车系统] 初始化");
    
    // 加载租车信息
    LoadRentalCars();
    
    // 初始化玩家租车信息
    for(new i = 0; i < MAX_PLAYERS; i++) {
        PlayerRentals[i][PlayerRentalVehicleID] = 0;
        PlayerRentals[i][PlayerRentalCarID] = -1;
        PlayerRentalIndex[i] = -1; // 初始化租车索引
    }
    
    return 1;
}

 // 处理玩家状态变化
hook OnPlayerStateChange(playerid, newstate, oldstate) {
    if(newstate == PLAYER_STATE_DRIVER) {
        new vehicleid = GetPlayerVehicleID(playerid);
        // 检查是否为租车
        if(IsRentalVehicle(vehicleid)) {
            // 检查玩家是否为车辆的所有者
            new owner = GetRentalVehicleOwner(vehicleid);
            if(owner != playerid) {
                // 强制玩家下车
                RemovePlayerFromVehicle(playerid);
                SendClientMessage(playerid, 0xFF0000AA, "[租车系统] 请先租用此车辆");
                return true;
            }
        }
    }
    return 1;
}

#endif // _rental_system_included