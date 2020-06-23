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
bool isTrendCandle(int argBarIndex, bool argBullCandle, bool argBearCandle)
  {

   bool thisOpenCondition;
   bool thisCloseCondition;
   double thisPercentagePrice;
   double thisUpperPercentPrice;
   double thisLowerPercentPrice;
   double thisOpen = iOpen(Symbol(),0,argBarIndex);
   double thisClose = iClose(Symbol(),0,argBarIndex);

   if(argBullCandle)
     {
      thisUpperPercentPrice=20;
      thisLowerPercentPrice=80;
     }
   else
     {
      thisUpperPercentPrice=80;
      thisLowerPercentPrice=20;
     }

   thisPercentagePrice=getPriceOfPercentage(argBarIndex,thisUpperPercentPrice);

   if(thisPercentagePrice > 0)
     {
      if(argBullCandle)
        {
         if(thisOpen <= thisPercentagePrice)
            thisOpenCondition=true;
        }
      if(argBearCandle)
        {
         if(thisOpen >= thisPercentagePrice)
            thisOpenCondition=true;
        }
     }

   thisPercentagePrice=getPriceOfPercentage(argBarIndex,thisLowerPercentPrice);

   if(thisPercentagePrice > 0)
     {
      if(argBullCandle)
        {
         if(thisClose >= thisPercentagePrice)
            thisCloseCondition=true;
        }
      if(argBearCandle)
        {
         if(thisClose <= thisPercentagePrice)
            thisCloseCondition=true;
        }
     }

   if(thisOpenCondition && thisCloseCondition)
      return(true);
   else
      return(false);

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isLongShadowCandle(int argBarIndex, bool argBullCandle, bool argBearCandle)
  {

   bool thisOpenCondition;
   bool thisCloseCondition;
   double thisPercentagePrice;
   double thisUpperPercentPrice;
   double thisLowerPercentPrice;
   double thisOpen = iOpen(Symbol(),0,argBarIndex);
   double thisClose = iClose(Symbol(),0,argBarIndex);
   int thisAtrPeriod=14;
   double thisAtrMultiplier=0.4;

   if(argBullCandle)
     {
      thisUpperPercentPrice=75; // Open should be at the tip.
      thisLowerPercentPrice=60; // Close should also be at tip but cut a little more slack.
     }
   else
     {
      thisUpperPercentPrice=25; // Open should be at the tip
      thisLowerPercentPrice=40; // Close should also be at tip but cut a little more slack.
     }

   thisPercentagePrice=getPriceOfPercentage(argBarIndex,thisUpperPercentPrice, thisAtrPeriod, thisAtrMultiplier);

   if(thisPercentagePrice > 0)
     {
      if(argBullCandle)
        {
         if(thisOpen >= thisPercentagePrice)
            thisOpenCondition=true;
        }
      if(argBearCandle)
        {
         if(thisOpen <= thisPercentagePrice)
            thisOpenCondition=true;
        }
     }

   thisPercentagePrice=getPriceOfPercentage(argBarIndex,thisLowerPercentPrice, thisAtrPeriod, thisAtrMultiplier);

   if(thisPercentagePrice > 0)
     {
      if(argBullCandle)
        {
         if(thisClose >= thisPercentagePrice)
            thisCloseCondition=true;
        }
      if(argBearCandle)
        {
         if(thisClose <= thisPercentagePrice)
            thisCloseCondition=true;
        }
     }

   if(thisOpenCondition && thisCloseCondition)
      return(true);
   else
      return(false);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getPriceOfPercentage(int argBarIndex, int argPercent, int argAtrPeriod=14, double argAtrMultiplier=1)
  {
   double thisHigh = iHigh(Symbol(),0,argBarIndex);
   double thisLow = iLow(Symbol(),0,argBarIndex);
   double thisRange = thisHigh-thisLow;

// Make sure we have a reasonable size candle.
   if(thisRange < (iATR(Symbol(),0,argAtrPeriod,argBarIndex)*argAtrMultiplier))
      return(false);

   if(argPercent > 0)
     {
      double thisUpperPercentPrice = thisLow + (thisRange / 100 * argPercent);
      return(thisUpperPercentPrice);
     }

   return(0);
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool flagBear(int i)
  {

   bool bCondition=false;
   bool bearFlag=true;

   if(isTrendCandle(i+1,0,bearFlag)==false)
      return(false);
   if(isLongShadowCandle(i,0,bearFlag)==false)
      return(false);

   bCondition=true;

   dBearMaTouchBuffer[i] = iHigh(Symbol(),0,i) + 50*Point;

   return(bCondition);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool flagBull(int i)
  {

   bool bCondition=false;
   bool bullFlag=true;

   if(isTrendCandle(i+1,bullFlag,0)==false)
      return(false);
   if(isLongShadowCandle(i,bullFlag,0)==false)
      return(false);

   bCondition=true;

   dBullMaTouchBuffer[i] = iLow(Symbol(),0,i) - 50*Point;

   return(bCondition);
  }
//+------------------------------------------------------------------+
