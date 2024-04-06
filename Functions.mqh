//+------------------------------------------------------------------+
//|                                                    Functions.mqh |
//|                              Copyright 2024, Eric Trader Company |
//|                                           https://erictrader.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Eric Trader Company"
#property link      "https://erictrader.com"
#property version   "1.00"
class Functions
  {
protected:
   double            SafeDiv(double a, double b);
   int               GetDigits(const double value);
   double            mPointValue(string pSymbol = NULL, bool isProfit = true);
   double            mTickValue(string pSymbol = NULL, bool isProfit = true);
public:
   double            TradeValue(const string symbol, const double volume);
   double            CalculateTickValue(const string pSymbol, bool isProfit = true);
   double            GetExchangeRate(string CCY1, string CCY2, ENUM_ORDER_TYPE OrderType);
   string            GetSymbolByCurrencies(string base_currency, string profit_currency);
   bool              CheckMarketWatch(string symbol);
   double            OrderCalcVolume(ENUM_ORDER_TYPE ordertype, string symbol, double risk_money, double price_open, double price_sl, double commission_lot = 0.0);
   double            CorrectVolume(string symbol,double volume,double price,ENUM_ORDER_TYPE ordertype);
   double            AccountFreeMarginCheck(ENUM_ORDER_TYPE ordertype, string symbol, double volume, double price);
   double            OrderCalcSwap(ENUM_ORDER_TYPE ordertype, string symbol, double volume);
   int               SymbolLeverage(const string symbol);
   int               Leverage(const string symbol);
   double            TradeNotionalValue(const string symbol, const double volume);
   string            FormatDouble(const double value, const int digits, const string separator=",");
  };
//+------------------------------------------------------------------+
//| Calculate point value for a profitable or losing position.       |
//| (profit/loss per lot per point in account currency).             |
//+------------------------------------------------------------------+
double Functions::mPointValue(string pSymbol = NULL, bool isProfit = true)
  {
   if(pSymbol == NULL)
      pSymbol = _Symbol;

   double PointSize = SymbolInfoDouble(pSymbol, SYMBOL_POINT);
   double TickSize  = SymbolInfoDouble(pSymbol, SYMBOL_TRADE_TICK_SIZE);
   double PointValue= SafeDiv(PointSize, TickSize) * mTickValue(pSymbol, isProfit); // fix for non-forex symbols

   return PointValue;
  }
//+------------------------------------------------------------------+
//| Calculate tick value for a profitable or losing position.        |
//| (profit/loss per lot per tick in account currency).              |
//+------------------------------------------------------------------+
double Functions::mTickValue(string pSymbol = NULL, bool isProfit = true)
  {
   if(pSymbol == NULL)
      pSymbol = _Symbol;

//--- fix for non-forex symbols (metals) on some brokers.
   long CalcMode = SymbolInfoInteger(pSymbol, SYMBOL_TRADE_CALC_MODE);
   if((CalcMode == SYMBOL_CALC_MODE_CFD) || (CalcMode == SYMBOL_CALC_MODE_CFDINDEX) || (CalcMode == SYMBOL_CALC_MODE_CFDLEVERAGE))
     {
      return CalculateTickValue(pSymbol, isProfit);
     }

   return SymbolInfoDouble(pSymbol, isProfit
                           ? SYMBOL_TRADE_TICK_VALUE_PROFIT
                           : SYMBOL_TRADE_TICK_VALUE_LOSS);
  }
