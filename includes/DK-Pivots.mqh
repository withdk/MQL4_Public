//+------------------------------------------------------------------+
//|                                                    DK-Pivots.mq4 |
//|                                                David Kierznowski |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "David Kierznowski"
#property link      ""

// These two constant variables could be changed to produce pivots
// on other timeframes.
#define BARSHIFT 1
#define TIMEFRAME PERIOD_D1

// We need the previous bar high, low and close to do the
// required calculations, so we'll do this first.
double GetHigh()
{
   return(iHigh(Symbol(),TIMEFRAME,BARSHIFT));
}

double GetLow()
{
   return(iLow(Symbol(),TIMEFRAME,BARSHIFT));
}

double GetClose()
{
   return(iClose(Symbol(),TIMEFRAME,BARSHIFT));
}

// Taken from PipPoint code to use NormalizeDouble method.
int GetDigits()
{
	int CalcDigits = MarketInfo(Symbol(),MODE_DIGITS);
	int CalcPoint;
		
	if(CalcDigits == 2 || CalcDigits == 3) 
	    CalcPoint = 2;
	else if(CalcDigits == 4 || CalcDigits == 5) 
	    CalcPoint = 4;
	else   
	    CalcPoint = 1; // DK TEST for 0 digits
		
		
	return(CalcPoint);
}

// We now have the functions we need so lets get on with
// providing getter methods for pivots.
double GetPP()
{
   double pp = ( GetHigh()+GetLow()+GetClose() )/3;
   pp = NormalizeDouble( pp, GetDigits() );
   return(pp);
}

double GetR1()
{
   // (2*p)-yesterday_low;
   double r1 = ( 2*GetPP() ) - GetLow();
   r1 = NormalizeDouble( r1, GetDigits() );
   return(r1);
}

double GetR2()
{
   // p+(yesterday_high - yesterday_low);
   double r2 = GetPP() + ( GetHigh() - GetLow() );
   r2 = NormalizeDouble( r2, GetDigits() );
   return(r2);
}

double GetR3()
{
   // PP + RANGE * 2
   double r3 = GetPP() + ( ( GetHigh() - GetLow() ) * 2 );
   r3 = NormalizeDouble( r3, GetDigits() );
   return(r3);
}

double GetR4()
{
   // PP + RANGE * 3
   double r4 = GetPP() + ( ( GetHigh() - GetLow() ) * 3 );
   r4 = NormalizeDouble( r4, GetDigits() );
   return(r4);
}


double GetS1()
{
   // (2*p)-yesterday_high;
   double s1 = ( 2*GetPP() ) - GetHigh();
   s1 = NormalizeDouble( s1, GetDigits() );
   return(s1);
}

double GetS2()
{
   // p-(yesterday_high - yesterday_low);
   double s2 = GetPP() - ( GetHigh() - GetLow() );
   s2 = NormalizeDouble( s2, GetDigits() );
   return(s2);
}

double GetS3()
{
   // PP - RANGE * 2
   double s3 = GetPP() - ( ( GetHigh() - GetLow() ) * 2 );
   s3 = NormalizeDouble( s3, GetDigits() );
   return(s3);
}

double GetS4()
{
   // PP - RANGE * 2
   double s4 = GetPP() - ( ( GetHigh() - GetLow() ) * 3 );
   s4 = NormalizeDouble( s4, GetDigits() );
   return(s4);
}

// Midpoints
// mR1, mR2, mR3, mR4
// mS1, mS2, mS4, mS4
double GetmR1()
{
   // R1 - PP / 2
   double mR1 = ( ( GetR1() - GetPP() ) / 2);
   mR1 = mR1 + GetPP();
   mR1 = NormalizeDouble( mR1, GetDigits() );
   return(mR1);
}

double GetmR2()
{
   // R2 - R1 / 2
   double mR2 = ( ( GetR2() - GetR1() ) / 2);
   mR2 = mR2 + GetR1();
   mR2 = NormalizeDouble( mR2, GetDigits() );
   return(mR2);
}

double GetmR3()
{
   // R3 - R2 / 2
   double mR3 = ( ( GetR3() - GetR2() ) / 2);
   mR3 = mR3 + GetR2();
   mR3 = NormalizeDouble( mR3, GetDigits() );
   return(mR3);
}

double GetmR4()
{
   // R4 - R3 / 2
   double mR4 = ( ( GetR4() - GetR3() ) / 2);
   mR4 = mR4 + GetR3();
   mR4 = NormalizeDouble( mR4, GetDigits() );
   return(mR4);
}

