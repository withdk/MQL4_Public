//+------------------------------------------------------------------+
//|                                               Range Breakout.mq4 |
//|                                Copyright 2020, David Kierznowski |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, David Kierznowski"
#property link      "https://github.com/withdk"
#property version   "1.01"
#property strict

#define APP_NAME     "Range Breakout"
#define APP_VERSION  "1.01"

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
v3.06 Modified the 5x62 stoploss to only trigger on a break of the high/low after a crossover.
      Modify the entry to take a trade as soon as the 5x18x62 align if that is not the case at open.
      Refactored code by adding VerifyInputs() function.
      Added take reverse trade option ReverseTradeOnProtectiveStop if ProtectiveStop's triggered.
      Broke ProtectiveStop/Target somehow. FIXME. Disabled by setting to 0 for time being.
v3.07 Added IsTradeAllowed() to prevent taking trades when the "context" is busy.
      Added additional return checks on key trading functions.
      Cleaned up code a little including commenting protectivestop/targets as it's causing issues.
      Added profit target to trade window.
v3.08 Changed MODE_EMA to MODE_SMA

v1.00 Modified v3.08 WS bot to UK100Club bot.
      Example Signals:
         29th September 	Sell CAD/JPY at 78.93 - Stop/Loss 80.32 (WEBSITE)
         Signal: Sell AUD/NZD at 1.0490 - Stop/Loss 1.0629 (EMAIL)
