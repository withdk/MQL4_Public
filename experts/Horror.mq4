//+------------------------------------------------------------------+
//|                                                       Horror.mq4 |
//|                                Copyright 2017, David Kierznowski |
//|                                        https://github.com/withdk |
//+------------------------------------------------------------------+

/* Horror Expert Advisor
   A simple bot that allows you place and manage trades through lines and buttons.
   It's fairly customised to the way I trade but it can be easily modified.

   Changelog
   v1.04 Fixed bug where the entry line bid price would not update or unselect.
         Added new method of identifying direction of trade (isBuy/isSell).
         Refactored the buttons code using structs, seems cleaner.
         Cleaned up code a bit and added some comments.
         Added Close Trade, Select lines, + and - buttons for further trade mgmt.
*/

#property copyright "Copyright 2017, David Kierznowski"
#property link      "https://github.com/withdk"
#property version   "1.04"
#property strict

#include <DKSpecialInclude.mqh>

input double FixedLotSize=0.1;
input const color LineColor=Black;
input bool UseTarget=False;
input bool UseBreakEven=True;
input int LineStyle=STYLE_DASH;
extern int MagicNumber=31337;
extern double HorizontalLinePrice;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct buttons_struct
  {
   long              id; // chart id always 0
   string            name; // object name
   int               x; // x coord.
   int               y; // y coord.
   int               w; // button width
   int               h; // button height
   ENUM_BASE_CORNER  corner; // anchor always 0
   string            value; // value of button on screen
  };
buttons_struct BTN[11];

string button_names[]=
  {
   "Button_BuyEntryOnHigh",
   "Button_BuyEntryOnClose",
   "Button_SellEntryOnLow",
   "Button_SellEntryOnClose",
   "Button_BringToBreakEven",
   "Button_CloseTrade",
   "Button_SelectLine",
   "Button_MoveUp",
   "Button_MoveDown",
   "Button_ActEntry",
   "Button_DeactEntry"
  };

string button_vals[]=
  {
   "Buy High",
   "Buy Close",
   "Sell Low",
   "Sell Close",
   "BreakEven",
   "Close Trade",
   "Select Line",
   "+",
   "-",
   "Activate",
   "Deactivate"
  };

int button_x_vals[]=
  {
   0,
   100,
   0,
   100,
   0,
   100,
   0,
   100,
   145,
   0,
   100
  };

int button_y_vals[]=
  {
   20,
   20,
   70,
   70,
   120,
   120,
   170,
   170,
   170,
   220,
   220
  };

// Create array of lines used for easy access
string HorrorLines[]=
  {
   "HLine",
   "StopBLine",
   "StopSLine",
   "TargBLine",
   "TargSLine",
   "BreakEvenBLine",
   "BreakEvenSLine"
  };

static double LastY;
static int UseSlippage;
static int Ticket=0;
static double OpenPrice;
double UsePoint;
bool ValidSetup;
bool isBuy;
bool isSell;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   HorizontalLinePrice=iHigh(NULL,PERIOD_CURRENT,1)+1*UsePoint;
   ObjectCreate("HLine",OBJ_HLINE,0,Time[0],HorizontalLinePrice);
   ObjectSet("HLine",OBJPROP_STYLE,LineStyle);
   ObjectSet("HLine",OBJPROP_COLOR,LineColor);
   ObjectSet("HLine",OBJPROP_WIDTH,1);
   ObjectSetText("HLine","Move to place order",8,"Tahoma",Silver);
   LastY=HorizontalLinePrice;
   UseSlippage=GetSlippage(Symbol(),3);
   UsePoint=PipPoint(Symbol());
   ValidSetup=False;
   isBuy=False;
   isSell=False;
   CreateButtons();
   Print(GetLastError());
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   for(int i=0;i<ArraySize(HorrorLines);i++)
      ObjectDelete(HorrorLines[i]);
   DeleteButtons();
//ObjectsDeleteAll(0);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
// Check if correct objects are still on the chart (TODO: add/check return).
   CheckObjects();

// Get the latest price of the HLine object and update if needed.
   HorizontalLinePrice=ObjectGet("HLine",OBJPROP_PRICE1);

