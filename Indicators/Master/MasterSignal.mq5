#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2

#property indicator_type1   DRAW_ARROW
#property indicator_color1  clrLime
#property indicator_width1  1
#property indicator_label1  "Buy"

#property indicator_type2   DRAW_ARROW
#property indicator_color2  clrRed
#property indicator_width2  1
#property indicator_label2  "Sell"

#include "..\..\Include\Config.mqh"
#include "..\..\Include\Handles.mqh"
#include "..\..\Include\Buffers.mqh"
#include "..\..\Include\FilterEngine.mqh"

input int  LookbackBars      = 500;
input bool ShowHistoryArrows = true;

SMasterBuffers g_buffers;
SModuleHandles g_handles;

int OnInit()
{
   SetIndexBuffer(0, g_buffers.buyArrow, INDICATOR_DATA);
   SetIndexBuffer(1, g_buffers.sellArrow, INDICATOR_DATA);

   ArraySetAsSeries(g_buffers.buyArrow, true);
   ArraySetAsSeries(g_buffers.sellArrow, true);

   PlotIndexSetInteger(0, PLOT_ARROW, 233);
   PlotIndexSetInteger(1, PLOT_ARROW, 234);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, MT5_EMPTY_VALUE);
   PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, MT5_EMPTY_VALUE);

   InitHandles(g_handles);

   g_handles.superTrend1 = iCustom(_Symbol, _Period, "Indicators\\Core\\SuperTrend");
   g_handles.macd        = iCustom(_Symbol, _Period, "Indicators\\Core\\MACD_4Color");
   g_handles.rsi         = iCustom(_Symbol, _Period, "Indicators\\Core\\RSI_Filter");
   g_handles.alligator   = iCustom(_Symbol, _Period, "Indicators\\Core\\Alligator_Filter");
   g_handles.ao          = iCustom(_Symbol, _Period, "Indicators\\Core\\AwesomeOscillator");
   g_handles.adx         = iCustom(_Symbol, _Period, "Indicators\\Core\\ADX_Filter");

   if(g_handles.superTrend1 == INVALID_HANDLE ||
      g_handles.macd == INVALID_HANDLE ||
      g_handles.rsi == INVALID_HANDLE ||
      g_handles.alligator == INVALID_HANDLE ||
      g_handles.ao == INVALID_HANDLE ||
      g_handles.adx == INVALID_HANDLE)
   {
      Print("MasterSignal: failed to create one or more iCustom handles");
      return(INIT_FAILED);
   }

   IndicatorSetString(INDICATOR_SHORTNAME, "MasterSignal (filter engine)");
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ReleaseAllHandles(g_handles);
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
   if(rates_total < 2)
      return(0);

   int bars_to_process = MathMin(MathMax(1, LookbackBars), rates_total - 1);

   for(int i = 0; i <= bars_to_process; ++i)
   {
      g_buffers.buyArrow[i] = MT5_EMPTY_VALUE;
      g_buffers.sellArrow[i] = MT5_EMPTY_VALUE;
   }

   double st_dir[], macd_hist[], macd_color[], ao_val[], ao_color[], adx_val[], plus_di[], minus_di[];
   ArraySetAsSeries(st_dir, true);
   ArraySetAsSeries(macd_hist, true);
   ArraySetAsSeries(macd_color, true);
   ArraySetAsSeries(ao_val, true);
   ArraySetAsSeries(ao_color, true);
   ArraySetAsSeries(adx_val, true);
   ArraySetAsSeries(plus_di, true);
   ArraySetAsSeries(minus_di, true);

   int copy_count = bars_to_process + 1;

   if(CopyBuffer(g_handles.superTrend1, 1, 0, copy_count, st_dir) <= 0) return(prev_calculated);
   if(CopyBuffer(g_handles.macd, 2, 0, copy_count, macd_hist) <= 0) return(prev_calculated);
   if(CopyBuffer(g_handles.macd, 3, 0, copy_count, macd_color) <= 0) return(prev_calculated);
   if(CopyBuffer(g_handles.ao, 0, 0, copy_count, ao_val) <= 0) return(prev_calculated);
   if(CopyBuffer(g_handles.ao, 1, 0, copy_count, ao_color) <= 0) return(prev_calculated);
   if(CopyBuffer(g_handles.adx, 0, 0, copy_count, adx_val) <= 0) return(prev_calculated);
   if(CopyBuffer(g_handles.adx, 1, 0, copy_count, plus_di) <= 0) return(prev_calculated);
   if(CopyBuffer(g_handles.adx, 2, 0, copy_count, minus_di) <= 0) return(prev_calculated);

   int first_shift = ShowHistoryArrows ? bars_to_process : 1;

   for(int shift = first_shift; shift >= 1; --shift)
   {
      FilterState s;
      s.st_dir = st_dir[shift];
      s.macd_hist = macd_hist[shift];
      s.macd_color = macd_color[shift];
      s.ao = ao_val[shift];
      s.ao_color = ao_color[shift];
      s.adx = adx_val[shift];
      s.plusDI = plus_di[shift];
      s.minusDI = minus_di[shift];

      bool allowBuy = false;
      bool allowSell = false;
      EvaluateFilters(s, allowBuy, allowSell);

      bool buy = allowBuy;
      bool sell = allowSell;

      if(buy && !sell)
      {
         g_buffers.buyArrow[shift]  = low[shift] - (10 * _Point);
         g_buffers.sellArrow[shift] = MT5_EMPTY_VALUE;
      }
      else if(sell && !buy)
      {
         g_buffers.sellArrow[shift] = high[shift] + (10 * _Point);
         g_buffers.buyArrow[shift]  = MT5_EMPTY_VALUE;
      }
      else
      {
         g_buffers.buyArrow[shift]  = MT5_EMPTY_VALUE;
         g_buffers.sellArrow[shift] = MT5_EMPTY_VALUE;
      }
   }

   return(rates_total);
}
