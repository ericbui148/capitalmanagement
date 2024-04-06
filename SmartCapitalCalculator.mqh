//+------------------------------------------------------------------+
//|                                       SmartCapitalCalculator.mqh |
//|                              Copyright 2024, Eric Trader Company |
//|                                           https://erictrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Eric Trader Company"
#property link      "https://erictrader.com"
#property version   "1.00"

#include <EricTrader\Controller\CapitalManagement\Calculators\BaseCapitalCalculator.mqh>;
#include <EricTrader\Common\DataType\ETParameter.mqh>;

//+------------------------------------------------------------------+
//| SmartCapitalCalculator class                                     |
//+------------------------------------------------------------------+
class SmartCapitalCalculator : public BaseCapitalCalculator
  {
protected:
   double            smartRRCapitalRatio;
   double            smartCapitalPercentEnquiry;
   double            smartCapitalMultiplier;
   double            smartCapitalSLPips;
   int               orderType;
   double            entryPrice;
   string            symbol;
public:
                     SmartCapitalCalculator(ETParameter *parameter);
   void              Processing() override;
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SmartCapitalCalculator::SmartCapitalCalculator(ETParameter *parameter) : BaseCapitalCalculator(parameter)
  {
   this.smartRRCapitalRatio = parameter.GetDouble("smartRRCapitalRatio");
   this.smartCapitalPercentEnquiry = parameter.GetDouble("smartCapitalPercentEnquiry");
   this.smartCapitalMultiplier = parameter.GetDouble("smartCapitalMultiplier");
   this.smartCapitalSLPips = parameter.GetDouble("smartCapitalSLPips");
   this.orderType = parameter.GetInteger("orderType");
   this.entryPrice = parameter.GetDouble("entryPrice");
  }


//+------------------------------------------------------------------+
//| Processing                                                       |
//+------------------------------------------------------------------+
void SmartCapitalCalculator::Processing() override
  {
   this.volume = this.CalculateVolume( 0, this.smartCapitalPercentEnquiry, slPips) * this.smartCapitalMultiplier;
   this.slPrice = this.CalculateSL(this.entryPrice, this.smartCapitalSLPips);
   this.tpPrice = this.CalculateTP(this.entryPrice, this.smartCapitalSLPips * this.smartRRCapitalRatio);  
  }
//+------------------------------------------------------------------+
