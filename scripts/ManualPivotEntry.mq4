//+------------------------------------------------------------------+
//|                                           ManualPivotEntry.mq4 |
//|                                Copyright 2017, David Kierznowski |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

/* Calculating pivots for 24-hour markets is fairly easy as we can simply use
   the previous day candle high,low & close. Other markets such as UKX, US30, 
   DAX etc. are not 24-hour markets, so using the previous candle will almost
   always give us the incorrect pivots. Instead we will want to provide the
   previous day values manually using historical data such as those prices
   found on Yahoo historical data, e.g. 
   https://finance.yahoo.com/quote/%5EGDAXI/history?p=%5EGDAXI.
   
   This script simply places the lines on the chart for you saving time before
   a live trading session.
*/

#property copyright "Copyright 2017, David Kierznowski"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property script_show_inputs

//--- input parameters
input double   PreviousHigh;
input double   PreviousLow;
input double   PreviousClose;
input color    LineColor=Black;
input int      LineWidth=1;
input bool     DebugEnable=False;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   double Pivot=((PreviousHigh+PreviousLow+PreviousClose)/3);
   double R1,R2,R3,R4,S1,S2,S3,S4;
   double M0,M1,M2,M3,M4,M5,M6,M7;
   double PivotsArray[17];
   int i;

// Inline with PivotPointCalculator.com
   R1 = (2*Pivot)-PreviousLow;
   S1 = (2*Pivot)-PreviousHigh;
   R2=Pivot+PreviousHigh-PreviousLow;
   S2=Pivot-PreviousHigh+PreviousLow;
   S3 = (Pivot - (2*(PreviousHigh-PreviousLow)));
   R3 = (Pivot + (2*(PreviousHigh-PreviousLow)));
   S4 = (Pivot - (3*(PreviousHigh-PreviousLow)));
   R4 = (Pivot + (3*(PreviousHigh-PreviousLow)));
   M0 = (S4+S3)/2;
   M1 = (S3+S2)/2;
   M2 = (S2+S1)/2;
   M3 = (S1+Pivot)/2;
   M4 = (Pivot+R1)/2;
   M5 = (R1+R2)/2;
   M6 = (R2+R3)/2;
   M7 = (R3+R4)/2;

// Inline with PivotPointCalculator.com
   PivotsArray[0]=Pivot; // Pivot
   PivotsArray[1] = R1; // R1
   PivotsArray[2] = R2; // R2
   PivotsArray[3] = R3; // R3
   PivotsArray[4] = R4; // R4
   PivotsArray[5]= S1;  // S1
   PivotsArray[6] = S2; // S2
   PivotsArray[7] = S3; // S3
   PivotsArray[8] = S4; // S4
   PivotsArray[9] = M0; // M0
   PivotsArray[10] = M1; // M1
   PivotsArray[11] = M2; // M2
   PivotsArray[12] = M3; // M3
   PivotsArray[13] = M4; // M4
   PivotsArray[14] = M5; // M5
   PivotsArray[15] = M6; // M5
   PivotsArray[16] = M7; // M5

   for(i=0;i<ArraySize(PivotsArray);i++)
     {
      string iToStr=IntegerToString(i);
      if(DebugEnable)
         PrintFormat("Setting up pivot ManPivot%s at %G",iToStr,PivotsArray[i]);
      ObjectDelete(0,"ManPivot"+iToStr);
      ObjectCreate("ManPivot"+iToStr,OBJ_HLINE,0,Time[0],PivotsArray[i]);
      ObjectSet("ManPivot"+iToStr,10,false);
      ObjectSet("ManPivot"+iToStr,OBJPROP_COLOR,LineColor);
      ObjectSet("ManPivot"+iToStr,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSet("ManPivot"+iToStr,OBJPROP_WIDTH,LineWidth);
     }

  }
//+------------------------------------------------------------------+
