//+------------------------------------------------------------------+
//|                                               BaseCalculator.mqh |
//|                              Copyright 2024, Eric Trader Company |
//|                                           https://erictrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Eric Trader Company"
#property link      "https://erictrader.com"
#property version   "1.00"

#include <EricTrader\Common\DataType\ETParameter.mqh>;
#include <EricTrader\Common\ETHelper.mqh>;
#include <EricTrader\Config\DataType.mqh>;
#include <EricTrader\Controller\CapitalManagement\Calculators\Functions.mqh>;
#include <Trade\SymbolInfo.mqh>;

//+------------------------------------------------------------------+
//| BaseCapitalCalculator class                                      |
//+------------------------------------------------------------------+
class BaseCapitalCalculator
  {
protected:
   ETParameter *     parameter;
   Functions  *      funcs;
   double            useBalance;
   long              useLeverage;
   double            entryPrice;
   double            volume;
   double            minimumVolume;
   double            maximumVolume;
   double            slPrice;
   double            tpPrice;
   string            symbol;
   ENUM_ORDER_TYPE   orderType;
   CSymbolInfo       mSym;
   double            CalculateVolume(double fixedVol, double percent, int stopPips);
   double            CalculateVolume(double fixedVol, double percent, int stopPips, double m_useBalance);
   double            VerifyVolume(double volume);
   double            CalculateTP(double m_entryPrice, double fixedTPPips);
   double            CalculateSL(double m_entryPrice, double fixedSLPips);
   int               StopPriceToPips(double stopPrice, double orderPrice);
   double            MoneyToPips(double moneyAmount);
   int               PipToPoint(int pips);
public:
                     BaseCapitalCalculator(ETParameter *m_parameter);
   virtual void      Processing() = 0;
   double            GetVolume();
   double            GetEntryPrice();
   double            GetSLPrice();
   double            GetTPPrice();
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
BaseCapitalCalculator::BaseCapitalCalculator(ETParameter *m_parameter)
  {
   this.parameter = m_parameter;
   this.funcs = new Functions();
   this.useLeverage = this.parameter.GetInteger("useLeverage");
   if(this.useLeverage == NULL || this.useLeverage <= 0)
     {
      this.useLeverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
     }
   this.useBalance = this.parameter.GetDouble("useBalance");
   if(this.useBalance == NULL || this.useBalance <= 0)
     {
      this.useBalance = AccountInfoDouble(ACCOUNT_BALANCE);
     }
   this.minimumVolume = this.parameter.GetDouble("minimumOrderVolume");
   this.maximumVolume = this.parameter.GetDouble("maximumOrderVolume");
   this.orderType = (ENUM_ORDER_TYPE)this.parameter.GetInteger("orderType");
   this.symbol = this.parameter.GetString("symbol");
   this.entryPrice = this.parameter.GetDouble("entryPrice");
   mSym.Name(this.symbol);
  }


//+------------------------------------------------------------------+
//| Calculate Volume                                                 |
//+------------------------------------------------------------------+
double BaseCapitalCalculator::CalculateVolume(double fixedVol, double riskPercent, int stopPips)
  {
   double tradeSize;
   if(riskPercent > 0 && stopPips > 0)
     {
      double riskMoney=riskPercent/100.0*this.useBalance;
      double pipValue = SymbolInfoDouble(this.symbol, SYMBOL_TRADE_TICK_VALUE); // Get the value of one pip for the currency pair
      double priceSL = this.entryPrice - (this.orderType == ORDER_TYPE_BUY?1:-1) * stopPips * pipValue;
      tradeSize = this.funcs.OrderCalcVolume(this.orderType, this.symbol, riskMoney, this.entryPrice, priceSL, 0);
      return VerifyVolume(tradeSize);
     }
   else
     {
      tradeSize = fixedVol;
      tradeSize = VerifyVolume(tradeSize);
      return tradeSize;
     }
  }

//+------------------------------------------------------------------+
//| Calculate Volume                                                 |
//+------------------------------------------------------------------+
double BaseCapitalCalculator::CalculateVolume(double fixedVol, double riskPercent, int stopPips, double m_useBalance)
  {
   double tradeSize;
   if(riskPercent > 0 && stopPips > 0)
     {
      double riskMoney=riskPercent/100.0*m_useBalance;
      double pipValue = SymbolInfoDouble(this.symbol, SYMBOL_TRADE_TICK_VALUE); // Get the value of one pip for the currency pair
      double priceSL = this.entryPrice - (this.orderType == ORDER_TYPE_BUY?1:-1) * stopPips * pipValue;
      tradeSize = this.funcs.OrderCalcVolume(this.orderType, this.symbol, riskMoney, this.entryPrice, priceSL, 0);
      return VerifyVolume(tradeSize);
     }
   else
     {
      tradeSize = fixedVol;
      tradeSize = VerifyVolume(tradeSize);
      return tradeSize;
     }
  }


//+------------------------------------------------------------------+
//| Verify Volume                                                    |
//+------------------------------------------------------------------+
double BaseCapitalCalculator::VerifyVolume(double m_volume)
  {
   double minVolume = SymbolInfoDouble(this.symbol,SYMBOL_VOLUME_MIN);
   double maxVolume = SymbolInfoDouble(this.symbol,SYMBOL_VOLUME_MAX);
   if(this.minimumVolume > 0 && this.minimumVolume > minVolume)
     {
      minVolume = this.minimumVolume;
     }
   if(this.maximumVolume > 0 && this.maximumVolume < maxVolume)
     {
      maxVolume = this.maximumVolume;
     }
   double stepVolume = SymbolInfoDouble(this.symbol,SYMBOL_VOLUME_STEP);

   double tradeSize;
   if(m_volume < minVolume)
      tradeSize = minVolume;
   else
      if(m_volume > maxVolume)
         tradeSize = maxVolume;
      else
         tradeSize = MathRound(m_volume / stepVolume) * stepVolume;

   if(stepVolume >= 0.1)
      tradeSize = NormalizeDouble(tradeSize, 1);
   else
      tradeSize = NormalizeDouble(tradeSize, 2);

   return(tradeSize);
  }


//+------------------------------------------------------------------+
//|  Calculate Price SL                                              |
//+------------------------------------------------------------------+
double BaseCapitalCalculator::CalculateSL(double m_entryPrice, double fixedSLPips)
  {
   double pipValue = SymbolInfoDouble(this.symbol, SYMBOL_TRADE_TICK_VALUE); // Get the value of one pip for the currency pair
   double m_slPrice = 0.0;

   if(orderType == ORDER_TYPE_BUY)
      m_slPrice = m_entryPrice - fixedSLPips * pipValue; // Calculate Stop Loss price for a buy order
   else
      if(orderType == ORDER_TYPE_SELL)
         m_slPrice = m_entryPrice + fixedSLPips * pipValue; // Calculate Stop Loss price for a sell order

   return m_slPrice; // Return the value of Stop Loss
  }

//+------------------------------------------------------------------+
//|  Calculate TP price                                              |
//+------------------------------------------------------------------+
double BaseCapitalCalculator::CalculateTP(double m_entryPrice, double fixedTPPips)
  {
   double pipValue = SymbolInfoDouble(this.symbol, SYMBOL_TRADE_TICK_VALUE); // Get the value of one pip for the currency pair
   double m_tpPrice = 0.0;

   if(orderType == ORDER_TYPE_BUY)
      m_tpPrice = m_entryPrice + fixedTPPips * pipValue; // Calculate Take Profit price for a buy order
   else
      if(orderType == ORDER_TYPE_SELL)
         m_tpPrice = m_entryPrice - fixedTPPips * pipValue; // Calculate Take Profit price for a sell order

   return m_tpPrice; // Return the Take Profit price
  }

//+------------------------------------------------------------------+
//| Stop Price To Pips                                               |
//+------------------------------------------------------------------+
int BaseCapitalCalculator::StopPriceToPips(double stopPrice, double orderPrice)
  {
   double stopDiff = MathAbs(stopPrice - orderPrice);
   double getPip = SymbolInfoDouble(this.symbol, SYMBOL_POINT);
   double priceToPip = stopDiff / getPip;
   return (int)priceToPip;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double BaseCapitalCalculator::MoneyToPips(double moneyAmount)
  {
   double symbolPoint = SymbolInfoDouble(this.symbol, SYMBOL_POINT);
   double pips = moneyAmount / symbolPoint; // Tính toán số pip
   return pips;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int BaseCapitalCalculator::PipToPoint(int pips)
  {
   if(Digits() == 2 || Digits() == 4)
      return pips;
   if(Digits() == 5 || Digits() == 3)
      return 10*pips;
   return NULL;
  }

//+------------------------------------------------------------------+
//| Get Volume                                                       |
//+------------------------------------------------------------------+
double BaseCapitalCalculator::GetVolume()
  {
   return this.volume;
  }

//+------------------------------------------------------------------+
//| Get Entry Price                                                  |
//+------------------------------------------------------------------+
double BaseCapitalCalculator::GetEntryPrice()
  {
   return this.entryPrice;
  }

//+------------------------------------------------------------------+
//| Get SL Price                                                     |
//+------------------------------------------------------------------+
double BaseCapitalCalculator::GetSLPrice()
  {
   return this.slPrice;
  }

//+------------------------------------------------------------------+
//| Get TP Price                                                     |
//+------------------------------------------------------------------+
double BaseCapitalCalculator::GetTPPrice()
  {
   return this.tpPrice;
  }
//+------------------------------------------------------------------+