*/

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum e_StopLossMethod
  {
//e_slFiveSixtyXOver=1,
//e_slStaticStopLoss=2,
//e_slUseAverageRange=3,
   e_slPriceStopLoss=4
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum e_TakeProfitMethod
  {
   e_tpFixedTakeProfit=1,
//e_tpTrailing20=2
  };

// input variables are constants versus extern vars which can change.
input string MenuSession="Bot Settings";
input string TradeSessopn="Trading Session Time";
extern string TradeStartTime="11:00";
extern string TradeEndTime="21:00";
input string RangeSession="Trading Range Times";
extern string RangeStartTime="9:00";
extern string RangeEndTime="10:59";
// TakeFirstAvailableSetup set to true will take setup when it occurs.
//input bool TakeFirstAvailableSetup=True;
//extern double StartRisk=5.0;
//extern double EndRisk=20.0;
//extern int MaShort=5;
//extern int MaLong=62;
input string MenuMoney="Money Settings";
input double FixedLotSize=0.1;
input double MaxSpread=3.0;
input string MenuTakeProfit="Take Profit Settings";
extern e_TakeProfitMethod TakeProfitMethod=e_tpFixedTakeProfit;
extern int TakeProfit=50;
input string Opt3="Stoploss Settings";
extern e_StopLossMethod StopLossMethod=e_slPriceStopLoss;
//extern int StopLoss=50;
//input string Opt4="Use ProtectiveStops & Targets";
//extern bool UseProtectiveStopProfit=False; // To many issues leaving for now.
input string MenuReversal="Reversal Settings";
input string Opt41="Set NumOfAttempt to 0 to disable reverse trades";
input int NumOfAttempts=1;
input string MenuMisc="General Bot Settings";
//extern int MagicNumber=20214;
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
//double ProtectiveStopPrice;
//bool ReverseTradeOnProtectiveStop;
datetime tpTimeStamp;
double _LOTSTEP,_MINLOT,_MAXLOT,_SPREAD;
int _LOTDIGITS;
double _STOPLEVEL,_FREEZELEVEL;
int SetupEntry;


// Local vars for this bot (don't change above vars)
bool isNewBar;
datetime lastBarOpenAt;
int startbarshift = 0;
int endbarshift = 0;
double rangehigh = 0;
double rangelow = 0;
bool israngecalc = False;
double StopLoss;
int MagicNumber;

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
//ProtectiveStopPrice=0;
   TotalPips=PipTally(Symbol(),MagicNumber);
   CanTrade=False;
//if(NumOfAttempts>0)
//ReverseTradeOnProtectiveStop=True;

   /* Check Inputs */
   int verify=VerifyInputs();

// Local var setup
   lastBarOpenAt = Time[0];

   MagicNumber = GetRandomMagicNumber();
   Print("Using Random Magic Number: " + MagicNumber);

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

//# New day, reset trade parameters.
   if(CurrentDayTimeStamp!=iTime(Symbol(),PERIOD_D1,0))
     {
      CurrentDayTimeStamp=iTime(Symbol(),PERIOD_D1,0);
      TotalPips=PipTally(Symbol(),MagicNumber);
      Print("Pips earned from trade: "+CalcPipsOfLastTrade(Symbol(),MagicNumber));
      startbarshift = 0;
      endbarshift = 0;
      israngecalc = False;
      rangelow = 0;
      rangehigh = 0;
      CanTrade = False;
     }


//# Test Magic Number
//Print(GetRandomMagicNumber());

//# Check for new bar
   if(lastBarOpenAt == Time[0]) // This tick is not in new bar
     {
      isNewBar=false;
     }
   else
     {
      lastBarOpenAt = Time[0];
      isNewBar = true;
     }

   if(isNewBar)
     {

      //# Get current barshift
      //int currbarshift = iBarShift(NULL,0,TimeCurrent(),True);

      //# Setup trade orders after endtime
      datetime stime = StrToTime(RangeStartTime);
      datetime etime = StrToTime(RangeEndTime);
      if(TimeCurrent() > etime && israngecalc == False)
        {
         startbarshift=iBarShift(NULL,0,stime, True);
         endbarshift=iBarShift(NULL,0,etime, True);
         //Print("Got new range startshift: " + startbarshift);
         //Print("Got new range endshift: " + endbarshift);
        }

      //# Get the range high/low prices if barshifts > 0 (validation check).
      if(startbarshift > 0 && endbarshift > 0 && israngecalc == False)
        {
         israngecalc = True;
         // We can short cut by just using startshift + 1
         int count = startbarshift + 1; // e.g. 3 or 4
         int rangehighshift = iHighest(NULL,0,MODE_HIGH,count,0); 
         int rangelowshift = iLowest(NULL,0,MODE_LOW,count,0); 
         rangehigh = iHigh(NULL, 0,  rangehighshift);
         rangelow = iLow(NULL, 0,  rangelowshift);
         Print("Session rangelow = " + rangelow + " , rangehigh= " + rangehigh);
         //Print("rangelowshift = " + startbarshift + " , rangehighshift= " + endbarshift);
         CanTrade = True;
        }

     }


   if(cValidTradeTime(TradeStartTime,TradeEndTime) && rangehigh > 0 && rangelow > 0)
     {

      if(TotalOrderCount(Symbol(),MagicNumber)==0 && TradeStage!=3 && CanTrade)
        {
         if(Bid > rangehigh)
           {
            if(IsTradeAllowed()) // Prevent context busy errors & conflicts with other bots
              {
               if(BuyIt())
                 {
                  Signal=1;
                  //if(DoStopProfit()==False)
                  //Print("Couldn't set protective stop/target orders.");
                  Print("Entering Buy at " + Bid + " .."); // buy
                 }
              }
           }
         else
            if(Bid < rangelow)
              {
               if(IsTradeAllowed()) // Prevent context busy errors & conflicts with other bots
                 {
                  if(SellIt())
                    {
                     Signal=2;
                     //if(DoStopProfit()==False)
                     //Print("Couldn't set protective stop/target orders.");
                     Print("Entering Sell at " + Bid + " .."); // sell
                    }
                 }
              }
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
         else
            if(Signal==2)
              {
               if(CloseAllSellOrders(Symbol(),MagicNumber,UseSlippage)==False)
                  AtomicError("CloseBuyOrder");
               //Ticket=0;
              }
         //TradeStage=0;
        }
     }


// If trade has been closed by ProtectiveStop open reverse trade
   /*
      if(ReverseTradeOnProtectiveStop && Ticket>0)
        {
         switch(Signal)
           {
            case 0:
               break;
            case 1: //buy trade
               if(TotalOrderCount(Symbol(),MagicNumber)==0 && ProtectiveStopPrice>0 && Bid<ProtectiveStopPrice) // Trade closed prematurely.
                 {
                  ReverseSetup();
                 }
               break;
            case 2: //sell trade
               if(TotalOrderCount(Symbol(),MagicNumber)==0 && ProtectiveStopPrice>0 && Bid>ProtectiveStopPrice) // Trade closed prematurely.
                 {
                  ReverseSetup();
                 }
            default:
               break;
           }
        }
       */

// Outside Valid Trade Hours && only if it knows about the trade (Ticket > 0)
   if(Ticket>0)
     {
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
         /*case 2:
            tpTrailing20(MagicNumber,Signal,tpTimeStamp,UseSlippage);
            break;*/
         default:
            Print("switch(Signal)");
        }

      switch(StopLossMethod)
        {
         /*case 1:
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
            break;*/
         case 4:
            if(Signal == 1)
               StopLoss = rangelow;
            else
               StopLoss = rangehigh;
            if(slPriceStop(Signal, StopLoss)==True)
              {
               ReverseSetup();
              }
            break;
         default:
            AtomicError("StopLoss Method Not Valid.");
        }
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
//|                                                                  |
//+------------------------------------------------------------------+
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
      //ProtectiveStopPrice=0;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool BuyIt()
  {
   Ticket=OpenBuyOrder(Symbol(),FixedLotSize,UseSlippage,MagicNumber);
   if(Ticket>0)
     {
      if(OrderSelect(Ticket,SELECT_BY_TICKET)==0)
         AtomicError("OrderSelect");

      OpenPrice=OrderOpenPrice();
      TradeStage=3;
      CanTrade=False;

      return(True);
     }
   return(False);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SellIt()
  {
   Ticket=OpenSellOrder(Symbol(),FixedLotSize,UseSlippage,MagicNumber);
   if(Ticket>0)
     {
      if(OrderSelect(Ticket,SELECT_BY_TICKET)==0)
         AtomicError("OrderSelect");

      OpenPrice=OrderOpenPrice();

      TradeStage=3;
      CanTrade=False;

      return(True);
     }
   return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int VerifyInputs()
  {
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   /*if(StopLossMethod<1 && StopLossMethod>4)
     {
      Alert("StopLossMethod is invalid!! Please check settings.");
      return(INIT_FAILED);
     }
   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+
   if(StopLoss<1 && StopLossMethod==2)
     {
      Alert("StopLossMethod 2 selected but no StopLoss has been set.");
      return(INIT_FAILED);
     }
   //+------------------------------------------------------------------+
   //|                                                                  |
   //+------------------------------------------------------------------+
   if(StopLoss>1 && StopLossMethod==1)
     {
      Alert("StopLossMethod 1 (e_slFiveSixtyXOver) selected but FixedStopLoss has been set. Please set FixedStopLoss to 0 or change the StopLossMethod.");
      return(INIT_FAILED);
     }*/

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

   if(StringLen(RangeStartTime)<4)
     {
      Alert("Invalid TradeStartTime length!! Please use format hh:ss.");
      return(INIT_FAILED);
     }

   if(StringLen(RangeEndTime)<4)
     {
      Alert("Invalid TradeEndTime length!! Please use format hh:ss.");
      return(INIT_FAILED);
     }

   if(StringFind(RangeStartTime,":")<0)
     {
      Alert("Invalid TradeStartTime format!! Please use format hh:ss.");
      return(INIT_FAILED);
     }

   if(StringFind(RangeEndTime,":")<0)
     {
      Alert("Invalid TradeEndTime format!! Please use format hh:ss.");
      return(INIT_FAILED);
     }

   if(TotalOrderCount(Symbol(),MagicNumber)>0)
     {
      Alert("Bot already has open trades. This may cause unexpected behaviour. Please close these first and try again.");
      return(INIT_FAILED);
     }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*
bool DoStopProfit()
  {
   if(UseProtectiveStopProfit)
     {
      double ps,pt;
      switch(Signal)
        {
         case 0:
            break;
         case 1:
            ps=CalcBuyStopLoss(Symbol(),StopLoss,OpenPrice);
            pt=CalcBuyTakeProfit(Symbol(),TakeProfit,OpenPrice);
            ps=AdjustBelowStopLevel(Symbol(),ps,0,OpenPrice);
            pt=AdjustAboveStopLevel(Symbol(),pt,0,OpenPrice);
            //PrintFormat("openprice = %G, ps = %G, pt = %G, ticket=%d",OpenPrice,ps,pt,Ticket);
            Sleep(5000); // TODO: Hack as IsTradeContextBusy doesn't work.
            if(AddStopProfit(Ticket,ps,pt))
              {
               ProtectiveStopPrice=pt;
               return(True);
              }
            break;
         case 2:
            ps=CalcSellStopLoss(Symbol(),StopLoss,OpenPrice);
            pt=CalcSellTakeProfit(Symbol(),TakeProfit,OpenPrice);
            ps=AdjustAboveStopLevel(Symbol(),ps,0,OpenPrice);
            pt=AdjustBelowStopLevel(Symbol(),pt,0,OpenPrice);
            //PrintFormat("openprice = %G, ps = %G, pt = %G, ticket=%d",OpenPrice,ps,pt,Ticket);
            Sleep(5000); //TODO: Hack as IsTradeContextBusy doesn't work.
            if(AddStopProfit(Ticket,ps,pt))
              {
               ProtectiveStopPrice=pt;
               return(True);
              }
            break;
         default:
            break;
        }
     }
   return(False);
  }
  */
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateBlock99(color LabelColor,int font_size,int block_count,int step_pixels)
  {
   string Obj;
   for(int i=0; i<block_count; i++)
     {
      Obj=APP_NAME+"block99-"+(i+1);
      if(ObjectFind(Obj)==-1)
         ObjectCreate(Obj,OBJ_LABEL,0,0,0);
      ObjectSetText(Obj,"g",font_size,"Webdings",LabelColor);
      ObjectSet(Obj,OBJPROP_XDISTANCE,85);
      ObjectSet(Obj,OBJPROP_YDISTANCE,80+step_pixels*i);
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
      s=s+" ";
   return(s);
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
   CreateBlock99(DashboardColor,140,1,140);
   string _spaces=extraSpaces(20);
   string s="\n\n\n\n\n\n\n";
   s=s+_spaces+APP_NAME+" v"+APP_VERSION+"\n\n\n";
   s=s+_spaces+"Market " + Symbol() + "\n\n";
   s=s+_spaces+"Spread: " + _SPREAD + " pips\n\n";
   s=s+_spaces+"Lot Size: " + FixedLotSize + "\n\n";
   s=s+_spaces+"MaxSpread "+MaxSpread+"\n\n";
   s=s+_spaces+"TakeProfit "+TakeProfit+"\n\n";
   e_StopLossMethod stopmethod=StopLossMethod;
   s=s+_spaces+"StopLossMethod: "+EnumToString(stopmethod)+"\n\n";
   if(StopLossMethod!=1)
      s=s+_spaces+"StopLoss: "+StopLoss+"\n\n";
//s=s+_spaces+"UseProtectiveStopProfit: "+UseProtectiveStopProfit+"\n";
   s=s+_spaces+"Trade Session: " +  TradeStartTime + " - " + TradeEndTime + "\n\n";
   s=s+_spaces+"Range Breakout Times: " +  RangeStartTime + " - " + RangeEndTime + "\n\n";
   s=s+_spaces+"NumOfReversal Attempts: " + NumOfAttempts + "\n\n";
   //s=s+_spaces+"Total Net Pips Earned: " + NormalizeDouble(TotalPips,2) + "\n\n";
//s=s+_spaces+"Bot Magic Number: " + MagicNumber + "\n\n";
   if(SellTakeProfit>0)
      s=s+_spaces+"Profit Target: "+DoubleToStr(SellTakeProfit,Digits)+"\n\n";
   if(BuyTakeProfit>0)
      s=s+_spaces+"Profit Target: "+DoubleToStr(BuyTakeProfit,Digits)+"\n\n";
   s=s+_spaces+"Candle Will Close In T-"+GetCandleTimer()+"\n\n";
//s=s+_spaces+"Point: " + Point + "\n\n";
//s=s+_spaces+"PipPoint: " + PipPoint(Symbol()) + "\n\n";

   Comment(s);
  }
//+------------------------------------------------------------------+
/* GetCandleTimer()
   Code snippet from https://www.mql5.com/en/forum/157277.
*/
string GetCandleTimer()
  {
   datetime beginOfBar=Time[0];
   datetime endOfBar=beginOfBar+60*_Period;
   return(IntegerToString((int)endOfBar-(int)TimeCurrent())); // Could go negative
  }
//+------------------------------------------------------------------+
