package dv.log
{
	import flash.external.ExternalInterface;
	import flash.utils.getQualifiedClassName;
	import flash.events.EventDispatcher;


	final public class Logger 
	{
		
		private static var _rules:Array = [];
		
		public static const MODE_DEBUG:String = 'mode_debug'; 
		public static const MODE_PRODUCTION:String = 'mode_production'; 
		
		public static const LOG_INFO:String = 'INFO'; 
		public static const LOG_ERROR:String = 'ERROR'; 
		public static const LOG_DEBUG:String = 'DEBUG'; 
		public static const LOG_NONE:String = 'NONE'; 
		public static const LOG_ALL:String = 'ALL'; 
		
		public static const SEPERATOR:String = " :: "; 
		
		private static var _references:Array = [];
		private static var _mode:String;
		private static var _buffer:Array = [];
		private static var _externalInterface:Boolean = false;
		private static var _useTrace:Boolean = true;
		private static var _eventDispatcher:EventDispatcher
		
		public static function get eventDispatcher():EventDispatcher
		{
			return _eventDispatcher;
		}

		public static function set eventDispatcher(value:EventDispatcher):void
		{
			_eventDispatcher = value;
		}

		public static function createLogger( ref:Object ):LogInstance
		{
			if ( _eventDispatcher == null ) {
				_eventDispatcher = new EventDispatcher();
			}
			var instance:LogInstance = new LogInstance();
			instance.handledClass = getQualifiedClassName(ref);
			trace("Created logger for",instance.handledClass);
			_references.push ( instance );
			return instance;
		}
		
		public static function addRule(classPath:String,level:String,show:Boolean = true ):void{
			trace("Add rule for",classPath,level,show.toString());
			_rules.push({classPath:classPath,level:level,show:show});
		}
		
		//nl.blueberry.ui::SlideShow
		
		public static function get useTrace():Boolean
		{
			return _useTrace;
		}

		public static function set useTrace(v:Boolean):void
		{
			_useTrace = v;
			trace("Use trace",v.toString());
		}

		public static function get buffer():String
		{
			return _buffer.join("\n");
		}

		public static function addToBuffer(level:String , v:String,ref:String):void
		{
			var msg:String = level + SEPERATOR + v;
			var show:Boolean = true;
			var rules:uint = _rules.length;
			for( var i:uint = 0 ; i <  rules; i ++ ) {
				var rule:Object = _rules[i]; 
				if ( rule.classPath == ref ){
					if ( rule.level == level || rule.level == LOG_ALL ) {
						show = rule.show;
					}
				}
			}
			
			if ( show ) {
				if ( _useTrace ) {
					trace ( msg );
				}
				if ( _externalInterface ) {
					ExternalInterface.call("console.log",msg);
				}
				if ( _buffer.length > 100 ) {
					_buffer.splice(0,1);
				}
				_buffer.push( msg );
				_eventDispatcher.dispatchEvent( new LogEvent(LogEvent.LOG_UPDATE) ) 
			}
		}

		public static function get externalInterface():Boolean
		{
			return _externalInterface;
		}

		public static function set externalInterface(v:Boolean):void
		{
			_externalInterface = v;
			trace("Use externalInterface",v.toString());
		}

		public static function set mode(value:String):void{
			_mode = value;
		}
		
		public static function get mode():String{
			if ( _mode == null ) {
				_mode = MODE_DEBUG;
			}
			return _mode;
		}
		
	}
}
