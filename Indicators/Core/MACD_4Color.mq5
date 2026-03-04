#property indicator_chart_window
#property indicator_buffers 4
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrLime,clrGreen,clrRed,clrTomato
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_label1  "MACD4C_Hist"

/*
Buffers contract:
- buffer2: histogram value
- buffer3: color index (0..3)
Inputs:
- InpFastEMA: fast EMA period
- InpSlowEMA: slow EMA period
- InpSignalSMA: signal SMA period
*/
input int InpFastEMA   = 12;
input int InpSlowEMA   = 26;
input int InpSignalSMA = 9;

double g_buf0[]; // reserved
double g_buf1[]; // reserved
double g_hist[]; // buffer2
double g_color[]; // buffer3

int OnInit()
{
   SetIndexBuffer(0, g_buf0, INDICATOR_CALCULATIONS);
   SetIndexBuffer(1, g_buf1, INDICATOR_CALCULATIONS);
   SetIndexBuffer(2, g_hist, INDICATOR_DATA);
   SetIndexBuffer(3, g_color, INDICATOR_COLOR_INDEX);

   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, InpSlowEMA + InpSignalSMA);
   PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 4);

   ArraySetAsSeries(g_hist, true);
   ArraySetAsSeries(g_color, true);

   IndicatorSetString(INDICATOR_SHORTNAME, "Core::MACD_4Color (skeleton)");
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
      double hist = close[i] - open[i];
      g_hist[i] = hist;

      if(hist >= 0.0)
         g_color[i] = (i + 1 < rates_total && g_hist[i + 1] <= hist) ? 0.0 : 1.0;
      else
         g_color[i] = (i + 1 < rates_total && g_hist[i + 1] <= hist) ? 2.0 : 3.0;
   }

   return(rates_total);
}
