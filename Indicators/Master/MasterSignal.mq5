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

   if(g_handles.superTrend1 == INVALID_HANDLE ||
      g_handles.macd == INVALID_HANDLE ||
      g_handles.rsi == INVALID_HANDLE ||
      g_handles.alligator == INVALID_HANDLE)
   {
      Print("MasterSignal: failed to create one or more iCustom handles");
      return(INIT_FAILED);
   }

   IndicatorSetString(INDICATOR_SHORTNAME, "MasterSignal (skeleton)");
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
   if(rates_total <= 0)
      return(0);

   int bars_to_process = MathMin(rates_total, MathMax(1, LookbackBars));
   int start = ShowHistoryArrows ? bars_to_process - 1 : 0;

   if(ShowHistoryArrows)
   {
      int clear_from = (prev_calculated > 0) ? MathMin(prev_calculated, rates_total) - 1 : bars_to_process - 1;
      for(int i = clear_from; i >= 0 && i >= rates_total - bars_to_process; --i)
      {
         g_buffers.buyArrow[i] = MT5_EMPTY_VALUE;
         g_buffers.sellArrow[i] = MT5_EMPTY_VALUE;
      }
   }
   else
   {
      g_buffers.buyArrow[0] = MT5_EMPTY_VALUE;
      g_buffers.sellArrow[0] = MT5_EMPTY_VALUE;
   }

   double st1_dir[], macd_hist[], rsi_val[], alligator_dir[];
   ArraySetAsSeries(st1_dir, true);
   ArraySetAsSeries(macd_hist, true);
   ArraySetAsSeries(rsi_val, true);
   ArraySetAsSeries(alligator_dir, true);

   if(CopyBuffer(g_handles.superTrend1, 1, 0, bars_to_process, st1_dir) <= 0) return(prev_calculated);
   if(CopyBuffer(g_handles.macd, 2, 0, bars_to_process, macd_hist) <= 0) return(prev_calculated);
   if(CopyBuffer(g_handles.rsi, 0, 0, bars_to_process, rsi_val) <= 0) return(prev_calculated);
   if(CopyBuffer(g_handles.alligator, 0, 0, bars_to_process, alligator_dir) <= 0) return(prev_calculated);

   int begin = ShowHistoryArrows ? start : 0;
   int end = 0;

   for(int i = begin; i >= end; --i)
   {
      bool buy  = (st1_dir[i] == 1.0) && (macd_hist[i] > 0.0) && (rsi_val[i] > 50.0);
      bool sell = (st1_dir[i] == -1.0) && (macd_hist[i] < 0.0) && (rsi_val[i] < 50.0);

      if(buy && !sell)
      {
         g_buffers.buyArrow[i]  = low[i] - (10 * _Point);
         g_buffers.sellArrow[i] = MT5_EMPTY_VALUE;
      }
      else if(sell && !buy)
      {
         g_buffers.sellArrow[i] = high[i] + (10 * _Point);
         g_buffers.buyArrow[i]  = MT5_EMPTY_VALUE;
      }
      else
      {
         g_buffers.buyArrow[i]  = MT5_EMPTY_VALUE;
         g_buffers.sellArrow[i] = MT5_EMPTY_VALUE;
      }
   }

   return(rates_total);
}
