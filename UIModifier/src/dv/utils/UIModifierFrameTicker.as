package dv.utils
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	/**
	 * This class can be used as a replacement for ENTER_FRAME
	 * <br/>You just change [DisplayObject].addEventListener(Event.ENTER_FRAME , doSomeThing, false, 0, true);
	 * <br/>To UIModifierFrameTicker.getInstance().addEventListener(UIModifierFrameTicker.FRAME_TICK , doSomeThing, false, 0, true);
	 * 
	 * <br/> <b>Make sure you called the UIModifierFrameTicker.getInstance().start(frameRate) first</b>
	 * @author Bart Ducheyne
	 */
	public class UIModifierFrameTicker extends EventDispatcher
	{

		public static const FRAME_TICK:String='FRAME_TICK';
		protected static var _frameRate:int=24;
		protected var _frameTimer:Timer;
		private static var _instance:UIModifierFrameTicker;
		private var _listeners:uint = 0;

		public function UIModifierFrameTicker(obj:SingletonEnforcer)
		{
		}
		
		public function start(frameRate:int= 24):void{
			_frameRate = frameRate;
			_frameTimer= new Timer(1000/_frameRate,0);
		}
			
		protected function frameTick(e:TimerEvent):void{
			dispatchEvent(new Event(FRAME_TICK));
			//trace("FrameTicker Tick");
		}
		
		/**
		 * This overrides addEventListener. When called it passes the supplied
		 * params back up to the super of the function and starts the timer
		 */
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			if(!_frameTimer.running){
				_frameTimer.addEventListener(TimerEvent.TIMER,frameTick,false,0,true);
				_frameTimer.start();
			}
			_listeners ++;
		}
		
		/**
		 * This overrides removeEventListener. When called, it passes the supplied
		 * params back up to the super of the function and tops the timer 
		 * if no one listens to this class anymore
		 */
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			super.removeEventListener(type, listener, useCapture);
			_listeners --;
			if(_listeners <= 0){
				_listeners=0;
				if(_frameTimer.running){
					_frameTimer.removeEventListener(TimerEvent.TIMER,frameTick);
					_frameTimer.stop();
				}
			}
		}

		public static function getInstance():UIModifierFrameTicker
		{
			if (_instance == null)
			{
				_instance=new UIModifierFrameTicker(new SingletonEnforcer());
			}
			return _instance;
		}
	}
}

class SingletonEnforcer
{
}