#include <YSI\YSI_Coding\y_hooks>
#include <YSI\YSI_Visual\y_commands>
#include <YSI\YSI_Data\y_iterate>

#include "../../src/data/shops/interior_data.pwn"
#include "../../src/locales/zh-CN.pwn"

// Defines
#define DIALOG_SHOP_MENU 10001
#define DIALOG_SHOP_CONFIRM 10002

static
    gPlayerCurrentShop[MAX_PLAYERS] = {-1, ...};

// -----------------------------------------------------------------------------
// Database Loading
// -----------------------------------------------------------------------------

forward OnShopsLoaded();
public OnShopsLoaded() {
    new rows;
    cache_get_row_count(rows);
    
    for(new i = 0; i < rows; i++) {
        new id, name[32], interiorid;
        new Float:ex, Float:ey, Float:ez;
        new Float:ix, Float:iy, Float:iz;
        
        cache_get_value_name_int(i, "ID", id);
        cache_get_value_name(i, "Name", name);
        cache_get_value_name_int(i, "InteriorID", interiorid);
        
        cache_get_value_name_float(i, "EnterX", ex);
        cache_get_value_name_float(i, "EnterY", ey);
        cache_get_value_name_float(i, "EnterZ", ez);
        
        cache_get_value_name_float(i, "ExitX", ix);
        cache_get_value_name_float(i, "ExitY", iy);
        cache_get_value_name_float(i, "ExitZ", iz);
        
        // Add to memory
        new idx = Iter_Free(Shops);
        if(idx != -1) {
            gShopData[idx][shopID] = id;
            format(gShopData[idx][shopName], 32, name);
            gShopData[idx][shopInteriorID] = interiorid;
            
            gShopData[idx][shopEnterX] = ex;
            gShopData[idx][shopEnterY] = ey;
            gShopData[idx][shopEnterZ] = ez;
            
            gShopData[idx][shopExitX] = ix;
            gShopData[idx][shopExitY] = iy;
            gShopData[idx][shopExitZ] = iz;
            
            gShopData[idx][shopExists] = true;
            
            // Create Visuals
            CreateShopVisuals(idx);
            
            // Load Items
            new query[128];
            mysql_format(ConnectSQL, query, sizeof(query), "SELECT * FROM `shop_items` WHERE `ShopID` = %d", id);
            mysql_tquery(ConnectSQL, query, "OnShopItemsLoaded", "i", idx);
            
            Iter_Add(Shops, idx);
        }
    }
    printf("[Shops] Loaded %d shops.", rows);
    return 1;
}

forward OnShopItemsLoaded(shopIdx);
public OnShopItemsLoaded(shopIdx) {
    new rows;
    cache_get_row_count(rows);
    
    for(new i = 0; i < rows; i++) {
        if(i >= MAX_SHOP_ITEMS) break;
        
        cache_get_value_name_int(i, "ID", gShopItems[shopIdx][i][sItemID]);
        cache_get_value_name(i, "Name", gShopItems[shopIdx][i][sItemName]);
        cache_get_value_name_int(i, "Price", gShopItems[shopIdx][i][sItemPrice]);
        cache_get_value_name_int(i, "Value", gShopItems[shopIdx][i][sItemValue]);
        
        gShopItems[shopIdx][i][sItemShopID] = gShopData[shopIdx][shopID];
    }
    // printf("[Shops] Loaded items for shop ID %d.", gShopData[shopIdx][shopID]);
    return 1;
}

// -----------------------------------------------------------------------------
// Core Logic
// -----------------------------------------------------------------------------

CreateShopVisuals(idx) {
    // Yellow Marker (19130 is yellow cone, or 1318 white arrow. User requested yellow marker)
    // 19130 is often used for entrances in RP servers.
    gShopData[idx][shopPickupID] = CreateDynamicPickup(1318, 1, gShopData[idx][shopEnterX], gShopData[idx][shopEnterY], gShopData[idx][shopEnterZ], 0, 0);
    
    new label[128];
    format(label, sizeof(label), MSG_SHOP_ENTER_LABEL, gShopData[idx][shopName]);
    gShopData[idx][shopLabelID] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, gShopData[idx][shopEnterX], gShopData[idx][shopEnterY], gShopData[idx][shopEnterZ] + 0.5, 10.0);
}

