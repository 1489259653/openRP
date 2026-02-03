#include <YSI\YSI_coding\y_hooks>
#include <json>

// 全局配置变量
new Float:gSpawnX = -2240.9197;
new Float:gSpawnY = 252.0263;
new Float:gSpawnZ = 35.3203;
new Float:gSpawnAngle = 91.2125;
new gStartingMoney = 1000;

// 加载 JSON 配置
LoadConfig() {
    new Node:root;
    new error;
    
    // 尝试解析 ServerConfig.json 文件（当前目录）
    error = JSON_ParseFile("ServerConfig.json", root);
    
    // 如果解析失败，尝试相对于 gamemodes 目录的路径
    if (error) {
        error = JSON_ParseFile("../ServerConfig.json", root);
    }
    
    // 如果仍然失败，尝试绝对路径
    if (error) {
        error = JSON_ParseFile("e:\\Dev\\samp\\openRP\\ServerConfig.json", root);
    }
    
    if (error) {
        printf("[Config] 无法解析 ServerConfig.json 配置文件，使用默认值，错误: %d", error);
        return 0;
    }
    
    // 读取出生位置配置
    new Node:spawnNode;
    JSON_GetObject(root, "spawn", spawnNode);
    
    // 检查 spawnNode 是否有效
    if (JSON_NodeType(spawnNode) == JSON_NODE_NULL) {
        print("[Config] 未找到 spawn 配置，使用默认值");
    } else {
        new Float:x, Float:y, Float:z, Float:angle;
        JSON_GetFloat(spawnNode, "x", x);
        JSON_GetFloat(spawnNode, "y", y);
        JSON_GetFloat(spawnNode, "z", z);
        JSON_GetFloat(spawnNode, "angle", angle);
        
        gSpawnX = x;
        gSpawnY = y;
        gSpawnZ = z;
        gSpawnAngle = angle;
        
        printf("[Config] 已加载出生位置: %.2f, %.2f, %.2f, %.2f", gSpawnX, gSpawnY, gSpawnZ, gSpawnAngle);
    }
    
    // 读取经济配置
    new Node:economyNode;
    JSON_GetObject(root, "economy", economyNode);
    
    // 检查 economyNode 是否有效
    if (JSON_NodeType(economyNode) == JSON_NODE_NULL) {
        print("[Config] 未找到 economy 配置，使用默认值");
    } else {
        new money;
        JSON_GetInt(economyNode, "starting_money", money);
        gStartingMoney = money;
        printf("[Config] 已加载初始金钱: %d", gStartingMoney);
    }
    
    return 1;
}

// Forwards
forward checkAccount(playerid);
forward loadAccount(playerid);
forward registerAccount(playerid);
forward saveAccount(playerid);
forward ShowRegisterDialog(playerid);

public checkAccount(playerid) {
    if(cache_num_rows() > 0) {
        cache_get_value_name(0, "Password", Player[playerid][Password], 24);
        ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_PASSWORD, "登录", "请输入您的密码以进入我们的服务器。", "确认", "退出");
    } else
        ShowRegisterDialog(playerid);
}

public registerAccount(playerid) {
    new Query[90];
    Player[playerid][ID] = cache_insert_id();
    printf("[MYSQL] 玩家 %s 注册为 ID %d", GetPlayerNameEx(playerid), Player[playerid][ID]);

    mysql_format(ConnectSQL, Query, sizeof(Query), "SELECT * FROM users WHERE ID='%i'", Player[playerid][ID]);
    mysql_query(ConnectSQL,Query);

    loadAccount(playerid);
    return true;
}

public ShowRegisterDialog(playerid) {
    ShowPlayerDialog(playerid, D_REGISTER, DIALOG_STYLE_INPUT, "注册", "请输入密码以在我们的服务器上注册", "注册", "退出");
    return true;
}

public loadAccount(playerid) {
    Player[playerid][isLogged] = true;

    cache_get_value_int(0,      "ID",       Player[playerid][ID]);
    cache_get_value_int(0,      "Money",    Player[playerid][Money]);
    cache_get_value_int(0,      "Admin",    Player[playerid][Admin]);
    cache_get_value_int(0,      "Level",    Player[playerid][Level]);
	cache_get_value_int(0,      "Exp",      Player[playerid][Exp]); 
    cache_get_value_int(0,      "Skin",     Player[playerid][Skin]);
    cache_get_value_float(0,    "PosX",     Player[playerid][PosX]);
    cache_get_value_float(0,    "PosY",     Player[playerid][PosY]);
    cache_get_value_float(0,    "PosZ",     Player[playerid][PosZ]);
    cache_get_value_float(0,    "PosA",     Player[playerid][PosA]);

    SetPlayerScore(playerid,                Player[playerid][Level]);
    GivePlayerMoney(playerid,               Player[playerid][Money]);

    SetSpawnInfo(playerid, 0, Player[playerid][Skin], Player[playerid][PosX], Player[playerid][PosY], Player[playerid][PosZ], Player[playerid][PosA], 0, 0, 0, 0 ,0, 0);
    SpawnPlayer(playerid);

    return true;
} 

