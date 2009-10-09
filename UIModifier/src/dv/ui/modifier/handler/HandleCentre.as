/**
 * Handler for pivot point
 *  
 * @author Martijn van Beek [martijn.vanbeek at gmail dot com]
 * @since September, Oktober 2008
 * @version 1.0
 * @license BSD
 * 
 */

package dv.ui.modifier.handler
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.managers.CursorManager;
	
	
	[ExcludeClass]
	public final class HandleCentre extends MouseHandler
	{
		
		private var _pivot:Point;
		private var _cursor:Class;
		private var _cursorID:Number;
		private var _bounds:Rectangle;
		
		public function HandleCentre()
		{
			super();
			updatePosition(null);
		}
		
		public function set bounds ( value:Rectangle ):void
		{
			/* _bounds = value;
			if (x > value.width ) x = value.width
			if (y > value.height ) y = value.height */
		}
		
		[Bindable]
		public function get pivot():Point{
			return _pivot;
		}
		
		public function set pivot(value:Point):void{
			x = value.x
			y = value.y
			_pivot = value
		}
		
		override protected function startModifier(event:MouseEvent):void
		{
			startDrag(false,_bounds);
			parent.stage.addEventListener(MouseEvent.MOUSE_UP,releaseReposition)
			addEventListener(Event.ENTER_FRAME,updatePosition);
		}
		
		private function releaseReposition(event:MouseEvent):void
		{
			stopDrag();
			parent.stage.removeEventListener(MouseEvent.MOUSE_UP,releaseReposition)
			removeEventListener(Event.ENTER_FRAME,updatePosition);
		}
		
		private function updatePosition(event:Event):void
		{
			x = Math.round(x)
			y = Math.round(y)
			pivot = new Point(x,y);
		}	
	}
}