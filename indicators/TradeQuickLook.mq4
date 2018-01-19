//+------------------------------------------------------------------+
//|                                               TradeQuickLook.mq4 |
//|                                Copyright 2017, David Kierznowski |
//|                                        https://github.com/withdk |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, David Kierznowski"
#property link      "https://github.com/withdk"
#property version   "1.00"
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
*/


double UsePoint;
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

            if(price>HighPrice) // calculate buy target
               target=HighPrice+(HighPrice-LowPrice);
            else
               target=LowPrice-(HighPrice-LowPrice); // else sell
            PrintFormat("bar number=%d, open=%G, high=%G, low=%G, close=%G, target=%G",i,OpenPrice,HighPrice,LowPrice,ClosePrice,target);

            //--- delete lines
            ObjectDelete(0,"V Line");
            ObjectDelete(0,"H Line");
            //--- create horizontal and vertical lines of the crosshair
            ObjectCreate(0,"H Line",OBJ_HLINE,window,dt,target);
            ObjectCreate(0,"V Line",OBJ_VLINE,window,dt,target);
            ChartRedraw(0);
           }
         //--- delete lines
         //ObjectDelete(0,"V Line");
         //ObjectDelete(0,"H Line");
         //--- create horizontal and vertical lines of the crosshair
         //ObjectCreate(0,"H Line",OBJ_HLINE,window,dt,price);
         //ObjectCreate(0,"V Line",OBJ_VLINE,window,dt,price);
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