//+------------------------------------------------------------------+
//| TV = ContractSize * TickSize * (Profit/Account) Exchange Rate.   |
//+------------------------------------------------------------------+
double Functions::CalculateTickValue(const string pSymbol, bool isProfit = true)
  {
//--- calculate profit/loss per lot per tick, in symbol's profit currency.
   double ContractSize = SymbolInfoDouble(pSymbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double TickSize = SymbolInfoDouble(pSymbol, SYMBOL_TRADE_TICK_SIZE);
   double TickValue = ContractSize * TickSize;

//--- converting into account currency.
   const string AccountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
   const string ProfitCurrency = SymbolInfoString(pSymbol, SYMBOL_CURRENCY_PROFIT);
   if(AccountCurrency != ProfitCurrency)
     {
      //--- multiply by the profit/account exchange rate.
      TickValue *= GetExchangeRate(ProfitCurrency, AccountCurrency, (ENUM_ORDER_TYPE)isProfit);
     }
//---
   return TickValue;
  }
//+------------------------------------------------------------------+
//| Returns the exchange rate for the "CCY1/CCY2" currency pair.     |
//+------------------------------------------------------------------+
double Functions::GetExchangeRate(string CCY1, string CCY2, ENUM_ORDER_TYPE OrderType)
  {
   string symbol = NULL;
//---
   if(CCY1 != CCY2)
     {
      //--- Try direct quote
      symbol = GetSymbolByCurrencies(CCY1, CCY2);
      if(symbol != NULL)
        {
         if(OrderType == ORDER_TYPE_SELL)
            //--- Using Sell price for direct quote.
            return SymbolInfoDouble(symbol, SYMBOL_BID);
         else
            //--- Using Buy price for direct quote.
            return SymbolInfoDouble(symbol, SYMBOL_ASK);
        }
      //--- Try reverse quote
      symbol = GetSymbolByCurrencies(CCY2, CCY1);
      if(symbol != NULL)
        {
         if(OrderType == ORDER_TYPE_SELL)
            //--- Using Buy price for reverse quote.
            return SafeDiv(1, SymbolInfoDouble(symbol, SYMBOL_ASK));
         else
            //--- Using Sell price for reverse quote.
            return SafeDiv(1, SymbolInfoDouble(symbol, SYMBOL_BID));
        }
      //--- Get the cross rate through US dollar, but only if it's not USD it is trying to find the rate for.
      if((CCY1 != "USD") && (CCY2 != "USD"))
        {
         return GetExchangeRate(CCY1, "USD", OrderType) * GetExchangeRate("USD", CCY2, OrderType);
        }
     }
//---
   return (1.0);
  }
//+------------------------------------------------------------------+
//| Returns a currency pair with the specified base/profit currency. |
//+------------------------------------------------------------------+
string Functions::GetSymbolByCurrencies(string base_currency, string profit_currency)
  {
   string symbol = NULL;
   static string CurrencyPairsList[];
//---
   bool is_custom = false;
   if(SymbolExist(base_currency + profit_currency, is_custom))
     {
      symbol = base_currency + profit_currency;
     }
//--- the symbol name is inverted or it may have a prefix/suffix.
   else
     {
      //--- cache all currency pairs to speed up further search.
      int CacheSize = ArraySize(CurrencyPairsList);
      if(!CacheSize)
        {
         int n = SymbolsTotal(false);
         for(int i = 0; i < n; i++)
           {
            string symbolname = SymbolName(i, false);
            long CalcMode = SymbolInfoInteger(symbolname, SYMBOL_TRADE_CALC_MODE);
            if((CalcMode == SYMBOL_CALC_MODE_FOREX) || (CalcMode == SYMBOL_CALC_MODE_FOREX_NO_LEVERAGE))
              {
               //--- add symbol to the cache.
               ArrayResize(CurrencyPairsList, CacheSize + 1, 128);
               CurrencyPairsList[CacheSize++] = symbolname;
              }
           }
        }
      //--- cycle through all currency pairs.
      for(int i = 0; i < CacheSize; i++)
        {
         string symbolname = CurrencyPairsList[i];
         string b_cur = SymbolInfoString(symbolname, SYMBOL_CURRENCY_BASE);
         string p_cur = SymbolInfoString(symbolname, SYMBOL_CURRENCY_PROFIT);
         if((b_cur == base_currency) && (p_cur == profit_currency))
           {
            symbol = symbolname;
            break;
           }
        }
     }
//--- if the fully qualified name is found.
   if(symbol != NULL)
     {
      //--- add symbol to the MarketWatch, if necessary.
      if(!CheckMarketWatch(symbol))
        {
         //--- if symbol cannot be added in the market watch
         return(NULL);
        }
     }
//---
   return (symbol);
  }
//+------------------------------------------------------------------+
//| Checks if symbol is selected in the MarketWatch                  |
//| and adds symbol to the MarketWatch, if necessary                 |
//+------------------------------------------------------------------+
bool Functions::CheckMarketWatch(string symbol)
  {
   ResetLastError();
//--- check if symbol is selected in the MarketWatch
   if(!SymbolInfoInteger(symbol,SYMBOL_SELECT))
     {
      if(GetLastError()==ERR_MARKET_UNKNOWN_SYMBOL)
        {
         printf(__FUNCTION__+": Unknown symbol '%s'",symbol);
         return(false);
        }
      if(!SymbolSelect(symbol,true))
        {
         printf(__FUNCTION__+": Error adding symbol %d",GetLastError());
         return(false);
        }
      printf(__FUNCTION__+": Symbol '%s' is added in the MarketWatch.",symbol);
     }
//--- succeed
   return(true);
  }
//+------------------------------------------------------------------+
//| Calculate the appropriate volume for the trade operation planned.|
//|                                                                  |
//| ordertype      : ORDER_TYPE_BUY or ORDER_TYPE_SELL only.         |
//| symbol         : Symbol name                                     |
//| risk_money     : Loss money when SL is hit, in account currency. |
//| price_open     : Open price                                      |
//| price_sl       : Close price                                     |
//| commission_lot : Comm. per lot per side, in account currency.    |
//+------------------------------------------------------------------+
double Functions::OrderCalcVolume(ENUM_ORDER_TYPE ordertype, string symbol, double risk_money, double price_open, double price_sl, double commission_lot = 0.0)
  {
   /**
    * Calculation using TICK_VALUE is less accurate:
    *    double TickSize  = SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
    *  //double TickValue = SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
    *    double TickValue = mTickValue(symbol,(bool)ordertype);
    *    double sl_ticks  = MathRound((ordertype == ORDER_TYPE_BUY ? price_open - price_sl : price_sl - price_open) / TickSize);
    *    double volume    = risk_money/(sl_ticks*TickValue+2*commission_lot);
    *
    * Instead, OrderCalcProfit() function is used here to:
    *    (1) apply the correct profit calculation method depending on SYMBOL_TRADE_CALC_MODE,
    *    (2) adjust the tick_value to future rate (SL) if the base currency == account currency.
    */
   double volume=0;
   double profit=0;
   double maxvol=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
//---
   if(OrderCalcProfit(ordertype,symbol,maxvol,price_open,price_sl,profit) && profit < 0)
     {
      volume=risk_money/(MathAbs(profit/maxvol)+2*commission_lot);

      volume=CorrectVolume(symbol,volume,price_open,ordertype);
     }
//---
   return volume;
  }
//+------------------------------------------------------------------+
//|  Correct the volume of market order                              |
//+------------------------------------------------------------------+
double Functions::CorrectVolume(string symbol,double volume,double price,ENUM_ORDER_TYPE ordertype)
  {
//--- Adjust volume to broker limits.
   double minvol=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   if(volume<minvol)
     {
      volume=0.0; // not taking this trade
     }
   double maxvol=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   if(volume>maxvol)
     {
      volume=maxvol;
     }
   double stepvol=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
   volume=MathRound(volume/stepvol)*stepvol;

//--- Adjust volume to account free margin (considering opposite open positions on the symbol).
   while(AccountFreeMarginCheck(ordertype,symbol,volume,price) < 0)
     {
      //--- normalize and check limits
      volume=MathFloor(volume/stepvol-1)*stepvol;
      //---
      if(volume<minvol)
         volume=0.0;
     }
//---
   return volume;
  }
//+------------------------------------------------------------------+
//| Returns free margin that remains after the specified order has   |
//| been opened at the current price on the current account.         |
//| If the free margin is insufficient, the function returns -1.     |
//| If parameters are filled out incorrectly, it returns 0.          |
//+------------------------------------------------------------------+
double Functions::AccountFreeMarginCheck(ENUM_ORDER_TYPE ordertype, string symbol, double volume, double price)
  {
//--- Display an alert if Algo Trading is disabled.
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && !MQLInfoInteger(MQL_TESTER))
     {
      Alert("Algo Trading must be enabled to check the free margin.");
     }
   MqlTradeRequest     request;    // request structure
   MqlTradeCheckResult result;     // result structure
//--- clean
   ZeroMemory(request);
   ZeroMemory(result);
//--- setting request
   request.action=TRADE_ACTION_DEAL;
   request.symbol=symbol;
   request.volume=volume;
   request.type  =ordertype;
   request.price =price;
   request.type_filling=(bool)(SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE) & SYMBOL_FILLING_FOK) ? ORDER_FILLING_FOK : ORDER_FILLING_IOC;
