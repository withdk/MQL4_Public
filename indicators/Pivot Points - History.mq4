//+------------------------------------------------------------------+
//|                                          Day Range Highlight.mq4 |
//|                      Copyright © 2009, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net"

#property indicator_chart_window

//---- input parameters
extern int  PeriodsToPlot= 200;   
extern bool Hourly  = true;
extern bool FourHourly = false;
extern bool Daily   = false;
extern bool Weekly  = false;
extern bool Monthly = false;
extern bool Yearly = false;
extern bool PivotAverage = false;
extern int NumPivotsToAve = 3;
extern color PPAveColour = Blue;
extern bool Alarm = false;
extern bool PredictedPivot = false;
extern color ExtremeSupportColour = LightGreen;
extern color ExtremeResistanceColour = LightCoral;

double Buf_CPP_MA[200];

double PreviousHigh;
double PreviousLow;
double PreviousClose;
double Period_Price[][6];
double Pivot,S1,S2,S3,R1,R2,R3,M0,M1,M2,M3,M4,M5;
int PeriodCode;
int PeriodBuffer;
string PeriodLabel;
double PPAverage;
double CPP;
string Direction;
double PreviousPeriodClose;
double PredictedCPP;
string DTofAlert = "NULL";

double Poin;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   Poin = Point;
	//Checking for unconvetional Point digits number
   if ((Point == 0.00001) || (Point == 0.001))
   {
      Poin *= 10;
   }
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   for(int i=0; i<=PeriodsToPlot; i++)
   {
      ObjectDelete("R2M4" + i);
      ObjectDelete("R1" + i);
      ObjectDelete("M3" + i);
      ObjectDelete("PP" + i);
      ObjectDelete("M2" + i);
      ObjectDelete("S1" + i);
      ObjectDelete("M1S2" + i);
      ObjectDelete("R3" + i);
      ObjectDelete("M5" + i);
      ObjectDelete("M0" + i);
      ObjectDelete("S3" + i);
      ObjectDelete("RangeBox" + i);
      ObjectDelete("PPAverage" + i);
   }
   
   ObjectDelete("PivotLabel");

   ObjectDelete("R1_Label");
   ObjectDelete("R2_Label");
   ObjectDelete("R3_Label");

   ObjectDelete("S1_Label");
   ObjectDelete("S2_Label");
   ObjectDelete("S3_Label"); 

   ObjectDelete("M0_Label");  
   ObjectDelete("M1_Label");
   ObjectDelete("M2_Label");  
   ObjectDelete("M3_Label");  
   ObjectDelete("M4_Label");
   ObjectDelete("M5_Label"); 

   ObjectDelete("PPAverage");
   ObjectDelete("PredictedCPP");
   
   return(0);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
  {
   deinit();
   
   if(Alarm)
      Comment("Pivot Alarm On");
   else
      Comment("");      
      
   if(Hourly==true)
   {
      PeriodCode = 60;
      PeriodLabel = "H";
      PeriodBuffer = 3600;
   }
   else if(FourHourly==true)
   {
      PeriodCode = 240;
      PeriodLabel = "4H";
      PeriodBuffer = 14400;

   }
   else if(Daily==true)
   {
      PeriodCode = 1440;
      PeriodLabel = "D";
      PeriodBuffer = 86400;
   }
   else if (Weekly==true)
   {
      PeriodCode = 10080;
      PeriodLabel = "W";
      PeriodBuffer = 604800;
   }
   else if (Monthly==true)
   {
      PeriodCode = 43200;
      PeriodLabel = "M";
      PeriodBuffer = 2629743;
   }
   else
   {
      //Yearly
      PeriodCode = 43200;
      PeriodLabel = "Y";
      PeriodBuffer = 15778380;
   }
            
   //ArrayInitialize(Period_Price,0);
   ArrayCopyRates(Period_Price,(Symbol()), PeriodCode);
   
   if(Yearly)
      PeriodsToPlot = 3;
   
   for(int i=0; i <= PeriodsToPlot; i++)
   {
       if(Yearly)
         {
            int year = Year() - (i+1);
            double close,high,low=10000;
            for (int x=0;x<60;x++)
            {
               if(TimeYear(Period_Price[x][0]) == year)
               {
                  if(Period_Price[x][3] > high)
                     high = Period_Price[x][3];
                  if(Period_Price[x][2] < low)
                     low = Period_Price[x][2];
                  if (TimeMonth(Period_Price[x][0]) == 12)
                     close = Period_Price[x][4];       
            
               }
            }
            PreviousHigh  = high;
            PreviousLow   = low;
            PreviousClose = close;
          }
      else
      {   
         PreviousHigh  = Period_Price[i+1][3];
         PreviousLow   = Period_Price[i+1][2];
         PreviousClose = Period_Price[i+1][4];
      }
      Pivot = ((PreviousHigh + PreviousLow + PreviousClose)/3);
      PredictedCPP = ((Period_Price[0][3] + Period_Price[0][2] + Period_Price[0][4]) / 3);

      R1 = (2*Pivot)-PreviousLow;
      S1 = (2*Pivot)-PreviousHigh;
      //R2 = Pivot+(R1-S1);
      R2 = Pivot + PreviousHigh - PreviousLow;
      //S2 = Pivot-(R1-S1);
      S2 = Pivot - PreviousHigh + PreviousLow;
      S3 = (PreviousLow - (2*(PreviousHigh-Pivot)));
      R3 = (PreviousHigh + (2*(Pivot-PreviousLow)));
      M0 = (S3+S2)/2;
      M1 = (S2+S1)/2;
      M2 = (S1+Pivot)/2;
      M3 = (Pivot+R1)/2;
      M4 = (R1+R2)/2;
      M5 = (R2+R3)/2; 

 
      if(i==0)
      {
         if(Yearly)
            ObjectCreate("PP"+i, OBJ_TREND,0,StrToTime((year + 1) + ".12.31 23:59") ,Pivot);
         else
            ObjectCreate("PP"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,Pivot);
         ObjectSet("PP"+i,10,false);
         ObjectSet("PP"+i, OBJPROP_COLOR, Black);
         ObjectSet("PP"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("PP"+i,OBJPROP_WIDTH,3);
         if(Yearly)
            ObjectSet("PP"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("PP"+i,2,Period_Price[i][0]);
         ObjectSet("PP"+i,3,Pivot);

         if(ObjectFind("PivotLabel") != 0)
         {
            ObjectCreate("PivotLabel", OBJ_TEXT, 0, Time[i] + (PeriodCode * 4), Pivot);
            ObjectSetText("PivotLabel", "                    " + PeriodLabel + "PP " +DoubleToStr(Pivot,4), 8, "Arial", Black);
         }
         else
         {
            ObjectMove("PivotLabel", 0, Time[i] + (PeriodCode * 4), Pivot);
         }
         
        if(PredictedPivot)
        {
            ObjectCreate("PredictedCPP", OBJ_TREND,0, Period_Price[i][0],PredictedCPP);
            ObjectSet("PredictedCPP",10,false);
            ObjectSet("PredictedCPP", OBJPROP_COLOR, Black);
            ObjectSet("PredictedCPP", OBJPROP_STYLE, STYLE_DASH);
            ObjectSet("PredictedCPP",OBJPROP_WIDTH,1);
            ObjectSet("PredictedCPP",2,Period_Price[i][0] + PeriodBuffer);
            ObjectSet("PredictedCPP",3,PredictedCPP);
            ObjectSetText("PredictedCPP","P. CPP");
         }   
         
         if(Yearly)
            ObjectCreate("M3"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),M3);
         else
            ObjectCreate("M3"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,M3);
         ObjectSet("M3"+i,10,false);
         ObjectSet("M3"+i, OBJPROP_COLOR, Red);
         ObjectSet("M3"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("M3"+i,OBJPROP_WIDTH,1);
         if(Yearly)
            ObjectSet("M3"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("M3"+i,2,Period_Price[i][0]);
         ObjectSet("M3"+i,3,M3);

         if(ObjectFind("M3_Label") != 0)
         {
            ObjectCreate("M3_Label", OBJ_TEXT, 0, Time[i] + (PeriodCode * 4), M3);
            ObjectSetText("M3_Label", "                    " + PeriodLabel + "M3 " +DoubleToStr(M3,4), 8, "Arial", Red);
         }
         else
         {
            ObjectMove("M3_Label", 0, Time[i] + (PeriodCode * 4), M3);
         }

         if(Yearly)
            ObjectCreate("R1"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),R1);
         else
            ObjectCreate("R1"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,R1);
         ObjectSet("R1"+i,10,false);
         ObjectSet("R1"+i, OBJPROP_COLOR, Red);
         ObjectSet("R1"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("R1"+i,OBJPROP_WIDTH,2);
         if(Yearly)
            ObjectSet("R1"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else   
            ObjectSet("R1"+i,2,Period_Price[i][0]);
         ObjectSet("R1"+i,3,R1);


         if(ObjectFind("R1_Label") != 0)
         {
            ObjectCreate("R1_Label", OBJ_TEXT, 0, Time[i] + (PeriodCode * 4), R1);
            ObjectSetText("R1_Label", "                    " + PeriodLabel + "R1 " +DoubleToStr(R1,4), 8, "Arial", Red);
         }
         else
         {
            ObjectMove("R1_Label", 0, Time[i] + (PeriodCode * 4), R1);
         }

         if(Yearly)
            ObjectCreate("R2M4" + i,OBJ_RECTANGLE,0,StrToTime((year + 1) + ".01.01 00:00"),M4);
         else
            ObjectCreate("R2M4" + i,OBJ_RECTANGLE,0,Period_Price[i][0],M4);
         if(Yearly)
            ObjectSet("R2M4" + i,2,StrToTime((year + 1) + ".12.31 23:59"));
         else
            ObjectSet("R2M4" + i,2,Period_Price[i][0] + PeriodBuffer);
         ObjectSet("R2M4" + i,3,R2);
         ObjectSet("R2M4" + i,6,ExtremeResistanceColour);


         if(ObjectFind("M4_Label") != 0)
         {
            ObjectCreate("M4_Label", OBJ_TEXT, 0, Time[i] + (PeriodCode * 4), M4);
            ObjectSetText("M4_Label", "                    " + PeriodLabel + "M4 " +DoubleToStr(M4,4), 8, "Arial", Red);
         }
         else
         {
            ObjectMove("M4_Label", 0, Time[i] + (PeriodCode * 4), M4);
         }

         if(ObjectFind("R2_Label") != 0)
         {
            ObjectCreate("R2_Label", OBJ_TEXT, 0, Time[i] + (PeriodCode * 4), R2);
            ObjectSetText("R2_Label", "                    " + PeriodLabel + "R2 " +DoubleToStr(R2,4), 8, "Arial", Black);
         }
         else
         {
            ObjectMove("R2_Label", 0, Time[i] + (PeriodCode * 4), R2);
         }

		   if(Yearly)
		       ObjectCreate("R3"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),R3);
		   else
		       ObjectCreate("R3"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,R3);
         ObjectSet("R3"+i,10,false);
         ObjectSet("R3"+i, OBJPROP_COLOR, Red);
         ObjectSet("R3"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("R3"+i,OBJPROP_WIDTH,2);
         if(Yearly)
            ObjectSet("R3"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("R3"+i,2,Period_Price[i][0]);   
         ObjectSet("R3"+i,3,R3);


         if(ObjectFind("R3_Label") != 0)
         {
            ObjectCreate("R3_Label", OBJ_TEXT, 0, Time[i] + (PeriodCode * 4), R3);
            ObjectSetText("R3_Label", "                    " + PeriodLabel + "R3 " +DoubleToStr(R3,4), 8, "Arial", Red);
         }
         else
         {
            ObjectMove("R3_Label", 0, Time[i] + (PeriodCode * 4), R3);
         }
		 
         if(Yearly)
            ObjectCreate("M2"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),M2);
         else
            ObjectCreate("M2"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,M2);   
         ObjectSet("M2"+i,10,false);
         ObjectSet("M2"+i, OBJPROP_COLOR, Green);
         ObjectSet("M2"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("M2"+i,OBJPROP_WIDTH,1);
         if(Yearly)
            ObjectSet("M2"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("M2"+i,2,Period_Price[i][0]);   
         ObjectSet("M2"+i,3,M2);

         if(ObjectFind("M2_Label") != 0)
         {
            ObjectCreate("M2_Label", OBJ_TEXT, 0, Time[i] + (PeriodCode * 4), M2);
            ObjectSetText("M2_Label", "                    " + PeriodLabel + "M2 " +DoubleToStr(M2,4), 8, "Arial", Green);
         }
         else
         {
            ObjectMove("M2_Label", 0, Time[i] + (PeriodCode * 4), M2);
         }

         if(Yearly)
            ObjectCreate("S1"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),S1);
         else
            ObjectCreate("S1"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,S1);   
         ObjectSet("S1"+i,10,false);
         ObjectSet("S1"+i, OBJPROP_COLOR, Green);
         ObjectSet("S1"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("S1"+i,OBJPROP_WIDTH,2);
         if(Yearly)
            ObjectSet("S1"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("S1"+i,2,Period_Price[i][0]);   
         ObjectSet("S1"+i,3,S1);

         if(ObjectFind("S1_Label") != 0)
         {
            ObjectCreate("S1_Label", OBJ_TEXT, 0, Time[i] + (PeriodCode * 4), S1);
            ObjectSetText("S1_Label", "                    " + PeriodLabel + "S1 " +DoubleToStr(S1,4), 8, "Arial", Green);
         }
         else
         {
            ObjectMove("S1_Label", 0, Time[i] + (PeriodCode * 4), S1);
         }

         if(Yearly)
            ObjectCreate("M1S2" + i,OBJ_RECTANGLE,0,StrToTime((year + 1) + ".01.01 00:00"),S2);
         else
            ObjectCreate("M1S2" + i,OBJ_RECTANGLE,0,Period_Price[i][0],S2);   
         if(Yearly)
            ObjectSet("M1S2" + i,2,StrToTime((year + 1) + ".12.31 23:59"));
         else
            ObjectSet("M1S2" + i,2,Period_Price[i][0] + PeriodBuffer);   
         ObjectSet("M1S2" + i,3,M1);
         ObjectSet("M1S2" + i,6,ExtremeSupportColour);

         if(ObjectFind("M1_Label") != 0)
         {
            ObjectCreate("M1_Label", OBJ_TEXT, 0, Time[i] + (PeriodCode * 4), M1);
            ObjectSetText("M1_Label", "                    " + PeriodLabel + "M1 " +DoubleToStr(M1,4), 8, "Arial", Black);
         }
         else
         {
            ObjectMove("M1_Label", 0, Time[i] + (PeriodCode * 4), M1);
         }

         if(ObjectFind("S2_Label") != 0)
         {
            ObjectCreate("S2_Label", OBJ_TEXT, 0, Time[i] + (PeriodCode * 4), S2);
            ObjectSetText("S2_Label", "                    " + PeriodLabel + "S2 " +DoubleToStr(S2,4), 8, "Arial", Green);
         }
         else
         {
            ObjectMove("S2_Label", 0, Time[i] + (PeriodCode * 4), S2);
         }
		 
		   if(Yearly)
		       ObjectCreate("S3"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),S3);
		   else
		       ObjectCreate("S3"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,S3);    
         ObjectSet("S3"+i,10,false);
         ObjectSet("S3"+i, OBJPROP_COLOR, Green);
         ObjectSet("S3"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("S3"+i,OBJPROP_WIDTH,2);
         if(Yearly)
            ObjectSet("S3"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("S3"+i,2,Period_Price[i][0]);   
         ObjectSet("S3"+i,3,S3);


         if(ObjectFind("S3_Label") != 0)
         {
            ObjectCreate("S3_Label", OBJ_TEXT, 0, Time[i] + (PeriodCode * 4), S3);
            ObjectSetText("S3_Label", "                    " + PeriodLabel + "S3 " +DoubleToStr(S3,4), 8, "Arial", Green);
         }
         else
         {
            ObjectMove("S3_Label", 0, Time[i] + (PeriodCode * 4), S3);
         }

         Buf_CPP_MA[i] = Pivot;
         //Check to see if alert is needed
         if(Alarm && DTofAlert != TimeToStr(Time[0],TIME_DATE|TIME_MINUTES))
         {
            if(DoubleToStr(Ask,4) >= DoubleToStr(M4,4))
            {
               Alert(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached M4 resistance");
               SendMail(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached M4 resistance");
               DTofAlert = TimeToStr(Time[0],TIME_DATE|TIME_MINUTES); 
            }
			   if(DoubleToStr(Ask,4) >= DoubleToStr(R3,4))
            {
               Alert(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached R3 resistance");
               SendMail(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached R3 resistance");
               DTofAlert = TimeToStr(Time[0],TIME_DATE|TIME_MINUTES); 
            }
			   if(DoubleToStr(Ask,4) >= DoubleToStr(R2,4))
            {
               Alert(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached R2 resistance");
               SendMail(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached R2 resistance");
               DTofAlert = TimeToStr(Time[0],TIME_DATE|TIME_MINUTES); 
            }
            if(DoubleToStr(Bid,4) <= DoubleToStr(M1,4))
            {
               Alert(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached M1 support");
               SendMail(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached M1 support");
               DTofAlert = TimeToStr(Time[0],TIME_DATE|TIME_MINUTES); 
            }
            if(DoubleToStr(Bid,4) == DoubleToStr(Pivot,4) || DoubleToStr(Ask,4) == DoubleToStr(Pivot,4))
            {
               Alert(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price at CPP");
               SendMail(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price at CPP");
               DTofAlert = TimeToStr(Time[0],TIME_DATE|TIME_MINUTES); 
            }
			   if(DoubleToStr(Bid,4) >= DoubleToStr(S3,4))
            {
               Alert(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached S3 support");
               SendMail(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached S3 support");
               DTofAlert = TimeToStr(Time[0],TIME_DATE|TIME_MINUTES); 
            }
			   if(DoubleToStr(Bid,4) >= DoubleToStr(S2,4))
            {
               Alert(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached S2 support");
               SendMail(TimeToStr(TimeLocal(),TIME_DATE|TIME_MINUTES) + " - " + Symbol() + " " + PeriodLabel + " Pivot Point Alert", " Price breached S2 support");
               DTofAlert = TimeToStr(Time[0],TIME_DATE|TIME_MINUTES); 
            }
             
         }         
                  
         
       }
      else
      {
         
         if(Yearly)
            ObjectCreate("PP"+i, OBJ_TREND,0,StrToTime((year + 1) + ".12.31 23:59") ,Pivot);
         else
            ObjectCreate("PP"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,Pivot);
         ObjectSet("PP"+i,10,false);
         ObjectSet("PP"+i, OBJPROP_COLOR, Black);
         ObjectSet("PP"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("PP"+i,OBJPROP_WIDTH,3);
         if(Yearly)
            ObjectSet("PP"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("PP"+i,2,Period_Price[i][0]);
         ObjectSet("PP"+i,3,Pivot);
         
         if(Yearly)
            ObjectCreate("M3"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),M3);
         else
            ObjectCreate("M3"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,M3);
         ObjectSet("M3"+i,10,false);
         ObjectSet("M3"+i, OBJPROP_COLOR, Red);
         ObjectSet("M3"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("M3"+i,OBJPROP_WIDTH,1);
         if(Yearly)
            ObjectSet("M3"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("M3"+i,2,Period_Price[i][0]);
         ObjectSet("M3"+i,3,M3);
         
         if(Yearly)
            ObjectCreate("R1"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),R1);
         else
            ObjectCreate("R1"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,R1);
         ObjectSet("R1"+i,10,false);
         ObjectSet("R1"+i, OBJPROP_COLOR, Red);
         ObjectSet("R1"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("R1"+i,OBJPROP_WIDTH,2);
         if(Yearly)
            ObjectSet("R1"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else   
            ObjectSet("R1"+i,2,Period_Price[i][0]);
         ObjectSet("R1"+i,3,R1);
         
         if(Yearly)
            ObjectCreate("R2M4" + i,OBJ_RECTANGLE,0,StrToTime((year + 1) + ".01.01 00:00"),M4);
         else
            ObjectCreate("R2M4" + i,OBJ_RECTANGLE,0,Period_Price[i][0],M4);
         if(Yearly)
            ObjectSet("R2M4" + i,2,StrToTime((year + 1) + ".12.31 23:59"));
         else
            ObjectSet("R2M4" + i,2,Period_Price[i][0] + PeriodBuffer);
         ObjectSet("R2M4" + i,3,R2);
         ObjectSet("R2M4" + i,6,ExtremeResistanceColour);
         
         if(Yearly)
		       ObjectCreate("R3"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),R3);
		   else
		       ObjectCreate("R3"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,R3);
         ObjectSet("R3"+i,10,false);
         ObjectSet("R3"+i, OBJPROP_COLOR, Red);
         ObjectSet("R3"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("R3"+i,OBJPROP_WIDTH,2);
         if(Yearly)
            ObjectSet("R3"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("R3"+i,2,Period_Price[i][0]);   
         ObjectSet("R3"+i,3,R3);
         
         if(Yearly)
            ObjectCreate("M2"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),M2);
         else
            ObjectCreate("M2"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,M2);   
         ObjectSet("M2"+i,10,false);
         ObjectSet("M2"+i, OBJPROP_COLOR, Green);
         ObjectSet("M2"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("M2"+i,OBJPROP_WIDTH,1);
         if(Yearly)
            ObjectSet("M2"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("M2"+i,2,Period_Price[i][0]);   
         ObjectSet("M2"+i,3,M2);
         
         if(Yearly)
            ObjectCreate("S1"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),S1);
         else
            ObjectCreate("S1"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,S1);   
         ObjectSet("S1"+i,10,false);
         ObjectSet("S1"+i, OBJPROP_COLOR, Green);
         ObjectSet("S1"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("S1"+i,OBJPROP_WIDTH,2);
         if(Yearly)
            ObjectSet("S1"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("S1"+i,2,Period_Price[i][0]);   
         ObjectSet("S1"+i,3,S1);
         
         if(Yearly)
            ObjectCreate("M1S2" + i,OBJ_RECTANGLE,0,StrToTime((year + 1) + ".01.01 00:00"),S2);
         else
            ObjectCreate("M1S2" + i,OBJ_RECTANGLE,0,Period_Price[i][0],S2);   
         if(Yearly)
            ObjectSet("M1S2" + i,2,StrToTime((year + 1) + ".12.31 23:59"));
         else
            ObjectSet("M1S2" + i,2,Period_Price[i][0] + PeriodBuffer);   
         ObjectSet("M1S2" + i,3,M1);
         ObjectSet("M1S2" + i,6,ExtremeSupportColour);
         
            if(Yearly)
		       ObjectCreate("S3"+i, OBJ_TREND,0, StrToTime((year + 1) + ".12.31 23:59"),S3);
		   else
		       ObjectCreate("S3"+i, OBJ_TREND,0, Period_Price[i][0] + PeriodBuffer,S3);    
         ObjectSet("S3"+i,10,false);
         ObjectSet("S3"+i, OBJPROP_COLOR, Green);
         ObjectSet("S3"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("S3"+i,OBJPROP_WIDTH,2);
         if(Yearly)
            ObjectSet("S3"+i,2,StrToTime((year + 1) + ".01.01 00:00"));
         else
            ObjectSet("S3"+i,2,Period_Price[i][0]);   
         ObjectSet("S3"+i,3,S3);
         /*
         ObjectCreate("PP"+i, OBJ_TREND,0, Period_Price[i-1][0],Pivot);
         ObjectSet("PP"+i,10,false);
         ObjectSet("PP"+i, OBJPROP_COLOR, Black);
         ObjectSet("PP"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("PP"+i,OBJPROP_WIDTH,3);
         ObjectSet("PP"+i,2,Period_Price[i][0]);
         ObjectSet("PP"+i,3,Pivot);
         
         ObjectCreate("M3"+i, OBJ_TREND,0, Period_Price[i-1][0],M3);
         ObjectSet("M3"+i,10,false);
         ObjectSet("M3"+i, OBJPROP_COLOR, Red);
         ObjectSet("M3"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("M3"+i,OBJPROP_WIDTH,1);
         ObjectSet("M3"+i,2,Period_Price[i][0]);
         ObjectSet("M3"+i,3,M3);

         ObjectCreate("R1"+i, OBJ_TREND,0, Period_Price[i-1][0],R1);
         ObjectSet("R1"+i,10,false);
         ObjectSet("R1"+i, OBJPROP_COLOR, Red);
         ObjectSet("R1"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("R1"+i,OBJPROP_WIDTH,2);
         ObjectSet("R1"+i,2,Period_Price[i][0]);
         ObjectSet("R1"+i,3,R1);

         ObjectCreate("R2M4" + i,OBJ_RECTANGLE,0,Period_Price[i][0],M4);
         ObjectSet("R2M4" + i,2,Period_Price[i-1][0]);
         ObjectSet("R2M4" + i,3,R2);
         ObjectSet("R2M4" + i,6,ExtremeResistanceColour);
         if(PeriodLabel == "H" || PeriodLabel == "4H")
         {
            ObjectSetText("R2M4" + i,TimeToStr(Period_Price[i-1][0] + 14400,TIME_MINUTES));
         }
        
		   ObjectCreate("R3"+i, OBJ_TREND,0, Period_Price[i-1][0],R3);
         ObjectSet("R3"+i,10,false);
         ObjectSet("R3"+i, OBJPROP_COLOR, Red);
         ObjectSet("R3"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("R3"+i,OBJPROP_WIDTH,2);
         ObjectSet("R3"+i,2,Period_Price[i][0]);
         ObjectSet("R3"+i,3,R3);
		
         ObjectCreate("M2"+i, OBJ_TREND,0, Period_Price[i-1][0],M2);
         ObjectSet("M2"+i,10,false);
         ObjectSet("M2"+i, OBJPROP_COLOR, Green);
         ObjectSet("M2"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("M2"+i,OBJPROP_WIDTH,1);
         ObjectSet("M2"+i,2,Period_Price[i][0]);
         ObjectSet("M2"+i,3,M2);

         ObjectCreate("S1"+i, OBJ_TREND,0, Period_Price[i-1][0],S1);
         ObjectSet("S1"+i,10,false);
         ObjectSet("S1"+i, OBJPROP_COLOR, Green);
         ObjectSet("S1"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("S1"+i,OBJPROP_WIDTH,2);
         ObjectSet("S1"+i,2,Period_Price[i][0]);
         ObjectSet("S1"+i,3,S1);

         ObjectCreate("M1S2" + i,OBJ_RECTANGLE,0,Period_Price[i][0],S2);
         ObjectSet("M1S2" + i,2,Period_Price[i-1][0]);
         ObjectSet("M1S2" + i,3,M1);
         ObjectSet("M1S2" + i,6,ExtremeSupportColour);
	 
		 ObjectCreate("S3"+i, OBJ_TREND,0, Period_Price[i-1][0],S3);
         ObjectSet("S3"+i,10,false);
         ObjectSet("S3"+i, OBJPROP_COLOR, Green);
         ObjectSet("S3"+i, OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("S3"+i,OBJPROP_WIDTH,2);
         ObjectSet("S3"+i,2,Period_Price[i][0]);
         ObjectSet("S3"+i,3,S3);
*/	                
         if (i > 1 && !Yearly)
         {
         ObjectCreate("RangeBox" + i,OBJ_RECTANGLE,0,Period_Price[i][0],S2);
         ObjectSet("RangeBox" + i,2,Period_Price[i-1][0]);
         ObjectSet("RangeBox" + i,3,R2);
         ObjectSet("RangeBox" + i,9,false);
         ObjectSet("RangeBox" + i,8,2);
         }
         Buf_CPP_MA[i] = Pivot;  
      }
      
      if (i > 1 && !Yearly)
      {
         ObjectSet("RangeBox" + i,6,Black);
         ObjectSet("RangeBox" + i,9,false);
         ObjectSet("RangeBox" + i,8,2);   
      }
      
      
   }   

   if (PivotAverage == true)
   {
      for(int counter=0; counter <= PeriodsToPlot-NumPivotsToAve; counter++)
      {
         double PPAverageTrend;
         
         for(int index=1;index<=NumPivotsToAve;index++)
         {
            PPAverageTrend = PPAverageTrend + Buf_CPP_MA[counter+index];
         }
         PPAverageTrend = PPAverageTrend/NumPivotsToAve;
            
         if(counter==0)
         {
            ObjectCreate("PPAverage"+counter, OBJ_TREND,0, Period_Price[counter][0],PPAverageTrend);
            ObjectSet("PPAverage"+counter,10,false);
            ObjectSet("PPAverage"+counter, OBJPROP_COLOR, PPAveColour);
            ObjectSet("PPAverage"+counter, OBJPROP_STYLE, STYLE_DASH);
            ObjectSet("PPAverage"+counter,OBJPROP_WIDTH,1);
            ObjectSet("PPAverage"+counter,2,Period_Price[counter][0] + PeriodBuffer);
            ObjectSet("PPAverage"+counter,3,PPAverageTrend);
            /*
            //if (Buf_CPP_MA[counter] < PPAverageTrend && Period_Price[counter+1][4] < PPAverageTrend)
            if (Buf_CPP_MA[counter] < PPAverageTrend && Period_Price[counter+1][4] < Buf_CPP_MA[counter])
            {
               Direction = "BEARISH";
            }
            //else if (Buf_CPP_MA[counter] > PPAverageTrend && Period_Price[counter+1][4] > PPAverageTrend)
            else if (Buf_CPP_MA[counter] > PPAverageTrend && Period_Price[counter+1][4] > Buf_CPP_MA[counter])
            {
               Direction = "BULLISH";
            }
            else
            {
               Direction = "NEUTRAL";
            }
            ObjectSetText("PPAverage"+counter,Direction);
            */     
         }
         else
         {
            ObjectCreate("PPAverage"+counter, OBJ_TREND,0, Period_Price[counter][0],PPAverageTrend);
            ObjectSet("PPAverage"+counter,10,false);
            ObjectSet("PPAverage"+counter, OBJPROP_COLOR, PPAveColour);
            ObjectSet("PPAverage"+counter, OBJPROP_STYLE, STYLE_DASH);
            ObjectSet("PPAverage"+counter,OBJPROP_WIDTH,1);
            ObjectSet("PPAverage"+counter,2,Period_Price[counter-1][0]);
            ObjectSet("PPAverage"+counter,3,PPAverageTrend);
            /*
            //if (Buf_CPP_MA[counter] < PPAverageTrend && Period_Price[counter+1][4] < PPAverageTrend)
            if (Buf_CPP_MA[counter] < PPAverageTrend && Period_Price[counter+1][4] < Buf_CPP_MA[counter])
            {
               Direction = "BEARISH";
            }
            //else if (Buf_CPP_MA[counter] > PPAverageTrend && Period_Price[counter+1][4] > PPAverageTrend)
            else if (Buf_CPP_MA[counter] > PPAverageTrend && Period_Price[counter+1][4] > Buf_CPP_MA[counter])
            {
               Direction = "BULLISH";
            }
            else
            {
               Direction = "NEUTRAL";
            }
            ObjectSetText("PPAverage"+counter,Direction);
            */
      }
         PPAverageTrend = 0;
      }
    } 
   PPAverage = 0;
   WindowRedraw(); 

   return(0);
  }




