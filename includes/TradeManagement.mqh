//+------------------------------------------------------------------+
//|                                              TradeManagement.mqh |
//|                                Copyright 2017, David Kierznowski |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, David Kierznowski"
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
bool cBuyPriceWithEma(double argOpen,double argClose,double argHigh,double argLow,double argEmaFast,double argEmaSlow)
  {
   double t_ma5=iMA(NULL,PERIOD_CURRENT,argEmaFast,0,MODE_EMA,PRICE_CLOSE,2);
//if(isPriceAboveEma(argClose,argEmaFast) && (argClose>argOpen) && (argEmaFast>argEmaSlow) && (argOpen<argEmaFast) && (Close[2]<t_ma5) && (argLow>Low[2]))
   return(isPriceWithEma(argHigh, argLow, argEmaFast));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cSellPriceWithEma(double argOpen,double argClose,double argHigh,double argLow,double argEmaFast,double argEmaSlow)
  {
   double t_ma5=iMA(NULL,PERIOD_CURRENT,argEmaFast,0,MODE_EMA,PRICE_CLOSE,2);
//if(isPriceBelowEma(argClose,argEmaFast) && (argClose<argOpen) && (argEmaFast<argEmaSlow) && (argOpen>argEmaFast) && (Close[2]>t_ma5) && (argHigh<High[2]))
   return(isPriceWithEma(argHigh, argLow, argEmaFast));
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void tpFixedTakeProfit(string argMagicNumber,double argTakeProfit,double argOpenPrice,int argTicket,int argSignal,int argSlippage)
  {
   if(TotalOrderCount(Symbol(),argMagicNumber)>0)
     {
      double locTakeProfit;

      if(OrderSelect(argTicket,SELECT_BY_TICKET)==0)
        {
         AtomicError("tpFixedTakeProfit() OrderSelect");
        }

      switch(argSignal)
        {
         case 0: // No Trade
            break;
         case 1: // buy takeprofit
            if(argTakeProfit>0)
              {
               locTakeProfit=CalcBuyTakeProfit(Symbol(),argTakeProfit,argOpenPrice);
               if(Bid>locTakeProfit)
                  if(CloseBuyOrder(Symbol(),argTicket,argSlippage)==False)
                     AtomicError("tpFixedTakeProfit() CloseBuyOrder");
              }
            break;
         case 2: // sell takeprofit
            if(TakeProfit>0)
              {
               locTakeProfit=CalcSellTakeProfit(Symbol(),argTakeProfit,argOpenPrice);
               if(Bid<locTakeProfit)
                  if(CloseSellOrder(Symbol(),argTicket,argSlippage)==False)
                     AtomicError("tpFixedTakeProfit() CloseSellOrder");
              }
            break;
         default:
            Print("switch(Signal)");
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void tpTrailing20(string argMagicNumber,int argSignal,datetime argTimeStamp,int argSlippage)
  {
   if(argTimeStamp!=Time[0])
     {
      argTimeStamp=Time[0];
      if(TotalOrderCount(Symbol(),argMagicNumber)>0)
        {
         int locIndex;
         double locTakeProfit;

         switch(Signal)
           {
            case 0: // No Trade
               break;
            case 1: // buy takeprofit
               locIndex=iLowest(NULL,0,MODE_LOW,20,2);
               locTakeProfit=iLow(NULL,0,locIndex);
               //Print("Buy Close price is currently " + locTakeProfit + " at index " + locIndex);
               if(Bid<locTakeProfit)
                  if(CloseAllBuyOrders(Symbol(),argMagicNumber,argSlippage)==False)
                     AtomicError("tpTrailing20() CloseBuyOrder");
               break;
            case 2: // sell takeprofit
               locIndex=iHighest(NULL,0,MODE_HIGH,20,2);
               locTakeProfit=iHigh(NULL,0,locIndex);
               //Print("Sell Close price is currently " + locTakeProfit + " at index " + tpIndex);
               if(Bid>locTakeProfit)
                  if(CloseAllSellOrders(Symbol(),argMagicNumber,argSlippage)==False)
                     AtomicError("tpTrailing20() CloseSellOrder");
               break;
            default:
               Print("switch(Signal)");
           }
        }
     }
  }
//+------------------------------------------------------------------+
/*
  Uses the babypips Cowabunga system exit, 1 to 1 or trailing 50/00 exits.
*/
void tpCowabungaTakeProfit(string argMagicNumber,double argOpenPrice,double &argTakeProfitPrice,int argTicket,int argSignal,int argSlippage)
  {

   if(TotalOrderCount(Symbol(),argMagicNumber)>0)
     {
      double locFirstTarget;
      argOpenPrice=argOpenPrice/UsePoint;

      if(tpTmp==0)
        {
         switch(argSignal)
           {
            case 0:
               break;
            case 1:
               locFirstTarget=MathRound(argOpenPrice/100)*100; // 13300 (entry 13305)
               locFirstTarget=locFirstTarget*UsePoint;
               argOpenPrice=argOpenPrice*UsePoint;


               Print("locFirstTarget rounded "+locFirstTarget); // 13300
               Print("argTakeProfitPrice "+argTakeProfitPrice); // 13340
               Print("OpenPrice "+argOpenPrice);

               if(locFirstTarget<argOpenPrice)
                  locFirstTarget=locFirstTarget+(50*UsePoint); // 13350

               if(locFirstTarget<argTakeProfitPrice) // Won't match
                  locFirstTarget=argTakeProfitPrice; // 13340

               Print("locFirstTarget after "+locFirstTarget); // 13350
               tpTmp=locFirstTarget;
               break;
            case 2:
               locFirstTarget=MathRound(argOpenPrice/100)*100; // 13300 (entry 13305)
               locFirstTarget=locFirstTarget*UsePoint;
               argOpenPrice=argOpenPrice*UsePoint;

               Print("locFirstTarget rounded "+locFirstTarget); // 13300
               Print("argTakeProfitPrice "+argTakeProfitPrice); // 13280
               Print("OpenPrice "+argOpenPrice);

               if(locFirstTarget>argOpenPrice)
                  locFirstTarget=locFirstTarget-(50*UsePoint); // 13250

               if(locFirstTarget>argTakeProfitPrice) // Won't match
                  locFirstTarget=argTakeProfitPrice; // 13280

               Print("locFirstTarget after "+locFirstTarget); // 13250
               tpTmp=locFirstTarget;
               break;
            default:
               Print("tpCowabungaTakeProfit() switch(Signal)");
           }
        }
      else
        {
         switch(argSignal)
           {
            case 0:
               break;
            case 1:
               if(Bid>tpTmp)
                 {
                  if(CloseBuyOrder(Symbol(),argTicket,argSlippage)==False)
                     AtomicError("tpCowabungaTakeProfit() CloseBuyOrder");
                 }
               break;
            case 2:
               if(Bid<tpTmp)
                 {
                  if(CloseSellOrder(Symbol(),argTicket,argSlippage)==False)
                     AtomicError("tpCowabungaTakeProfit() CloseSellOrder");
                 }
               break;
            default:
               Print("tpCowabungaTakeProfit() switch(Signal)");
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void tpDynTakeProfit(string argMagicNumber,double argOpenPrice,double argDynTakeProfit,int argTicket,int argSignal,int argSlippage)
  {
   if(TotalOrderCount(Symbol(),argMagicNumber)>0)
     {
      double locTakeProfit;
      double iAtr=iATR(Symbol(),PERIOD_CURRENT,20,1);
      argDynTakeProfit=argDynTakeProfit*(iAtr/UsePoint);
      //Print("iAtr " + iAtr);
      //Print("argDynTakeProfit " + argDynTakeProfit);

      if(OrderSelect(argTicket,SELECT_BY_TICKET)==0)
        {
         AtomicError("tpFixedTakeProfit() OrderSelect");
        }

      switch(argSignal)
        {
         case 0: // No Trade
            break;
         case 1: // buy takeprofit

            if(argDynTakeProfit>0)
              {
               //Print("argDynTakeProfit "+argDynTakeProfit);
               locTakeProfit=CalcBuyTakeProfit(Symbol(),argDynTakeProfit,argOpenPrice);
               if(Bid>locTakeProfit)
                  if(CloseBuyOrder(Symbol(),argTicket,argSlippage)==False)
                     AtomicError("tpDynTakeProfit() CloseBuyOrder");
              }
            break;
         case 2: // sell takeprofit
            if(argDynTakeProfit>0)
              {
               //Print("argDynTakeProfit "+argDynTakeProfit);
               locTakeProfit=CalcSellTakeProfit(Symbol(),argDynTakeProfit,argOpenPrice);
               if(Bid<locTakeProfit)
                  if(CloseSellOrder(Symbol(),argTicket,argSlippage)==False)
                     AtomicError("tpDynTakeProfit() CloseSellOrder");
              }
            break;
         default:
            Print("switch(Signal)");
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void tpSmartTakeProfit(string argMagicNumber,int argTicket,int argSignal,int argSlippage)
  {
   if(TotalOrderCount(Symbol(),argMagicNumber)>0)
     {
      int locHighest;
      double locTakeProfit;
      double locAtr;

      if(OrderSelect(argTicket,SELECT_BY_TICKET)==0)
        {
         AtomicError("tpSmartTakeProfit() OrderSelect");
        }

      switch(argSignal)
        {
         case 0: // No Trade
            break;
         case 1: // buy takeprofit
            //Print("tpTmp "+tpTmp);
            if(tpTmp>0)
              {
               locTakeProfit=tpTmp;
              }
            else
              {
               locHighest=iHighest(Symbol(),PERIOD_CURRENT,MODE_CLOSE,20,1);
               locTakeProfit=iHigh(Symbol(),PERIOD_CURRENT,locHighest);
               locAtr=iATR(Symbol(),PERIOD_CURRENT,20,1);
               locAtr=Bid+locAtr;
               if(Bid<locTakeProfit)
                  locTakeProfit=locAtr;
               tpTmp=locTakeProfit;
              }
            if(Bid>=locTakeProfit)
              {
               if(CloseBuyOrder(Symbol(),argTicket,argSlippage)==False)
                  AtomicError("tpSmartTakeProfit() CloseBuyOrder");
              }
            break;
         case 2: // sell takeprofit
            //Print("tpTmp "+tpTmp);
            if(tpTmp>0)
              {
               locTakeProfit=tpTmp;
              }
            else
              {
               locHighest=iLowest(Symbol(),PERIOD_CURRENT,MODE_CLOSE,20,1);
               locTakeProfit=iLow(Symbol(),PERIOD_CURRENT,locHighest);
               locAtr=iATR(Symbol(),PERIOD_CURRENT,20,1);
               locAtr=Bid-locAtr;
               if(Bid>locTakeProfit)
                  locTakeProfit=locAtr;
               tpTmp=locTakeProfit;
              }
            if(Bid<=locTakeProfit)
              {
               if(CloseSellOrder(Symbol(),argTicket,argSlippage)==False)
                  AtomicError("tpSmartTakeProfit() CloseSellOrder");
              }
            break;
         default:
            Print("switch(Signal)");
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool slFiveSixtyXStop(int argMagicNumber,int argSignal,datetime argTimeStamp,int argTicket,double argEmaFast,double argEmaSlow,int argSlippage)
  {
   if(TotalOrderCount(Symbol(),MagicNumber)>0)
     {
      double lma5=iMA(NULL,PERIOD_CURRENT,argEmaFast,0,MODE_EMA,PRICE_CLOSE,1);
      double lma62=iMA(NULL,PERIOD_CURRENT,argEmaSlow,0,MODE_EMA,PRICE_CLOSE,1);

      // TODO: uses global variable not local variable. Index also a global variable, messy.
      if(CurrentTimeStamp!=Time[0] && index==0)
        {
         CurrentTimeStamp=Time[0];
         double lAtr=iATR(Symbol(),PERIOD_CURRENT,20,1);

         switch(argSignal)
           {
            case 0:
               break;
            case 1: // buy stop check
               if(lma5<lma62)
                 {
                  lAtr=Bid-(lAtr*UsePoint);
                  if(lAtr<Low[1])
                     index=Low[1];
                  else
                     index=lAtr;
                 }
               break;
            case 2: // sell stop check
               if(lma5>lma62)
                 {
                  lAtr=Bid+(lAtr*UsePoint);
                  if(lAtr>High[1])
                     index=High[1];
                  else
                     index=lAtr;
                 }
               break;
            default:
               Print("slFiveSixtyXStop switch(Signal)");
           }
        }

      switch(argSignal)
        {
         case 0:
            break;
         case 1:
            if(lma5<lma62)
              {
               if(index>0 && Bid<index)
                  return(CloseBuyOrder(Symbol(),argTicket,argSlippage));
              }
            break;
         case 2:
            if(lma5>lma62)
              {
               if(index>0 && Bid>index) // issue here, using closes, need to move Bids outside of if())
                  return(CloseSellOrder(Symbol(),argTicket,argSlippage));
              }
            break;
         default:
            Print("slFiveSixtyXStop switch(Signal)");
        }
     }
   return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool slUseAverageRange()
  {
   if(TotalOrderCount(Symbol(),MagicNumber)>0)
     {
      if(slPrice==0)
        {
         slPrice=iATR(NULL,0,20,1)*2;
         slPrice=slPrice/PipPoint(Symbol());
         //Print("slPrice is " + slPrice);
         slOpenOne=slPrice+(slPrice/2);
         slOpenTwo=slPrice+slPrice;
         slOpenThree=slPrice+slPrice+(slPrice/2);
         //Print("Next order at "+CalcBuyTakeProfit(Symbol(),slOpenOne,OpenPrice));
         //Print("Next order at "+CalcSellTakeProfit(Symbol(),slOpenOne,OpenPrice));
        }
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(Signal==1)
        {
         if(slOpenOne>0)
           {
            if(Bid>CalcBuyTakeProfit(Symbol(),slOpenOne,OpenPrice))
              {
               Print("Opening second buy position.");
               BuyIt();
               slOpenOne=0;
               slPrice=iATR(NULL,0,20,1)*2;
               slPrice=slPrice/PipPoint(Symbol());
              }
           }
         if(slOpenTwo>0)
           {
            if(Bid>CalcBuyTakeProfit(Symbol(),slOpenTwo,OpenPrice))
              {
               Print("Opening third buy position.");
               BuyIt();
               slOpenTwo=0;
               slPrice=iATR(NULL,0,20,1)*2;
               slPrice=slPrice/PipPoint(Symbol());
              }
           }
         if(slOpenThree>0)
           {
            if(Bid>CalcBuyTakeProfit(Symbol(),slOpenThree,OpenPrice))
              {
               Print("Opening fourth buy position.");
               BuyIt();
               slOpenThree=0;
               slPrice=iATR(NULL,0,20,1)*2;
               slPrice=slPrice/PipPoint(Symbol());
              }
           }

         BuyStopLoss=CalcBuyStopLoss(Symbol(),slPrice,OpenPrice);
         if(Bid<BuyStopLoss && BuyStopLoss>0)
           {
            return(CloseAllBuyOrders(Symbol(),MagicNumber,UseSlippage));
           }
        }
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      else
         if(Signal==2)
           {
            if(slOpenOne>0)
              {
               if(Bid<CalcSellTakeProfit(Symbol(),slOpenOne,OpenPrice))
                 {
                  Print("Opening second sell position.");
                  SellIt();
                  slOpenOne=0;
                  slPrice=iATR(NULL,0,20,1)*2;
                  slPrice=slPrice/PipPoint(Symbol());
                 }
              }
            if(slOpenTwo>0)
              {
               if(Bid<CalcSellTakeProfit(Symbol(),slOpenTwo,OpenPrice))
                 {
                  Print("Opening third sell position.");
                  SellIt();
                  slOpenTwo=0;
                  slPrice=iATR(NULL,0,20,1)*2;
                  slPrice=slPrice/PipPoint(Symbol());
                 }
              }
            if(slOpenThree>0)
              {
               if(Bid<CalcSellTakeProfit(Symbol(),slOpenThree,OpenPrice))
                 {
                  Print("Opening fourth sell position.");
                  SellIt();
                  slOpenThree=0;
                  slPrice=iATR(NULL,0,20,1)*2;
                  slPrice=slPrice/PipPoint(Symbol());
                 }
              }
            SellStopLoss=CalcSellStopLoss(Symbol(),slPrice,OpenPrice);
            if(Bid>SellStopLoss && SellStopLoss>0)
              {
               Print("in slUseAverageRange() closing all sell orders at "+SellStopLoss);
               return(CloseAllSellOrders(Symbol(),MagicNumber,UseSlippage));
              }
           }
     }
   return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool slFixedStop(int argSignal)
  {
   switch(argSignal)
     {
      case 0:
         break;
      case 1:
         if(StopLoss>0)
           {
            BuyStopLoss=CalcBuyStopLoss(Symbol(),StopLoss,OpenPrice);
            if(Bid<BuyStopLoss)
              {
               return(CloseBuyOrder(Symbol(),Ticket,UseSlippage));
              }
           }
         break;
      case 2:
         if(StopLoss>0)
           {
            SellStopLoss=CalcSellStopLoss(Symbol(),StopLoss,OpenPrice);
            if(Bid>SellStopLoss)
              {
               return(CloseSellOrder(Symbol(),Ticket,UseSlippage));
              }
           }
         break;
      default:
         Print("slFixedStop() switch(" + Signal + ")");
     }
   return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool slDynStop(int argSignal,double argDynStopLoss)
  {
   double locAtr=iATR(NULL,PERIOD_CURRENT,20,1);
   argDynStopLoss=argDynStopLoss*(locAtr/UsePoint);

   switch(argSignal)
     {
      case 0:
         break;
      case 1:
         if(argDynStopLoss>0)
           {
            BuyStopLoss=CalcBuyStopLoss(Symbol(),argDynStopLoss,OpenPrice);
            if(Bid<BuyStopLoss)
              {
               return(CloseBuyOrder(Symbol(),Ticket,UseSlippage));
              }
           }
         break;
      case 2:
         if(argDynStopLoss>0)
           {
            SellStopLoss=CalcSellStopLoss(Symbol(),argDynStopLoss,OpenPrice);
            if(Bid>SellStopLoss)
              {
               return(CloseSellOrder(Symbol(),Ticket,UseSlippage));
              }
           }
      default:
         Print("slDynStop() switch("+argSignal+")");
     }
   return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool slPriceStop(int argSignal, double argStopPrice)
  {
   switch(argSignal)
     {
      case 0:
         break;
      case 1:
         if(argStopPrice>0)
           {
            if(Bid<argStopPrice)
              {
               return(CloseBuyOrder(Symbol(),Ticket,UseSlippage));
              }
           }
         break;
      case 2:
         if(StopLoss>0)
           {
            if(Bid>argStopPrice)
              {
               return(CloseSellOrder(Symbol(),Ticket,UseSlippage));
              }
           }
         break;
      default:
         Print("slFixedStop() switch(" + Signal + ")");
     }
   return(False);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReverseSetup()
  {
   if(CheckAttempts<NumOfAttempts && NumOfAttempts>0) // 0:T, 1:T
     {
      Print("Entering reversal trade... "+NumOfAttempts);
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      if(Signal==1) // was a buy so sell
        {
         Signal=2;
         SellIt();
        }
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
      else
         if(Signal==2)
           {
            Signal=1; // was a sell so buy
            BuyIt();
           }
     }
   CheckAttempts++;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void GetSpreadSize()
  {
   if(Point==PipPoint(Symbol()))
      _SPREAD=DoubleToStr((MarketInfo(Symbol(),MODE_SPREAD)*Point));
   else
      _SPREAD=DoubleToStr((MarketInfo(Symbol(),MODE_SPREAD)*Point)/PipPoint(Symbol()));
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(StrToDouble(_SPREAD)>MaxSpread)
     {
      //Print(APP_NAME+" on "+Symbol()+" Spread to large, not trading...");
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isPriceWithEma(double argHigh,double argLow,double argEma)
  {
   bool r=((argHigh>argEma) && (argLow<argEma));
//Print("isPriceWithEma return is "+r);
   return(r);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isPriceAboveEma(double argClose,double argEma)
  {
   return(argClose>argEma);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isPriceBelowEma(double argClose,double argEma)
  {
   return(argClose<argEma);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cValidTradeTime(string argStartTime,string argEndTime) // e.g. "15:25"
  {
   datetime stime = StrToTime(argStartTime);
   datetime etime = StrToTime(argEndTime);
//Print("stime = "+TimeToStr(stime)+" etime = "+TimeToStr(etime)+TimeToStr(TimeCurrent()));

   if((TimeCurrent()>=stime) && (TimeCurrent()<etime))
      return(true);
   else
      return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cValidTradeSize(double maxPips)
  {
   /*if(TakeProfitMethod==e_tpTrailCandles)
        {
         double high=iHigh(Symbol(),PERIOD_M30,1);
         double low=iLow(Symbol(),PERIOD_M30,1);

         double pips=CalcDistanceInPoints(high,low);
         Print(pips);
         return(pips<maxPips);
        }*/
   return(True);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool calcNCandleStop(int argMagicNumber,int argSignal,int argCandleCount,double &argPrice,bool argNewCandle,int argIndex)
  {
   if(SetupEntry>0 && argNewCandle)
     {
      //Print("Entered calcTwoCandleStop..");
      int locHighLowIndex;

      if(argPrice==0)
        {
         switch(argSignal)
           {
            case 0:
               break;
            case 1: // buy
               locHighLowIndex=iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,argIndex,1);
               argPrice=iLow(Symbol(),PERIOD_CURRENT,locHighLowIndex);
               argPrice=argPrice-(1*UsePoint);
               Print("calcTwoCandleStop argPrice "+argPrice);
               //if(argPrice<iLow(Symbol(),PERIOD_CURRENT,argCandleCount+1))
               //{
               //argPrice=iLow(Symbol(),PERIOD_CURRENT,argCandleCount+1);
               //}

               break;
            case 2: // sell
               locHighLowIndex=iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,argIndex,1);
               argPrice=iHigh(Symbol(),PERIOD_CURRENT,locHighLowIndex);
               argPrice=argPrice+(1*UsePoint);
               Print("calcTwoCandleStop argPrice "+argPrice);
               //if(argPrice>iHigh(Symbol(),PERIOD_CURRENT,argCandleCount+1))
               //{
               //argPrice=iHigh(Symbol(),PERIOD_CURRENT,argCandleCount+1);
               //}
               break;
            default:
               break;
           }
        }
     }

   if(argPrice>0)
      return(True);
   else
      return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool calcTwoCandleStop(int argMagicNumber,int argSignal,int &argCandleCount,double &argPrice,bool argNewCandle,int argIndex)
  {
   if(TotalOrderCount(Symbol(),argMagicNumber)>0 && argNewCandle)
     {
      Print("Entered calcTwoCandleStop..");
      if(argCandleCount==argIndex)
        {
         Print("Entered calcTwoCandleStop..");
         int locHighLowIndex;

         if(argPrice==0)
           {
            switch(argSignal)
              {
               case 0:
                  break;
               case 1: // buy
                  locHighLowIndex=iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,argIndex,1);
                  argPrice=iLow(Symbol(),PERIOD_CURRENT,locHighLowIndex);
                  argPrice=argPrice+(1*UsePoint);
                  Print("calcTwoCandleStop argPrice "+argPrice);
                  if(argPrice<iLow(Symbol(),PERIOD_CURRENT,argCandleCount+1))
                    {
                     argPrice=iLow(Symbol(),PERIOD_CURRENT,argCandleCount+1);
                    }

                  break;
               case 2: // sell
                  locHighLowIndex=iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,argIndex,1);
                  argPrice=iHigh(Symbol(),PERIOD_CURRENT,locHighLowIndex);
                  argPrice=argPrice-(1*UsePoint);
                  Print("calcTwoCandleStop argPrice "+argPrice);
                  if(argPrice>iHigh(Symbol(),PERIOD_CURRENT,argCandleCount+1))
                    {
                     argPrice=iHigh(Symbol(),PERIOD_CURRENT,argCandleCount+1);
                    }
                  break;
               default:
                  break;
              }
           }
        }
      else
         argCandleCount++;
     }

   if(argPrice>0)
      return(True);
   else
      return(False);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool calcTwoCandleStopWithTrade(int argMagicNumber,int argSignal,int &argCandleCount,double &argPrice,bool argNewCandle)
  {
   if(TotalOrderCount(Symbol(),argMagicNumber)>0 && argNewCandle)
     {
      int locMaxCandleCount=2;
      //Print("argCandleCount " + argCandleCount);

      if(argCandleCount==locMaxCandleCount)
        {
         int locHighLowIndex;

         if(argPrice==0)
           {
            switch(argSignal)
              {
               case 0:
                  break;
               case 1: // buy
                  locHighLowIndex=iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,locMaxCandleCount,1);
                  argPrice=iLow(Symbol(),PERIOD_CURRENT,locHighLowIndex);
                  Print("calcTwoCandleStop argPrice "+argPrice);
                  if(argPrice<iLow(Symbol(),PERIOD_CURRENT,argCandleCount+1))
                    {
                     argPrice=iLow(Symbol(),PERIOD_CURRENT,argCandleCount+1);
                    }

                  break;
               case 2: // sell
                  locHighLowIndex=iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,locMaxCandleCount,1);
                  argPrice=iHigh(Symbol(),PERIOD_CURRENT,locHighLowIndex);
                  Print("calcTwoCandleStop argPrice "+argPrice);
                  if(argPrice>iHigh(Symbol(),PERIOD_CURRENT,argCandleCount+1))
                    {
                     argPrice=iHigh(Symbol(),PERIOD_CURRENT,argCandleCount+1);
                    }
                  break;
               default:
                  break;
              }
           }
        }
      else
         argCandleCount++;
     }

   if(argPrice>0)
      return(True);
   else
      return(False);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double calcEntryPrice(int argSignal,int argIndex)
  {
   int locHighest;
   double locEntry;

   switch(argSignal)
     {
      case 0: // No Trade
         break;
      case 1: // buy takeprofit
         locHighest=iHighest(Symbol(),PERIOD_CURRENT,MODE_HIGH,argIndex,1);
         locEntry=iHigh(Symbol(),PERIOD_CURRENT,locHighest);
         if(locEntry>0)
            locEntry=locEntry+(1*UsePoint);
         break;
      case 2: // sell takeprofit
         locHighest=iLowest(Symbol(),PERIOD_CURRENT,MODE_LOW,argIndex,1);
         locEntry=iLow(Symbol(),PERIOD_CURRENT,locHighest);
         if(locEntry>0)
            locEntry=locEntry-(1*UsePoint);
         break;
      default:
         Print("switch(Signal)");
     }

   return(locEntry);
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetRandomMagicNumber()
  {
   int rounds = 5;
   int aMagicNumber = WindowHandle(NULL, 0);
   
   for (int i = 0; i<rounds; i++)
   {
      MathSrand(GetTickCount());
      aMagicNumber = aMagicNumber + MathRand();
      Sleep(100);
   }
   
   return(aMagicNumber);
  }
//+------------------------------------------------------------------+
