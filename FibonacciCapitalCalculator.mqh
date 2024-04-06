//+------------------------------------------------------------------+
//|                                          FibonacciCalculator.mqh |
//|                              Copyright 2024, Eric Trader Company |
//|                                           https://erictrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Eric Trader Company"
#property link      "https://erictrader.com"
#property version   "1.00"

#include <EricTrader\Controller\CapitalManagement\Calculators\BaseCapitalCalculator.mqh>;
#include <EricTrader\Common\DataType\ETParameter.mqh>;

class FibonacciCapitalCalculator : public BaseCapitalCalculator
{
   protected:
      double fibonacciCapitalPercentEnquiry;
      double fibonacciCapitalVolume;
      int fibonacciCapitalSLPips;
      int fibonacciCapitalTPPips;
      double pEntryPrice;
      double pSlPrice;
      double pTPPrice;
      double pOrderSize;
      double ppOrderSize;
   public:
       FibonacciCapitalCalculator(ETParameter *m_parameter);
       void Processing() override;
};

FibonacciCapitalCalculator::FibonacciCapitalCalculator(ETParameter *m_parameter) : BaseCapitalCalculator(m_parameter)
{
   bool needFibonacci = parameter.GetBool("needFibonacci"); 
   if (needFibonacci) {
      this.pEntryPrice = parameter.GetDouble("pEntryPrice");
      this.pOrderSize = parameter.GetDouble("pOrderSize");
      this.pSlPrice = parameter.GetDouble("pSlPrice");
      this.pTPPrice = parameter.GetDouble("pTPPrice");
      this.pTPPrice = parameter.GetDouble("pTPPrice");
      this.ppOrderSize = parameter.GetDouble("ppOrderSize");   
   } else {
      this.fibonacciCapitalPercentEnquiry = parameter.GetDouble("fibonacciCapitalPercentEnquiry");
      this.fibonacciCapitalVolume = parameter.GetDouble("fibonacciCapitalVolume");
      this.fibonacciCapitalSLPips = parameter.GetInteger("fibonacciCapitalSLPips");
      if (this.fibonacciCapitalSLPips <= 0) {
         this.fibonacciCapitalSLPips = parameter.GetInteger("defaultSL");
      }
      this.fibonacciCapitalTPPips = parameter.GetInteger("fibonacciCapitalTPPips");
      if (this.fibonacciCapitalTPPips <= 0) {
         this.fibonacciCapitalTPPips = parameter.GetInteger("defaultSL");
      }
      this.entryPrice = parameter.GetDouble("entryPrice");   
   }
}

void FibonacciCapitalCalculator::Processing() override
{
   bool needFibonacci = parameter.GetBool("needFibonacci");
   if (needFibonacci) {
   
      double m_slPrice = 0;
      double m_tpPrice = 0;
      // Calculate SL and TP prices
      int m_orderType = parameter.GetInteger("orderType");
      if (ETHelper::IsOrderBuy(m_orderType)) {
           m_slPrice = entryPrice - (pEntryPrice - pSlPrice);
           m_tpPrice = entryPrice + (pTPPrice - pOrderSize);
      } else if (ETHelper::IsOrderSell(m_orderType)) {
           m_slPrice = entryPrice + (pSlPrice - pEntryPrice);
           m_tpPrice = entryPrice - (pEntryPrice - pTPPrice);
      }
      // Calculate lot size
      this.volume = pOrderSize + this.ppOrderSize;
      this.slPrice = m_slPrice;
      this.tpPrice = m_tpPrice;
   } else {
      int slPips = this.StopPriceToPips(this.slPrice, this.entryPrice);
      this.volume = this.CalculateVolume( this.fibonacciCapitalVolume, this.fibonacciCapitalPercentEnquiry, slPips);
      
      if (this.fibonacciCapitalTPPips > 0) {
         this.tpPrice = this.CalculateTP(this.entryPrice, this.fibonacciCapitalTPPips);
      }
      
      if (this.fibonacciCapitalVolume > 0 && this.fibonacciCapitalSLPips) {
         this.slPrice = this.CalculateSL(this.entryPrice, this.fibonacciCapitalSLPips);
      }   
   }

}