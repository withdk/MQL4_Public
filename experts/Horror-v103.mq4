//+------------------------------------------------------------------+
//|                                                       Horror.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, David Kierznowski"
#property link      "https://www.mql5.com"
#property version   "1.03"
#property strict

#include <DKSpecialInclude.mqh>

input double FixedLotSize=0.1;
input color LineColor=Black;
input bool UseTarget=False;
input bool UseBreakEven=True;
input int LineStyle=STYLE_DASH;
extern int MagicNumber=31337;
extern double HorizontalLinePrice;

static double LastY;
static int UseSlippage;
static int Ticket=0;
static double OpenPrice;
double UsePoint;
double PriceAtClick;
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
   PriceAtClick=0;
   CreateBtn(0,"Button_BuyEntryOnHigh1",0,20,60,20,0,"BHigh");
   CreateBtn(0,"Button_BuyEntryOnClose1",70,20,60,20,0,"BClose");

   CreateBtn(0,"Button_SellEntryOnLow1",0,50,60,20,0,"SLow");
   CreateBtn(0,"Button_SellEntryOnClose1",70,50,60,20,0,"SClose");

   CreateBtn(0,"Button_BringToBreakEven",0,80,60,20,0,"BrkEven");
   Print(GetLastError());
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ObjectDelete("HLine");
   ObjectDelete("StopBLine");
   ObjectDelete("StopSLine");
   ObjectDelete("TargBLine");
   ObjectDelete("TargSLine");
   ObjectDelete("BreakEvenBLine");
   ObjectDelete("BreakEvenSLine");
   ObjectDelete("Button_BuyEntryOnHigh1");
   ObjectDelete("Button_SellEntryOnLow1");
   ObjectDelete("Button_BuyEntryOnClose1");
   ObjectDelete("Button_SellEntryOnClose1");
   ObjectDelete("Button_BringToBreakEven");