SaveShop(idx) {
    if(!Iter_Contains(Shops, idx)) return 0;
    
    new query[512];
    mysql_format(ConnectSQL, query, sizeof(query), "UPDATE `shops` SET `Name` = '%e', `InteriorID` = %d, `EnterX` = %f, `EnterY` = %f, `EnterZ` = %f, `ExitX` = %f, `ExitY` = %f, `ExitZ` = %f WHERE `ID` = %d",
        gShopData[idx][shopName],
        gShopData[idx][shopInteriorID],
        gShopData[idx][shopEnterX],
        gShopData[idx][shopEnterY],
        gShopData[idx][shopEnterZ],
        gShopData[idx][shopExitX],
        gShopData[idx][shopExitY],
        gShopData[idx][shopExitZ],
        gShopData[idx][shopID]
    );
    mysql_tquery(ConnectSQL, query);
    return 1;
}

// -----------------------------------------------------------------------------
// Hooks
// -----------------------------------------------------------------------------

hook OnGameModeInit() {
    // Create Tables if not exist
    mysql_tquery(ConnectSQL, "CREATE TABLE IF NOT EXISTS `shops` (`ID` INT AUTO_INCREMENT PRIMARY KEY, `Name` varchar(32), `InteriorID` INT, `EnterX` FLOAT, `EnterY` FLOAT, `EnterZ` FLOAT, `ExitX` FLOAT, `ExitY` FLOAT, `ExitZ` FLOAT)");
    mysql_tquery(ConnectSQL, "CREATE TABLE IF NOT EXISTS `shop_items` (`ID` INT AUTO_INCREMENT PRIMARY KEY, `ShopID` INT, `Name` varchar(32), `Price` INT, `Value` INT, FOREIGN KEY (`ShopID`) REFERENCES `shops`(`ID`) ON DELETE CASCADE)");
    
    mysql_tquery(ConnectSQL, "SELECT * FROM `shops`", "OnShopsLoaded");
    return 1;
}

hook OnGameModeExit() {
    foreach(new i : Shops) {
        SaveShop(i);
    }
    return 1;
}

hook OnPlayerConnect(playerid) {
    gPlayerCurrentShop[playerid] = -1;
    return 1;
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys) {
    // Enter Shop (F / Enter)
    if((newkeys & t_KEY:KEY_SECONDARY_ATTACK) && !(oldkeys & t_KEY:KEY_SECONDARY_ATTACK)) {
        if(IsPlayerInAnyVehicle(playerid)) return 1;

        foreach(new i : Shops) {
            if(IsPlayerInRangeOfPoint(playerid, 2.0, gShopData[i][shopEnterX], gShopData[i][shopEnterY], gShopData[i][shopEnterZ])) {
                // Enter
                SetPlayerPos(playerid, gShopData[i][shopExitX], gShopData[i][shopExitY], gShopData[i][shopExitZ]);
                SetPlayerInterior(playerid, gShopData[i][shopInteriorID]);
                SetPlayerVirtualWorld(playerid, gShopData[i][shopID]); // Use Shop ID as VW to separate shops
                
                gPlayerCurrentShop[playerid] = i;
                SendClientMessage(playerid, -1, MSG_SHOP_WELCOME);
                return 1;
            }
            
            // Exit
            if(gPlayerCurrentShop[playerid] == i) {
                 if(IsPlayerInRangeOfPoint(playerid, 2.0, gShopData[i][shopExitX], gShopData[i][shopExitY], gShopData[i][shopExitZ])) {
                    SetPlayerPos(playerid, gShopData[i][shopEnterX], gShopData[i][shopEnterY], gShopData[i][shopEnterZ]);
                    SetPlayerInterior(playerid, 0);
                    SetPlayerVirtualWorld(playerid, 0);
                    gPlayerCurrentShop[playerid] = -1;
                    return 1;
                 }
            }
        }
    }
    
    // Open Menu (L.ALT / Walk)
    if((newkeys & t_KEY:KEY_WALK) && !(oldkeys & t_KEY:KEY_WALK)) {
        new shopIdx = gPlayerCurrentShop[playerid];
        if(shopIdx != -1) {
             ShowShopMenu(playerid, shopIdx);
        }
    }
    return 1;
}

