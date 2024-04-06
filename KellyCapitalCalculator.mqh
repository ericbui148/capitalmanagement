//+------------------------------------------------------------------+
//|                                              KellyCalculator.mqh |
//|                              Copyright 2024, Eric Trader Company |
//|                                           https://erictrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Eric Trader Company"
#property link      "https://erictrader.com"
#property version   "1.00"

#include <EricTrader\Controller\CapitalManagement\Calculators\BaseCapitalCalculator.mqh>;
#include <EricTrader\Controller\CapitalManagement\Calculators\KellyCapitalCalculator.mqh>;
#include <EricTrader\Common\DataType\ETParameter.mqh>;

class KellyCapitalCalculator : public BaseCapitalCalculator
{
   protected:
       double kellyRRRatio;
       double kellyWinrate;
       double kellyCapitalPercentEnquiry;
       int kellyCapitalSLPips;
   public:
       KellyCapitalCalculator(ETParameter *m_parameter);
       void Processing() override;
};

KellyCapitalCalculator::KellyCapitalCalculator(ETParameter *m_parameter) : BaseCapitalCalculator(m_parameter)
{
   this.kellyRRRatio = parameter.GetDouble("kellyCapitalRatio");
   this.kellyWinrate = parameter.GetDouble("kellyWinrate");
   this.kellyCapitalPercentEnquiry = MathAbs((kellyWinrate - (100 - kellyWinrate)/this.kellyRRRatio) * 100);
   this.entryPrice = parameter.GetDouble("entryPrice");
   this.kellyCapitalSLPips = parameter.GetInteger("kellyCapitalSLPips");
   if (this.kellyCapitalSLPips <= 0) {
      this.kellyCapitalSLPips = parameter.GetInteger("defaultSL");
   }
}


void KellyCapitalCalculator::Processing() override
{
   this.volume = this.CalculateVolume(0, this.kellyCapitalPercentEnquiry, this.kellyCapitalSLPips);
   this.slPrice = this.CalculateSL(this.entryPrice, this.kellyCapitalSLPips);
   this.tpPrice = this.CalculateTP(this.entryPrice, this.kellyRRRatio * this.kellyCapitalSLPips);
}