//ObjectsDeleteAll(0);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(!ObjectGet("HLine",OBJPROP_PRICE1))
     {
      HorizontalLinePrice=iHigh(NULL,PERIOD_CURRENT,1)+1*UsePoint;
      ObjectCreate("HLine",OBJ_HLINE,0,Time[0],HorizontalLinePrice);
      ObjectSet("HLine",OBJPROP_STYLE,LineStyle);
      ObjectSet("HLine",OBJPROP_COLOR,LineColor);
      ObjectSet("HLine",OBJPROP_WIDTH,1);
      ObjectSetText("HLine","Move to place order",8,"Tahoma",Silver);
      LastY=HorizontalLinePrice;
     }

   if(!ObjectGet("Button_BuyEntryOnHigh1",0))
     {
      CreateBtn(0,"Button_BuyEntryOnHigh1",0,20,60,20,0,"BHigh");
     }
   if(!ObjectGet("Button_BuyEntryOnClose1",0))
     {
      CreateBtn(0,"Button_BuyEntryOnClose1",70,20,60,20,0,"BClose");
     }

   if(!ObjectGet("Button_SellEntryOnLow1",0))
     {
      CreateBtn(0,"Button_SellEntryOnLow1",0,50,60,20,0,"SLow");
     }

   if(!ObjectGet("Button_SellEntryOnClose1",0))
     {
      CreateBtn(0,"Button_SellEntryOnClose1",70,50,60,20,0,"SClose");
     }

   if(!ObjectGet("Button_BringToBreakEven",0))
     {
      CreateBtn(0,"Button_BringToBreakEven",0,80,60,20,0,"BrkEven");
     }

   HorizontalLinePrice=ObjectGet("HLine",OBJPROP_PRICE1);
   if(HorizontalLinePrice!=LastY)
     {
      if(ObjectGet("HLine",OBJPROP_SELECTED))
        {
         ObjectSet("HLine",OBJPROP_WIDTH,1);
         ObjectSet("HLine",OBJPROP_STYLE,STYLE_DASH);
        }
      else
        {
         ObjectSet("HLine",OBJPROP_STYLE,STYLE_SOLID);
         ObjectSet("HLine",OBJPROP_WIDTH,2);
        }
      PriceAtClick=Bid;
      LastY=HorizontalLinePrice;
     }

   if(PriceAtClick>0)
     {
      if(PriceAtClick<=HorizontalLinePrice && Bid>HorizontalLinePrice && !OrderSelect(Ticket,SELECT_BY_TICKET) && !ObjectGet("HLine",OBJPROP_SELECTED))
        {
         Print("Opening Buy Trade...");
         BuyIt();
         Print(GetLastError());
         SetStop("StopBLine");
         if(UseTarget)
            SetTarget("StopBLine","TargBLine");
         if(UseBreakEven)
            SetTarget("StopBLine","BreakEvenBLine");
        }
      else if(PriceAtClick>=HorizontalLinePrice && Bid<HorizontalLinePrice && !OrderSelect(Ticket,SELECT_BY_TICKET) && !ObjectGet("HLine",OBJPROP_SELECTED))
        {
         Print("Opening Sell Trade...");
         SellIt();
         LastY=HorizontalLinePrice;
         Print(GetLastError());
         SetStop("StopSLine");
         if(UseTarget)
            SetTarget("StopSLine","TargSLine");
         if(UseBreakEven)
            SetTarget("StopSLine","BreakEvenSLine");
        }
     }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if(Ticket>0)
     {
      if(ObjectGet("TargBLine",OBJPROP_SELECTED))
        {
         ObjectSet("TargBLine",OBJPROP_WIDTH,1);
         ObjectSet("TargBLine",OBJPROP_STYLE,STYLE_DASH);
        }
      else
        {
         ObjectSet("TargBLine",OBJPROP_STYLE,STYLE_SOLID);
         ObjectSet("TargBLine",OBJPROP_WIDTH,2);
        }
      if(ObjectGet("TargSLine",OBJPROP_SELECTED))
        {
         ObjectSet("TargSLine",OBJPROP_WIDTH,1);
         ObjectSet("TargSLine",OBJPROP_STYLE,STYLE_DASH);
        }
      else
        {
         ObjectSet("TargSLine",OBJPROP_STYLE,STYLE_SOLID);
         ObjectSet("TargSLine",OBJPROP_WIDTH,2);
        }

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

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

void ResetSetup()
  {
   Ticket=0;
   ObjectDelete("HLine");
   ObjectDelete("StopBLine");
   ObjectDelete("StopSLine");
   ObjectDelete("TargBLine");
   ObjectDelete("TargSLine");
   ObjectDelete("BreakEvenBLine");
   ObjectDelete("BreakEvenSLine");
   ObjectDelete("Button_BringToBreakEven");
   HorizontalLinePrice=iHigh(NULL,PERIOD_CURRENT,1);
   ObjectCreate("HLine",OBJ_HLINE,0,Time[0],HorizontalLinePrice);
   ObjectSet("HLine",OBJPROP_STYLE,LineStyle);
   ObjectSet("HLine",OBJPROP_COLOR,Black);
   ObjectSet("HLine",OBJPROP_WIDTH,2);
   ObjectSetText("HLine","Move to place order",8,"Tahoma",Silver);
   LastY=HorizontalLinePrice;
   PriceAtClick=0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
int AtomicError(string Err)
  {
   Alert(Err," returned the error of ",GetLastError());

   return 0;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Create the Buy button                                                |
//+------------------------------------------------------------------+
bool CreateBtn(const long              chart_ID=0,// chart's ID
               const string            name="Button_BuyEntryOnHigh1",// button name
               const int               x=0,// X coordinate
               const int               y=20,// Y coordinate
               const int               width=60,                 // button width
               const int               height=20,                // button height
               const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring
               const string            text="Buy",               // text
               const string            font="Courier New",       // font
               const int               font_size=10,             // font size
               const color             clr=clrBlack,             // text color
               const color             back_clr=clrGray,         // background color
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
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam=="Button_BuyEntryOnHigh1")
        {
         ObjectSet("HLine",OBJPROP_PRICE1,iHigh(Symbol(),PERIOD_CURRENT,1)+1*UsePoint);
         ObjectSetInteger(0,"Button_BuyEntryOnHigh1",OBJPROP_STATE,false);
         LastY=0;
        }
      if(sparam=="Button_SellEntryOnLow1")
        {
         ObjectSet("HLine",OBJPROP_PRICE1,iLow(Symbol(),PERIOD_CURRENT,1)-1*UsePoint);
         ObjectSetInteger(0,"Button_Sell",OBJPROP_STATE,false);
         LastY=0;
        }
      if(sparam=="Button_BuyEntryOnClose1")
        {
         ObjectSet("HLine",OBJPROP_PRICE1,iClose(Symbol(),PERIOD_CURRENT,1)+1*UsePoint);
         ObjectSetInteger(0,"Button_Close",OBJPROP_STATE,false);
         LastY=0;
        }
      if(sparam=="Button_SellEntryOnClose1")
        {
         ObjectSet("HLine",OBJPROP_PRICE1,iClose(Symbol(),PERIOD_CURRENT,1)-1*UsePoint);
         ObjectSetInteger(0,"Button_Reverse",OBJPROP_STATE,false);
         LastY=0;
        }
      if(sparam=="Button_BringToBreakEven")
        {
         if(ObjectGet("StopSLine",0))
            ObjectSet("StopSLine",OBJPROP_PRICE1,ObjectGet("HLine",OBJPROP_PRICE1));
         if(ObjectGet("StopBLine",0))
            ObjectSet("StopBLine",OBJPROP_PRICE1,ObjectGet("HLine",OBJPROP_PRICE1));
         ObjectSetInteger(0,"Button_Reverse",OBJPROP_STATE,false);
        }
     }
  }
//+------------------------------------------------------------------+
