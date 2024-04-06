//+------------------------------------------------------------------+
//|                                             VictorCalculator.mqh |
//|                              Copyright 2024, Eric Trader Company |
//|                                           https://erictrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Eric Trader Company"
#property link      "https://erictrader.com"
#property version   "1.00"

#include <EricTrader\Controller\CapitalManagement\Calculators\BaseCapitalCalculator.mqh>;
#include <EricTrader\Common\DataType\ETParameter.mqh>;

//+------------------------------------------------------------------+
//| VictorCapitalCalculator class                                    |
//+------------------------------------------------------------------+
class VictorCapitalCalculator : public BaseCapitalCalculator
  {
protected:
   double            victorCapitalPercentEnquiry;
   double            victorCapitalVolume;
   int               victorCapitalSLPips;
   int               victorCapitalTPPips;
   double            multiplier;
public:
                     VictorCapitalCalculator(ETParameter *m_parameter);
   void              Processing() override;
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
VictorCapitalCalculator::VictorCapitalCalculator(ETParameter *m_parameter) : BaseCapitalCalculator(m_parameter)
  {
   this.victorCapitalPercentEnquiry = parameter.GetDouble("victorCapitalPercentEnquiry");
   this.victorCapitalVolume = parameter.GetDouble("victorCapitalVolume");
   this.victorCapitalSLPips = parameter.GetInteger("victorCapitalSLPips");
   if (this.victorCapitalSLPips <= 0) {
      this.victorCapitalSLPips = parameter.GetInteger("defaultSL");
   }
   this.victorCapitalTPPips = parameter.GetInteger("victorCapitalTPPips");
   this.orderType = (ENUM_ORDER_TYPE)parameter.GetInteger("orderType");
   this.entryPrice = parameter.GetDouble("entryPrice");
   this.multiplier = parameter.GetDouble("multiplier");
  }


//+------------------------------------------------------------------+
//| Processing                                                       |
//+------------------------------------------------------------------+
void VictorCapitalCalculator::Processing() override
  {
   this.volume = this.CalculateVolume(this.victorCapitalVolume, this.victorCapitalPercentEnquiry, this.victorCapitalSLPips) * this.multiplier;
   this.slPrice = this.CalculateSL(this.entryPrice, this.victorCapitalSLPips);
   this.tpPrice = this.CalculateTP(this.entryPrice, this.victorCapitalTPPips);
  }
//+------------------------------------------------------------------+