double GetmS1()
{
   // PP - S1 / 2
   double mS1 = ( ( GetPP() - GetS1() ) / 2);
   mS1 = mS1 + GetS1();
   mS1 = NormalizeDouble( mS1, GetDigits() );
   return(mS1);
}

double GetmS2()
{
   // S1 - S2 / 2
   double mS2 = ( ( GetS1() - GetS2() ) / 2);
   mS2 = mS2 + GetS2();
   mS2 = NormalizeDouble( mS2, GetDigits() );
   return(mS2);
}

double GetmS3()
{
   // S2 - S3 / 2
   double mS3 = ( ( GetS2() - GetS3() ) / 2);
   mS3 = mS3 + GetS3();
   mS3 = NormalizeDouble( mS3, GetDigits() );
   return(mS3);
}

double GetmS4()
{
   // S3 - S4 / 2
   double mS4 = ( ( GetS3() - GetS4() ) / 2);
   mS4 = mS4 + GetS4();
   mS4 = NormalizeDouble( mS4, GetDigits() );
   return(mS4);
}

// Get Pivot Location
string GetPivotLocation(int TradeDirection) // 1: buy, 0: sell, -1: error
{
  // Ask: Price top, Bid: Price bottom
   double BidAsk;
   if(TradeDirection == 1)
      BidAsk = Ask;
   else if(TradeDirection == 0)
      BidAsk = Bid;
   else
      return("-1"); // No valid TradeDirection.
  
  // Find price location
   // R-Values
   if ( BidAsk > GetPP() && BidAsk < GetR1() ) // R1
      return("PPR1");
   else if ( BidAsk > GetR1() && BidAsk < GetR2() ) // R2
      return("R1R2");
   else if ( BidAsk > GetR2() && BidAsk < GetR3() ) // R3
      return("R2R3");
   else if ( BidAsk > GetR3() && BidAsk < GetR4() ) // R4
      return("R3R4");
   // S-Values   
   else if ( BidAsk < GetPP() && BidAsk > GetS1() ) // S1
      return("PPS1");
   else if ( BidAsk < GetS1() && BidAsk > GetS2() ) // S2
      return("S1S2");
   else if ( BidAsk < GetS2() && BidAsk > GetS3() ) // S3
      return("S2S3");
   else if ( BidAsk < GetS3() && BidAsk > GetS4() ) // S4
      return("S3S4");
   else
      return("-2");  // Price extremes
}

// Set Target To Pivot Level 
double GetPivotTarget(int TradeDirection, string PivotLocation) // 1: buy, 0: sell, -1: error
{

  // Buy trades aiming up
   if(TradeDirection == 1) 
   {
      if(PivotLocation == "PPR1")
         return( GetR1() );  // R1 
      else if (PivotLocation == "R1R2")
         return (GetR2() );  // R2
      else if (PivotLocation == "R2R3")
         return (GetR3() );  // R3
      else if (PivotLocation == "R3R4")
         return (GetR4() );  // R4
      else if (PivotLocation == "PPS1")
         return (GetPP() );  // PP
      else if (PivotLocation == "S1S2")
         return (GetS1() );  // S1
      else if (PivotLocation == "S2S3")
         return (GetS2() );  // S2
      else if (PivotLocation == "S3S4")
         return (GetS3() );  // S3
      else
         return(-1); // Error
   }
  // Sell trades aiming down
   else if(TradeDirection == 0)
   {
      if(PivotLocation == "PPR1")
         return( GetPP() );  // R1 
      else if (PivotLocation == "R1R2")
         return (GetR1() );  // R2
      else if (PivotLocation == "R2R3")
         return (GetR2() );  // R3
      else if (PivotLocation == "R3R4")
         return (GetR3() );  // R4
      else if (PivotLocation == "PPS1")
         return (GetS1() );  // PP
      else if (PivotLocation == "S1S2")
         return (GetS2() );  // S1
      else if (PivotLocation == "S2S3")
         return (GetS3() );  // S2
      else if (PivotLocation == "S3S4")
         return (GetS4() );  // S3
      else
         return(-1); // Error
   }
   else
      return(-2); // Error
}

