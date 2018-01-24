//+------------------------------------------------------------------+
//|                                               TradeQuickLook.mq4 |
//|                                Copyright 2017, David Kierznowski |
//|                                        https://github.com/withdk |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, David Kierznowski"
#property link      "https://github.com/withdk"
#property version   "1.02"
#property strict
#property indicator_chart_window

/* TradeQuickLook Indicator
   A simple proof of concept indicator that allows you click on a bar and 
   project an easy to see risk/reward target based on the candle size.
   
   If clicked above the high of the candle the indicator will show a
   crosshair 1x the candle length above the current candle. If below
   it assumes a sell target and shows a sell target.
   
   Changelog
   v1.00 Basic proof of concept.
   v1.01 Add feature to change target using closing prices not high/low.
         Click the same bar twice to adjust. Three times to remove lines.
         Added user defined colours.
   v1.02 Added candle countdown timer.
*/

input bool UseTimer=True;
input color CountDownColor=Blue;
input color VerticalColor=Blue;
input color targ1color=Blue;
input color targ2color=Blue;
input color targ3color=Blue;

double UsePoint;
int itCounter;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
   UsePoint=PipPoint(Symbol());
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   if(UseTimer)
     {
      // Taken from https://www.forexfactory.com/showthread.php?t=326577
      string textname="CountDown";
      ObjectDelete(0,textname);
      ObjectCreate(textname,OBJ_LABEL,0,0,0);
      ObjectSetText(textname,GetCandleTimer(),36,"Corbel Bold",CountDownColor);
      ObjectSet(textname,OBJPROP_CORNER,1);
      ObjectSet(textname,OBJPROP_XDISTANCE,15);
      ObjectSet(textname,OBJPROP_YDISTANCE,1);
     }

//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
/* OnChartEvent()
   Code mainly taken from https://docs.mql4.com/chart_operations/chartxytotimeprice.
*/
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//--- Show the event parameters on the chart
   Comment(__FUNCTION__,": id=",id," lparam=",lparam," dparam=",dparam," sparam=",sparam);
//--- If this is an event of a mouse click on the chart
   if(id==CHARTEVENT_CLICK)
     {
      //--- Prepare variables
      int      x     =(int)lparam;
      int      y     =(int)dparam;
      datetime dt    =0;
      double   price =0;
      int      window=0;
      //--- Convert the X and Y coordinates in terms of date/time
      if(ChartXYToTimePrice(0,x,y,window,dt,price))
        {
         PrintFormat("Window=%d X=%d  Y=%d  =>  Time=%s  Price=%G",window,x,y,TimeToString(dt),price);
         //--- Perform reverse conversion: (X,Y) => (Time,Price)
         if(ChartTimePriceToXY(0,window,dt,price,x,y))
            PrintFormat("Time=%s  Price=%G  =>  X=%d  Y=%d",TimeToString(dt),price,x,y);
         else
            Print("ChartTimePriceToXY return error code: ",GetLastError());

         // We use iBarShift to retrieve the bar shift based on the datetime.
         int i=iBarShift(Symbol(),PERIOD_CURRENT,dt);

         if(i>0)
           {
            double OpenPrice=iOpen(Symbol(),PERIOD_CURRENT,i);
            double HighPrice=iHigh(Symbol(),PERIOD_CURRENT,i);
            double LowPrice=iLow(Symbol(),PERIOD_CURRENT,i);
            double ClosePrice=iClose(Symbol(),PERIOD_CURRENT,i);
            double target;
            double target2;
            double target3;
            double stop=HighPrice-LowPrice;

            if(price>HighPrice) // calculate buy target
              {
               if(itCounter==1)
                 {
                  if(ClosePrice>OpenPrice)
                    {
                     stop=ClosePrice-LowPrice;
                     PrintFormat("stop is %G - %G",ClosePrice,LowPrice);
                     target=ClosePrice+stop;
                     PrintFormat("target is %G + %G + %d",ClosePrice,stop,MODE_SPREAD);
                    }
                  else
                    {
                     stop=OpenPrice-LowPrice;
                     target=OpenPrice+stop;
                    }
                 }
               else
                 {
                  target=HighPrice+stop;
                 }
               target2=target+stop;
               target3=target2+stop;
              }
            else // calculate sell target
              {
               if(itCounter==1)
                 {
                  if(ClosePrice<OpenPrice)
                    {
                     stop=HighPrice-ClosePrice;
                     target=ClosePrice-stop;
                    }
                  else
                    {
                     stop=HighPrice-OpenPrice;
                     target=OpenPrice-stop;
                    }
                 }
               else
                 {
                  target=LowPrice-stop;
                 }
               target2=target-stop;
               target3=target2-stop;
              }
            PrintFormat("bar number=%d, open=%G, high=%G, low=%G, close=%G, stop=%G, target=%G, target2=%G",i,OpenPrice,HighPrice,LowPrice,ClosePrice,stop,target,target2);
            PrintFormat("Candle close in %s seconds",GetCandleTimer());

            //--- delete lines
            ObjectDelete(0,"TQVLine");
            ObjectDelete(0,"TQHLine");
            //ObjectDelete(0,"TQVLine2");
            ObjectDelete(0,"TQHLine2");
            ObjectDelete(0,"TQHLine3");
            //--- create horizontal and vertical lines of the crosshair
            ObjectCreate(0,"TQHLine",OBJ_HLINE,window,dt,target);
            ObjectCreate(0,"TQVLine",OBJ_VLINE,window,dt,target);
            ObjectCreate(0,"TQHLine2",OBJ_HLINE,window,dt,target2);
            ObjectCreate(0,"TQHLine3",OBJ_HLINE,window,dt,target3);
            ObjectSet("TQVLine",OBJPROP_COLOR,VerticalColor);
            ObjectSet("TQHLine",OBJPROP_COLOR,targ1color);
            ObjectSet("TQHLine2",OBJPROP_COLOR,targ2color);
            ObjectSet("TQHLine3",OBJPROP_COLOR,targ3color);
            //ObjectCreate(0,"TQVLine2",OBJ_VLINE,window,dt,target2);
            ChartRedraw(0);
            if(itCounter>2) // 1. i=iBarShift!=itCounter, 2. 
              {
               ObjectDelete(0,"TQVLine");
               ObjectDelete(0,"TQHLine");
               //ObjectDelete(0,"TQVLine2");
               ObjectDelete(0,"TQHLine2");
               ObjectDelete(0,"TQHLine3");
               itCounter=0;
              }
            itCounter=itCounter+1;
           }
         //--- delete lines
         //ObjectDelete(0,"TQVLine");
         //ObjectDelete(0,"TQHLine");
         //--- create horizontal and vertical lines of the crosshair
         //ObjectCreate(0,"TQHLine",OBJ_HLINE,window,dt,price);
         //ObjectCreate(0,"TQVLine",OBJ_VLINE,window,dt,price);
         //ChartRedraw(0);
        }
      else
         Print("ChartXYToTimePrice return error code: ",GetLastError());
      Print("+--------------------------------------------------------------+");
     }
  }
//+------------------------------------------------------------------+
double PipPoint(string Currency)
  {
   double CalcDigits=MarketInfo(Currency,MODE_DIGITS);
   double CalcPoint;

   if(CalcDigits== 2|| CalcDigits == 3)
      CalcPoint = 0.01;
   else if(CalcDigits==4 || CalcDigits==5)
      CalcPoint=0.0001;
   else
      CalcPoint=1; // DK TEST for 0 digits

   return(CalcPoint);
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