//--- action and return the result
   if(OrderCheck(request, result))
      return(result.margin_free);
   else
      if(result.retcode==TRADE_RETCODE_NO_MONEY)
         return(-1);
      //--- wrong parameters
      else
         return(0);
  }
//+------------------------------------------------------------------+
//| Calculate the swap value per one holding day.                    |
//+------------------------------------------------------------------+
double Functions::OrderCalcSwap(ENUM_ORDER_TYPE ordertype, string symbol, double volume)
  {
   double swap = 0.0;
//---
   ENUM_SYMBOL_SWAP_MODE swap_mode = (ENUM_SYMBOL_SWAP_MODE)SymbolInfoInteger(symbol, SYMBOL_SWAP_MODE);
   switch(swap_mode)
     {
      // no swaps
      case SYMBOL_SWAP_MODE_DISABLED:
         swap = 0;
         break;

      // in points
      case SYMBOL_SWAP_MODE_POINTS:
        {
         double PointValue_long = mPointValue(symbol, (SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG) > 0));
         double PointValue_short = mPointValue(symbol, (SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT) > 0));

         if(ordertype == ORDER_TYPE_BUY)
            swap = volume * SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG) * PointValue_long;
         if(ordertype == ORDER_TYPE_SELL)
            swap = volume * SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT) * PointValue_short;
        }
      break;

      // in money, in client deposit currency
      case SYMBOL_SWAP_MODE_CURRENCY_DEPOSIT:
        {
         if(ordertype == ORDER_TYPE_BUY)
            swap = volume * SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG);
         if(ordertype == ORDER_TYPE_SELL)
            swap = volume * SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT);
        }
      break;

      // in money, in base or margin currency of the symbol
      case SYMBOL_SWAP_MODE_CURRENCY_SYMBOL:
      case SYMBOL_SWAP_MODE_CURRENCY_MARGIN:
        {
         if(ordertype == ORDER_TYPE_BUY)
            swap = volume * SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG);
         if(ordertype == ORDER_TYPE_SELL)
            swap = volume * SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT);

         string base_or_margin_currency;
         if(swap_mode == SYMBOL_SWAP_MODE_CURRENCY_SYMBOL)
           {
            base_or_margin_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
           }
         else
           {
            base_or_margin_currency = SymbolInfoString(symbol, SYMBOL_CURRENCY_MARGIN);
           }

         string account_currency = AccountInfoString(ACCOUNT_CURRENCY);
         //--- converting into deposit currency.
         if(base_or_margin_currency != account_currency)
           {
            swap *= GetExchangeRate(base_or_margin_currency, account_currency, ordertype);
           }
        }
      break;

      // as annual interest, using the current or open price
      case SYMBOL_SWAP_MODE_INTEREST_CURRENT:
      case SYMBOL_SWAP_MODE_INTEREST_OPEN:
        {
         double tradeValue=TradeNotionalValue(symbol,volume);

         if(ordertype == ORDER_TYPE_BUY)
            swap = tradeValue * SymbolInfoDouble(symbol, SYMBOL_SWAP_LONG) / 100 / 360;
         if(ordertype == ORDER_TYPE_SELL)
            swap = tradeValue * SymbolInfoDouble(symbol, SYMBOL_SWAP_SHORT) / 100 / 360;
        }
      break;

      // not implemented.
      case SYMBOL_SWAP_MODE_REOPEN_CURRENT:
      case SYMBOL_SWAP_MODE_REOPEN_BID:
         swap = 0;
         break;

      default:
         break;
     }
