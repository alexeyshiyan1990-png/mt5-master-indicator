#ifndef __MT5_MASTER_HANDLES_MQH__
#define __MT5_MASTER_HANDLES_MQH__

struct SModuleHandles
{
   int superTrend1;
   int superTrend2;
   int macd;
   int rsi;
   int alligator;
   int ao;
   int adx;
};

void InitHandles(SModuleHandles &h)
{
   h.superTrend1 = INVALID_HANDLE;
   h.superTrend2 = INVALID_HANDLE;
   h.macd        = INVALID_HANDLE;
   h.rsi         = INVALID_HANDLE;
   h.alligator   = INVALID_HANDLE;
   h.ao          = INVALID_HANDLE;
   h.adx         = INVALID_HANDLE;
}

void ReleaseHandle(int &handle)
{
   if(handle != INVALID_HANDLE)
   {
      IndicatorRelease(handle);
      handle = INVALID_HANDLE;
   }
}

void ReleaseAllHandles(SModuleHandles &h)
{
   ReleaseHandle(h.superTrend1);
   ReleaseHandle(h.superTrend2);
   ReleaseHandle(h.macd);
   ReleaseHandle(h.rsi);
   ReleaseHandle(h.alligator);
   ReleaseHandle(h.ao);
   ReleaseHandle(h.adx);
}

#endif // __MT5_MASTER_HANDLES_MQH__