// -----------------------------------------------------------------------------
// GUI / Menu
// -----------------------------------------------------------------------------

ShowShopMenu(playerid, shopIdx) {
    new string[1024];
    format(string, sizeof(string), MSG_SHOP_MENU_HEADER);
    
    for(new i = 0; i < MAX_SHOP_ITEMS; i++) {
        if(gShopItems[shopIdx][i][sItemID] != 0) {
            format(string, sizeof(string), "%s%s\t$%d\n", string, gShopItems[shopIdx][i][sItemName], gShopItems[shopIdx][i][sItemPrice]);
        }
    }
    
    ShowPlayerDialog(playerid, DIALOG_SHOP_MENU, DIALOG_STYLE_TABLIST_HEADERS, gShopData[shopIdx][shopName], string, MSG_SHOP_BTN_BUY, MSG_SHOP_BTN_CANCEL);
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[]) {
    if(dialogid == DIALOG_SHOP_MENU) {
        if(!response) return 1;
        
        new shopIdx = gPlayerCurrentShop[playerid];
        if(shopIdx == -1) return 1;
        
        // Find the selected item (skip empty slots logic needed if list is sparse, but here it's packed in display? No, loop above iterates 0..MAX. If sparse, listitem index won't match. 
        // Need to map listitem to actual item index.
        new count = 0;
        new selectedItemIdx = -1;
        
        for(new i = 0; i < MAX_SHOP_ITEMS; i++) {
             if(gShopItems[shopIdx][i][sItemID] != 0) {
                 if(count == listitem) {
                     selectedItemIdx = i;
                     break;
                 }
                 count++;
             }
        }
        
        if(selectedItemIdx != -1) {
            // Confirm Purchase
            new string[128];
            format(string, sizeof(string), MSG_SHOP_BUY_CONFIRM, gShopItems[shopIdx][selectedItemIdx][sItemName], gShopItems[shopIdx][selectedItemIdx][sItemPrice]);
            
            // Store item idx in PVar or similar to pass to next dialog
            SetPVarInt(playerid, "ShopItemIdx", selectedItemIdx);
            ShowPlayerDialog(playerid, DIALOG_SHOP_CONFIRM, DIALOG_STYLE_MSGBOX, MSG_SHOP_DIALOG_TITLE, string, MSG_SHOP_BTN_YES, MSG_SHOP_BTN_NO);
        }
        return 1;
    }
    
    if(dialogid == DIALOG_SHOP_CONFIRM) {
        if(response) {
            new shopIdx = gPlayerCurrentShop[playerid];
            new itemIdx = GetPVarInt(playerid, "ShopItemIdx");
            
            if(shopIdx != -1 && itemIdx != -1) {
                // Check Money (Mockup function, assume GivePlayerMoney/GetPlayerMoney works or custom var)
                if(GetPlayerMoney(playerid) >= gShopItems[shopIdx][itemIdx][sItemPrice]) {
                    GivePlayerMoney(playerid, -gShopItems[shopIdx][itemIdx][sItemPrice]);
                    
                    // Give Item Logic (Simple example: Weapon or Health)
                    // In real RP, this would add to inventory.
                    // For now, let's just give a weapon if name contains "Weapon" or just generic success.
                    SendClientMessage(playerid, 0x00FF00FF, MSG_SHOP_BUY_SUCCESS);
                    
                    // Example effect
                    if(strcmp(gShopItems[shopIdx][itemIdx][sItemName], "Health", true) == 0) {
                        SetPlayerHealth(playerid, 100.0);
                    }
                } else {
                    SendClientMessage(playerid, 0xFF0000FF, MSG_SHOP_NO_MONEY);
                }
            }
        }
        DeletePVar(playerid, "ShopItemIdx");
        return 1;
    }
    return 1;
}

