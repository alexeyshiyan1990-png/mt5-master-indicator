#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   1

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrDeepSkyBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label1  "SuperTrendLine"

/*
Buffers contract:
- buffer0: SuperTrend line (price level)
- buffer1: direction (+1 for bullish, -1 for bearish)
Inputs:
- InpATRPeriod: ATR averaging period
- InpMultiplier: ATR multiplier for band distance
*/
input int    InpATRPeriod = 10;
input double InpMultiplier = 3.0;

double g_line[]; // buffer0
double g_dir[];  // buffer1

int OnInit()
{
   SetIndexBuffer(0, g_line, INDICATOR_DATA);
   SetIndexBuffer(1, g_dir, INDICATOR_CALCULATIONS);

   ArraySetAsSeries(g_line, true);
   ArraySetAsSeries(g_dir, true);

   IndicatorSetString(INDICATOR_SHORTNAME, "Core::SuperTrend (skeleton)");
   return(INIT_SUCCEEDED);
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
   if(rates_total <= 0)
      return(0);

   int start = (prev_calculated > 0) ? prev_calculated - 1 : rates_total - 1;
   if(start < 0)
      start = 0;

   for(int i = start; i >= 0; --i)
   {
      g_line[i] = close[i];
      g_dir[i]  = (close[i] >= open[i]) ? 1.0 : -1.0;
   }

   return(rates_total);
}
