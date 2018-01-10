//+------------------------------------------------------------------+
//|                                                   DK Daily20.mq4 |
//|                                                David Kierznowski |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "David Kierznowski"
#property link      ""

#include <DKSpecialInclude.mqh>
#include <DK-Pivots.mqh>

// External Global Vars
extern string _A_MM                              = "----- Money Mgmt";
extern string MoneyMgmtDynamic                   = "Option 1: Percentage (dynamic)";
extern bool DynamicLotSize                       = false;
extern double EquityPercent                      = 2;
extern string MoneyMgmtFixed                     = "Option 2: Fixed Lot Sizes";
extern double FixedLotSize                       = 0.6;

extern string _A_Stop                            = "----- Option 1: Use FixedStop";
extern double StopLoss                           = 30;   // Daily20: 30

extern string _A_TP                              = "----- TakeProfit Settings";
extern double TakeProfit                         = 20;    // Daily20: 20

extern string _A_EXTRA                           = "How many pips from high/low in order to trigger?";
extern double AddPipsToTrigger                   = 21;   // Daily20: 21
extern double StartHour                          = 5;    // Daily20: 6-GMT (5-DST)
extern double EndHour                            = 17;   // Daily20: 18-GMT (17-DST)
extern double ActivateEntry                      = 18.0;   // Min distance from entry. Taken from method: 18 default

extern string _A_TRADEOPTIONS                    = "Define METHOD variation to use";
extern string _AA_TRADEOPTIONS                   = "METHOD 1: Standard Daily 20 Method: 20.TP/30.SL/21.AddPipsToTrigger/6.TriggerHour(GMT)";
extern bool UseDaily20                           = true;

                                                 // For Buy/Sell Orders
extern string MiscSettings                       = "----- Misc"; 
extern int Slippage                              = 5;
extern int MagicNumber                           = 12345;

// Global Vars
double DailyPivot;
double ActivatedEntry;
bool TradeIsAllowed;
bool SessionLocked;
bool CheckAgain; 
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
     CheckAgain = false;

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
	   
	      // Reset and get ready for the new day!
          TriggerBuyPrice = 0; 
          TriggerSellPrice = 0;
          SessionLocked = false;
          TradeIsAllowed = false;
         
         // Daily20: Get Direction
          if (UseDaily20 == true)
          {
              // Get Pivot Point (00:00 - 00:00)
               double DailyPivot = GetPP();
               Print("UseDaily20 Pivot Price: ", DailyPivot);
               Print("Candle Open price: ", Open[0]);
              // Get "market price" << doc isn't very clear what then means
               double DailyOpen = iOpen(Symbol(),PERIOD_D1,0); 
              
               
               if (DailyOpen > DailyPivot)
               {
                  TriggerBuyPrice = DailyPivot + (AddPipsToTrigger*UsePoint);
                  ActivatedEntry = TriggerBuyPrice - (ActivateEntry*UsePoint);
               }
               else
               {
                  TriggerSellPrice = DailyPivot - (AddPipsToTrigger*UsePoint);
                  ActivatedEntry = TriggerSellPrice + (ActivateEntry*UsePoint);
               }
               
               Print("UseDaily20 breakout target, buy: ", TriggerBuyPrice);
               Print("UseDaily20 breakout target, sell: ", TriggerSellPrice);
               Print("UseDaily20 ActivateEntry: ", ActivatedEntry);
          }

	      // Set current day
	       CurrentDayTimeStamp = iTime(Symbol(),PERIOD_D1,0);
	       
	   }	
         
     // ENTRY XX
     // Execute once each bar open
   	if(CurrentTimeStamp != Time[0]) 
		{
		  
          
         // CheckAgain to test if price has become valid
          if(CheckAgain == true)
          {
           // if(DailyPivot == 
          }
		  
		   // Set current time
		    CurrentTimeStamp = Time[0];
		     
	   } 


      // Daily20 kick off trades
          if (UseDaily20 == true && Hour() >= StartHour && Hour() < EndHour && TradeIsAllowed == false)
          {              
              // Setup Day Trade
		        // Buy only && must be below our price
		         if(TriggerBuyPrice > 0 && Bid < ActivatedEntry)
		         {
		             TradeIsAllowed = true;
		             Print("UseDaily20 breakout target, buy: ", TriggerBuyPrice);
		         }
		        // Sell only && must be above our sell price
		         else if (TriggerSellPrice > 0 && Ask > ActivatedEntry)
		         {
		             TradeIsAllowed = true;
		             Print("UseDaily20 breakout target, sell: ", TriggerSellPrice);
               }
              // No trade if equal
               else
               {
                  // Print("Session not valid, will continue checking each hour till end of session...");
               }
          }
	
	  // Do we potential setups?
	  // ..
	     // Place Buy Order
         if(TriggerBuyPrice > 0 && Bid == TriggerBuyPrice && SessionLocked == false && TradeIsAllowed == true)
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
   	   if(TriggerSellPrice > 0 && Ask < TriggerSellPrice && SessionLocked == false && TradeIsAllowed == true)
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