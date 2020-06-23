//+------------------------------------------------------------------+
//|                                                 Price Action.mq4 |
//|                                                  Jason Normandin |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "Jason Normandin mod by DK"
#property link      ""

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_color1 Lime
#property indicator_color2 Red

//We define the periods of the two indicators
input int MASlowPeriod=5;
input ENUM_MA_METHOD MASlowType=MODE_EMA;
input int MAFastPeriod=18;
input ENUM_MA_METHOD MAFastType=MODE_EMA;
input int MAAlertPeriod=62;
input ENUM_MA_METHOD MAAlertType=MODE_EMA;
input bool ShowCircles=True;

double   dBullMaTouchBuffer[];
double   dBearMaTouchBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {

   if(ShowCircles==true)
     {
      SetIndexBuffer(0,dBullMaTouchBuffer);
      SetIndexStyle(0,DRAW_ARROW,EMPTY,2);
      SetIndexArrow(0,225);

      SetIndexBuffer(1,dBearMaTouchBuffer);
      SetIndexStyle(1,DRAW_ARROW,EMPTY,2);
      SetIndexArrow(1,226);
     }

   return(0);
  }


//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {

   return(0);

  }


//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {

// Number of bars already processed.
// Always reprocess the last completed bar
   int      iBarsCalced = IndicatorCounted();
   if(iBarsCalced > 0)
      iBarsCalced--;

// Iterate through bars checking for patterns
// Do not process last incomplete bar
   for(int i=Bars-iBarsCalced-1; i>0; i--)
     {

      flagBull(i);
      flagBear(i);

     }

   return(0);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool flagBear(int i)
  {

   bool bCondition=false;
   double CurrHigh = iHigh(Symbol(),PERIOD_D1,i);

   double UpperPercent=80; // open and close in upper/lower 20%
   double LowerPercent=20;

   double PrevOpen = iOpen(Symbol(),PERIOD_D1,i+1);
   double PrevHigh = iHigh(Symbol(),PERIOD_D1,i+1);
   double PrevLow = iLow(Symbol(),PERIOD_D1,i+1);
   double PrevClose = iClose(Symbol(),PERIOD_D1,i+1);
   double PrevRange = PrevHigh-PrevLow;
   double UpperPercentPrice = PrevLow + (PrevRange / 100 * UpperPercent);
   double LowerPercentPrice = PrevLow + (PrevRange / 100 * LowerPercent);
   bool LowerCheck;
   bool UpperCheck;

   if(PrevRange < (iATR(Symbol(),PERIOD_D1,14,i+1+1)*1.5))
      return(false);

   if(CurrHigh < PrevHigh)
      return(false);

   if(PrevOpen <= LowerPercentPrice)
      LowerCheck=True;
   else
      return(false);

   if(PrevClose >= UpperPercentPrice)
      UpperCheck=True;
   else
      return(false);

   bCondition=true;

//if(ShowCircles)
//if(iClose(Symbol(),0,i+1)>MAAlertCurr2)
   dBearMaTouchBuffer[i] = iHigh(Symbol(),PERIOD_D1,i) + 50*Point;
//else
//dBearMaTouchBuffer[i] = High[i] + 50*Point;
   return(bCondition);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool flagBull(int i)
  {

   bool bCondition=false;
   double CurrLow = iLow(Symbol(),PERIOD_D1,i);

   double UpperPercent=80; // open and close in upper/lower 20%
   double LowerPercent=20;


   double PrevOpen = iOpen(Symbol(),PERIOD_D1,i+1);
   double PrevHigh = iHigh(Symbol(),PERIOD_D1,i+1);
   double PrevLow = iLow(Symbol(),PERIOD_D1,i+1);
   double PrevClose = iClose(Symbol(),PERIOD_D1,i+1);
   double PrevRange = PrevHigh-PrevLow;
   double UpperPercentPrice = PrevLow + (PrevRange / 100 * UpperPercent);
   double LowerPercentPrice = PrevLow + (PrevRange / 100 * LowerPercent);
   bool LowerCheck;
   bool UpperCheck;

   if(PrevRange < (iATR(Symbol(),PERIOD_D1,14,i+1)*1.5))
      return(false);

   if(CurrLow > PrevLow)
      return(false);

   if(PrevOpen >= UpperPercentPrice)
      LowerCheck=True;
   else
      return(false);

   if(PrevClose <= LowerPercentPrice)
      UpperCheck=True;
   else
      return(false);

   bCondition=true;

//if(ShowCircles)
//if(iClose(Symbol(),0,i+1)>MAAlertCurr2)
   dBullMaTouchBuffer[i] = iLow(Symbol(),PERIOD_D1,i) - 50*Point;
//else
//dBearMaTouchBuffer[i] = High[i] + 50*Point;
   return(bCondition);
  }
//+------------------------------------------------------------------+
