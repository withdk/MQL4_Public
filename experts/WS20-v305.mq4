//+------------------------------------------------------------------+
//|                                                     WS20-Rev.mq4 |
//|                                Copyright 2017, David Kierznowski |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, David Kierznowski"
#property link      "https://www.mql5.com"
#property version   "3.05"
#property strict

#define APP_NAME     "WS20-Rev-Bot"
#define APP_VERSION  "3.05"

#include <DKSpecialInclude.mqh>
#include <TradeManagement.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*
v1.00 Initial version.
v1.01 Added Dashboard, MaxSpread Check and Additional External Options
v1.02 Modying entry on 5x62 status not candle close, Changed CloseBuyOrder, CalcBuyStopLoss, Ticket for their sell equivilents.
v1.03 Adding Martingale 
v3.00 Fixed 5x62 stop loss method, made huge changes to the structure of the code, added alot more checks to prevent user error.
v3.01 Fixed two bugs, first changing if/if statement in Reversal() to if/else if. Second, using Signal instead of Buy/Tickets.
v3.02 Added ProtectiveStop & ProtectiveTarget. Added valid trade window of 10 seconds from TradeStartTime.
      Moved Stop/Target functions outside of the ValidTradeHours loop so it always applies.
      Added RiskCheck which ensures the 5x62 is at least 2 pips apart so bad setups can be avoided.
v3.03 Fixed RiskCheck to use UsePoint for multiple markets.
v3.04 Created new shared library file "TradeManagement.mph" and migrated functions out to be used by multiple EAs.
      Removed BuyTicket and SellTicket and replaced with just Ticket.
      Fixed slFiveSixtyXStop() was a mess and wasn't working correctly. Now seems to work as expected.
      Added 1*ATR to slFiveSixtyXStop() to minimise large losses.
