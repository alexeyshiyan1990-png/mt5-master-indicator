#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1

#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMediumPurple
#property indicator_style1  STYLE_DOT
#property indicator_width1  1
#property indicator_label1  "AlligatorDir"

/*
Buffers contract:
- buffer0: direction (+1 bullish, -1 bearish)
Inputs:
- InpJawPeriod: jaw period proxy
- InpTeethPeriod: teeth period proxy
- InpLipsPeriod: lips period proxy
*/
input int InpJawPeriod   = 13;
input int InpTeethPeriod = 8;
input int InpLipsPeriod  = 5;

double g_dir[]; // buffer0

int OnInit()
{
   SetIndexBuffer(0, g_dir, INDICATOR_DATA);
   ArraySetAsSeries(g_dir, true);
   IndicatorSetString(INDICATOR_SHORTNAME, "Core::Alligator_Filter (skeleton)");
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
      g_dir[i] = (close[i] >= open[i]) ? 1.0 : -1.0;

   return(rates_total);
}
