//+------------------------------------------------------------------+
//|                                            DoubleWateCapital.mqh |
//|                              Copyright 2024, Eric Trader Company |
//|                                           https://erictrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Eric Trader Company"
#property link      "https://erictrader.com"
#property version   "1.00"

#include <EricTrader\Controller\CapitalManagement\Calculators\BaseCapitalCalculator.mqh>;
#include <EricTrader\Common\DataType\ETParameter.mqh>;

class DoubleMethodCapitalCalculator : public BaseCapitalCalculator
{
   protected:
      double rrDoubleMethodCapitalRatio;
      double doubleMethodCapitalPercentEnquiry;
      int doubleMethodCapitalSLPips;
      double lossAmount;
   public:
       DoubleMethodCapitalCalculator(ETParameter *parameter);
       void Processing() override;
};

DoubleMethodCapitalCalculator::DoubleMethodCapitalCalculator(ETParameter *m_parameter) : BaseCapitalCalculator(m_parameter)
{
   this.rrDoubleMethodCapitalRatio = parameter.GetDouble("rrDoubleMethodCapitalRatio");
   this.doubleMethodCapitalPercentEnquiry = parameter.GetDouble("doubleMethodCapitalPercentEnquiry");
   this.doubleMethodCapitalSLPips = parameter.GetInteger("doubleMethodCapitalSLPips");
   if (this.doubleMethodCapitalSLPips <= 0) {
      this.doubleMethodCapitalSLPips = parameter.GetInteger("defaultSL");
   }
   this.lossAmount = parameter.GetDouble("lossAmount");
   this.useLeverage = parameter.GetInteger("useLeverage");
   this.orderType = (ENUM_ORDER_TYPE)parameter.GetInteger("orderType");
   this.entryPrice = parameter.GetDouble("entryPrice");
}


void DoubleMethodCapitalCalculator::Processing() override
{
   if (lossAmount > 0) {
      this.volume = this.CalculateVolume( 0, this.doubleMethodCapitalPercentEnquiry, this.doubleMethodCapitalSLPips) + this.CalculateVolume( 0, 100, this.doubleMethodCapitalSLPips, this.lossAmount);
   } else {
      this.volume = this.CalculateVolume( 0, this.doubleMethodCapitalPercentEnquiry, this.doubleMethodCapitalSLPips);
   }
   this.slPrice = this.CalculateSL(this.entryPrice, this.doubleMethodCapitalSLPips);
   this.tpPrice = this.CalculateTP(this.entryPrice, this.doubleMethodCapitalSLPips * this.rrDoubleMethodCapitalRatio);
}