// USE MIDPOINTS
// Get Pivot Location
string GetPivotLocationWMid(int TradeDirection) // 1: buy, 0: sell, -1: error
{
  // Ask: Price top, Bid: Price bottom
   double BidAsk;
   if(TradeDirection == 1)
      BidAsk = Ask;
   else if(TradeDirection == 0)
      BidAsk = Bid;
   else
      return("-1"); // No valid TradeDirection.
  
  // Find price location
   // R-Values
   if ( BidAsk > GetPP() && BidAsk < GetmR1() ) // mR1
      return("mR1");
   if ( BidAsk > GetmR1() && BidAsk < GetR1() ) // R1
      return("R1");
   else if ( BidAsk > GetR1() && BidAsk < GetmR2() ) // mR2
      return("mR2");
   else if ( BidAsk > GetmR2() && BidAsk < GetR2() ) // R2
      return("R2");
   else if ( BidAsk > GetR2() && BidAsk < GetmR3() ) // mR3
      return("mR3");
   else if ( BidAsk > GetmR3() && BidAsk < GetR3() ) // R3
      return("R3");
   else if ( BidAsk > GetR3() && BidAsk < GetmR4() ) // mR4
      return("mR4");
   else if ( BidAsk > GetmR4() && BidAsk < GetR4() ) // R4
      return("R4");
   // S-Values   
   else if ( BidAsk < GetPP() && BidAsk > GetmS1() ) // mS1
      return("mS1");
   else if ( BidAsk < GetmS1() && BidAsk > GetS1() ) // S1
      return("S1");
   else if ( BidAsk < GetS1() && BidAsk > GetmS2() ) // mS2
      return("mS2");
   else if ( BidAsk < GetmS2() && BidAsk > GetS2() ) // S2
      return("S2");
   else if ( BidAsk < GetS2() && BidAsk > GetmS3() ) // mS3
      return("mS3");
   else if ( BidAsk < GetmS3() && BidAsk > GetS3() ) // S3
      return("S3");
   else if ( BidAsk < GetS3() && BidAsk > GetmS4() ) // mS4
      return("mS4");
   else if ( BidAsk < GetmS4() && BidAsk > GetS4() ) // S4
      return("S4");
   else
      return("-2");  // Price extremes
}

// Set Target To Pivot Level 
double GetPivotTargetWMid(int TradeDirection, string PivotLocation) // 1: buy, 0: sell, -1: error
{

  // Buy trades aiming up
   if(TradeDirection == 1) 
   {
      if(PivotLocation == "mR1")
         return( GetmR1() );  // mR1 
      else if(PivotLocation == "R1")
         return( GetR1() );  // R1
      else if (PivotLocation == "mR2")
         return (GetmR2() );  // mR2   
      else if (PivotLocation == "R2")
         return (GetR2() );  // R2
      else if (PivotLocation == "mR3")
         return (GetmR3() );  // mR3
      else if (PivotLocation == "R3")
         return (GetR3() );  // R3
      else if (PivotLocation == "mR4")
         return (GetmR4() );  // mR4
      else if (PivotLocation == "R4")
         return (GetR4() );  // R4

      else if (PivotLocation == "mS1")
         return (GetPP() );  // mS1
      else if (PivotLocation == "S1")
         return (GetmS1() );  // S1
      else if (PivotLocation == "mS2")
         return (GetS1() );  // mS2
      else if (PivotLocation == "S2")
         return (GetmS2() );  // S2
      else if (PivotLocation == "mS3")
         return (GetS2() );  // mS3
      else if (PivotLocation == "S3")
         return (GetmS3() );  // S3
      else if (PivotLocation == "mS4")
         return (GetS3() );  // mS4
      else if (PivotLocation == "S4")
         return (GetmS4() );  // S4
      else
         return(-1); // Error
   }
  // Sell trades aiming down
   else if(TradeDirection == 0)
   {
      if(PivotLocation == "mR1")
         return( GetPP() );  // mR1 
      else if(PivotLocation == "R1")
         return( GetmR1() );  // R1
      else if (PivotLocation == "mR2")
         return (GetR1() );  // mR2   
      else if (PivotLocation == "R2")
         return (GetmR2() );  // R2
      else if (PivotLocation == "mR3")
         return (GetR2() );  // mR3
      else if (PivotLocation == "R3")
         return (GetmR3() );  // R3
      else if (PivotLocation == "mR4")
         return (GetR3() );  // mR4
      else if (PivotLocation == "R4")
         return (GetmR4() );  // R4

      else if (PivotLocation == "mS1")
         return (GetmS1() );  // mS1
      else if (PivotLocation == "S1")
         return (GetS1() );  // S1
      else if (PivotLocation == "mS2")
         return (GetmS2() );  // mS2
      else if (PivotLocation == "S2")
         return (GetS2() );  // S2
      else if (PivotLocation == "mS3")
         return (GetmS3() );  // mS3
      else if (PivotLocation == "S3")
         return (GetS3() );  // S3
      else if (PivotLocation == "mS4")
         return (GetmS4() );  // mS4
      else if (PivotLocation == "S4")
         return (GetS4() );  // S4
      else
         return(-2); // Error
    }
}

