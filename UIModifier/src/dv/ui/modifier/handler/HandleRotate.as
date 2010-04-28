/**
 * Handler for rotation
 *  
 * @author Martijn van Beek [martijn.vanbeek at gmail dot com]
 * @since September, Oktober 2008
 * @version 1.0
 * @license BSD
 * 
 */

package dv.ui.modifier.handler
{
	import dv.events.HandleEvent;
	import dv.utils.UIModifierFrameTicker;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	public final class HandleRotate extends MouseHandler
	{
		
		public static const LEFT_TOP:String = 'left_rotate';
		public static const RIGHT_TOP:String = 'right_rotate';
		public static const LEFT_BOTTOM:String = 'top_rotate';
		public static const RIGHT_BOTTOM:String = 'bottom_rotate';
		
		private var _id:String;

		private var _startPoint:Point;
		
		public function HandleRotate ()
		{
			super();
		}
		
		public function get startPoint():Point
		{
			return _startPoint;
		}

		public function set startPoint(value:Point):void
		{
			_startPoint = value;
		}

		public function set pid(value:String):void{
			_id = value;
		}

		override protected function startModifier(event:MouseEvent):void{
			startPoint = new Point ( parent.mouseX , parent.mouseY );
			parent.stage.addEventListener(MouseEvent.MOUSE_UP,releaseScale)
			UIModifierFrameTicker.getInstance().addEventListener(UIModifierFrameTicker.FRAME_TICK, updatePosition, false, 0, true);
			super.startModifier(event);
		}
		
		private function updatePosition(event:Event):void{
			dispatchEvent( new HandleEvent(HandleEvent.ROTATED,x,y,_id));
		}
		
		private function releaseScale(event:MouseEvent):void{
			//stopDrag();
			UIModifierFrameTicker.getInstance().removeEventListener(UIModifierFrameTicker.FRAME_TICK ,updatePosition);
			hideCursor(null);
		}
	}
}