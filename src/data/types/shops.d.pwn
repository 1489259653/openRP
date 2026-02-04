#define MAX_SHOPS 50
#define MAX_SHOP_ITEMS 20

enum E_SHOP_DATA {
    shopID,
    shopName[32],
    shopInteriorID, // The GTA SA Interior ID
    Float:shopEnterX,
    Float:shopEnterY,
    Float:shopEnterZ,
    Float:shopExitX, // Coordinates inside the interior
    Float:shopExitY,
    Float:shopExitZ,
    shopPickupID,
    Text3D:shopLabelID,
    bool:shopExists
}

enum E_SHOP_ITEM_DATA {
    sItemID,
    sItemShopID,
    sItemName[32],
    sItemPrice,
    sItemValue // e.g. Weapon ID or Health amount
}

new gShopData[MAX_SHOPS][E_SHOP_DATA];
new gShopItems[MAX_SHOPS][MAX_SHOP_ITEMS][E_SHOP_ITEM_DATA];
new Iterator:Shops<MAX_SHOPS>;
