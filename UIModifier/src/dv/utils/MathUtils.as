/**
 * Basic math simplified
 *  
 * @author Martijn van Beek [martijn.vanbeek at gmail dot com]
 * @since September, Oktober 2008
 * @version 1.0
 * @license BSD
 * 
 */

package dv.utils
{
	import flash.geom.Point;
	
	public class MathUtils
	{

		/**
		 * Convert degrees to radians
		 *  
		 * @param radians
		 * @return 
		 * 
		 */
		public static function degree2radian (radians:Number):Number
		{
			return radians * ( Math.PI / 180 );
		}
	
		/**
		 * Convert radians to degrees
		 * 
		 * @param degree
		 * @return 
		 * 
		 */
		public static function radian2degree ( degree:Number):Number
		{
			return degree * ( 180 / Math.PI ) ;
		}
	
		/**
		 * Calculate the distance between given points
		 *  
		 * @param pointA
		 * @param pointB
		 * @return 
		 * 
		 */
		public static function distance ( pointA:Point , pointB:Point ):Number
		{
			var dx:Number = pointA.x - pointB.x;
			var dy:Number = pointA.y - pointB.y;
			return Math.atan2(dy, dx);
		}
	}
}