//---
   return (swap);
  }
//+------------------------------------------------------------------+
//| Calculates the symbol's dynamic leverage.                        |
//+------------------------------------------------------------------+
/**
 * Leverage = notional value / required margin
 */
int Functions::SymbolLeverage(const string symbol)
  {
   int leverage=-1;
   double margin=0.0;
   double volume=SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double tradeValue=TradeNotionalValue(symbol,volume);
   if(OrderCalcMargin(ORDER_TYPE_BUY,symbol,volume,SymbolInfoDouble(symbol,SYMBOL_ASK),margin) && margin > 0.1)
     {
      leverage=(int)MathRound(tradeValue/margin);
     }
   return leverage;
  }
//+------------------------------------------------------------------+
//| Calculates the symbol's dynamic leverage (another way).          |
//+------------------------------------------------------------------+
/**
 * Leverage = % change in account / % change in price
 */
int Functions::Leverage(const string symbol)
  {
   int leverage=-1;
   double margin=0.0;
   double profit=0;
   double volume=SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double ask=SymbolInfoDouble(symbol, SYMBOL_ASK);
   if(OrderCalcMargin(ORDER_TYPE_BUY,symbol,volume,ask,margin) && margin > 0.01)
      if(OrderCalcProfit(ORDER_TYPE_BUY,symbol,volume,ask,ask*1.001,profit))
         leverage=(int)MathRound(profit / 0.001 / margin);
   return leverage;
  }
