package ;

import flash.media.Sound;
import flash.media.SoundChannel;
import openfl.Assets;
import flash.display.Bitmap;
import flash.events.KeyboardEvent;
import flash.events.Event;
import flash.text.TextFormat;
import flash.Lib;
import flash.text.TextFieldAutoSize;
import flash.text.TextField;
import flash.display.Sprite;

class Menu extends Sprite{
	private var _tf:TextField;

	static var raskadrovka0 = "raskadrovka/0.jpg";
	static var raskadrovka1 = "raskadrovka/1.jpg";
	static var raskadrovka2 = "raskadrovka/2.jpg";
	static var raskadrovka3 = "raskadrovka/3.jpg";
	static var raskadrovka4 = "raskadrovka/4.jpg";
	static var raskadrovka5 = "raskadrovka/5.jpg";
	static var raskadrovka6 = "raskadrovka/6.jpg";

	var frames:Array<Bitmap> = [];
	var frame = 0;

	var time:Float = 0;
	var currentTime:Float = 0;
	public var prevTime:Float = 0;
	public var nextFrameTime:Float = 300;

	var bg:Sprite;

	public function new() {
		super();

		INSTANCE = this;

		prevTime = flash.Lib.getTimer();
		currentTime = flash.Lib.getTimer();

		frames.push(new Bitmap(Assets.getBitmapData(raskadrovka0)));
		frames.push(new Bitmap(Assets.getBitmapData(raskadrovka1)));
		frames.push(new Bitmap(Assets.getBitmapData(raskadrovka2)));
		frames.push(new Bitmap(Assets.getBitmapData(raskadrovka3)));
		frames.push(new Bitmap(Assets.getBitmapData(raskadrovka4)));
		frames.push(new Bitmap(Assets.getBitmapData(raskadrovka5)));
		frames.push(new Bitmap(Assets.getBitmapData(raskadrovka6)));

		bg = new Sprite();

		bg.addChild(frames[frame]);

		_tf = new TextField();
		var tff = new TextFormat();
		tff.color = 0xffffff;
		tff.size = 36;
		_tf.x = 550;
		_tf.y = 600;
		_tf.defaultTextFormat = tff;
		_tf.autoSize = TextFieldAutoSize.CENTER;
		_tf.text = "Martial Canterel\npress x";

		addChild(bg);
		bg.x = (1600 - bg.width) / 2;
		bg.y = (1000 - bg.height) / 2;
		addChild(_tf);

		bgmSound = Assets.getMusic("music/microcosmos444.mp3");
		bgmSoundChannel = bgmSound.play();
		bgmSoundChannel.addEventListener( Event.SOUND_COMPLETE, onBackgroundMusicFinished );

		addListeners();
	}

	var bgmSound:Sound;
	var bgmSoundChannel:SoundChannel;

	public function addListeners(){
		Lib.current.stage.addEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
		Lib.current.stage.addEventListener(Event.ENTER_FRAME,onEnterFrame);
	}

	function removeListeners(){
		Lib.current.stage.removeEventListener(KeyboardEvent.KEY_DOWN,onKeyDown);
		Lib.current.stage.removeEventListener(Event.ENTER_FRAME,onEnterFrame);
	}

	function onEnterFrame(e:Event){
		bg.removeChild(frames[frame]);

		prevTime = currentTime;
		currentTime = flash.Lib.getTimer();
		var diff = currentTime - prevTime;
		time += diff;
		if (time >= nextFrameTime){
			frame++;
			frame %= frames.length;
			time -= nextFrameTime;

			var lambda = .01;
			nextFrameTime = 60 + -1.0 / lambda * Math.log(Math.random());
		}

		bg.addChild(frames[frame]);
	}

	static inline var KEY_X = 88;

	function onKeyDown(e:KeyboardEvent):Void {
		if (e.keyCode == KEY_X){
			removeListeners();
			Lib.current.stage.removeChild(this);
			Lib.current.stage.addChild(new Game());
		}
	}

	public static var INSTANCE:Menu;

	public function onBackgroundMusicFinished( event:Event ):Void
	{
		bgmSoundChannel.removeEventListener( Event.SOUND_COMPLETE, onBackgroundMusicFinished );
		bgmSoundChannel = bgmSound.play();
		bgmSoundChannel.addEventListener( Event.SOUND_COMPLETE, onBackgroundMusicFinished );
	}
}
