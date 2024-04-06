//+------------------------------------------------------------------+
//|                                       FixedCapitalCalculator.mqh |
//|                              Copyright 2024, Eric Trader Company |
//|                                           https://erictrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Eric Trader Company"
#property link      "https://erictrader.com"
#property version   "1.00"
#include <EricTrader\Controller\CapitalManagement\Calculators\BaseCapitalCalculator.mqh>;
#include <EricTrader\Common\DataType\ETParameter.mqh>;

class FixedCapitalCalculator : public BaseCapitalCalculator
{
   protected:
      double fixedCapitalPercentEnquiry;
      double fixedCapitalVolume;
      int fixedCapitalSLPips;
      int fixedCapitalTPPips;
   public:
       FixedCapitalCalculator(ETParameter *m_parameter);
       void Processing() override;
};

FixedCapitalCalculator::FixedCapitalCalculator(ETParameter *m_parameter) : BaseCapitalCalculator(m_parameter)
{
   this.fixedCapitalPercentEnquiry = m_parameter.GetDouble("fixedCapitalPercentEnquiry");
   this.fixedCapitalVolume = m_parameter.GetDouble("fixedCapitalVolume");
   this.fixedCapitalSLPips = m_parameter.GetInteger("fixedCapitalSLPips");
   if (this.fixedCapitalSLPips <= 0) {
      this.fixedCapitalSLPips = m_parameter.GetInteger("defaultSL");
   }
   this.fixedCapitalTPPips = m_parameter.GetInteger("fixedCapitalTPPips");
   this.entryPrice = m_parameter.GetDouble("entryPrice");
}


void FixedCapitalCalculator::Processing() override
{
   this.volume = this.CalculateVolume( this.fixedCapitalVolume, this.fixedCapitalPercentEnquiry, this.fixedCapitalSLPips);
   this.slPrice = this.CalculateSL(this.entryPrice, this.fixedCapitalSLPips);
   this.tpPrice = this.CalculateTP(this.entryPrice, this.fixedCapitalTPPips);
   
}