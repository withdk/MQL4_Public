//+------------------------------------------------------------------+
//|                                                  PriceAction.mqh |
//|                                Copyright 2017, David Kierznowski |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, David Kierznowski"
#property link      "https://www.mql5.com"
#property strict
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
// #define MacrosHello   "Hello, world!"
// #define MacrosYear    2010
//+------------------------------------------------------------------+
//| DLL imports                                                      |
//+------------------------------------------------------------------+
// #import "user32.dll"
//   int      SendMessageA(int hWnd,int Msg,int wParam,int lParam);
// #import "my_expert.dll"
//   int      ExpertRecalculate(int wParam,int lParam);
// #import
//+------------------------------------------------------------------+
//| EX5 imports                                                      |
//+------------------------------------------------------------------+
// #import "stdlib.ex5"
//   string ErrorDescription(int error_code);
// #import
//+------------------------------------------------------------------+
bool isHammer()
  {
   return(False);
   double k=(High[1]-Low[1])/3;
   if((Open[1]>(Low[1]+2*k)) && (Close[1]>(Low[1]+2*k)))
      return(True);
   return(False);
  }
//+------------------------------------------------------------------+

bool isShootStar()
  {
   return(False);
   double k=(High[1]-Low[1])/3;
   if((Open[1]<(High[1]-2*k)) && (Close[1]<(High[1]-2*k)))
      return(True);
   return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBullEngulf()
  {
   if((Open[2]>Close[2]) && (Close[2]>Low[1]) && (Close[1]>Open[2])) // Relax rule 2 make it Low[1] instead of open Open[1]
      return(True);
   return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBearEngulf()
  {
   if((Close[2]>Open[2]) && (Open[1]>Close[2]) && (High[2]>Close[1])) // Relax rule 2 make it Low[1] instead of open Open[1]
      return(True);
   return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isCandleLtAtr()
  {
   double locSize=MathAbs(High[1]-Low[1]);
   double locAtr=iATR(Symbol(),PERIOD_CURRENT,20,1);

   if(locSize<(locAtr*1.5))
      return(True);
   else
      return(False);

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBullCandle(double shortEma,double prevShortEma)
  {
   if(isHammer())
      return(True);
   else if(isBullEngulf() && isBullPullBack(shortEma,prevShortEma) && isCandleLtAtr())
      return(True);
   else
      return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBearCandle(double shortEma,double prevShortEma)
  {
   if(isShootStar())
      return(True);
   else if(isBearEngulf() && isBearPullBack(shortEma,prevShortEma) && isCandleLtAtr())
      return(True);
   else
      return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBullPullBack(double shortEma,double prevShortEma)
  {
   if(Open[1]<shortEma && Close[1]>shortEma && Close[2]<prevShortEma)
      return(True);
   return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isBearPullBack(double shortEma,double prevShortEma)
  {
   if(Open[1]>shortEma && Close[1] < shortEma && Close[2]>prevShortEma)
      return(True);
   return(False);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void runTester()
  {
   if(isHammer())
      Print("Hammer detected.");
   if(isShootStar())
      Print("Shooting Star detected.");
  }
//+------------------------------------------------------------------+
