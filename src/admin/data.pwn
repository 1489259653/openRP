forward SetAdminLevel(playerid, level);
forward GetAdminLevel(playerid);
forward isPlayerRPAdmin(playerid);

public SetAdminLevel(playerid, level) {
    return Player[playerid][Admin] = level;
}

public GetAdminLevel(playerid) {
    return Player[playerid][Admin];
}

public isPlayerRPAdmin(playerid) {
    return Player[playerid][Admin] > 0 || IsPlayerAdmin(playerid);
}
