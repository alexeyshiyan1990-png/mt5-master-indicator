#ifndef __MT5_MASTER_CONFIG_MQH__
#define __MT5_MASTER_CONFIG_MQH__

// Shared constants for the modular Master indicator
#define MT5_EMPTY_VALUE EMPTY_VALUE

input bool UseST = true;

input bool UseMACD = true;
input bool MACD_UseColorFilter = false;

input bool UseAO = true;
input bool AO_UseSignFilter = true;
input bool AO_UseColorFilter = false;

input bool UseADX = true;
input double ADX_Min = 20.0;
input bool ADX_UseDI_Direction = true;

input bool Debug = true;
input int DebugLogEveryNSeconds = 10;

#endif // __MT5_MASTER_CONFIG_MQH__
