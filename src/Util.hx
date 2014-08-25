package ;

class Util {
	public static inline function rad2deg(r:Float):Float {
		var a =	(r * 180.0 / Math.PI);

		return (360) * ((a / (360)) - Math.floor(a / (360)));
	}
}
