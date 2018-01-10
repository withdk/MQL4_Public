//+------------------------------------------------------------------+
//|                                               DK Day Breaker.mq4 |
//|                                                David Kierznowski |
//|                                                 v1.1             |
//+------------------------------------------------------------------+
// Optimal Settings:
// Still under development
// 1H EURUSD
// SL 40 or 80 pips
// TP 10, 50-90
// AddPips 25, 30

// Interesting results:
// SL    TP    AddPips    Timeframe / MARKET
// 80    10    30         1H / EURUSD (Using Candle Close method, i.e. UseCandleClose = true, UseCounterTend=0);
// 50    10    2          1H  (Using standard breakout, i.e.UseCandleClose = false, UseCounterTend=0);

#property copyright "David Kierznowski"
#property link      ""

#include <DKSpecialInclude.mqh>

// External Global Vars
extern string _A_MM                              = "----- Money Mgmt";
extern string MoneyMgmtDynamic                   = "Option 1: Percentage (dynamic)";
extern bool DynamicLotSize                       = false;
extern double EquityPercent                      = 2;
extern string MoneyMgmtFixed                     = "Option 2: Fixed Lot Sizes";
extern double FixedLotSize                       = 0.6;

extern string _A_Stop                            = "----- Option 1: Use FixedStop";
extern double StopLoss                           = 80;

extern string _A_TP                              = "----- TakeProfit Settings";
extern double TakeProfit                         = 15;

extern string _A_BE                              = "----- Break Even On Profit Settings (0 disable)";
extern double BreakEvenProfit                    = 0;

extern string _A_EXTRA                           = "How many pips from high/low in order to trigger?";
extern double AddPipsToTrigger                   = 30;

extern string _A_TRADEOPTIONS                    = "Define METHOD variation to use";
extern string _AA_TRADEOPTIONS                   = "METHOD 1: Candle Close Breakout, set, UseCandleClose = true";
extern string _AB_TRADEOPTIONS                   = "METHOD 2: Normal breakout, set, UseCandleClose = false and UseCounterTrend = 0";
extern string _AC_TRADEOPTIONS                   = "METHOD 3: Counter trend, set, UseCandleClose = false and UseCounterTrend = 1";
extern bool UseCandleClose                       = false;
extern int UseCounterTrend                       = 0; // 0: disabled, 1: enabled.


                                                 // For Buy/Sell Orders
extern string MiscSettings                       = "----- Misc"; 
extern int Slippage                              = 5;
extern int MagicNumber                           = 12345;

// Global Vars
bool SessionLocked;
double PrevDayHigh, PrevDayLow;
int PrevDayHighTouched, PrevDayLowTouched;
double TriggerBuyPrice;
double TriggerSellPrice;
datetime CurrentTimeStamp;
datetime CurrentDayTimeStamp;
int BuyTicket;
int SellTicket;
double UsePoint;
int UseSlippage;

//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
  {
    // Set current day
    // CurrentDayTimeStamp = iTime(Symbol(),PERIOD_D1,0);
    // Set current Time
     CurrentTimeStamp = Time[0];
    // Set slippage
     UseSlippage = GetSlippage(Symbol(),Slippage);
    // To allow user pips to be added to prices
     UsePoint = PipPoint(Symbol());
    // Open for business
     SessionLocked = false;

     return(0);
  }