public saveAccount(playerid) {
    if(Player[playerid][isLogged] == false)
        return false;

    new Query[250];
    Player[playerid][Money] = GetPlayerMoney(playerid); 
    Player[playerid][Level] = GetPlayerScore(playerid);
    Player[playerid][Skin] = GetPlayerSkin(playerid);
    GetPlayerPos(playerid, Player[playerid][PosX], Player[playerid][PosY], Player[playerid][PosZ]);
    GetPlayerFacingAngle(playerid, Player[playerid][PosA]);

    mysql_format(ConnectSQL, Query, sizeof(Query), "UPDATE `users` SET \
    `Money`='%i', \
    `Admin`='%i', \
    `Level`='%i', \
    `Exp`='%i', \
    `Skin`='%i', \
    `PosX`='%f', \
    `PosY`='%f', \
    `PosZ`='%f', \
    `PosA`='%f' WHERE `ID`='%i'", 	Player[playerid][Money],
                                    Player[playerid][Admin],
										Player[playerid][Level],
										Player[playerid][Exp],
										Player[playerid][Skin],
										Player[playerid][PosX],
										Player[playerid][PosY],
										Player[playerid][PosZ],
										Player[playerid][PosA],
										Player[playerid][ID]);
    mysql_query(ConnectSQL, Query);

    printf("[MYSQL] 玩家 %s 的 ID %d 成功保存数据", GetPlayerNameEx(playerid), Player[playerid][ID]); // Apenas um debug

    return true;
}

stock clearAccount(playerid) {
    Player[playerid][ID]            = 0;
    Player[playerid][Password]      = 0;
    Player[playerid][Admin]         = 0;
    Player[playerid][Money]         = 0;
    Player[playerid][Level]         = 0;
    Player[playerid][Exp]           = 0;
    Player[playerid][Skin]          = 0;

    Player[playerid][PosX]          = 0;
    Player[playerid][PosA]          = 0;
    Player[playerid][PosY]          = 0;
    Player[playerid][PosA]          = 0;

    Player[playerid][isLogged]      = false;
}

// 配置加载标志
new bool:gConfigLoaded = false;

hook OnPlayerConnect(playerid) {
	new Query[90];
	TogglePlayerSpectating(playerid, true); // Disable "spawn" menu when start server;

	// 确保配置已加载
	if (!gConfigLoaded) {
		LoadConfig();
		gConfigLoaded = true;
	}

	mysql_format(ConnectSQL, Query, sizeof(Query), "SELECT `Password`, `ID` FROM `Users` WHERE `Name`='%e'", GetPlayerNameEx(playerid));
    mysql_tquery(ConnectSQL, Query, "checkAccount", "i", playerid);
	return true;
}

hook OnPlayerDisconnect(playerid, reason) {
	if(Player[playerid][isLogged] == true && reason >= 0) 
    {
        saveAccount(playerid);
        clearAccount(playerid);
    }
	return true;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    new Query[250];

    switch(dialogid) {
        case D_REGISTER: {
            if(!response)
                return Kick(playerid);

            if(strlen(inputtext) < 4 || strlen(inputtext) > 24) {
                SendClientMessage(playerid, 0xFF0000AA, "[服务器] 请选择4到24个字符之间的密码。");
                TogglePlayerSpectating(playerid, true);

                ShowRegisterDialog(playerid); // 显示对话框让他重新尝试。

            } else {
                TogglePlayerSpectating(playerid, false);
                mysql_format(ConnectSQL, Query, sizeof(Query), "INSERT INTO `users`(`Name`,`Password`,`PosX`,`PosY`,`PosZ`,`PosA`,`Money`) VALUES ('%e', '%e', '%f', '%f', '%f', '%f', '%d')", GetPlayerNameEx(playerid), inputtext, gSpawnX, gSpawnY, gSpawnZ, gSpawnAngle, gStartingMoney);
                mysql_tquery(ConnectSQL, Query, "registerAccount", "i", playerid);
            }
        }
        case D_LOGIN: {
            if(!response)
                return Kick(playerid);

            if(!strcmp(Player[playerid][Password], inputtext, true, 24)) {
                TogglePlayerSpectating(playerid, false);
                mysql_format(ConnectSQL, Query, sizeof(Query), "SELECT * FROM users WHERE Name='%e'", GetPlayerNameEx(playerid));
                mysql_tquery(ConnectSQL, Query, "loadAccount", "i", playerid);

                SendClientMessage(playerid, 0x80FF00AA, "[Server] Logado com sucesso.");
            } else {
                TogglePlayerSpectating(playerid, true);
                SendClientMessage(playerid, 0xFF0000AA, "[SERVER] Senha errada, tente novamente.");
                ShowPlayerDialog(playerid, D_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Digite sua senha para entrar em nosso servidor.", "Confirmar", "Sair");
            }
        }
    }
    return true;
}