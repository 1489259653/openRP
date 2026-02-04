// Interior Data (ID -> Coordinates)
// Source: https://open.mp/docs/scripting/resources/interiorids

stock GetInteriorPos(interiorid, &Float:x, &Float:y, &Float:z) {
    switch(interiorid) {
        // 24/7s
        case 6: { x = -26.6916; y = -55.7149; z = 1003.5469; } // 24/7 6
        case 10: { x = 6.0912; y = -29.2719; z = 1003.5494; } // 24/7 2
        case 18: { x = -30.9467; y = -91.6434; z = 1003.5469; } // 24/7 3
        
        // Ammu-nations
        case 1: { x = 286.1490; y = -40.6444; z = 1001.5156; } // Ammu-nation 2
        case 4: { x = 285.5030; y = -82.5476; z = 1001.5156; } // Ammu-nation 3
        
        // Fast Food
        case 5: { x = 372.3520; y = -131.6510; z = 1001.4922; } // Pizza Stack
        case 9: { x = 365.6550; y = -10.9168; z = 1001.8516; } // Cluckin' Bell
        case 17: { x = 377.0880; y = -193.2570; z = 1000.6328; } // Rusty Brown's Donuts
        
        // Clothes
        case 15: { x = 207.7379; y = -109.0440; z = 1005.1328; } // Binco
        case 3: { x = 206.7145; y = -138.8320; z = 1003.0938; } // Pro-Laps
        case 14: { x = 204.3429; y = -166.6949; z = 1000.5234; } // Didier Sachs
        
        // Bars/Clubs
        case 11: { x = 501.9809; y = -69.1502; z = 998.7578; } // Bar
        case 12: { x = 493.3909; y = -22.7227; z = 1000.6797; } // Club
        
        // Default (0)
        default: { x = 0.0; y = 0.0; z = 0.0; return 0; }
    }
    return 1;
}
