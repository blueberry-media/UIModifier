/**
 * Handler for rotation
 *  
 * @author Martijn van Beek [martijn.vanbeek at gmail dot com]
 * @since September, Oktober 2008
 * @version 1.0
 * @license BSD
 * 
 */

package dv.ui.modifier
{
	import dv.events.HandleEvent;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public class HandleRotate extends MouseHandler
	{
		
		public static const LEFT_TOP:String = 'left_rotate';
		public static const RIGHT_TOP:String = 'right_rotate';
		public static const LEFT_BOTTOM:String = 'top_rotate';
		public static const RIGHT_BOTTOM:String = 'bottom_rotate';
		
		private var _id:String;

		
		public function HandleRotate ()
		{
			super();
		}
		
		public function set pid(value:String):void{
			_id = value;
		}

		override protected function startModifier(event:MouseEvent):void{
			parent.stage.addEventListener(MouseEvent.MOUSE_UP,releaseScale)
			addEventListener(Event.ENTER_FRAME,updatePosition);
			super.startModifier(event);
		}
		
		private function updatePosition(event:Event):void{
			dispatchEvent( new HandleEvent(HandleEvent.ROTATED,x,y,_id));
		}
		
		private function releaseScale(event:MouseEvent):void{
			//stopDrag();
			removeEventListener(Event.ENTER_FRAME,updatePosition);
			hideCursor(null)
		}
	}
}