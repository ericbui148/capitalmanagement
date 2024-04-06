//+------------------------------------------------------------------+
//|                                              TradeCalculator.mqh |
//|                              Copyright 2024, Eric Trader Company |
//|                                           https://erictrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Eric Trader Company"
#property link      "https://erictrader.com"
#property version   "1.00"

#include <EricTrader\Controller\CapitalManagement\Calculators\BaseCapitalCalculator.mqh>;
#include <EricTrader\Common\DataType\ETParameter.mqh>;

//+------------------------------------------------------------------+
//| RRCapitalCalculator class                                        |
//+------------------------------------------------------------------+
class RRCapitalCalculator: public BaseCapitalCalculator
  {
protected:
   double            rrRatio;
   double            rrCapitalPercentEnquiry;
   int               rrCapitalSLPips;
public:
                     RRCapitalCalculator(ETParameter *m_parameter);
   void              Processing() override;
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
RRCapitalCalculator::RRCapitalCalculator(ETParameter *m_parameter) : BaseCapitalCalculator(m_parameter)
  {
   this.rrRatio = parameter.GetDouble("rrCapitalRatio");
   this.rrCapitalPercentEnquiry = parameter.GetDouble("rrCapitalPercentEnquiry");
   this.entryPrice = parameter.GetDouble("entryPrice");
   this.rrCapitalSLPips = parameter.GetInteger("rrCapitalSLPips");
  }

//+------------------------------------------------------------------+
//| Processing                                                       |
//+------------------------------------------------------------------+
void RRCapitalCalculator::Processing() override
  {
   this.volume = this.CalculateVolume(0, this.rrCapitalPercentEnquiry, this.rrCapitalSLPips);
   this.slPrice = this.CalculateSL(this.entryPrice, this.rrCapitalSLPips);
   this.tpPrice = this.CalculateTP(this.entryPrice, this.rrRatio * this.rrCapitalSLPips);
  }
//+------------------------------------------------------------------+
