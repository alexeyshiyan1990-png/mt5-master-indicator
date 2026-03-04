#property indicator_separate_window
#property indicator_buffers 2
#property indicator_plots   1

#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  clrLime,clrRed
#property indicator_width1  2
#property indicator_label1  "AO"

/*
Контракт буферов:
- buffer0: AO value = SMA(MedianPrice,5) - SMA(MedianPrice,34)
- buffer1: color index (0 green if ao[i] > ao[i+1], else 1 red)
*/

double g_ao[];
double g_color[];

int OnInit()
{
   SetIndexBuffer(0, g_ao, INDICATOR_DATA);
   SetIndexBuffer(1, g_color, INDICATOR_COLOR_INDEX);

   ArraySetAsSeries(g_ao, true);
   ArraySetAsSeries(g_color, true);

   PlotIndexSetInteger(0, PLOT_DRAW_BEGIN, 34);
   PlotIndexSetInteger(0, PLOT_COLOR_INDEXES, 2);

   IndicatorSetString(INDICATOR_SHORTNAME, "Core::AwesomeOscillator");
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
   if(rates_total < 34)
      return(0);

   double median[];
   ArrayResize(median, rates_total);
   ArraySetAsSeries(median, true);

   for(int i = rates_total - 1; i >= 0; --i)
      median[i] = (high[i] + low[i]) * 0.5;

   int oldest = rates_total - 1;
   double sum5 = 0.0;
   double sum34 = 0.0;

   for(int i = oldest; i >= 0; --i)
   {
      sum5 += median[i];
      sum34 += median[i];

      if(i + 5 <= oldest)
         sum5 -= median[i + 5];
      if(i + 34 <= oldest)
         sum34 -= median[i + 34];

      if(i + 33 <= oldest)
         g_ao[i] = (sum5 / 5.0) - (sum34 / 34.0);
      else
         g_ao[i] = 0.0;
   }

   for(int i = rates_total - 1; i >= 0; --i)
   {
      if(i + 1 < rates_total && g_ao[i] > g_ao[i + 1])
         g_color[i] = 0.0;
      else
         g_color[i] = 1.0;
   }

   return(rates_total);
}
