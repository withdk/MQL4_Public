//+------------------------------------------------------------------+
//|                                                 Price Action.mq4 |
//|                                                  Jason Normandin |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "Jason Normandin mod by DK"
#property link      ""

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Lime
#property indicator_color2 Red
#property indicator_color3 Black
#property indicator_color4 Black

//We define the periods of the two indicators
input int MASlowPeriod=5;
input ENUM_MA_METHOD MASlowType=MODE_EMA;
input int MAFastPeriod=18;
input ENUM_MA_METHOD MAFastType=MODE_EMA;
input int MAAlertPeriod=62;
input ENUM_MA_METHOD MAAlertType=MODE_EMA;
input bool ShowCircles=True;

double   dBearPriceActionBuffer[];
double   dBullPriceActionBuffer[];
double   dBullMaTouchBuffer[];
double   dBearMaTouchBuffer[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MASlowCurr;
//MASlowPrev is the value of the slow moving average at the last closed candle/bar
double MASlowPrev;
//MAFastCurr is the value of the fast moving average at the current instant
double MAFastCurr;
//MAFastPrev is the value of the fast moving average at the last closed candle/bar
double MAFastPrev;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {

   if(ShowCircles==true)
     {
      
      SetIndexBuffer(0,dBearPriceActionBuffer);
      SetIndexStyle(0,DRAW_ARROW,EMPTY,2);
      SetIndexArrow(0,161);

      SetIndexBuffer(1,dBullPriceActionBuffer);
      SetIndexStyle(1,DRAW_ARROW,EMPTY,2);
      SetIndexArrow(1,161);

      SetIndexBuffer(2,dBullMaTouchBuffer);
      SetIndexStyle(2,DRAW_ARROW,EMPTY,2);
      SetIndexArrow(2,225);
      
      SetIndexBuffer(3,dBearMaTouchBuffer);
      SetIndexStyle(3,DRAW_ARROW,EMPTY,2);
      SetIndexArrow(3,226);
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
      //iMA is the function to get the value of a moving average indicator

      //MASlowCurr is the value of the slow moving average at the current instant
      MASlowCurr=iMA(Symbol(),0,MASlowPeriod,0,MASlowType,PRICE_CLOSE,i);
      //MASlowPrev is the value of the slow moving average at the last closed candle/bar
      MASlowPrev=iMA(Symbol(),0,MASlowPeriod,0,MASlowType,PRICE_CLOSE,i+1);
      //MAFastCurr is the value of the fast moving average at the current instant
      MAFastCurr=iMA(Symbol(),0,MAFastPeriod,0,MAFastType,PRICE_CLOSE,i);
      //MAFastPrev is the value of the fast moving average at the last closed candle/bar
      MAFastPrev=iMA(Symbol(),0,MAFastPeriod,0,MAFastType,PRICE_CLOSE,i+1);

      flagBullishXover(i);
      flagBearishXover(i);
      flagTouchOfMa(i);
      
     }

   return(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool flagBullishXover(int i)
  {

   bool CrossToBuy=false;
   if(MASlowPeriod < 1 || MAFastPeriod < 1)
      return(CrossToBuy);

//We compare the values and detect if one of the crossover has happened
   if(MASlowPrev>MAFastPrev && MAFastCurr>MASlowCurr)
     {
      CrossToBuy=true;
     }
   else
     {
      return(false);
     }

// All criteria passed
   if(ShowCircles)
      dBullPriceActionBuffer[i] = Low[i] - 8*Point;
   return(CrossToBuy);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool flagBearishXover(int i)
  {

//bool CrossToBuy=false;
   bool CrossToSell=false;
   if(MASlowPeriod < 1 || MAFastPeriod < 1)
      return(CrossToSell);

   if(MASlowPrev<MAFastPrev && MAFastCurr<MASlowCurr)
     {
      CrossToSell=true;
     }
   else
     {
      return(false);
     }

// All criteria passed
   if(ShowCircles) 
      dBearPriceActionBuffer[i] = High[i] + 8*Point;
   return(CrossToSell);
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool flagTouchOfMa(int i)
  {

   bool bCondition=false;
   //if(MAAlertPeriod < 1)
   //   return(bCondition);

   double MAAlertCurr=iMA(Symbol(),0,MAAlertPeriod,0,MAAlertType,PRICE_CLOSE,i);
   double MAAlertCurr2=iMA(Symbol(),0,MAAlertPeriod,0,MAAlertType,PRICE_CLOSE,i+1);
   double myAtr = iADX(Symbol(),0,14,PRICE_CLOSE,MODE_MAIN,i);

   if(iHigh(Symbol(),0,i)>MAAlertCurr && iLow(Symbol(),0,i)<MAAlertCurr) //&& myAtr>=40)
     {
      if(iHigh(Symbol(),0,i+1)>MAAlertCurr2 && iLow(Symbol(),0,i+1)<MAAlertCurr2)
         return(false);
      else
         bCondition=true;
      //PlaySound("alert.wav"); // Added sound
     }
   else
     {
      return(false);
     }

   if(ShowCircles)
      if(iClose(Symbol(),0,i+1)>MAAlertCurr2)
         dBullMaTouchBuffer[i] = Low[i] - 50*Point;
      else
         dBearMaTouchBuffer[i] = High[i] + 50*Point;
   return(bCondition);
  }
//+------------------------------------------------------------------+
