//+------------------------------------------------------------------+
//|                                                     WS20-Rev.mq4 |
//|                                Copyright 2017, David Kierznowski |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, David Kierznowski"
#property link      "https://www.mql5.com"
#property version   "3.00"
#property strict

#define APP_NAME     "WS20-Rev-Bot"
#define APP_VERSION  "3.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*
v1.00 Initial version.
v1.01 Added Dashboard, MaxSpread Check and Additional External Options
v1.02 Modying entry on 5x62 status not candle close, Changed CloseBuyOrder, CalcBuyStopLoss, BuyTicket for their sell equivilents.
v1.03 Adding Martingale 
v3.00 Fixed 5x62 stop loss method, made huge changes to the structure of the code, added alot more checks to prevent user error.
*/

#include <DKSpecialInclude.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum e_TakeProfitMethod
  {
   e_tpTrailing20=1
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum e_StopLossMethod
  {
   e_slUseAverageRange=1
  };

// input variables are constants versus extern vars which can change.
input string MenuSession="Bot Settings - US30 default";
extern string EntryTime="15:00";
extern string TradeStartTime="15:00";
extern string TradeEndTime="21:00";
input string MenuMoney="Money Settings";
input double FixedLotSize=0.1;
input double MaxSpread=3.0;
input string MenuTakeProfit="Take Profit Settings";
extern e_TakeProfitMethod TakeProfitMethod=e_tpTrailing20;
input string Opt3="Stoploss Settings";
extern e_StopLossMethod StopLossMethod=e_slUseAverageRange;
input string MenuMisc="General Bot Settings";
extern int MagicNumber=10055;
extern color DashboardColor=C'0x46,0x91,0xEC';

int TradeStage;
int Signal; // 0 Error, 1 Buy, 2 Sell
int CheckAttempts;
datetime CurrentDayTimeStamp;
datetime CurrentTimeStamp;
//double UsePoint;
int UseSlippage;
int BuyTicket;
int SellTicket;
bool CanTrade;
double SellTakeProfit;
double BuyTakeProfit;
double BuyStopLoss;
double SellStopLoss;
double OpenPrice;
double ma5;
double ma62;
double index;
datetime tpTimeStamp;
double slPrice;
double slOpenOne;
double slOpenTwo;
double slOpenThree;
double _LOTSTEP,_MINLOT,_MAXLOT,_SPREAD;
int _LOTDIGITS;
double _STOPLEVEL,_FREEZELEVEL;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int init()
  {

   if(!IsConnected())
      Alert(APP_NAME+" v"+APP_VERSION+": No connection with broker server! EA will start running once connection established");
   if(!IsExpertEnabled())
      Alert(APP_NAME+" v"+APP_VERSION+": Please enable \"Expert Advisors\" in the top toolbar of Metatrader to run this EA");
   if(!IsTradeAllowed())
      Alert(APP_NAME+" v"+APP_VERSION+": Trade is not allowed. EA cannot run. Please check \"Allow live trading\" in the \"Common\" tab of the EA properties window");

   _LOTSTEP=MarketInfo(Symbol(),MODE_LOTSTEP);
   _MINLOT = MarketInfo(Symbol(), MODE_MINLOT);
   _MAXLOT = MarketInfo(Symbol(), MODE_MAXLOT);

   CurrentDayTimeStamp=iTime(Symbol(),PERIOD_D1,0);
   CurrentTimeStamp=Time[0];
   tpTimeStamp=Time[0];
//UsePoint=PipPoint(Symbol());
   UseSlippage=GetSlippage(Symbol(),3);
   TradeStage=0;
   Signal=0;
   BuyTicket=0;
   SellTicket=0;
   SellTakeProfit=0;
   BuyTakeProfit=0;
   BuyStopLoss=0;
   SellStopLoss=0;
   CheckAttempts=0;
   slPrice=0;
   ma5=0;
   ma62=0;
   CanTrade=True;

   if(StringLen(TradeStartTime)<4)
     {
      Alert("Invalid TradeStartTime length!! Please use format hh:ss.");
      return(INIT_FAILED);
     }

   if(StringLen(TradeEndTime)<4)
     {
      Alert("Invalid TradeEndTime length!! Please use format hh:ss.");
      return(INIT_FAILED);
     }

   if(StringFind(TradeStartTime,":")<0)
     {
      Alert("Invalid TradeStartTime format!! Please use format hh:ss.");
      return(INIT_FAILED);
     }

   if(StringFind(TradeEndTime,":")<0)
     {
      Alert("Invalid TradeEndTime format!! Please use format hh:ss.");
      return(INIT_FAILED);
     }

   if(TotalOrderCount(Symbol(),MagicNumber)>0)
     {
      Alert("WS20 bot already has open trades. This may cause unexpected behaviour. Please close these first and try again.");
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
   GetSpreadSize();
   printComments();

   if(CurrentDayTimeStamp!=iTime(Symbol(),PERIOD_D1,0))
     {
      //CanTrade=True;
      CurrentDayTimeStamp=iTime(Symbol(),PERIOD_D1,0);

      if(TakeProfitMethod==e_tpTrailing20)
        {
         //datetime tmp_dt=StrToTime(TradeEndTime);
         //tmp_dt=TimeCurrent()+3600;
         //TradeEndTime=TimeToStr(tmp_dt);
         //tmp_dt= StrToTime(TradeStartTime);
         //tmp_dt=TimeCurrent()-3600;
         //TradeStartTime=TimeToStr(tmp_dt);
         //Print("TradeEndTime " + TimeToStr(TradeEndTime) + " TimeCurrent " + TimeCurrent());
        }

      //if(cValidTradeTime(TradeStartTime,TradeEndTime))
      // {
      if(TotalOrderCount(Symbol(),MagicNumber)==0 && TradeStage!=3)
        {
         // Update moving averages
         if(cIsNPeriodBuyBreakout(55))
           {
            Signal=1;
            CanTrade=False;
            Print("Entering Buy.."); // buy
            BuyIt();
           }
         if(cIsNPeriodSellBreakout(55))
           {
            Signal=2;
            CanTrade=False;
            Print("Entering Sell.."); // sell
            SellIt();
           }
         //  }
        }
     }
   switch(TakeProfitMethod)
     {
      case 1:
         tpTrailing20();
         break;
      default:
         Print("switch(Signal)");
     }

   switch(StopLossMethod)
     {
      case 1:
         if(slUseAverageRange()==True)
           {
           }
         break;
      default:
         AtomicError("StopLoss Method Not Valid.");
     }

   CheckForSetupReset();

   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int AtomicError(string Err)
  {
   Alert(Err," returned the error of ",GetLastError());
   CanTrade=False;

   return 0;
  }
//+------------------------------------------------------------------+

void CheckForSetupReset()
  {
   if(TotalOrderCount(Symbol(),MagicNumber)==0)
     {
      TradeStage=0;
      Signal=0;
      CheckAttempts=0;
      OpenPrice=0;
      BuyTicket=0;
      SellTicket=0;
      SellTakeProfit=0;
      BuyTakeProfit=0;
      BuyStopLoss=0;
      SellStopLoss=0;
      ma5=0;
      ma62=0;
      index=0;
      slPrice=0;
      slOpenOne=0;
      slOpenTwo=0;
      slOpenThree=0;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuyIt()
  {
   BuyTicket=OpenBuyOrder(Symbol(),FixedLotSize,UseSlippage,MagicNumber);

   if(BuyTicket>0)
     {
      if(OrderSelect(BuyTicket,SELECT_BY_TICKET)==0)
         AtomicError("OrderSelect");

      OpenPrice=OrderOpenPrice();
      TradeStage=3;
     }
   else
      AtomicError("BuyTicket");

//else
//{
//AtomicError("BuyIt() called but already in trade, ignoring...");
//}
  }
//+------------------------------------------------------------------+

void SellIt()
  {
   SellTicket=OpenSellOrder(Symbol(),FixedLotSize,UseSlippage,MagicNumber);

   if(SellTicket>0)
     {
      if(OrderSelect(SellTicket,SELECT_BY_TICKET)==0)
         AtomicError("OrderSelect");

      OpenPrice=OrderOpenPrice();
      TradeStage=3;
     }
   else
      AtomicError("SellTicket");
//else
//{
//AtomicError("SellIt() called but already in trade, ignoring...");
//}
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void tpTrailing20()
  {
   if(tpTimeStamp!=Time[0])
     {
      tpTimeStamp=Time[0];
      if(TotalOrderCount(Symbol(),MagicNumber)>0)
        {
         int tpIndex;
         double tpTakeProfit;

         switch(Signal)
           {
            case 0: // No Trade
               break;
            case 1: // buy takeprofit
               tpIndex=iLowest(NULL,0,MODE_LOW,20,2);
               tpTakeProfit=iLow(NULL,0,tpIndex);
               //Print("Buy Close price is currently " + tpTakeProfit + " at index " + tpIndex);
               if(Bid<tpTakeProfit)
                  if(CloseAllBuyOrders(Symbol(),MagicNumber,UseSlippage)==False)
                     AtomicError("CloseBuyOrder");
               break;
            case 2: // sell takeprofit
               tpIndex=iHighest(NULL,0,MODE_HIGH,20,2);
               tpTakeProfit=iHigh(NULL,0,tpIndex);
               //Print("Sell Close price is currently " + tpTakeProfit + " at index " + tpIndex);
               if(Bid>tpTakeProfit)
                  if(CloseAllSellOrders(Symbol(),MagicNumber,UseSlippage)==False)
                     AtomicError("CloseSellOrder");
               break;
            default:
               Print("switch(Signal)");
           }
        }
     }
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
      else if(Signal==2)
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
            Print("in slUseAverageRange() closing all sell orders at " + SellStopLoss);
            return(CloseAllSellOrders(Symbol(),MagicNumber,UseSlippage));
           }
        }
     }
   return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
bool cIsNPeriodBuyBreakout(int argNPeriod)
  {
   int cIndex=iHighest(NULL,0,MODE_HIGH,argNPeriod,2);
   double cEntry=iHigh(NULL,0,cIndex);

   if(Close[1]>cEntry)
      return(True);
   else
      return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cIsNPeriodSellBreakout(int argNPeriod)
  {
   int cIndex=iLowest(NULL,0,MODE_LOW,argNPeriod,2);
   double cEntry=iLow(NULL,0,cIndex);

   if(Close[1]<cEntry)
      return(True);
   else
      return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateBlock99(color LabelColor,int font_size,int block_count,int step_pixels)
  {
   string Obj;
   for(int i=0; i<block_count; i++)
      //+------------------------------------------------------------------+
      //|                                                                  |
      //+------------------------------------------------------------------+
     {
      Obj=APP_NAME+"block99-"+(i+1);
      if(ObjectFind(Obj)==-1)
         ObjectCreate(Obj,OBJ_LABEL,0,0,0);
      ObjectSetText(Obj,"g",font_size,"Webdings",LabelColor);
      ObjectSet(Obj,OBJPROP_XDISTANCE,85);
      ObjectSet(Obj,OBJPROP_YDISTANCE,72+step_pixels*i);
      ObjectSet(Obj,OBJPROP_COLOR,LabelColor);
      ObjectSet(Obj,OBJPROP_FONTSIZE,font_size);
     } //for
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string extraSpaces(int c=0)
  {
   string s="";
   for(int i=0; i<c; i++)
      s=s+" "; return(s);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string BoolToStr(bool b,string text_true="Yes",string text_false="No")
  {
   if(b)
      return(text_true);
   else
      return(text_false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void printComments()
  {
   CreateBlock99(DashboardColor,140,1,130);
   string _spaces=extraSpaces(30);
   string s="\n\n\n\n\n\n";
   s=s+_spaces+APP_NAME+" v"+APP_VERSION+"\n\n";
   s=s+_spaces+"Market " + Symbol() + "\n";
   s=s+_spaces+"Spread: " + _SPREAD + " pips\n";
   s=s+_spaces+"Lot Size: " + FixedLotSize + "\n";
   s=s+_spaces+"MaxSpread "+MaxSpread+"\n";
   e_StopLossMethod stopmethod=StopLossMethod;
   s=s+_spaces+"StopLossMethod: "+EnumToString(stopmethod)+"\n";
   s=s+_spaces+"Trade Session: " +  TradeStartTime + " - " + TradeEndTime + "\n";
   s=s+_spaces+"Bot Magic Number: " + MagicNumber + "\n";
//s=s+_spaces+"Point: " + Point + "\n";
//s=s+_spaces+"PipPoint: " + PipPoint(Symbol()) + "\n";

   Comment(s);
  }
//+------------------------------------------------------------------+
