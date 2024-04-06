//+------------------------------------------------------------------+
//|                                            DCADownCalculator.mqh |
//|                              Copyright 2024, Eric Trader Company |
//|                                           https://erictrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Eric Trader Company"
#property link      "https://erictrader.com"
#property version   "1.00"

#include <EricTrader\Controller\CapitalManagement\Calculators\BaseCapitalCalculator.mqh>;
#include <EricTrader\Common\DataType\ETParameter.mqh>;

//+------------------------------------------------------------------+
//| DCACapitalCalculator class                                                      |
//+------------------------------------------------------------------+
class DCACapitalCalculator : public BaseCapitalCalculator
  {
protected:
   int               dcaCapitalMethod;
   double            dcaCapitalPercentEnquiry;
   double            dcaCapitalVolume;
   int               dcaCapitalSLPips;
   int               dcaCapitalTPPips;
   double            changedAmount;
   double            lastOrderVolume;
   double            dcaCapitalMultiplier;
public:
                     DCACapitalCalculator(ETParameter *parameter);
   void              Processing() override;
  };

//+------------------------------------------------------------------+
//|  Constructor                                                     |
//+------------------------------------------------------------------+
DCACapitalCalculator::DCACapitalCalculator(ETParameter *m_parameter):BaseCapitalCalculator(m_parameter)
  {
   this.dcaCapitalMethod = this.parameter.GetInteger("dcaCapitalMethod");
   this.dcaCapitalPercentEnquiry = this.parameter.GetDouble("dcaCapitalPercentEnquiry");
   this.dcaCapitalVolume = this.parameter.GetDouble("dcaCapitalVolume");
   this.dcaCapitalSLPips = this.parameter.GetInteger("dcaCapitalSLPips");
   this.dcaCapitalTPPips = this.parameter.GetInteger("dcaCapitalTPPips");
   if (this.dcaCapitalTPPips <= 0) {
      this.dcaCapitalTPPips = this.parameter.GetInteger("defaultSL");
   }
   this.changedAmount = this.parameter.GetDouble("changedAmount");
   this.useLeverage = this.parameter.GetInteger("useLeverage");
   this.lastOrderVolume = this.parameter.GetDouble("lastOrderVolume");
   this.dcaCapitalMultiplier = this.parameter.GetDouble("dcaCapitalMultiplier");
   this.dcaCapitalMethod = parameter.GetInteger("dcaCapitalMethod");
   this.entryPrice = parameter.GetDouble("entryPrice");
  }

//+------------------------------------------------------------------+
//| Processing                                                       |
//+------------------------------------------------------------------+
void DCACapitalCalculator::Processing() override
  {
   this.slPrice = this.CalculateSL(this.entryPrice, this.dcaCapitalSLPips);
   int slPips = this.dcaCapitalSLPips;
   if(this.changedAmount > 0 && this.lastOrderVolume > 0 && this.dcaCapitalMultiplier > 0 && this.dcaCapitalMethod)
     {
      if((DCACapitalMethod)this.dcaCapitalMethod == DCA_CAPITAL_METHOD_UP)
        {
         this.volume = this.CalculateVolume(this.dcaCapitalVolume, this.dcaCapitalPercentEnquiry, slPips, this.changedAmount);
        }
      else
        {
         this.volume = this.CalculateVolume(this.dcaCapitalVolume, this.dcaCapitalPercentEnquiry, slPips, this.useBalance - this.changedAmount);
        }

      if(this.volume > this.lastOrderVolume)
        {
         this.volume = this.lastOrderVolume * this.dcaCapitalMultiplier;
        }
     }
   else
     {
      this.volume = this.CalculateVolume(this.dcaCapitalVolume, this.dcaCapitalPercentEnquiry, slPips);
     }

   if(this.dcaCapitalTPPips > 0)
     {
      this.tpPrice = this.CalculateTP(this.entryPrice, this.dcaCapitalTPPips);
     }

  }
//+------------------------------------------------------------------+
