#ifndef __MT5_MASTER_FILTER_ENGINE_MQH__
#define __MT5_MASTER_FILTER_ENGINE_MQH__

#include "Config.mqh"

struct FilterState
{
   double st_dir;
   double macd_hist;
   double macd_color;
   double ao;
   double ao_color;
   double adx;
   double plusDI;
   double minusDI;
};

enum EFilterReason
{
   REASON_NONE = 0,
   REASON_ST   = 1,
   REASON_MACD = 2,
   REASON_ADX  = 4,
   REASON_AO   = 8
};

int EvaluateFilters(const FilterState &s, bool &allowBuy, bool &allowSell)
{
   allowBuy = true;
   allowSell = true;
   int reasonMask = REASON_NONE;

   if(UseST)
   {
      bool stBuy = (s.st_dir == 1.0);
      bool stSell = (s.st_dir == -1.0);
      if(!stBuy)
         allowBuy = false;
      if(!stSell)
         allowSell = false;
      if(!stBuy || !stSell)
         reasonMask |= REASON_ST;
   }

   if(UseMACD)
   {
      bool macdBuy = (s.macd_hist > 0.0);
      bool macdSell = (s.macd_hist < 0.0);

      if(MACD_UseColorFilter)
      {
         bool macdGreen = (s.macd_color == 0.0 || s.macd_color == 1.0);
         bool macdRed = (s.macd_color == 2.0 || s.macd_color == 3.0);
         macdBuy = macdBuy && macdGreen;
         macdSell = macdSell && macdRed;
      }

      if(!macdBuy)
         allowBuy = false;
      if(!macdSell)
         allowSell = false;
      if(!macdBuy || !macdSell)
         reasonMask |= REASON_MACD;
   }

   if(UseADX)
   {
      bool adxBuy = true;
      bool adxSell = true;

      if(s.adx < ADX_Min)
      {
         adxBuy = false;
         adxSell = false;
      }

      if(ADX_UseDI_Direction)
      {
         adxBuy = adxBuy && (s.plusDI > s.minusDI);
         adxSell = adxSell && (s.minusDI > s.plusDI);
      }

      if(!adxBuy)
         allowBuy = false;
      if(!adxSell)
         allowSell = false;
      if(!adxBuy || !adxSell)
         reasonMask |= REASON_ADX;
   }

   if(UseAO)
   {
      bool aoBuy = true;
      bool aoSell = true;

      if(AO_UseSignFilter)
      {
         aoBuy = aoBuy && (s.ao > 0.0);
         aoSell = aoSell && (s.ao < 0.0);
      }

      if(AO_UseColorFilter)
      {
         aoBuy = aoBuy && (s.ao_color == 0.0);
         aoSell = aoSell && (s.ao_color == 1.0);
      }

      if(!aoBuy)
         allowBuy = false;
      if(!aoSell)
         allowSell = false;
      if(!aoBuy || !aoSell)
         reasonMask |= REASON_AO;
   }

   return(reasonMask);
}

#endif // __MT5_MASTER_FILTER_ENGINE_MQH__