// Is touching a pivot includes midpoints
string IsTouchingPivot()
{
  // PP
   if(High[1] >= GetPP() && Low[1] <= GetPP()) return("PP");
  // Rs  
   if(High[1] >= GetmR1() && Low[1] <= GetmR1()) return("mR1");
   if(High[1] >= GetR1() && Low[1] <= GetR1()) return("R1");
   if(High[1] >= GetmR2() && Low[1] <= GetmR2()) return("mR2");
   if(High[1] >= GetR2() && Low[1] <= GetR2()) return("R2");
   if(High[1] >= GetmR3() && Low[1] <= GetmR3()) return("mR3");
   if(High[1] >= GetR3() && Low[1] <= GetR3()) return("R3");
   if(High[1] >= GetmR4() && Low[1] <= GetmR4()) return("mR4");
   if(High[1] >= GetR4() && Low[1] <= GetR4()) return("R4");
  // Ss 
   if(High[1] >= GetmS1() && Low[1] <= GetmS1()) return("mS1");
   if(High[1] >= GetS1() && Low[1] <= GetS1()) return("S1");
   if(High[1] >= GetmS2() && Low[1] <= GetmS2()) return("mS2");
   if(High[1] >= GetS2() && Low[1] <= GetS2()) return("S2");
   if(High[1] >= GetmS3() && Low[1] <= GetmS3()) return("mS3");
   if(High[1] >= GetS3() && Low[1] <= GetS3()) return("S3");
   if(High[1] >= GetmS4() && Low[1] <= GetmS4()) return("mS4");
   if(High[1] >= GetS4() && Low[1] <= GetS4()) return("S4");
   
  // No touchy
   return("-1");
}

// Return the touching pivot price 
double GetPivotPrice(string CurrentPivot)
{
   if(CurrentPivot != "-1")
   {
      if(CurrentPivot == "PP") return(GetPP());
      if(CurrentPivot == "mR1") return(GetmR1());
      if(CurrentPivot == "R1") return(GetR1());
      if(CurrentPivot == "mR2") return(GetmR2());
      if(CurrentPivot == "R2") return(GetR2());
      if(CurrentPivot == "mR3") return(GetmR3());
      if(CurrentPivot == "R3") return(GetR3());
      if(CurrentPivot == "mR4") return(GetmR4());
      if(CurrentPivot == "R4") return(GetR4());
      if(CurrentPivot == "mS1") return(GetmS1());
      if(CurrentPivot == "S1") return(GetS1());
      if(CurrentPivot == "mS2") return(GetmS2());
      if(CurrentPivot == "S2") return(GetS2());
      if(CurrentPivot == "mS3") return(GetmS3());
      if(CurrentPivot == "S3") return(GetS3());
      if(CurrentPivot == "mS4") return(GetmS4());
      if(CurrentPivot == "S4") return(GetS4());
   }   
   
   return(-1.0);
}