// Prevent taking trades if line is selected and updates HLine price once unselected.
   if(HorizontalLinePrice!=LastY)
     {
      if(ObjectGet("HLine",OBJPROP_SELECTED))
        {
         ObjectSet("HLine",OBJPROP_WIDTH,1);
         ObjectSet("HLine",OBJPROP_STYLE,STYLE_DASH);
        }
      else
        {
         //ObjectSet("HLine",OBJPROP_SELECTED,1);
         ValidSetup=True;
         LastY=HorizontalLinePrice;
        }
     }

// Check and enter trade if parameters are valid.
   if(ValidSetup)
     {
      if(isBuy && Bid>HorizontalLinePrice && !OrderSelect(Ticket,SELECT_BY_TICKET) && !ObjectGet("HLine",OBJPROP_SELECTED) && TotalOrderCount(Symbol(),MagicNumber)==0)
        {
         Print("Opening Buy Trade...");
         BuyIt(); // TODO: add/check return value.
         Print(GetLastError());
         SetStop("StopBLine");
         if(UseTarget)
            SetTarget("StopBLine","TargBLine");
         if(UseBreakEven)
            SetTarget("StopBLine","BreakEvenBLine");
        }
      else if(isSell && Bid<HorizontalLinePrice && !OrderSelect(Ticket,SELECT_BY_TICKET) && !ObjectGet("HLine",OBJPROP_SELECTED) && TotalOrderCount(Symbol(),MagicNumber)==0)
        {
         Print("Opening Sell Trade...");
         SellIt(); // TODO: add/check return value.
         LastY=HorizontalLinePrice;
         Print(GetLastError());
         SetStop("StopSLine");
         if(UseTarget)
            SetTarget("StopSLine","TargSLine");
         if(UseBreakEven)
            SetTarget("StopSLine","BreakEvenSLine");
        }
     }

// If we are in a trade manage it accordingly based on object locations.
   if(Ticket>0)
     {
      if(ObjectGet("TargBLine",OBJPROP_PRICE1)>0)
        {
         if(Bid>ObjectGet("TargBLine",OBJPROP_PRICE1) && !ObjectGet("TargBLine",OBJPROP_SELECTED))
           {
            if(CloseBuyOrder(Symbol(),Ticket,UseSlippage)==False)
               AtomicError("CloseBuyOrder");
            else
               ResetSetup();
           }
        }
      if(ObjectGet("StopBLine",OBJPROP_PRICE1)>0)
        {
         if(Bid<ObjectGet("StopBLine",OBJPROP_PRICE1) && !ObjectGet("StopBLine",OBJPROP_SELECTED))
           {
            Print("StopBLine Hit");
            if(CloseBuyOrder(Symbol(),Ticket,UseSlippage)==False)
               AtomicError("CloseBuyOrder");
            else
               ResetSetup();
           }
        }

      if(ObjectGet("TargSLine",OBJPROP_PRICE1)>0)
        {
         if(Bid<ObjectGet("TargSLine",OBJPROP_PRICE1) && !ObjectGet("TargSLine",OBJPROP_SELECTED))
           {
            if(CloseSellOrder(Symbol(),Ticket,UseSlippage)==False)
               AtomicError("CloseSellOrder");
            else
               ResetSetup();
           }
        }
      if(ObjectGet("StopSLine",OBJPROP_PRICE1)>0)
        {
         if(Bid>ObjectGet("StopSLine",OBJPROP_PRICE1) && !ObjectGet("StopSLine",OBJPROP_SELECTED))
           {
            if(CloseSellOrder(Symbol(),Ticket,UseSlippage)==False)
               AtomicError("CloseSellOrder");
            else
               ResetSetup();
           }
        }

      if(ObjectGet("BreakEvenBLine",OBJPROP_PRICE1)>0)
        {
         if(Bid>=ObjectGet("BreakEvenBLine",OBJPROP_PRICE1) && !ObjectGet("BreakEvenBLine",OBJPROP_SELECTED))
           {
            ObjectSet("StopBLine",OBJPROP_PRICE1,ObjectGet("HLine",OBJPROP_PRICE1));
            ObjectDelete("BreakEvenBLine");
            Print("Price hit breakeven, moving stop.");
           }
        }

      if(ObjectGet("BreakEvenSLine",OBJPROP_PRICE1)>0)
        {
         if(Bid<=ObjectGet("BreakEvenSLine",OBJPROP_PRICE1) && !ObjectGet("BreakEvenSLine",OBJPROP_SELECTED))
           {
            ObjectSet("StopSLine",OBJPROP_PRICE1,ObjectGet("HLine",OBJPROP_PRICE1));
            ObjectDelete("BreakEvenSLine");
            Print("Price hit breakeven, moving stop.");
           }
        }
     }

