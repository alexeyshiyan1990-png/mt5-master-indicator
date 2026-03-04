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
datetime g_lastDebugLogTime = 0;

void LogOncePerNSeconds(const string text)
{
   if(!Debug)
      return;

   datetime now = TimeCurrent();
   int everySeconds = MathMax(1, DebugLogEveryNSeconds);
   if(g_lastDebugLogTime != 0 && (now - g_lastDebugLogTime) < everySeconds)
      return;

   g_lastDebugLogTime = now;
   Print(text);
}

int CreateHandleWithDiagnostics(const string module, const string path)
{
   Print("INFO: iCustom path for ", module, " = ", path);
   ResetLastError();
   int handle = iCustom(_Symbol, _Period, path);
   if(handle == INVALID_HANDLE)
      Print("ERROR: iCustom failed for ", module, ", path=", path, ", err=", GetLastError());
   return(handle);
}

bool CopyBufferOrLog(const int handle,
                     const string module,
                     const int bufferIndex,
                     const int shift,
                     const int count,
                     double &target[])
{
   ResetLastError();
   int copied = CopyBuffer(handle, bufferIndex, shift, count, target);
   if(copied <= 0)
   {
      Print("ERROR: CopyBuffer failed ", module,
            " buffer=", bufferIndex,
            " shift=", shift,
            " err=", GetLastError());
      return(false);
   }
   return(true);
}

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

   // Paths for iCustom are relative to MQL5/Indicators.
   g_handles.superTrend1 = CreateHandleWithDiagnostics("SuperTrend", "Core\\SuperTrend");
   g_handles.macd        = CreateHandleWithDiagnostics("MACD_4Color", "Core\\MACD_4Color");
   g_handles.rsi         = CreateHandleWithDiagnostics("RSI_Filter", "Core\\RSI_Filter");
   g_handles.alligator   = CreateHandleWithDiagnostics("Alligator_Filter", "Core\\Alligator_Filter");
   g_handles.ao          = CreateHandleWithDiagnostics("AwesomeOscillator", "Core\\AwesomeOscillator");
   g_handles.adx         = CreateHandleWithDiagnostics("ADX_Filter", "Core\\ADX_Filter");

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

   if(!CopyBufferOrLog(g_handles.superTrend1, "SuperTrend", 1, 0, copy_count, st_dir)) return(prev_calculated);
   if(!CopyBufferOrLog(g_handles.macd, "MACD_4Color", 2, 0, copy_count, macd_hist)) return(prev_calculated);
   if(!CopyBufferOrLog(g_handles.macd, "MACD_4Color", 3, 0, copy_count, macd_color)) return(prev_calculated);
   if(!CopyBufferOrLog(g_handles.ao, "AwesomeOscillator", 0, 0, copy_count, ao_val)) return(prev_calculated);
   if(!CopyBufferOrLog(g_handles.ao, "AwesomeOscillator", 1, 0, copy_count, ao_color)) return(prev_calculated);
   if(!CopyBufferOrLog(g_handles.adx, "ADX_Filter", 0, 0, copy_count, adx_val)) return(prev_calculated);
   if(!CopyBufferOrLog(g_handles.adx, "ADX_Filter", 1, 0, copy_count, plus_di)) return(prev_calculated);
   if(!CopyBufferOrLog(g_handles.adx, "ADX_Filter", 2, 0, copy_count, minus_di)) return(prev_calculated);

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
      int reasonMask = EvaluateFilters(s, allowBuy, allowSell);

      LogOncePerNSeconds(StringFormat(
         "DEBUG: shift=%d time=%s st_dir=%.2f macd_hist=%.5f ao=%.5f adx=%.5f plusDI=%.5f minusDI=%.5f allowBuy=%s allowSell=%s reasonMask=%d (%s)",
         shift,
         TimeToString(time[shift], TIME_DATE | TIME_SECONDS),
         s.st_dir,
         s.macd_hist,
         s.ao,
         s.adx,
         s.plusDI,
         s.minusDI,
         allowBuy ? "true" : "false",
         allowSell ? "true" : "false",
         reasonMask,
         ExplainReasonMask(reasonMask)
      ));

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