// Get Double of Upper Pivot
double GetUpperPivot(string CurrentPivot, bool UseMidLevels)
{
   if(CurrentPivot != "-1")
   {
     // WITH MIDPOINTS
     if (UseMidLevels == true)
     {
      if(CurrentPivot == "PP") return(GetmR1());
      if(CurrentPivot == "mR1") return(GetR1());
      if(CurrentPivot == "R1") return(GetmR2());
      if(CurrentPivot == "mR2") return(GetR2());
      if(CurrentPivot == "R2") return(GetmR3());
      if(CurrentPivot == "mR3") return(GetR3());
      if(CurrentPivot == "R3") return(GetmR4());
      if(CurrentPivot == "mR4") return(GetR4());
      if(CurrentPivot == "R4") return(-1.0); // Extreme prices No trade
      if(CurrentPivot == "mS1") return(GetPP());
      if(CurrentPivot == "S1") return(GetmS1());
      if(CurrentPivot == "mS2") return(GetS1());
      if(CurrentPivot == "S2") return(GetmS2());
      if(CurrentPivot == "mS3") return(GetS2());
      if(CurrentPivot == "S3") return(GetmS3());
      if(CurrentPivot == "mS4") return(GetS3());
      if(CurrentPivot == "S4") return(GetmS4());
     }
     // WITHOUT MIDPOINTS
     else
     {
      if(CurrentPivot == "PP") return(GetR1());
      if(CurrentPivot == "R1") return(GetR2());
      if(CurrentPivot == "R2") return(GetR3());
      if(CurrentPivot == "R3") return(GetR4());
      if(CurrentPivot == "R4") return(-1.0); // Extreme prices No trade
      if(CurrentPivot == "S1") return(GetPP());
      if(CurrentPivot == "S2") return(GetS1());
      if(CurrentPivot == "S3") return(GetS2());
      if(CurrentPivot == "S4") return(GetS3());
     } 
     
     return (-1.0);
   } // end of CurrentPivot != -1
   
   return(-1.0);
}

// Get Double of Lower Pivot 
double GetLowerPivot(string CurrentPivot, bool UseMidLevels)
{
   if(CurrentPivot != "-1")
   {
     // WITH MIDPOINTS
     if (UseMidLevels == true)
     {
      if(CurrentPivot == "PP") return(GetmS1());
      if(CurrentPivot == "mR1") return(GetPP());
      if(CurrentPivot == "R1") return(GetmR1());
      if(CurrentPivot == "mR2") return(GetR1());
      if(CurrentPivot == "R2") return(GetmR2());
      if(CurrentPivot == "mR3") return(GetR2());
      if(CurrentPivot == "R3") return(GetmR3());
      if(CurrentPivot == "mR4") return(GetR3());
      if(CurrentPivot == "R4") return(GetmR4()); 
      if(CurrentPivot == "mS1") return(GetS1());
      if(CurrentPivot == "S1") return(GetmS2());
      if(CurrentPivot == "mS2") return(GetS2());
      if(CurrentPivot == "S2") return(GetmS3());
      if(CurrentPivot == "mS3") return(GetS3());
      if(CurrentPivot == "S3") return(GetmS4());
      if(CurrentPivot == "mS4") return(GetS4());
      if(CurrentPivot == "S4") return(-1.0); // Extreme prices no trade
     }
     // WITHOUT MIDPOINTS
     else
     {
      if(CurrentPivot == "PP") return(GetS1());
      if(CurrentPivot == "R1") return(GetPP());
      if(CurrentPivot == "R2") return(GetR1());
      if(CurrentPivot == "R3") return(GetR2());
      if(CurrentPivot == "R4") return(GetR3()); 
      if(CurrentPivot == "S1") return(GetS2());
      if(CurrentPivot == "S2") return(GetS3());
      if(CurrentPivot == "S3") return(GetS4());
      if(CurrentPivot == "S4") return(-1.0); // Extreme prices no trade
     } 
     
     return (-1.0);
   } // end of CurrentPivot != -1
   
   return(-1.0);
}

// Check distance between two pivots
bool IsPivotLargeEnough(double biggerPrice, double lowerPrice, double MinDistanceSize)
{
   MinDistanceSize = MinDistanceSize * PipPoint(Symbol());
   double PivotsDistance = MathAbs(biggerPrice - lowerPrice);
   return(PivotsDistance >  MinDistanceSize);
}


// Check valid touch and touch spanning two pivots
bool VerifyPivotTouch()
{
   
}

// DEBUG
void PivotsDebug()
{
   Print( "High: ", GetHigh(), ", Low: ", GetLow(), ", Close: ", GetClose() );
   
   Print( "PP: ", GetPP() );
      Print( "mR1: ", GetmR1() );
   Print( "R1: ", GetR1() );
      Print( "mR2: ", GetmR2() );
   Print( "R2: ", GetR2() );
      Print( "mR3: ", GetmR3() );
   Print( "R3: ", GetR3() );
      Print( "mR4: ", GetmR4() );
   Print( "R4: ", GetR4() );

      Print( "mS1: ", GetmS1() );
   Print( "S1: ", GetS1() );
      Print( "mS2: ", GetmS2() );
   Print( "S2: ", GetS2() );
      Print( "mS3: ", GetmS3() );
   Print( "S3: ", GetS3() );
      Print( "mS4: ", GetmS4() );
   Print( "S4: ", GetS4() );
}