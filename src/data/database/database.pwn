#define HOST    "localhost"
#define USER    "root"
#define DB      "open-rp"
#define PASS    ""

new MySQL:ConnectSQL;

#include <YSI\YSI_coding\y_hooks>

hook OnGameModeInit() {
    ConnectSQL = mysql_connect(HOST, USER, PASS, DB);

    if(mysql_errno(ConnectSQL) != 0) {
        print("[MySQL] 数据库连接失败.");
    } else {
        print("[MySQL] 数据库连接成功.");
    }
    return true;
}

hook OnGameModeExit() {
    mysql_close(ConnectSQL);
    return true;
}