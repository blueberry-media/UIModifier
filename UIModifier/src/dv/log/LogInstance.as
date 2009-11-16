package dv.log
{
	import flash.external.ExternalInterface;

	final public class LogInstance
	{
		
		private var _handledClass:String
		
		public function LogInstance(){
		}
	
		public function get handledClass():String
		{
			return _handledClass;
		}

		public function set handledClass(v:String):void
		{
			_handledClass = v;
		}
	
		private function createMessage(...msg):String{
			var report:Array = [ new Date() , _handledClass , msg.toString() ];
			var mesg:String = report.join(Logger.SEPERATOR);
			return mesg;
		}

		public function info(...msg):void{
			if ( Logger.mode != Logger.MODE_PRODUCTION ) {
				Logger.addToBuffer( Logger.LOG_INFO , createMessage(msg) , _handledClass );
			}
		}

		public function debug(...msg):void{
			if ( Logger.mode != Logger.MODE_PRODUCTION ) {
				Logger.addToBuffer( Logger.LOG_DEBUG , createMessage(msg) , _handledClass );
			}
		}

		public function error(...msg):void{
			var mesg:String = createMessage(msg);
			Logger.addToBuffer( Logger.LOG_ERROR , mesg , _handledClass );
		}
	}
}