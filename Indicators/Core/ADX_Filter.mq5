#property indicator_separate_window
#property indicator_buffers 3
#property indicator_plots   1

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDodgerBlue
#property indicator_width1  1
#property indicator_label1  "ADX"

/*
Контракт буферов:
- buffer0: ADX
- buffer1: +DI
- buffer2: -DI
*/

input int InpADXPeriod = 14;

double g_adx[];
double g_plusDI[];
double g_minusDI[];

int g_adxHandle = INVALID_HANDLE;

int OnInit()
{
   SetIndexBuffer(0, g_adx, INDICATOR_DATA);
   SetIndexBuffer(1, g_plusDI, INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, g_minusDI, INDICATOR_CALCULATIONS);

   ArraySetAsSeries(g_adx, true);
   ArraySetAsSeries(g_plusDI, true);
   ArraySetAsSeries(g_minusDI, true);

   g_adxHandle = iADX(_Symbol, _Period, InpADXPeriod);
   if(g_adxHandle == INVALID_HANDLE)
   {
      Print("ADX_Filter: failed to create iADX handle");
      return(INIT_FAILED);
   }

   IndicatorSetString(INDICATOR_SHORTNAME, "Core::ADX_Filter");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(g_adxHandle != INVALID_HANDLE)
   {
      IndicatorRelease(g_adxHandle);
      g_adxHandle = INVALID_HANDLE;
   }
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if(rates_total <= 0 || g_adxHandle == INVALID_HANDLE)
      return(0);

   if(CopyBuffer(g_adxHandle, 0, 0, rates_total, g_adx) <= 0)
      return(prev_calculated);
   if(CopyBuffer(g_adxHandle, 1, 0, rates_total, g_plusDI) <= 0)
      return(prev_calculated);
   if(CopyBuffer(g_adxHandle, 2, 0, rates_total, g_minusDI) <= 0)
      return(prev_calculated);

   return(rates_total);
}