v3.05 Added 5x18x62 Filter.
*/

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum e_StopLossMethod
  {
   e_slFiveSixtyXOver=1,
   e_slStaticStopLoss=2,
   e_slUseAverageRange=3
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum e_TakeProfitMethod
  {
   e_tpFixedTakeProfit=1,
   e_tpTrailing20=2
  };

// input variables are constants versus extern vars which can change.
input string MenuSession="Bot Settings";
extern string TradeStartTime="15:00";
extern string TradeEndTime="21:00";
//extern double StartRisk=5.0;
//extern double EndRisk=20.0;
extern int MaShort=5;
extern int MaLong=62;
input string MenuMoney="Money Settings";
input double FixedLotSize=0.1;
input double MaxSpread=3.0;
input string MenuTakeProfit="Take Profit Settings";
extern e_TakeProfitMethod TakeProfitMethod=e_tpFixedTakeProfit;
extern int TakeProfit=20;
extern int ProtectiveTarget=20;
input string Opt3="Stoploss Settings";
extern e_StopLossMethod StopLossMethod=e_slFiveSixtyXOver;
extern int StopLoss=0;
extern int ProtectiveStop=50;
input string MenuReversal="Reversal Settings";
input string Opt41="Set NumOfAttempt to 0 to disable reverse trades";
input int NumOfAttempts=1;
input string MenuMisc="General Bot Settings";
extern int MagicNumber=20214;
extern color DashboardColor=C'0x46,0x91,0xEC';

int TradeStage;
int Signal; // 0 Error, 1 Buy, 2 Sell
int CheckAttempts;
datetime CurrentDayTimeStamp;
datetime CurrentTimeStamp;
double UsePoint;
int UseSlippage;
int Ticket;
bool CanTrade;
double SellTakeProfit;
double BuyTakeProfit;
double BuyStopLoss;
double SellStopLoss;
double OpenPrice;
double ma5;
double ma62;
double index;
double slPrice;
double slOpenOne;
double slOpenTwo;
double slOpenThree;
double TotalPips;
double tpTmp;
datetime tpTimeStamp;
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
   UsePoint=PipPoint(Symbol());
   UseSlippage=GetSlippage(Symbol(),3);
   TradeStage=0;
   Signal=0;
   Ticket=0;
   SellTakeProfit=0;
   BuyTakeProfit=0;
   BuyStopLoss=0;
   SellStopLoss=0;
   CheckAttempts=0;
   ma5=0;
   ma62=0;
   CanTrade=True;
   TotalPips=PipTally(Symbol(),MagicNumber);

   if(ProtectiveStop<1 && ProtectiveTarget<1)
     {
      Alert("ProtectiveStop or ProtectiveTarget NOT set! You have no protection if the bot gets shutdown.");
     }

   if(StopLossMethod<1 && StopLossMethod>3)
     {
      Alert("StopLossMethod is invalid!! Please check settings.");
      return(INIT_FAILED);
     }

   if(StopLoss<1 && StopLossMethod==2)
     {
      Alert("StopLossMethod 2 selected but no StopLoss has been set.");
      return(INIT_FAILED);
     }

   if(StopLoss>1 && StopLossMethod==1)
     {
      Alert("StopLossMethod 1 (e_slFiveSixtyXOver) selected but FixedStopLoss has been set. Please set FixedStopLoss to 0 or change the StopLossMethod.");
      return(INIT_FAILED);
     }

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
      CanTrade=True;
      CurrentDayTimeStamp=iTime(Symbol(),PERIOD_D1,0);
      TotalPips=PipTally(Symbol(),MagicNumber);
      Print("Pips earned from trade: "+CalcPipsOfLastTrade(Symbol(),MagicNumber));
     }

   if(cValidTradeTime(TradeStartTime,TradeEndTime))
     {
      // 10 Seconds to take a trade.
      bool ValidTradeTime=False;
      if(TimeCurrent()>=StrToTime(TradeStartTime) && TimeCurrent()<=StrToTime(TradeStartTime)+120)
        {
         ValidTradeTime=True;
        }
      if(TotalOrderCount(Symbol(),MagicNumber)==0 && TradeStage!=3 && CanTrade && ValidTradeTime)
        {
         // Update moving averages
         ma5=iMA(NULL,PERIOD_CURRENT,MaShort,0,MODE_EMA,PRICE_CLOSE,1);
         ma62=iMA(NULL,PERIOD_CURRENT,MaLong,0,MODE_EMA,PRICE_CLOSE,1);
         double ma18=iMA(NULL,PERIOD_CURRENT,18,0,MODE_EMA,PRICE_CLOSE,1);
         //Print("ma5 "+NormalizeDouble(ma5,2));
         //Print("ma62 "+NormalizeDouble(ma62,2));
         //Print("MA Delta "+MathAbs(ma62-ma5));
         //Print("iATR "+iATR(Symbol(),0,20,1));
         //Print("iATR/MA "+MathAbs(ma62-ma5)/iATR(Symbol(),0,20,1));
         double RiskCheck=MathAbs(ma62-ma5);
         //Print("RiskCheck " + (2*UsePoint));
         // Check the trade conditions
         if(ma5>ma18 && ma18>ma62 && RiskCheck>(2*UsePoint))
           {
            Signal=1;
            BuyIt();
            Print("Entering Buy.."); // buy
           }
         else if(ma5<ma18 && ma18 < ma62 && RiskCheck>(2*UsePoint))
           {
            Signal=2;
            SellIt();
            Print("Entering Sell.."); // sell
           }
         else
            CanTrade=False;
        }
     }
   else
     {
      if(TotalOrderCount(Symbol(),MagicNumber)>0)
        {
         if(Signal==1)
           {
            if(CloseAllBuyOrders(Symbol(),MagicNumber,UseSlippage)==False)
               AtomicError("CloseBuyOrder");
            //Ticket=0;
           }
         else if(Signal==2)
           {
            if(CloseAllSellOrders(Symbol(),MagicNumber,UseSlippage)==False)
               AtomicError("CloseBuyOrder");
            //Ticket=0;
           }
         //TradeStage=0;
        }
     }

