//+------------------------------------------------------------------+
//|                                          Cowabunga- Any Pair.mq4 |
//|                                    by Pipalot, 18th October 2007 |
//|                                                                  |
//| The original Cowabunga indicator was posted by ybop01 and this   |
//| version in as adaption created by Pipalot on 18th October 2007.  |
//| Main changes made since the original version:                    |                            
//|   1. iMACD replaced with iOsMA (MT4's MACD histogram function)   |
//|   2. Turned on the feature to send email alerts                  |
//|   3. Alerts will also now play a sound (email.wav)               |                                   |
//|   3. Changes to enable it to work on any pair (15 minute chart)  |                 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_chart_window
#property indicator_buffers 4
#property indicator_color1 Blue
#property indicator_color2 Red
#property indicator_color3 Blue
#property indicator_color4 Red

extern int IndicatorDisplacement = 15;
extern bool Show_Trend = true;
extern bool Only_Show_Valid_Triggers= true;
extern bool Send_Mail = true;
//---- buffers
double UPTrend[];
double DNTrend[];
double UPTrigger[];
double DNTrigger[];


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- additional buffers are used for counting
   IndicatorBuffers(4);
//---- indicators

   SetIndexLabel(0,"UP TREND");
   SetIndexLabel(1,"DOWN TREND");
   SetIndexLabel(2,"UP ARROW");
   SetIndexLabel(3,"DOWN ARROW");
   
   if((Period()==PERIOD_M15))
      {
      SetIndexStyle(0,DRAW_LINE,STYLE_DOT,1,Blue);
      SetIndexStyle(1,DRAW_LINE,STYLE_DOT,1,Red);
      }
   else
      {
      SetIndexStyle(0,DRAW_LINE,0,3,Blue);
      SetIndexStyle(1,DRAW_LINE,0,3,Red);
      }
   SetIndexStyle(2,DRAW_ARROW,EMPTY,3,Blue);
   SetIndexStyle(3,DRAW_ARROW,EMPTY,3,Red);
   SetIndexArrow(2,SYMBOL_ARROWUP);
   SetIndexArrow(3,SYMBOL_ARROWDOWN);
   SetIndexBuffer(0,UPTrend);
   SetIndexBuffer(1,DNTrend);
   SetIndexBuffer(2,UPTrigger);
   SetIndexBuffer(3,DNTrigger);

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
//----
   
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
   {
   int maCross,StochCHANGE,maCross4H,StochCHANGE4H,MACDChange,i,counted_bars=IndicatorCounted();
   double ma5now,ma10now,ma5prev,ma10prev,ma5now4H,ma10now4H,ma5prev4H,ma10prev4H;
   double RSI,Stoch1,Stoch2,Signal1,Signal2,MACDChange1,MACDChange2,RSI4H,Stoch4H1,Stoch4H2,Signal4H1,Signal4H2;
   int Trigger,i4h;
   static int TrendON;
   bool Period15m,MACDEnable;
   string text,CRLF;   
      
   CRLF=CharToStr(13) + CharToStr(10);
   
   Period15m=(Period()==PERIOD_M15);
   if(Period15m) MACDEnable=true;          

   if(Bars<=100) return(0);
  //---- check for possible errors
     if(counted_bars<0) return(-1);
  //---- the last counted bar will be recounted
   if(counted_bars>0) counted_bars--;
   i=Bars-counted_bars;

   while(i>=0)
      {
                        //---- TREND4H
      i4h=iBarShift(NULL,PERIOD_H4,iTime(NULL,0,i),true)+1;
      ma5now4H=iMA(NULL,PERIOD_H4,5,0,MODE_EMA,PRICE_CLOSE,i4h);
      ma10now4H=iMA(NULL,PERIOD_H4,10,0,MODE_EMA,PRICE_CLOSE,i4h);  
      ma5prev4H=iMA(NULL,PERIOD_H4,5,0,MODE_EMA,PRICE_CLOSE,i4h+1);
      ma10prev4H=iMA(NULL,PERIOD_H4,10,0,MODE_EMA,PRICE_CLOSE,i4h+1);
      if(ma5now4H > ma5prev4H && ma10now4H > ma10prev4H && ma5prev4H < ma10prev4H && ma5now4H > ma10now4H) maCross4H=1;
      else if(ma5now4H < ma5prev4H && ma10now4H < ma10prev4H && ma5prev4H > ma10prev4H && ma5now4H < ma10now4H) maCross4H=2;
      else maCross4H=0;
      RSI4H= iRSI(NULL,PERIOD_H4,9,PRICE_CLOSE,i4h);
      Stoch4H1= iStochastic(NULL,PERIOD_H4,10,3,3,MODE_SMA,0,MODE_MAIN,i4h);
      Stoch4H2= iStochastic(NULL,PERIOD_H4,10,3,3,MODE_SMA,0,MODE_MAIN,i4h+1);
      Signal4H1= iStochastic(NULL,PERIOD_H4,10,3,3,MODE_SMA,0,MODE_SIGNAL,i4h);
      Signal4H2= iStochastic(NULL,PERIOD_H4,10,3,3,MODE_SMA,0,MODE_SIGNAL,i4h+1);
      if(Stoch4H1>Stoch4H2 && Signal4H1>Signal4H2) StochCHANGE4H=1;
      else if(Stoch4H1<Stoch4H2 && Signal4H1<Signal4H2) StochCHANGE4H=2;
      else StochCHANGE4H=0;

      if((maCross4H==1) && (RSI4H>50) && (StochCHANGE4H==1)) TrendON=1;
      if((maCross4H==2) && (RSI4H<50) && (StochCHANGE4H==2)) TrendON=-1;

      if(Show_Trend)
         {
         if(TrendON==1) UPTrend[i]= High[i]+IndicatorDisplacement*Point;
         if(TrendON==-1) DNTrend[i]= Low[i]-IndicatorDisplacement*Point;         
         }
      
      if(Period15m)
         {
               //---- TRIGGERS
         ma5now=iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,i);
         ma10now=iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,i);  
         ma5prev=iMA(NULL,0,5,0,MODE_EMA,PRICE_CLOSE,i+1);
         ma10prev=iMA(NULL,0,10,0,MODE_EMA,PRICE_CLOSE,i+1);
         if(ma5now > ma5prev && ma10now > ma10prev && ma5prev < ma10prev && ma5now > ma10now) maCross=1;
         else if(ma5now < ma5prev && ma10now < ma10prev && ma5prev > ma10prev && ma5now < ma10now) maCross=2;
         else maCross=0;
         RSI= iRSI(NULL,0,9,PRICE_CLOSE,i);
         Stoch1= iStochastic(NULL,0,10,3,3,MODE_SMA,0,MODE_MAIN,i);
         Stoch2= iStochastic(NULL,0,10,3,3,MODE_SMA,0,MODE_MAIN,i+1);
         Signal1= iStochastic(NULL,0,10,3,3,MODE_SMA,0,MODE_SIGNAL,i);
         Signal2= iStochastic(NULL,0,10,3,3,MODE_SMA,0,MODE_SIGNAL,i+1);
         if(Stoch1>Stoch2 && Signal1>Signal2) StochCHANGE=1;
         else if(Stoch1<Stoch2 && Signal1<Signal2) StochCHANGE=2;
         else StochCHANGE=0;
         
         //MACDChange1=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,i);
         MACDChange1=iOsMA(NULL,0,12,26,9,PRICE_CLOSE,i);
         //MACDChange2=iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,i+1);
         MACDChange2=iOsMA(NULL,0,12,26,9,PRICE_CLOSE,i+1);
         
         if(MACDChange2<0 && MACDChange2<MACDChange1) MACDChange=1;
         else if(MACDChange2>0 && MACDChange2>MACDChange1) MACDChange=2;
         else MACDChange=0;

         if((maCross==1) && (RSI>50) && (StochCHANGE==1) && (MACDChange==1) && ((TrendON==1)||(Only_Show_Valid_Triggers==false))) Trigger=1;
         if((maCross==2) && (RSI<50) && (StochCHANGE==2) && (MACDChange==2) && ((TrendON==-1)||(Only_Show_Valid_Triggers==false))) Trigger=2;
     
         if(Trigger==1) UPTrigger[i]= High[i]+10*Point;
         if(Trigger==2) DNTrigger[i]= Low[i]-10*Point;
         
         if((Trigger>0)&&(Send_Mail) && (TimeYear(Time[i])>=Year())&&(TimeMonth(Time[i])>=Month())&&(TimeDay(Time[i])>=Day())&&(TimeHour(Time[i])>=Hour())&&(TimeMinute(Time[i])>=Minute()))
            {
            if(Trigger==1) text="BUY ";
            else text="SELL ";
            text=text + "trigger occurred on " +TimeDay(Time[i])+"/"+TimeMonth(Time[i])+"/"+TimeYear(Time[i])+" at "+TimeHour(Time[i])+":"+TimeMinute(Time[i]) + "  (server time)" + CRLF;
            text=text + CRLF + CRLF;
            
            text=text + "Trend is ";
            if(TrendON==1) text=text + "UP" + CRLF + CRLF;
            else text=text + "DOWN" + CRLF + CRLF;
            text = text +"MA5 = " + ma5now + CRLF;
            text = text +"MA10 = " + ma10now + CRLF;
            text = text +"MA5 Previous Bar = " + ma5prev + CRLF;
            text = text +"MA10 Previous Bar = " + ma10prev + CRLF;
            text = text +"RSI = " + RSI + CRLF;
            text = text +"STOCHASTIC MAIN = " + Stoch1 + CRLF;
            text = text +"STOCHASTIC SIGNAL = " + Signal1 + CRLF;
            text = text +"STOCHASTIC MAIN Previous Bar = " + Stoch2 + CRLF;
            text = text +"STOCHASTIC SIGNAL Previous Bar = " + Signal2 + CRLF;            
            text = text +"MACD = " + MACDChange1 + CRLF;
            text = text +"MACD Previous Bar = " + MACDChange2 + CRLF;
            
            SendMail("COWABUNGA Trigger " + Symbol(),text);
            PlaySound("email.wav");
            Print(text);
            Send_Mail=false;
            }
         /*if(Trigger>0)
            {
            Print(TimeDay(Time[i])+"/"+TimeMonth(Time[i])+"/"+TimeYear(Time[i])+" at "+TimeHour(Time[i])+":"+TimeMinute(Time[i]));
            Print(Day()+"/"+Month()+"/"+Year()+" at "+Hour()+":"+Minute());
            Print(Send_Mail);
            }*/
            
         }
      Trigger=0;
      i--;
      }
   return(0);
   }
//+-----------------------------------------------------------------+