// Check if trade closed and reset back to default.
   if(TotalOrderCount(Symbol(),MagicNumber)==0 && ((ObjectGet("StopBLine",OBJPROP_PRICE1)>0) || (ObjectGet("StopSLine",OBJPROP_PRICE1)>0)))
     {
      Print("Trade closed out manually, resetting to defaults.\n");
      ResetSetup();
     }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/* ResetSetup()
   If called it resets objects back to defaults.
*/
void ResetSetup()
  {
   Ticket=0;
   for(int i=0;i<ArraySize(HorrorLines);i++)
      ObjectDelete(HorrorLines[i]);
   HorizontalLinePrice=iHigh(NULL,PERIOD_CURRENT,1); // TODO: should be able to remove this code and CheckObjects() will sort this.
   ObjectCreate("HLine",OBJ_HLINE,0,Time[0],HorizontalLinePrice);
   ObjectSetText("HLine","Move to place order",8,"Tahoma",Silver);
   LineDeactivate("HLine");
   LastY=HorizontalLinePrice;
   ValidSetup=False; // This doesn't happen if object is deleted/replaced?
   isBuy=False;
   isSell=False;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/* SetStop()
*/
void SetStop(string stopType)
  {
   if(stopType=="StopBLine")
     {
      ObjectCreate(stopType,OBJ_HLINE,0,Time[0],iLow(NULL,PERIOD_CURRENT,1));
      ObjectSet(stopType,OBJPROP_STYLE,LineStyle);
      ObjectSet(stopType,OBJPROP_COLOR,Red);
      ObjectSet(stopType,OBJPROP_WIDTH,2);
      ObjectSetText(stopType,"Move to place stop order",8,"Tahoma",Silver);
      Print(GetLastError());
     }
   else if(stopType=="StopSLine")
     {
      ObjectCreate(stopType,OBJ_HLINE,0,Time[0],iHigh(NULL,PERIOD_CURRENT,1));
      ObjectSet(stopType,OBJPROP_STYLE,LineStyle);
      ObjectSet(stopType,OBJPROP_COLOR,Red);
      ObjectSet(stopType,OBJPROP_WIDTH,2);
      ObjectSetText(stopType,"Move to place stop order",8,"Tahoma",Silver);
      Print(GetLastError());
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

void SetTarget(string stopType,string targetType)
  {
   double target;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(stopType=="StopBLine")
     {
      target=Bid+(ObjectGet("HLine",OBJPROP_PRICE1)-ObjectGet(stopType,OBJPROP_PRICE1));
      Print("Target initially set to "+string(target));
      ObjectCreate(targetType,OBJ_HLINE,0,Time[0],target);
      ObjectSet(targetType,OBJPROP_STYLE,LineStyle);
      ObjectSet(targetType,OBJPROP_COLOR,Blue);
      ObjectSet(targetType,OBJPROP_WIDTH,2);
      ObjectSetText(targetType,"Move to place target order",8,"Tahoma",Silver);
      Print(GetLastError());
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   else if(stopType=="StopSLine")
     {
      target=Bid-(ObjectGet(stopType,OBJPROP_PRICE1)-ObjectGet("HLine",OBJPROP_PRICE1));
      Print("Target initially set to "+string(target));
      ObjectCreate(targetType,OBJ_HLINE,0,Time[0],target);
      ObjectSet(targetType,OBJPROP_STYLE,LineStyle);
      ObjectSet(targetType,OBJPROP_COLOR,Blue);
      ObjectSet(targetType,OBJPROP_WIDTH,2);
      ObjectSetText(targetType,"Move to place target order",8,"Tahoma",Silver);
      Print(GetLastError());
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetBreakEven(string stopType,string targetType)
  {
   double target;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(stopType=="BreakEvenBLine")
     {
      target=Bid+(ObjectGet("HLine",OBJPROP_PRICE1)-ObjectGet(stopType,OBJPROP_PRICE1));
      Print("Breakeven initially set to "+string(target));
      ObjectCreate(targetType,OBJ_HLINE,0,Time[0],target);
      ObjectSet(targetType,OBJPROP_STYLE,LineStyle);
      ObjectSet(targetType,OBJPROP_COLOR,Blue);
      ObjectSet(targetType,OBJPROP_WIDTH,2);
      ObjectSetText(targetType,"Move to adjust breakeven price",8,"Tahoma",Silver);
      Print(GetLastError());
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   else if(stopType=="BreakEvenSLine")
     {
      target=Bid-(ObjectGet(stopType,OBJPROP_PRICE1)-ObjectGet("HLine",OBJPROP_PRICE1));
      Print("Breakeven initially set to "+string(target));
      ObjectCreate(targetType,OBJ_HLINE,0,Time[0],target);
      ObjectSet(targetType,OBJPROP_STYLE,LineStyle);
      ObjectSet(targetType,OBJPROP_COLOR,Blue);
      ObjectSet(targetType,OBJPROP_WIDTH,2);
      ObjectSetText(targetType,"Move to adjust breakeven price",8,"Tahoma",Silver);
      Print(GetLastError());
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BuyIt()
  {
   Ticket=OpenBuyOrder(Symbol(),FixedLotSize,UseSlippage,MagicNumber);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Ticket>0)
     {
      if(OrderSelect(Ticket,SELECT_BY_TICKET)==0)
         AtomicError("OrderSelect");

      OpenPrice=OrderOpenPrice();
     }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   else
     {
      AtomicError("Ticket");
      BuyIt();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

void SellIt()
  {
   Ticket=OpenSellOrder(Symbol(),FixedLotSize,UseSlippage,MagicNumber);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Ticket>0)
     {
      if(OrderSelect(Ticket,SELECT_BY_TICKET)==0)
         AtomicError("OrderSelect");

      OpenPrice=OrderOpenPrice();
     }
   else
     {
      AtomicError("Ticket");
      BuyIt();
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/* Object verification
   Start of object verification to replace objects if they are removed from chart.
*/
void CheckObjects()
  {
   int i;

   if(ObjectFind("HLine")<0)
     {
      Print("HLine removed, fixing...");
      HorizontalLinePrice=iHigh(NULL,PERIOD_CURRENT,1)+1*UsePoint;
      ObjectCreate("HLine",OBJ_HLINE,0,Time[0],HorizontalLinePrice);
      ObjectSet("HLine",OBJPROP_STYLE,LineStyle);
      ObjectSet("HLine",OBJPROP_COLOR,LineColor);
      ObjectSet("HLine",OBJPROP_WIDTH,1);
      ObjectSetText("HLine","Move to place order",8,"Tahoma",Silver);
      LastY=HorizontalLinePrice;
     }
//TODO: make this into an array for easier management.
   for(i=0;i<ArraySize(BTN);i++)
     {
      if(ObjectFind(BTN[i].name)<0)
        {
         Print("Button removed, fixing...");
         DeleteButtons();
         CreateButtons();
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int AtomicError(string Err)
  {
   Alert(Err," returned the error of ",GetLastError());

   return 0;
  }
//+------------------------------------------------------------------+
/* CreateButtons
*/
void CreateButtons()
  {

/*
   struct buttons_struct
   {
      long id; // chart id always 0
      string name; // object name
      int x; // x coord.
      int y; // y coord.
      int w; // button width
      int h; // button height
      const ENUM_BASE_CORNER corner; // anchor always 0
      string value; // value of button on screen
   };
*/

   int i;

   for(i=0;i<ArraySize(BTN);i++)
     {
      BTN[i].id=0;
      BTN[i].name=button_names[i];
      BTN[i].x=button_x_vals[i];
      BTN[i].y=button_y_vals[i];
      if(BTN[i].name=="Button_MoveUp" || BTN[i].name=="Button_MoveDown")
         BTN[i].w=40;
      else
         BTN[i].w=85;
      BTN[i].h=30;
      BTN[i].corner=0;
      BTN[i].value=button_vals[i];
     }

   for(i=0;i<ArraySize(BTN);i++)
     {
      CreateBtn(
                BTN[i].id,
                BTN[i].name,
                BTN[i].x,
                BTN[i].y,
                BTN[i].w,
                BTN[i].h,
                BTN[i].corner,
                BTN[i].value
                );
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/* DeleteButtons()
*/
void DeleteButtons()
  {
   int i;

   for(i=0;i<ArraySize(BTN);i++)
     {
      ObjectDelete(BTN[i].id,BTN[i].name);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
/*
*/
bool CreateBtn(const long              chart_ID=0,// chart's ID
               const string            name="Button_BuyEntryOnHigh1",// button name
               const int               x=0,// X coordinate
               const int               y=20,// Y coordinate
               const int               width=60,                 // button width
               const int               height=20,                // button height
               const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
               const string            text="Buy",               // text
               const string            font="Arial",// font
               const int               font_size=10,// font size
               const color             clr=White,// text color 
               const color             back_clr=Blue,// background color
               const bool              back=false                // in the background
               )
  {
//--- reset the error value
   ResetLastError();
//--- create the button
   ObjectCreate(chart_ID,name,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(chart_ID,name,OBJPROP_XSIZE,width);
   ObjectSetInteger(chart_ID,name,OBJPROP_YSIZE,height);
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BGCOLOR,back_clr);
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);

//--- successful execution
   return(true);
  }
//+------------------------------------------------------------------+

/* OnChartEvent()
   Primary actions/triggers for onclick events.
*/
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam=="Button_BuyEntryOnHigh")
        {
         ObjectSet("HLine",OBJPROP_PRICE1,iHigh(Symbol(),PERIOD_CURRENT,1)+1*UsePoint);
         LastY=0;
         isBuy=True;
         LineDeactivate("HLine");
         ObjectSetInteger(0,"Button_BuyEntryOnHigh",OBJPROP_STATE,false);
        }
      if(sparam=="Button_SellEntryOnLow")
        {
         ObjectSet("HLine",OBJPROP_PRICE1,iLow(Symbol(),PERIOD_CURRENT,1)-1*UsePoint);
         LastY=0;
         isSell=True;
         LineDeactivate("HLine");
         ObjectSetInteger(0,"Button_SellEntryOnLow",OBJPROP_STATE,false);
        }
      if(sparam=="Button_BuyEntryOnClose")
        {
         ObjectSet("HLine",OBJPROP_PRICE1,iClose(Symbol(),PERIOD_CURRENT,1)+1*UsePoint);
         LastY=0;
         isBuy=True;
         LineDeactivate("HLine");
         ObjectSetInteger(0,"Button_BuyEntryOnClose",OBJPROP_STATE,false);
        }
      if(sparam=="Button_SellEntryOnClose") // SClose
        {
         ObjectSet("HLine",OBJPROP_PRICE1,iClose(Symbol(),PERIOD_CURRENT,1)-1*UsePoint);
         LastY=0;
         isSell=True;
         LineDeactivate("HLine");
         ObjectSetInteger(0,"Button_SellEntryOnClose",OBJPROP_STATE,false);
        }
      if(sparam=="Button_BringToBreakEven")
        {
         if(ObjectGet("StopSLine",0))
            ObjectSet("StopSLine",OBJPROP_PRICE1,ObjectGet("HLine",OBJPROP_PRICE1));
         if(ObjectGet("StopBLine",0))
            ObjectSet("StopBLine",OBJPROP_PRICE1,ObjectGet("HLine",OBJPROP_PRICE1));
         LineDeactivate("HLine");
         ObjectSetInteger(0,"Button_BringToBreakEven",OBJPROP_STATE,false);
        }
      if(sparam=="Button_SelectLine")
        {
         int i;
         int index=0;

         // Get index of currently selected line.
         for(i=0;i<ArraySize(HorrorLines);i++)
           {
            if(ObjectGet(HorrorLines[i],OBJPROP_SELECTED))
              {
               index=i;
               Print("Current line selected "+HorrorLines[i]);
              }
           }

         // If none or last object selected then select the first in array.
         if(index==0 || index==ArraySize(HorrorLines))
           {
            if(!ObjectGet(HorrorLines[0],OBJPROP_SELECTED))
              {
               ObjectSet(HorrorLines[0],OBJPROP_SELECTED,1);
               Print("Start/End using first line "+HorrorLines[0]+" index "+index+" ArraySize(HorrorLines) "+ArraySize(HorrorLines));
              }
            // Deselect current line and increment the index
            else
              {
               ObjectSet(HorrorLines[0],OBJPROP_SELECTED,0);
               index=index+1;
               ObjectSet(HorrorLines[index],OBJPROP_SELECTED,1);
              }
           }
         else
           {
            // Find the next line on chart and select it.
            ObjectSet(HorrorLines[index],OBJPROP_SELECTED,0);
            for(i=index+1;i<ArraySize(HorrorLines);i++)
              {
               if(ObjectGet(HorrorLines[i],0))
                 {
                  ObjectSet(HorrorLines[i],OBJPROP_SELECTED,1);
                  Print("Selected next line "+HorrorLines[i]);
                  break;
                 }
              }
           }
         ObjectSetInteger(0,"Button_SelectLine",OBJPROP_STATE,false);
        }
      if(sparam=="Button_MoveUp")
        {
         int i;

         // Get index of currently selected line.
         for(i=0;i<ArraySize(HorrorLines);i++)
           {
            if(ObjectGet(HorrorLines[i],OBJPROP_SELECTED))
              {
               double currentPrice=ObjectGet(HorrorLines[i],OBJPROP_PRICE1);
               if(currentPrice>0)
                  ObjectSet(HorrorLines[i],OBJPROP_PRICE1,currentPrice+(1*UsePoint));
               //Print("Current line selected "+HorrorLines[i]);
              }
           }
         ObjectSetInteger(0,"Button_MoveUp",OBJPROP_STATE,false);
        }
      if(sparam=="Button_MoveDown")
        {
         int i;

         // Get index of currently selected line.
         for(i=0;i<ArraySize(HorrorLines);i++)
           {
            if(ObjectGet(HorrorLines[i],OBJPROP_SELECTED))
              {
               double currentPrice=ObjectGet(HorrorLines[i],OBJPROP_PRICE1);
               if(currentPrice>0)
                  ObjectSet(HorrorLines[i],OBJPROP_PRICE1,currentPrice-(1*UsePoint));
               //Print("Current line selected "+HorrorLines[i]);
              }
           }
         ObjectSetInteger(0,"Button_MoveDown",OBJPROP_STATE,false);
        }
      if(sparam=="Button_ActEntry")
        {
         LineActivate("HLine");
         ObjectSetInteger(0,"Button_ActEntry",OBJPROP_STATE,false);
        }
      if(sparam=="Button_DeactEntry")
        {
         LineDeactivate("HLine");
         ObjectSetInteger(0,"Button_DeactEntry",OBJPROP_STATE,false);
        }
      if(sparam=="Button_CloseTrade")
        {
         if(TotalOrderCount(Symbol(),MagicNumber)>0)
           {
            Print("isBuy="+isBuy+", isSell="+isSell);
            if(isBuy)
               CloseBuyOrder(Symbol(),Ticket,GetSlippage(Symbol(),3));
            else if(isSell)
               CloseSellOrder(Symbol(),Ticket,GetSlippage(Symbol(),3));
           }
         else
            AtomicError("No trade found, please close manually");
        }
     }
  }
//+------------------------------------------------------------------+

void LineActivate(string aLine)
  {
   ObjectSet(aLine,OBJPROP_STYLE,STYLE_SOLID);
   ObjectSet(aLine,OBJPROP_WIDTH,2);
   ObjectSet(aLine,OBJPROP_SELECTED,0);
  }
//+------------------------------------------------------------------+
void LineDeactivate(string aLine)
  {
   ObjectSet(aLine,OBJPROP_STYLE,STYLE_DASH);
   ObjectSet(aLine,OBJPROP_WIDTH,1);
   ObjectSet(aLine,OBJPROP_SELECTED,1);
   ObjectSet(aLine,OBJPROP_COLOR,LineColor);
  }
//+------------------------------------------------------------------+