// Outside Valid Trade Hours
   switch(TakeProfitMethod)
     {
      case 1: // e_tpFixedTakeProfit Method
         if(TakeProfit>0)
           {
            tpFixedTakeProfit(MagicNumber,TakeProfit,OpenPrice,Ticket,Signal,UseSlippage);
           }
         else
            Alert("TakeProfit is not set!! Don't no where to exit. Check bot settings.");
         break;
      case 2:
         tpTrailing20(MagicNumber,Signal,tpTimeStamp,UseSlippage);
         break;
      default:
         Print("switch(Signal)");
     }

   switch(StopLossMethod)
     {
      case 1:
         if(slFiveSixtyXStop(MagicNumber,Signal,CurrentTimeStamp,Ticket,MaShort,MaLong,UseSlippage)==True)
           {
            ReverseSetup();
           }
         break;
      case 2:
         if(slFixedStop(Signal)==True)
           {
            ReverseSetup();
           }
         break;
      case 3:
         if(slUseAverageRange()==True)
           {
            ReverseSetup();
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


void CheckForSetupReset()
  {
   if(TotalOrderCount(Symbol(),MagicNumber)==0)
     {
      TradeStage=0;
      Signal=0;
      CheckAttempts=0;
      OpenPrice=0;
      Ticket=0;
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
      tpTmp=0;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuyIt()
  {
   Ticket=OpenBuyOrder(Symbol(),FixedLotSize,UseSlippage,MagicNumber);
   CanTrade=False;

   if(Ticket>0)
     {
      if(OrderSelect(Ticket,SELECT_BY_TICKET)==0)
         AtomicError("OrderSelect");

      OpenPrice=OrderOpenPrice();
      // Add Protective Stop
      if(ProtectiveStop>0 && ProtectiveTarget>0)
        {
         double ps=CalcBuyStopLoss(Symbol(),ProtectiveStop,OpenPrice);
         double pt=CalcBuyTakeProfit(Symbol(),ProtectiveTarget,OpenPrice);
         ps=AdjustBelowStopLevel(Symbol(),ps,0,OpenPrice);
         pt=AdjustAboveStopLevel(Symbol(),pt,0,OpenPrice);
         AddStopProfit(Ticket,ps,pt);
        }

      TradeStage=3;
     }
   else
      AtomicError("Ticket");
  }
//+------------------------------------------------------------------+

void SellIt()
  {
   Ticket=OpenSellOrder(Symbol(),FixedLotSize,UseSlippage,MagicNumber);
   CanTrade=False;

   if(Ticket>0)
     {
      if(OrderSelect(Ticket,SELECT_BY_TICKET)==0)
         AtomicError("OrderSelect");

      OpenPrice=OrderOpenPrice();
      // Add Protective Stop
      if(ProtectiveStop>0 && ProtectiveTarget>0)
        {
         double ps=CalcSellStopLoss(Symbol(),ProtectiveStop,OpenPrice);
         double pt=CalcSellTakeProfit(Symbol(),ProtectiveTarget,OpenPrice);
         ps=AdjustAboveStopLevel(Symbol(),ps,0,OpenPrice);
         pt=AdjustBelowStopLevel(Symbol(),pt,0,OpenPrice);
         AddStopProfit(Ticket,ps,pt);
        }
      TradeStage=3;
     }
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
   s=s+_spaces+"TakeProfit "+TakeProfit+"\n";
   e_StopLossMethod stopmethod=StopLossMethod;
   s=s+_spaces+"StopLossMethod: "+EnumToString(stopmethod)+"\n";
   if(StopLossMethod!=1)
      s=s+_spaces+"StopLoss: "+StopLoss+"\n";
   s=s+_spaces+"ProtectiveStop "+ProtectiveStop+"\n";
   s=s+_spaces+"ProtectiveTarget "+ProtectiveTarget+"\n";
   s=s+_spaces+"Trade Session: " +  TradeStartTime + " - " + TradeEndTime + "\n";
   s=s+_spaces+"NumOfReversal Attempts: " + NumOfAttempts + "\n";
   s=s+_spaces+"Total Net Pips Earned: " + NormalizeDouble(TotalPips,2) + "\n";
   s=s+_spaces+"Bot Magic Number: " + MagicNumber + "\n";
//s=s+_spaces+"Point: " + Point + "\n";
//s=s+_spaces+"PipPoint: " + PipPoint(Symbol()) + "\n";

   Comment(s);
  }
//+------------------------------------------------------------------+
