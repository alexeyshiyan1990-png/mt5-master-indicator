#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrGold
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
#property indicator_label1  "RSI"

/*
Buffers contract:
- buffer0: RSI value (0..100)
Inputs:
- InpRSIPeriod: RSI period
*/
input int InpRSIPeriod = 14;

double g_rsi[]; // buffer0

int OnInit()
{
   SetIndexBuffer(0, g_rsi, INDICATOR_DATA);
   ArraySetAsSeries(g_rsi, true);
   IndicatorSetString(INDICATOR_SHORTNAME, "Core::RSI_Filter (skeleton)");
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
      g_rsi[i] = 50.0 + MathMin(50.0, MathMax(-50.0, close[i] - open[i]));
   }

   return(rates_total);
}
