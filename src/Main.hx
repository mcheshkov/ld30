package ;

import flash.Lib;
import flash.display.Sprite;

class Main extends Sprite {
	public static function main():Void {
		Lib.current.stage.addChild(new Menu());
	}
}