//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start()
  {   		    

	  // Execute once at the beginning of each day
	   if(CurrentDayTimeStamp != iTime(Symbol(),PERIOD_D1,0))
	   {
	   
	     	 Print("New day*****************");
	     	 Print("Closing any open trades...");
	     	 // Close buy orders
	       if(BuyMarketCount(Symbol(),MagicNumber) > 0)
			 { 
			      CloseAllBuyOrders(Symbol(),MagicNumber,Slippage);
			 }
			 // Close sell orders
		    if(SellMarketCount(Symbol(),MagicNumber) > 0)
			 { 
			      CloseAllSellOrders(Symbol(),MagicNumber,Slippage);
			 }
	   
	      // Reset and get ready for the new day!
          TriggerBuyPrice = 0; 
          TriggerSellPrice = 0;
          PrevDayHighTouched = 0;
          PrevDayLowTouched = 0;
          SessionLocked = false;
          
         // Set the day high / low trigger points
          PrevDayHigh = iHigh(Symbol(), PERIOD_D1, 1);
          PrevDayLow = iLow(Symbol(), PERIOD_D1,1);
          Print("Day High: ", PrevDayHigh);
          Print("Day Low: ", PrevDayLow);
          
         // ENTRY OPTION 1 & 2
          if (UseCandleClose == false)
          {
           // First standard breakout
            if(UseCounterTrend == 0)
            {
               PrevDayHighTouched = 1;
		         TriggerBuyPrice = PrevDayHigh + (AddPipsToTrigger*UsePoint);
		         Print("Using standard breakout target, buy: ", TriggerBuyPrice);
		         
		         PrevDayLowTouched = 1;
		         TriggerSellPrice = PrevDayLow - (AddPipsToTrigger*UsePoint);
		         Print("Using standard breakout target, sell:: ", TriggerSellPrice);
            }
           // Counter trend
            else if (UseCounterTrend == 1)
            {
               PrevDayHighTouched = 1;
		         TriggerBuyPrice = PrevDayLow - (AddPipsToTrigger*UsePoint);
		         Print("Using standard breakout target, buy: ", TriggerBuyPrice);
		         
		         PrevDayLowTouched = 1;
		         TriggerSellPrice = PrevDayHigh + (AddPipsToTrigger*UsePoint);
		         Print("Using standard breakout target, sell:: ", TriggerSellPrice);
            }
          }

	      // Set current day
	       CurrentDayTimeStamp = iTime(Symbol(),PERIOD_D1,0);
	       
	   }	
         
     // ENTRY OPTION "ONCLOSE"
     // Execute once each bar open
   	if(CurrentTimeStamp != Time[0]) 
		{
		  
		   // Set current time
		    CurrentTimeStamp = Time[0];
		    
		   // Check if previous bar closed above PrevDayHigh / Low
		   if (UseCandleClose == true)
		   {
		       if (Close[1] >= PrevDayHigh && SessionLocked == false && PrevDayHighTouched == 0)
		       {
		          PrevDayHighTouched = 1;
		          TriggerBuyPrice = High[1] + (AddPipsToTrigger*UsePoint);
		          Print("We have a buy close, trigger set at: ", TriggerBuyPrice);
		       }
		       else if (Close[1] <= PrevDayLow && SessionLocked == false && PrevDayLowTouched == 0)
		       {
		          PrevDayLowTouched = 1;
		          TriggerSellPrice = Low[1] - (AddPipsToTrigger*UsePoint);
		          Print("We have a sell close, trigger set at: ", PrevDayLowTouched);
		       }
		   }
		    
	   } 
	   
	  // Implement Breakeven functionality
	  // Bring trade to breakeven if there is one
	   if(BuyMarketCount(Symbol(),MagicNumber) > 0 && BreakEvenProfit > 0)
		{
		    BuyBreakEvenProfit(Symbol(),BreakEvenProfit,MagicNumber);
		}

	   if(SellMarketCount(Symbol(),MagicNumber) > 0 && BreakEvenProfit > 0)
	   {
	        SellBreakEvenProfit(Symbol(),BreakEvenProfit,MagicNumber);
	   }

	
	  // Do we potential setups?
	  // ..
	     // Place Buy Order
         if(TriggerBuyPrice > 0 && Ask > TriggerBuyPrice && SessionLocked == false)
         {
            // Close all sell trades
					  if(SellMarketCount(Symbol(),MagicNumber) > 0)
					  { 
					 		CloseAllSellOrders(Symbol(),MagicNumber,Slippage);
					  }
					  SellTicket = 0;
					  
				 // Dynamic or Fixed
		          double LotSize = CalcLotSize(DynamicLotSize,EquityPercent,StopLoss,FixedLotSize);
					  
				 // Enter Buy Trade
                BuyTicket = OpenBuyOrder(Symbol(),LotSize,UseSlippage,MagicNumber);
                
               // Order modification
					 if(BuyTicket > 0 && (StopLoss > 0 || TakeProfit > 0))
					 {
								OrderSelect(BuyTicket,SELECT_BY_TICKET);
								double OpenPrice = OrderOpenPrice();
				           
				           // Get stop loss price
							   double BuyStopLoss = CalcBuyStopLoss(Symbol(),StopLoss,OpenPrice);
								if(BuyStopLoss > 0) BuyStopLoss = AdjustBelowStopLevel(Symbol(),BuyStopLoss,5);	
					
					        // Get a valid profit target in case of slippage
					         double BuyTakeProfit;
								BuyTakeProfit = CalcBuyTakeProfit(Symbol(),TakeProfit,OpenPrice);

								if(BuyTakeProfit > 0) BuyTakeProfit = AdjustAboveStopLevel(Symbol(),BuyTakeProfit,5);
					
							  // Modify order with stop loss and take profit
								AddStopProfit(BuyTicket,BuyStopLoss,BuyTakeProfit);
					 }
                
                TriggerBuyPrice = 0; // reset session
         }
	     // If touching sell.. sell
   	   if(TriggerSellPrice > 0 && Bid < TriggerSellPrice && SessionLocked == false)
         {
            // Close all buy trades  
                if(BuyMarketCount(Symbol(),MagicNumber) > 0)
					 { 
							CloseAllBuyOrders(Symbol(),MagicNumber,Slippage);
					 }
					 BuyTicket = 0;
					 
				// Dynamic or Fixed
		          LotSize = CalcLotSize(DynamicLotSize,EquityPercent,StopLoss,FixedLotSize);
					 
			   // Enter Sell Trade
					 SellTicket = OpenSellOrder(Symbol(),LotSize,UseSlippage,MagicNumber);
					 
				// Order modification
					 if(SellTicket > 0 && (StopLoss > 0 || TakeProfit > 0))
					 {
								OrderSelect(SellTicket,SELECT_BY_TICKET);
								OpenPrice = OrderOpenPrice();
				           
				           // Get sell stop loss price
							   double SellStopLoss = CalcSellStopLoss(Symbol(),StopLoss,OpenPrice);
								if(SellStopLoss > 0) SellStopLoss = AdjustAboveStopLevel(Symbol(),SellStopLoss,5);	
					
					        // Get a valid profit target in case of slippage
					        double SellTakeProfit;

							  SellTakeProfit = CalcSellTakeProfit(Symbol(),TakeProfit,OpenPrice);

							  if(SellTakeProfit > 0) SellTakeProfit = AdjustBelowStopLevel(Symbol(),SellTakeProfit,5);
					
							  // Modify order with stop loss and take profit
								AddStopProfit(SellTicket,SellStopLoss,SellTakeProfit);
					 }
					 
                TriggerSellPrice = 0; // Reset
         }
   	   
     // End of potential setups

   return(0);
  }
//+------------------------------------------------------------------+