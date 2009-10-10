/**
 * 
 * UI Modifier can modify width, height, x, y and rotation of every DisplayObject
 * Because Flash doesn't support pivot editing on runtime and therefor has no place
 * to store the pivot data. You have to store it somewhere. The Class dispatches an event
 * by every modification which contains the pivot location. Using the setTarget method
 * you can tell the Class the pivot location otherwise the pivot is always in the
 * centre of the DisplayObject.
 * 
 * version 1.0:
 * - Scaling + rotation + position works nicely on every type of DisplayObject of the real
 *   pivot point is located at 0,0
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
	import dv.events.UIModifierEvent;
	import dv.log.LogInstance;
	import dv.log.Logger;
	import dv.ui.modifier.handler.HandleCentre;
	import dv.ui.modifier.handler.HandleRotate;
	import dv.ui.modifier.handler.HandleScale;
	import dv.utils.MathUtils;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.managers.CursorManager;
	import mx.styles.CSSStyleDeclaration;
	import mx.styles.StyleManager;
	
	import nbilyk.utils.PivotRotate;
	
	[Event(name="modified", type="dv.events.UIMofifierEvent")]
	
	[IconFile("UIModifier.png")]


	[Style(name="borderColor", type="Number", inherit="no")]
	[Style(name="borderAlpha", type="Number", inherit="no")]
	[Style(name="borderThickness", type="Number", inherit="no")]
	[Style(name="scaleHandle", type="Class", inherit="no")]
	[Style(name="rotateHandle", type="Class", inherit="no")]
	[Style(name="centrePoint", type="Class", inherit="no")]
	[Style(name="cursorLeftRight", type="Class", inherit="no")]
	[Style(name="cursorRightLeft", type="Class", inherit="no")]
	[Style(name="cursorVertical", type="Class", inherit="no")]
	[Style(name="cursorHorizontal", type="Class", inherit="no")]
	[Style(name="cursorMove", type="Class", inherit="no")]
	[Style(name="cursorPivot", type="Class", inherit="no")]
	[Style(name="cursorRotate", type="Class", inherit="no")]
	

	public class UIModifier extends UIComponent
	{

		[Bindable] 
		private var _handle:Class;
		
		[Bindable] 
		private var _rotate_handle:Class;
		
		[Bindable]
		private var _centrePoint:Class;
		
		[Bindable] 
		private var _cursor_left_right:Class;
		
		[Bindable] 
		private var _cursor_right_left:Class;
		
		[Bindable] 
		private var _cursor_vertical:Class;
		
		[Bindable] 
		private var _cursor_horizontal:Class;
		
		[Bindable] 
		private var _cursor_move:Class;
		
		[Bindable] 
		private var _cursor_pivot:Class;
		
		[Bindable] 
		private var _cursor_rotate:Class;
		
		private var _overlay:UIComponent;
		private var _cross:UIComponent;
		private var _target:DisplayObject;
		private var _handles:Object;
		private var _maxBoundries:Rectangle = new Rectangle(0,0,1000,1000);
		private var _minBoundries:Rectangle = new Rectangle(0,0,10,10);
		private var _cursorID:Number;
		private var _centre:HandleCentre
		private var _modifier:UIComponent;
		private var _debug:Boolean = false;
		private var _created:Boolean = false;
		private var _resizeCounts:Number = 0;
		private var _resizeTries:Number = 10;
		private var _rotateHandlerSize:Object;
		private var _scaleMode:Number;
		private var _ratio:Number;
		
		private var _enableRotation:Boolean = true;
		private var _enableScaling:Boolean = true;
		private var _enableMoving:Boolean = true;
		
		private var _storage:Object;
		
		private var log:LogInstance = dv.log.Logger.createLogger( this );
		
		
		public static const DIRECTION_X:uint = 1;
		public static const DIRECTION_Y:uint = 2;
		public static const DIRECTION_BOTH:uint = 3;
		
		public static const SCALE_ALL:uint = 1;
		public static const SCALE_PROPORTIONAL:uint = 2;
		public static const SCALE_HORIZONTAL:uint = 3;
		public static const SCALE_VERTICAL:uint = 4;

		[Embed (source="/assets/graphics.swf",symbol="handle")]
		[Bindable] private static var __scaleHandle:Class;

		[Embed (source="/assets/graphics.swf",symbol="rotate_handle")]
		[Bindable] private static var __rotateHandle:Class;

		[Embed (source="/assets/graphics.swf",symbol="centrePoint")]
		[Bindable] private static var __centrePoint:Class;

		[Embed (source="/assets/graphics.swf",symbol="cursor_left_right")]
		[Bindable] private static var __cursorLeftRight:Class;

		[Embed (source="/assets/graphics.swf",symbol="cursor_right_left")]
		[Bindable] private static var __cursorRightLeft:Class;

		[Embed (source="/assets/graphics.swf",symbol="cursor_vertical")]
		[Bindable] private static var __cursorVertical:Class;

		[Embed (source="/assets/graphics.swf",symbol="cursor_horizontal")]
		[Bindable] private static var __cursorHorizontal:Class;

		[Embed (source="/assets/graphics.swf",symbol="cursor_move")]
		[Bindable] private static var __cursorMove:Class;

		[Embed (source="/assets/graphics.swf",symbol="cursor_pivot")]
		[Bindable] private static var __cursorPivot:Class;

		[Embed (source="/assets/graphics.swf",symbol="cursor_rotate")]
		[Bindable] private static var __cursorRotate:Class;
		
         // Define a static variable.
		private static var defaultStylesInitialized:Boolean = setDefaultStyles();

		private static function setDefaultStyles ():Boolean{
			
			var style:CSSStyleDeclaration = StyleManager.getStyleDeclaration("UIModifier");
			if (!style){
				// If there is no CSS definition for StyledRectangle, 
				// then create one and set the default value.
				style = new CSSStyleDeclaration();
				style.defaultFactory = function():void{
					this.borderColor      = 0x000000;
					this.borderThickness  = 0;
					this.borderAlpha      = 1;
					this.scaleHandle      = __scaleHandle;
					this.rotateHandle     = __rotateHandle
					this.centrePoint      = __centrePoint;
					this.cursorLeftRight  = __cursorLeftRight;
					this.cursorRightLeft  = __cursorRightLeft;
					this.cursorVertical   = __cursorVertical;
					this.cursorHorizontal = __cursorHorizontal;
					this.cursorMove       = __cursorMove;
					this.cursorPivot      = __cursorPivot;
					this.cursorRotate     = __cursorRotate;
				}
				StyleManager.setStyleDeclaration("UIModifier", style , true );
			}
			return true;
		}
	
		/**
		 * 
		 * 
		 */
		public function UIModifier()
		{
			super();
			focusEnabled = true;
			mouseEnabled = true;
			buttonMode = false;
		}
		
		override protected function createChildren():void {
			super.createChildren();
			createdHandler(null)
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			width = unscaledWidth;
			height = unscaledHeight;
			applyModifications();
		}
		
		private function createdHandler(event:FlexEvent):void
		{
			_handle = getStyle("scaleHandle");
			_rotate_handle = getStyle("rotateHandle");
			_centrePoint = getStyle("centrePoint");
			_cursor_left_right = getStyle("cursorLeftRight");
			_cursor_right_left = getStyle("cursorRightLeft");
			_cursor_vertical = getStyle("cursorVertical");
			_cursor_horizontal = getStyle("cursorHorizontal");
			_cursor_move = getStyle("cursorMove");
			_cursor_pivot = getStyle("cursorPivot");
			_cursor_rotate = getStyle("cursorRotate");
			
			_modifier = new UIComponent();
			addChild(_modifier);
			
			createHandles();
		}
		
		/**
		 * @return Boolean
		 */
		public function get debug():Boolean 
		{
			return _debug;
		}
		
		/**
		 * @param value
		 */
		public function set debug( value:Boolean ):void 
		{
			_debug = value;
		}
		
		/**
		 * @return Boolean
		 */
		public function get scaleMode():Number 
		{
			return _scaleMode;
		}
		
		/**
		 * @param value
		 */
		public function set scaleMode( value:Number ):void 
		{
			_scaleMode = value;
			if ( _created ) {
				handleVisibleScaleHandlers();
			}
		}
		
		/**
		 * @return Boolean
		 */
		public function get enableRotation():Boolean 
		{
			return _enableRotation;
		}
		
		/**
		 * @param value
		 */
		public function set enableRotation( value:Boolean ):void 
		{
			_enableRotation = value;
			if ( _created ) {
				handleVisibleScaleHandlers();
			}
		}
		
		/**
		 * @return Boolean
		 */
		public function get enableScaling():Boolean 
		{
			return _enableScaling;
		}
		
		/**
		 * @param value
		 */
		public function set enableScaling( value:Boolean ):void 
		{
			_enableScaling = value;
			if ( _created ) {
				handleVisibleScaleHandlers();
			}
		}
		
		/**
		 * @return Boolean
		 */
		public function get enableMoving():Boolean 
		{
			return _enableMoving;
		}
		
		/**
		 * @param value
		 */
		public function set enableMoving( value:Boolean ):void 
		{
			_enableMoving = value;
			if ( _created ) {
				handleVisibleScaleHandlers();
			}
		}
		
		/**
		 * @return Rectangle
		 */
		public function get maxBoundries():Rectangle 
		{
			return _maxBoundries
		}
		
		/**
		 * @param value
		 */
		public function set maxBoundries( value:Rectangle ):void 
		{
			_maxBoundries = value;
		}
	
		/**
		 * To use UIModifier you have to pass you objects which you want to modify
		 * through setTarget
		 * 
		 * @param value A displayobject where the graphics are starting at 0,0
		 * @param pivot The starting point where the rotation turns around
		 * 
		 */	
		public function setTarget(value:DisplayObject , pivot:Point = null ):void
		{
			_target = value;
			if ( pivot == null ) {
				_centre.pivot = new Point( _target.width / 2 ,_target.height / 2);
			}else{
				_centre.pivot = pivot;
			}
			_storage = {
				x:_target.x,
				y:_target.y,
				width:_target.width,
				height:_target.height,
				rotation:_target.rotation
			}
			
			
			_centre.bounds = new Rectangle(0,0,width,height);
			_ratio = _target.width / _target.height;
			
			x = _target.x;
			y = _target.y;
			rotation = _target.rotation
			width = _target.width;
			height = _target.height;
			
			applyModifications();
		}
			
		public function reset():void{
			x = _storage.x;
			y = _storage.y;
			width = _storage.width;
			height = _storage.height;
			rotation = _storage.rotation;
			applyModifications()
		}

		
		/**
		 *
		 * Correction on the rotation because the registration point is virtual the
		 * rotation needs reposition.
		 *  
		 * @param event
		 * 
		 */
		 
		private function updateHandleRotate(event:HandleEvent):void
		{
			var point:Point = HandleRotate( event.target ).startPoint;
			var startPoint:Point = new Point( mouseX  , mouseY  );
			
			var lineLength:Number = Point.distance( _centre.pivot , startPoint  );
			var corner:Number = -MathUtils.radian2degree( lineLength );
			var pivotRotate:PivotRotate = new PivotRotate(this,_centre.pivot);
			
			var overcorner:Number = startPoint.y - _centre.pivot.y;
			var extra:Number = Math.asin( overcorner / lineLength );
			
			log.info( startPoint ,  _centre.pivot );
			log.info( extra  ,overcorner  , lineLength );
			
			pivotRotate.rotation = - (  (corner - rotation) + extra );
			
			if ( debug ) {
	 			graphics.clear();
				graphics.lineStyle( 0 , 0xFF0000 , 1 );
				graphics.moveTo(_centre.pivot.x,_centre.pivot.y);
				graphics.lineTo( point.x , point.y );
				graphics.moveTo(_centre.pivot.x,_centre.pivot.y);
				graphics.lineTo( startPoint.x , startPoint.y );
			}
			applyModifications();
		}
		
		/**
		 * 
		 * Correction on the positioning of the subject in all directions
		 * 
		 * @param position
		 * @return 
		 * 
		 */
		private function calculatePosition ( position:Point , direction:Number = 1 ) : Point
		{
			var xpos:Number;
			var ypos:Number;
			var radians:Number = MathUtils.degree2radian ( rotation );
			
			switch ( direction ) {
				case DIRECTION_X:
					xpos = position.x * Math.cos(radians);
					ypos = position.x * Math.sin(radians);
					break;
				case DIRECTION_Y:
					xpos = position.y * Math.sin(-radians);
					ypos = position.y * Math.cos(-radians);
					break;
				case DIRECTION_BOTH:
					var x1:Number = position.x * Math.cos(radians);
					var x2:Number = position.y * Math.sin(-radians);
					var y1:Number = position.x * Math.sin(radians);
					var y2:Number = position.y * Math.cos(-radians);
					xpos = x1 + x2
					ypos = y2 + y1
					break;
			}
			
			
			if ( debug ) {
				graphics.clear()
				graphics.lineStyle(0,0xFF0000);
				graphics.moveTo(position.x,position.y)
				graphics.lineTo(xpos,ypos)
			}
			
			return new Point ( xpos , ypos );
		}
		
		/**
		 * 
		 * Every handle can scale the subject but rotation has effect of scaling because the
		 * actual registration point is not modified and width and height are not the 
		 * real values the modification need. Not every handle has trouble with rotation. 
		 * The right bottom, bottom and the right handle doesn't need correction
		 * The right top, left bottom, top and the left need one direction correction
		 * The left top needs correction in all directions
		 * 
		 * @param event
		 * 
		 */
		private function updateHandleMove(event:HandleEvent):void
		{
			var position:Point
			switch ( event.id ) {
				// Modify properties that always work (rotation has no effect)
				case HandleScale.RIGHT_BOTTOM:
					_handles.right_top.x = event.x
					_handles.left_bottom.y = event.y
					break;
				case HandleScale.BOTTOM:
					_handles.right_bottom.y = event.y
					break;
				case HandleScale.RIGHT:
					_handles.right_bottom.x = event.x
					break;
				
				// Modify properties that need reposition once
				case HandleScale.RIGHT_TOP:
 					position = calculatePosition ( new Point ( event.x , event.y ) , DIRECTION_Y );
					x += position.x;
					y += position.y;
					_handles.right_bottom.x = event.x
					_handles.right_bottom.y -= event.y
					break;
				case HandleScale.LEFT_BOTTOM:
					position = calculatePosition ( new Point ( event.x , event.y ) , DIRECTION_X );
					x += position.x;
					y += position.y;
					_handles.right_bottom.x -= event.x
					_handles.right_bottom.y = event.y
					break;
				case HandleScale.TOP:
					position = calculatePosition ( new Point ( event.x , event.y ) , DIRECTION_Y );
					x += position.x;
					y += position.y;
					_handles.right_bottom.y -= event.y
					break;
				case HandleScale.LEFT:
					position = calculatePosition ( new Point ( event.x , event.y ) , DIRECTION_X );
					x += position.x;
					y += position.y;
					_handles.right_bottom.x -= event.x
					break;

				
				// Modify properties that need reposition twice
				case HandleScale.LEFT_TOP:
					position = calculatePosition ( new Point ( event.x , event.y ) , DIRECTION_BOTH );
					x += position.x;
					y += position.y;
					_handles.left_top.x = 0;
					_handles.left_top.y = 0;
					_handles.right_bottom.x -= event.x
					_handles.right_bottom.y -= event.y
					
					break;
			}
			
			width  = Math.round(_handles.right_bottom.x)
			height = Math.round(_handles.right_bottom.y)
			applyModifications()
		}
		
		/**
		 * Start dragging the subject
		 * 
		 * @param event
		 * 
		 */
		private function startDragging(event:MouseEvent):void
		{
			var max:Rectangle = _maxBoundries.clone()
			max.width -= width
			max.height -= height
			startDrag(false, max )
			stage.addEventListener(MouseEvent.MOUSE_UP,stopDragging);
			stage.addEventListener(Event.ENTER_FRAME,repositionTarget);
		}
		
		/**
		 * Called every time the user moves it's mouse while dragging subject
		 * 
		 * @param event
		 * 
		 */
		private function repositionTarget(event:Event):void
		{
			applyModifications();
		}
		
		/**
		 * Called when user decides to stop the dragging
		 * 
		 * @param event
		 * 
		 */
		private function stopDragging(event:MouseEvent):void
		{
			stopDrag();
			stage.removeEventListener(MouseEvent.MOUSE_UP,stopDragging);
			stage.removeEventListener(Event.ENTER_FRAME,repositionTarget);
			applyModifications();
		}

		/**
		 * Dispatches all modification
		 */
		private function updateModifiedData():void
		{
			dispatchEvent( new UIModifierEvent( UIModifierEvent.MODIFIED,x,y,width,height,rotation,_centre.pivot));
		}
		
		/**
		 * Create all handlers
		 */
		private function createHandles():void
		{
			_overlay = new UIComponent();
			_modifier.addChild(_overlay);
			
			_handles = {}
			
			var rotate:HandleRotate;
			
			var rotateObjects:Array = [
				HandleRotate.LEFT_BOTTOM,
				HandleRotate.LEFT_TOP,
				HandleRotate.RIGHT_BOTTOM,
				HandleRotate.RIGHT_TOP
			]
			for ( var i:Number = 0 ; i < rotateObjects.length ; i++ ) {
				rotate = new HandleRotate();
				rotate.visual = _rotate_handle;
				rotate.pid = rotateObjects[i];
				rotate.cursor = _cursor_rotate;
				rotate.addEventListener(HandleEvent.ROTATED,updateHandleRotate);
				_modifier.addChild(rotate);
				_handles[rotateObjects[i]] = rotate;
				if ( !debug ) {
					rotate.alpha = 0;
				}
			}
			
			var handle:HandleScale
			var scaleObjects:Array = [
				{name:HandleScale.LEFT_BOTTOM,cursor:_cursor_left_right},
				{name:HandleScale.LEFT_TOP,cursor:_cursor_right_left},
				{name:HandleScale.RIGHT_BOTTOM,cursor:_cursor_right_left},
				{name:HandleScale.RIGHT_TOP,cursor:_cursor_left_right},
				{name:HandleScale.LEFT,cursor:_cursor_horizontal},
				{name:HandleScale.TOP,cursor:_cursor_vertical},
				{name:HandleScale.RIGHT,cursor:_cursor_horizontal},
				{name:HandleScale.BOTTOM,cursor:_cursor_vertical}
			]
			
			var handles:UIComponent = new UIComponent();
			
			for ( i = 0 ; i < scaleObjects.length ; i++ ) {
				handle = new HandleScale();
				handle.visual = _handle;
				handle.pid = scaleObjects[i].name;
				handle.cursor = scaleObjects[i].cursor
				handle.addEventListener(HandleEvent.MOVED,updateHandleMove);
				handles.addChild(handle);
				_handles[scaleObjects[i].name] = handle;
			}
			
			_modifier.addChild(handles);
			
			
			_centre = new HandleCentre();
			_centre.visual = _centrePoint;
			_centre.cursor = _cursor_pivot;
			
			_modifier.addChild(_centre);
			
			_created = true;
			handleVisibleScaleHandlers()
		}
		
		/**
		 * Handle different modes of movement, scaling and rotation 
		 * 
		 */
		private function handleVisibleScaleHandlers():void
		{
			_handles[HandleRotate.LEFT_TOP].visible = _enableRotation;
			_handles[HandleRotate.RIGHT_TOP].visible = _enableRotation;
			_handles[HandleRotate.LEFT_BOTTOM].visible = _enableRotation;
			_handles[HandleRotate.RIGHT_BOTTOM].visible = _enableRotation;
			_centre.visible = _enableRotation;
			
			_handles[HandleScale.LEFT_BOTTOM].visible = _enableScaling;
			_handles[HandleScale.LEFT_TOP].visible = _enableScaling;
			_handles[HandleScale.LEFT].visible = _enableScaling;
			_handles[HandleScale.RIGHT_BOTTOM].visible = _enableScaling;
			_handles[HandleScale.RIGHT_TOP].visible = _enableScaling;
			_handles[HandleScale.RIGHT].visible = _enableScaling;
			_handles[HandleScale.TOP].visible = _enableScaling;
			_handles[HandleScale.BOTTOM].visible = _enableScaling;
			
			if ( _enableScaling ) {
				switch ( scaleMode ) {
					case SCALE_ALL:
						break;
					case SCALE_PROPORTIONAL:
						_handles[HandleScale.LEFT].visible = false;
						_handles[HandleScale.BOTTOM].visible = false;
						_handles[HandleScale.TOP].visible = false;
						_handles[HandleScale.RIGHT].visible = false;
						break;
					case SCALE_VERTICAL:
						_handles[HandleScale.LEFT_BOTTOM].visible = false;
						_handles[HandleScale.LEFT_TOP].visible = false;
						_handles[HandleScale.RIGHT_BOTTOM].visible = false;
						_handles[HandleScale.RIGHT_TOP].visible = false;
						_handles[HandleScale.RIGHT].visible = false;
						_handles[HandleScale.LEFT].visible = false;
						break;
					case SCALE_HORIZONTAL:
						_handles[HandleScale.LEFT_BOTTOM].visible = false;
						_handles[HandleScale.LEFT_TOP].visible = false;
						_handles[HandleScale.RIGHT_BOTTOM].visible = false;
						_handles[HandleScale.RIGHT_TOP].visible = false;
						_handles[HandleScale.TOP].visible = false;
						_handles[HandleScale.BOTTOM].visible = false;
						break;
				}
			}
			
			var hasEvent:Boolean = _overlay.hasEventListener(MouseEvent.MOUSE_DOWN)
			if ( _enableMoving && !hasEvent ) {
				_overlay.addEventListener(MouseEvent.MOUSE_DOWN,startDragging);
				_overlay.addEventListener(MouseEvent.MOUSE_OVER,showCursor)
				_overlay.addEventListener(MouseEvent.MOUSE_OUT,hideCursor)
			}else if( !_enableMoving && hasEvent ){
				_overlay.removeEventListener(MouseEvent.MOUSE_DOWN,startDragging);
				_overlay.removeEventListener(MouseEvent.MOUSE_OVER,showCursor)
				_overlay.removeEventListener(MouseEvent.MOUSE_OUT,hideCursor)
			}
		}
		
		/**
		 * Apply the modifications to the target and send them out as an event.
		 * Also start the event to ensure the graphics display correctly.
		 * 
		 */
		private function applyModifications():void
		{
			if ( _target != null ) {
				_target.x = x;	
				_target.y = y;
				_target.rotation = rotation
			}
			updateModifiedData()
			_resizeCounts = 0;
			if ( !hasEventListener(Event.ENTER_FRAME) ) {
				addEventListener(Event.ENTER_FRAME,_resize);
			}
		}
		
		/**
		 * Every time "applyModifications" is triggered, resizing is done 
		 * via variable _resizeCount
		 *  
		 * @param event
		 * 
		 */
		private function _resize(event:Event):void
		{
			if ( width < _minBoundries.width ){
				width = _minBoundries.width
			}
			if ( height < _minBoundries.height ){
				height = _minBoundries.height
			}
			// apply ratio if scaleMode is set to SCALE_PROPORTIANAL ( Experimental )
			if ( scaleMode == SCALE_PROPORTIONAL ) {
				height = width * _ratio;
			}
			
			var rotate:HandleRotate = _handles[HandleRotate.LEFT_BOTTOM]
			_rotateHandlerSize = {width:rotate.width,height:rotate.height}
			
			
			_handles[HandleRotate.LEFT_TOP].x = -(_rotateHandlerSize.width/2);
			_handles[HandleRotate.LEFT_TOP].y = -(_rotateHandlerSize.height/2);
			_handles[HandleRotate.LEFT_BOTTOM].x = -(_rotateHandlerSize.width/2);
			_handles[HandleRotate.LEFT_BOTTOM].y = height + (_rotateHandlerSize.height/2);
			_handles[HandleRotate.RIGHT_TOP].x = width + (_rotateHandlerSize.width/2);
			_handles[HandleRotate.RIGHT_TOP].y = -(_rotateHandlerSize.height/2);
			_handles[HandleRotate.RIGHT_BOTTOM].x = width + (_rotateHandlerSize.width/2);
			_handles[HandleRotate.RIGHT_BOTTOM].y = height +(_rotateHandlerSize.height/2);
			
			_handles[HandleScale.LEFT_BOTTOM].x = 0;
			_handles[HandleScale.LEFT_BOTTOM].y = height;
			_handles[HandleScale.RIGHT_TOP].x = width;
			_handles[HandleScale.RIGHT_TOP].y = 0;
			_handles[HandleScale.RIGHT_BOTTOM].x = width;
			_handles[HandleScale.RIGHT_BOTTOM].y = height;
/* 			
			_handles[HandleScale.LEFT_BOTTOM].bounds  = new Rectangle(10,10,-1000, 1000);
			_handles[HandleScale.LEFT_TOP].bounds     = new Rectangle(10,10,-1000,-1000);
			_handles[HandleScale.RIGHT_TOP].bounds    = new Rectangle(10,10, 1000,-1000);
			_handles[HandleScale.RIGHT_BOTTOM].bounds = new Rectangle(10,10, 1000, 1000);
			_handles[HandleScale.LEFT].bounds         = new Rectangle(10,10,-1000, 1000);
			_handles[HandleScale.TOP].bounds          = new Rectangle(10,10,-1000,-1000);
			_handles[HandleScale.RIGHT].bounds        = new Rectangle(10,10, 1000,-1000);
			_handles[HandleScale.BOTTOM].bounds       = new Rectangle(10,10, 1000, 1000);
*/
			
			_handles[HandleScale.TOP].x = width / 2;
			_handles[HandleScale.TOP].y = 0;
			
			_handles[HandleScale.BOTTOM].x = width / 2;
			_handles[HandleScale.BOTTOM].y = height;
			
			_handles[HandleScale.LEFT].x = 0
			_handles[HandleScale.LEFT].y = height / 2
			
			_handles[HandleScale.RIGHT].x = width
			_handles[HandleScale.RIGHT].y = height / 2
			
			_overlay.width = width
			_overlay.height = height;
			
			_overlay.graphics.clear()
			_overlay.graphics.lineStyle(getStyle("borderThickness"),getStyle("borderColor"),getStyle("borderAlpha"));
			_overlay.graphics.beginFill(0xffffff,0);
			_overlay.graphics.drawRect(0,0,width,height);
			
			if ( _target != null ) {
				_target.width = width
				_target.height = height
			}
			
			_centre.bounds = new Rectangle(0,0,width,height);
			
			_resizeCounts ++
			if ( _resizeCounts > _resizeTries ) {
				removeEventListener(Event.ENTER_FRAME,_resize);
				updateModifiedData()
			}
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */
		private function showCursor(event:MouseEvent):void
		{
			_cursorID = CursorManager.setCursor(_cursor_move);
		}
		
		/**
		 * 
		 * @param event
		 * 
		 */
		private function hideCursor(event:MouseEvent):void
		{
			CursorManager.removeCursor(_cursorID);
		}
	}
}