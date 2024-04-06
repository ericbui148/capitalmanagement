//+------------------------------------------------------------------+
//|                                    MartingaleCapitalCalculator.mqh |
//|                              Copyright 2024, Eric Trader Company |
//|                                           https://erictrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Eric Trader Company"
#property link      "https://erictrader.com"
#property version   "1.00"

#include <EricTrader\Controller\CapitalManagement\Calculators\BaseCapitalCalculator.mqh>;
#include <EricTrader\Common\DataType\ETParameter.mqh>;

class MartingaleCapitalCalculator : public BaseCapitalCalculator
{
   protected:
      double martingaleCapitalPercentEnquiry;
      double martingaleCapitalVolume;
      int martingaleCapitalSLPips;
      int martingaleCapitalTPPips;
      double prvEntryPrice;
      double prvOrderSize;
      double prvSlPrice;
      double prvTPPrice;
      string martingaleType;
      double multiplier;
   public:
       MartingaleCapitalCalculator(ETParameter *m_parameter);
       void Processing() override;
};

MartingaleCapitalCalculator::MartingaleCapitalCalculator(ETParameter *m_parameter) : BaseCapitalCalculator(m_parameter)
{
   bool needMartingale = m_parameter.GetBool("needMartingale");
   if (needMartingale) {
      this.prvEntryPrice = m_parameter.GetDouble("prvEntryPrice");
      this.prvOrderSize = m_parameter.GetDouble("prvOrderSize");
      this.prvSlPrice = m_parameter.GetDouble("prvSlPrice");
      this.prvTPPrice = m_parameter.GetDouble("prvTPPrice");
      this.prvTPPrice = m_parameter.GetDouble("prvTPPrice");
      this.multiplier = m_parameter.GetDouble("martingaleCapitalMultiplier");
   } else {
      this.martingaleCapitalPercentEnquiry = m_parameter.GetDouble("martingaleCapitalPercentEnquiry");
      this.martingaleCapitalVolume = m_parameter.GetDouble("martingaleCapitalVolume");
      this.martingaleCapitalSLPips = m_parameter.GetInteger("martingaleCapitalSLPips");
      if (this.martingaleCapitalSLPips <= 0) {
         this.martingaleCapitalSLPips = m_parameter.GetInteger("defaultSL");
      }
      this.martingaleCapitalTPPips = m_parameter.GetInteger("martingaleCapitalTPPips");
      this.entryPrice = m_parameter.GetDouble("entryPrice");     
   }

}

void MartingaleCapitalCalculator::Processing() override
{
   bool needMartingale = this.parameter.GetBool("needMartingale");
   if (needMartingale) {
      double m_slPrice = 0;
      double m_tpPrice = 0;
      // Calculate SL and TP prices
      int m_orderType = this.parameter.GetInteger("orderType");
      if (ETHelper::IsOrderBuy(m_orderType)) {
           m_slPrice = entryPrice - (prvEntryPrice - prvSlPrice);
           m_tpPrice = entryPrice + (prvTPPrice - prvOrderSize);
      } else if (ETHelper::IsOrderSell(m_orderType)) {
           m_slPrice = entryPrice + (prvSlPrice - prvEntryPrice);
           m_tpPrice = entryPrice - (prvEntryPrice - prvTPPrice);
      }
      
      if (prvSlPrice == 0) m_slPrice = 0;
      if (prvTPPrice == 0) m_tpPrice = 0;
      
      // Calculate lot size
      this.volume = prvOrderSize * this.multiplier;
      this.slPrice = m_slPrice;
      this.tpPrice = m_tpPrice;
   } else {
      
      this.volume = this.CalculateVolume( this.martingaleCapitalVolume, this.martingaleCapitalPercentEnquiry, this.martingaleCapitalSLPips);
      this.slPrice = this.CalculateSL(this.entryPrice, this.martingaleCapitalSLPips);
      this.tpPrice = this.CalculateTP(this.entryPrice, this.martingaleCapitalTPPips);  
   }

}