// -----------------------------------------------------------------------------
// Commands
// -----------------------------------------------------------------------------

YCMD:createshop(playerid, params[], help) {
    if(help) return SendClientMessage(playerid, -1, "Creates a shop.");
    
    new interiorid, name[32];
    if(sscanf(params, "is[32]", interiorid, name)) {
        return SendClientMessage(playerid, -1, MSG_SHOP_USAGE);
    }
    
    // Get interior coordinates
    new Float:ix, Float:iy, Float:iz;
    if(!GetInteriorPos(interiorid, ix, iy, iz)) {
        return SendClientMessage(playerid, 0xFF0000FF, MSG_SHOP_INVALID_INT);
    }
    
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    // Insert into DB
    new query[512];
    mysql_format(ConnectSQL, query, sizeof(query), "INSERT INTO `shops` (`Name`, `InteriorID`, `EnterX`, `EnterY`, `EnterZ`, `ExitX`, `ExitY`, `ExitZ`) VALUES ('%e', %d, %f, %f, %f, %f, %f, %f)",
        name, interiorid, x, y, z, ix, iy, iz);
        
    mysql_tquery(ConnectSQL, query, "OnShopCreated", "d", playerid);
    return 1;
}

forward OnShopCreated(playerid);
public OnShopCreated(playerid) {
    new id = cache_insert_id();
    SendClientMessage(playerid, 0x00FF00FF, MSG_SHOP_CREATED);
    
    // Reload shops (Simplest way to sync)
    // Or just add locally. Let's add locally for speed.
    new idx = Iter_Free(Shops);
    if(idx != -1) {
        new query[128];
        mysql_format(ConnectSQL, query, sizeof(query), "SELECT * FROM `shops` WHERE `ID` = %d", id);
        mysql_tquery(ConnectSQL, query, "OnShopRowReload", "i", idx);
    }
    return 1;
}

forward OnShopRowReload(idx);
public OnShopRowReload(idx) {
    new rows;
    cache_get_row_count(rows);
    if(rows > 0) {
        new id, name[32], interiorid;
        new Float:ex, Float:ey, Float:ez;
        new Float:ix, Float:iy, Float:iz;
        
        cache_get_value_name_int(0, "ID", id);
        cache_get_value_name(0, "Name", name);
        cache_get_value_name_int(0, "InteriorID", interiorid);
        
        cache_get_value_name_float(0, "EnterX", ex);
        cache_get_value_name_float(0, "EnterY", ey);
        cache_get_value_name_float(0, "EnterZ", ez);
        
        cache_get_value_name_float(0, "ExitX", ix);
        cache_get_value_name_float(0, "ExitY", iy);
        cache_get_value_name_float(0, "ExitZ", iz);
        
        gShopData[idx][shopID] = id;
        format(gShopData[idx][shopName], 32, name);
        gShopData[idx][shopInteriorID] = interiorid;
        
        gShopData[idx][shopEnterX] = ex;
        gShopData[idx][shopEnterY] = ey;
        gShopData[idx][shopEnterZ] = ez;
        
        gShopData[idx][shopExitX] = ix;
        gShopData[idx][shopExitY] = iy;
        gShopData[idx][shopExitZ] = iz;
        
        gShopData[idx][shopExists] = true;
        
        CreateShopVisuals(idx);
        Iter_Add(Shops, idx);
        
        // Add default items for testing
        new query[256];
        mysql_format(ConnectSQL, query, sizeof(query), "INSERT INTO `shop_items` (`ShopID`, `Name`, `Price`, `Value`) VALUES (%d, 'Health', 100, 100), (%d, 'Armor', 200, 100)", id, id);
        mysql_tquery(ConnectSQL, query);
        
        // Reload items
        mysql_format(ConnectSQL, query, sizeof(query), "SELECT * FROM `shop_items` WHERE `ShopID` = %d", id);
        mysql_tquery(ConnectSQL, query, "OnShopItemsLoaded", "i", idx);
    }
    return 1;
}