//+------------------------------------------------------------------+
//| Calculates the trade's notional value, in account currency.      |
//+------------------------------------------------------------------+
/**
 * Notional value = unit price * no. of units * profit/account exchange rate.
 */
double Functions::TradeNotionalValue(const string symbol, const double volume)
  {
   const double ContractSize = SymbolInfoDouble(symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   const string BaseCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_BASE);
   const string ProfitCurrency = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
   const string AccountCurrency = AccountInfoString(ACCOUNT_CURRENCY);
//--- Some brokers have wrong configuration of the base currency.
// const double CrossRate = GetExchangeRate(BaseCurrency, AccountCurrency, ORDER_TYPE_BUY);
   const double CrossRate = SymbolInfoDouble(symbol, SYMBOL_ASK) * GetExchangeRate(ProfitCurrency, AccountCurrency, ORDER_TYPE_BUY);  // base/prof * prof/acc = base/acc
   const double TradeValue = volume * ContractSize * CrossRate;
   return TradeValue;
  }
//+------------------------------------------------------------------+
//| Calculates the trade's notional value, in account currency.      |
//+------------------------------------------------------------------+
/**
 * Notional value = unit price * no. of units * profit/account exchange rate.
 *                = unit price * lots * ContractSize * profit/account exchange rate * (TickSize / TickSize)
 * Notional value = unit price * lots * TickValue / TickSize
 */
double Functions::TradeValue(const string symbol, const double volume)
  {
   const double TickSize=SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   const double TickValue=mTickValue(symbol,false); // fix for non-forex symbols
   const double Price=SymbolInfoDouble(symbol, SYMBOL_ASK);
   const double TradeValue = volume * Price * TickValue / TickSize;
   return TradeValue;
  }
//+------------------------------------------------------------------+
//| Formats double with thousands separator and specified decimals.  |
//+------------------------------------------------------------------+
string Functions::FormatDouble(const double value, const int digits, const string separator=",")
  {
//--- Convert double to string
   string str_value = DoubleToString(NormalizeDouble(value, digits), digits); // FormatDouble(1.005, 2) => "1.01"

//--- Find "." position.
   int pos = StringFind(str_value, ".");
   string integer = str_value;
   string decimal = "";
   if(pos > -1)
     {
      integer = StringSubstr(str_value, 0, pos);
      decimal = StringSubstr(str_value, pos);
     }
   string formatted = "";
   string comma = "";

   while(StringLen(integer) > 3)
     {
      int length = StringLen(integer);
      string group = StringSubstr(integer, length - 3);
      formatted = group + comma + formatted;
      comma = separator;
      integer = StringSubstr(integer, 0, length - 3);
     }

   if(integer == "-")
      comma = "";
   if(integer != "")
      formatted = integer + comma + formatted;

   return (formatted + decimal);
  }
//+------------------------------------------------------------------+
//| Avoids zero divide error that forces the mql program to stop.    |
//+------------------------------------------------------------------+
double Functions::SafeDiv(double a, double b)
  {
//--- force double division.
   return (b != 0) ? a / b : 0;
  }
//+------------------------------------------------------------------+
//| Get number of decimal digits after the decimal point.            |
//+------------------------------------------------------------------+
int Functions::GetDigits(const double value)
  {
   int d = 0;
   for(double p = 1; value != MathRound(value * p) / p; p *= 10)
      d++;
   return d;
  }
//+------------------------------------------------------------------+
