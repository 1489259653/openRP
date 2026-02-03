YCMD:v (playerid, params[]) {
    new	Float:x, Float:y, Float:z, Float:a, idx[100], veh;
    if(sscanf(params, "s[100]", idx)) return SendClientMessage(playerid, -1, "[X] 使用: /v [车辆名称]");
    if(veh > 0) {
        DestroyVehicle(veh);
    }
	GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new vehicleName = GetVehicleModelIDFromName(idx);
    if(vehicleName < 400 || vehicleName > 611) return SendClientMessage(playerid, -1, "[X] 您必须输入400到611之间的车辆名称或ID！");

    veh = CreateVehicle(vehicleName, x, y, z + 2.0, a, 3, 3, 10000, false);

    LinkVehicleToInterior(veh, GetPlayerInterior(playerid));
    PutPlayerInVehicle(playerid, veh, 0);
	return true;
}

YCMD:kick(playerid, params[], help)
{
    if(GetAdminLevel(playerid) < 1)
        return SendClientMessage(playerid, COLOR_ERROR, "* 您没有权限。");

    new targetid, reason[128];

    if(sscanf(params, "k<u>s[128]", targetid, reason))
        return SendClientMessage(playerid, COLOR_ERROR, "* /kick [玩家ID] [原因]");

    else if(playerid == targetid)
        return SendClientMessage(playerid, COLOR_ERROR, "* 您不能踢出自己。");

    Kick(targetid);
    return 1;
}

YCMD:ch(playerid, params[]) {
    if(GetAdminLevel(playerid) < 1) 
        return SendClientMessage(playerid, COLOR_ERROR, "您没有权限创建房屋。");

    new price;

    if(sscanf(params, "i", price)) 
        return SendClientMessage(playerid, COLOR_ERROR, "使用: /ch [价格]");

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    createHouse(playerid, 0, 0, 3, price, x, y, z);
    return true;
}

YCMD:c(playerid, params[]) {
    if(GetAdminLevel(playerid) < 1)
        return SendClientMessage(playerid, COLOR_ERROR, "* 您没有权限使用此命令。");

    new modelid;
    if(sscanf(params, "i", modelid))
        return SendClientMessage(playerid, COLOR_ERROR, "* 使用: /c [模型ID]");

    if(modelid < 400 || modelid > 611)
        return SendClientMessage(playerid, COLOR_ERROR, "* 车辆模型ID必须在400到611之间！");

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new veh = CreateVehicle(modelid, x, y, z + 2.0, a, 3, 3, 10000, false);
    LinkVehicleToInterior(veh, GetPlayerInterior(playerid));
    PutPlayerInVehicle(playerid, veh, 0);
    return true;
}

YCMD:tp(playerid, params[]) {
    if(GetAdminLevel(playerid) < 1)
        return SendClientMessage(playerid, COLOR_ERROR, "* 您没有权限使用此命令。");

    new Float:x, Float:y, Float:z;
    if(sscanf(params, "fff", x, y, z))
        return SendClientMessage(playerid, COLOR_ERROR, "* 使用: /tp [X] [Y] [Z]");

    SetPlayerPos(playerid, x, y, z);
    SendClientMessage(playerid, -1, "* 已传送到指定位置。");
    return true;
}

YCMD:coords(playerid, params[]) {
    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new coordsText[128];
    format(coordsText, sizeof(coordsText), "* 当前坐标: X: %.2f, Y: %.2f, Z: %.2f, 朝向: %.2f", x, y, z, a);
    SendClientMessage(playerid, -1, coordsText);
    return true;
}

// 初始化函数，解决编译错误
public InitCommands() {
    return true;
}