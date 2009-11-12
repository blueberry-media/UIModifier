package dv.log{
	
	import flash.events.Event;
	
	
	public class LogEvent extends Event{
		
		public static const LOG_UPDATE:String = 'log_update';
		
		public function LogEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}