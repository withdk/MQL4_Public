#define	MESSAGE_SUBJECT	"Pattern Match"

// Keep track of current bar so only one alert sent per new bar.
datetime dtCurrentBarTime = 0;

//We define the periods of the two indicators
#property indicator_chart_window

input int MASlowPeriod;
input ENUM_MA_METHOD MASlowType=MODE_EMA;
input int MAFastPeriod;
input ENUM_MA_METHOD MAFastType=MODE_EMA;
input int MAAlertPeriod;
input ENUM_MA_METHOD MAAlertType=MODE_EMA;

int init() {

	// Set dtCurrentBarTime to Time[0]
	// Alerts will only begin when a new bar displays
	dtCurrentBarTime = Time[0];
	
	return(0);

}

int start() {

	bool 	bIsCondition	= false;
	string	sMessage	= "";
		
	// If not a new bar, do nothing
	if (dtCurrentBarTime == Time[0])
		return(0);

	// Flip pinbar flag if bar just completed is a pinbar
	if (iCustom(Symbol(),0,"XOver Indicator",MASlowPeriod,MASlowType,MAFastPeriod,MAFastType,MAAlertPeriod,MAAlertType,0,1) != EMPTY_VALUE
			|| iCustom(Symbol(),0,"XOver Indicator",MASlowPeriod,MASlowType,MAFastPeriod,MAFastType,MAAlertPeriod,MAAlertType,1,1) != EMPTY_VALUE)
		bIsCondition = true;
   Print(bIsCondition);
   
	// Prep message based on matches
	if (bIsCondition)
		sMessage = sMessage + Symbol() + " " + TimeToStr(Time[1]) + " ";
	
	// Send email if there's a message
	if (StringLen(sMessage) > 0) {
		//Print("Emailing: ", sMessage);
		//SendMail(MESSAGE_SUBJECT, sMessage);
		Print("SendNotification: ", sMessage);
		SendNotification(sMessage);
		PlaySound("alert.wav"); // Added sound
	}
	
	// Update dtCurrentBarTime so no alerts until next bar
	dtCurrentBarTime = Time[0];
	
	return(0);

}