package ;

import motion.Actuate;
import flash.filters.BlurFilter;
import flash.events.MouseEvent;
import nape.constraint.PivotJoint;
import nape.constraint.WeldJoint;
import nape.phys.Compound;
import nape.callbacks.PreListener;
import flash.display.Bitmap;
import openfl.Assets;
import nape.shape.Shape;
import nape.callbacks.InteractionCallback;
import nape.callbacks.InteractionType;
import nape.callbacks.CbEvent;
import nape.callbacks.CbType;
import nape.callbacks.InteractionListener;
import flash.events.KeyboardEvent;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.phys.BodyType;
import nape.phys.Body;
import flash.events.Event;
import nape.geom.Vec2;
import nape.util.Debug;
import nape.util.BitmapDebug;
import nape.space.Space;
import flash.Lib;
import flash.display.Sprite;
import Util.rad2deg;

class Game extends Sprite {

	static inline var DEBUG_DRAW:Bool = false;

	static var mainPlanetPath = "gfx/main_planet.png";
	static var planet2Path = "gfx/planet2.png";
	static var planet3Path = "gfx/planet3.png";
	static var planet4Path = "gfx/planet4.png";
	static var planet5Path = "gfx/planet5.png";
	static var planet6Path = "gfx/planet6.png";
	static var handPath = "gfx/hand_2.png";

	static var fon1Path = "gfx/fon/fon1.png";
	static var fon2Path = "gfx/fon/fon2.png";
	static var fon3Path = "gfx/fon/fon3.png";
	static var fon4Path = "gfx/fon/fon4.png";
	static var fon5Path = "gfx/fon/fon5.png";

	public function new(){
		super();

		floorType = new CbType();
		stickType = new CbType();
		planetType = new CbType();

		if (stage != null) {
			initialise(null);
		}
		else {
			addEventListener(Event.ADDED_TO_STAGE, initialise);
		}
	}


	var space:Space;
	var debug:Debug;

	var handJoint:PivotJoint;

	var heroBody:Body;
	var heroCompound:Compound;

	var planets:Array<{body:Body,sprite:Sprite}> = [];
	var planetType:CbType;
	var stickType:CbType;
	var floorType:CbType;

	static inline var GRAV = 600;

	static inline var FLOOR_X = 0;
	static inline var FLOOR_Y = 950;
	static inline var FLOOR_W = 15000;
	static inline var FLOOR_H = 1;

	var bg:Sprite;
	var fonPaths = [];

	function initialise(ev:Event):Void {
		if (ev != null) {
			removeEventListener(Event.ADDED_TO_STAGE, initialise);
		}

//		fonPaths = [fon1Path,fon2Path,fon3Path,fon4Path,fon5Path];
		fonPaths = [fon2Path,fon3Path,fon4Path,fon5Path];

		bg = new Sprite();
		initBg();
		addChild(bg);

// Create a new simulation Space.
// Weak Vec2 will be automatically sent to object pool.
// when used as argument to Space constructor.
		var gravity = Vec2.weak(0, GRAV);
		space = new Space(gravity);

// Create a new BitmapDebug screen matching stage dimensions and
// background colour.
// The Debug object itself is not a DisplayObject, we add its
// display property to the display list.
		if (DEBUG_DRAW){
			debug = new BitmapDebug(5000, stage.stageHeight, stage.color);
			debug.drawConstraints = true;
			debug.drawBodyDetail = true;
			addChild(debug.display);
		}

		setUp();

		stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
		stage.addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
		stage.addEventListener(Event.ENTER_FRAME, enterFrameHandler);
		stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
		stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
	}

	function initBg(){
		var prevIdx:Null<Int> = null;
		for (i in 0 ... 10){
			var idx;
			do{
				idx = Math.floor(Math.random()*fonPaths.length);
			} while (prevIdx != null && idx == prevIdx);
			prevIdx = idx;
			var fon = new Bitmap(Assets.getBitmapData(fonPaths[idx]));
			fon.x = i*1000 + Math.random()*100;
			fon.scaleX = fon.scaleY = 1 + Math.random();
			fon.alpha = 0.4 - 0.1 * fon.scaleY - Math.random() * 0.1;
			fon.filters = [new BlurFilter(fon.scaleY*2, fon.scaleY*2)];
			bg.addChild(fon);

			function addMovingAlpha(){
				Actuate.tween(fon,2,{alpha:Math.random()}).onComplete(addMovingAlpha);
			}

//			addMovingAlpha();
		}
	}

	function setUp() {
		var w = stage.stageWidth;
		var h = stage.stageHeight;


		handJoint = new PivotJoint(space.world, null, Vec2.weak(), Vec2.weak());
		handJoint.space = space;
		handJoint.active = false;

// Create the floor for the simulation.
// We use a STATIC type object, and give it a single
// Polygon with vertices defined by Polygon.rect utility
// whose arguments are (x, y) of top-left corner and the
// width and height.
//
// A static object does not rotate, so we don't need to
// care that the origin of the Body (0, 0) is not in the
// centre of the Body's shapes.
		var floor = new Body(BodyType.STATIC);
		floor.shapes.add(new Polygon(Polygon.rect(FLOOR_X, FLOOR_Y, FLOOR_W, FLOOR_H)));
		floor.space = space;

		floor.cbTypes.add(floorType);

// Create a tower of boxes.
// We use a DYNAMIC type object, and give it a single
// Polygon with vertices defined by Polygon.box utility
// whose arguments are the width and height of box.
//
// Polygon.box(w, h) === Polygon.rect((-w / 2), (-h / 2), w, h)
// which means we get a box whose centre is the body origin (0, 0)
// and that when this object rotates about its centre it will
// act as expected.

//		for (i in 0...16) {
//			var box = new Body(BodyType.DYNAMIC);
//			box.shapes.add(new Polygon(Polygon.box(16, 32)));
//			box.position.setxy((w / 2), ((h - 50) - 32 * (i + 0.5)));
//			box.space = space;
//		}

// Create the rolling ball.
// We use a DYNAMIC type object, and give it a single
// Circle with radius 50px. Unless specified otherwise
// in the second optional argument, the circle is always
// centered at the origin.
//
// we give it an angular velocity so when it touched
// the floor it will begin rolling towards the tower.


		for (i in 0 ... 10){
			planets.push(makePlanet());
		}

		heroBody = planets[0].body;
		heroCompound = heroBody.compound;

		heroBody.position.setxy(50, 800);
		heroBody.angularVel = 10;

		for (i in 1 ... 10){
			planets[i].body.position.setxy(400 + 1000*i + Math.random()*250, stage.height * 0.8);
			planets[i].body.rotation = Math.random()*Math.PI;
		}

		space.listeners.add(new InteractionListener(CbEvent.ONGOING,InteractionType.COLLISION,stickType,floorType,onStickFloorCollide));
		space.listeners.add(new InteractionListener(CbEvent.BEGIN,InteractionType.COLLISION,stickType,stickType,onStickStickCollide));

		for (p in planets)
			addChild(p.sprite);

		updateGfxFromPhys();

// In each case we have used for adding a Shape to a Body
// body.shapes.add(shape);
// We can also use:
// shape.body = body;
//
// And for adding the Body to a Space:
// body.space = space;
// We can also use:
// space.bodies.add(body);
	}

	static var planetRadius:Float = 68.0;
	static var stickLength:Float = 25.0;
	static var stickWidth:Float = 19;

	static inline var PLANET_MASS:Float = 50;

	function makePlanet(){
		var planet = new Body(BodyType.DYNAMIC);
		planet.gravMass = PLANET_MASS;
		planet.shapes.add(new Circle(planetRadius));
		var stick = new Polygon(Polygon.box(stickWidth, planetRadius+stickLength));
		stick.translate(new Vec2(0,planetRadius));
		stick.cbTypes.add(stickType);
		planet.shapes.add(stick);
		var cmpnd = new Compound();
		cmpnd.bodies.add(planet);
		cmpnd.space = space;

		var planetSprite = new Sprite();
//		planetSprite.graphics.beginFill(0xccff77);
//		planetSprite.graphics.drawRect(-10,-10,20,20);
//		planetSprite.graphics.endFill();
		var planetPaths = [mainPlanetPath,planet2Path,planet3Path,planet4Path,planet5Path,planet6Path];
		var idx = Math.floor(Math.random() * planetPaths.length);
		var planetPath = planetPaths[idx];
		var bmp = new Bitmap(Assets.getBitmapData(planetPath));
		bmp.scaleX = bmp.scaleY = 0.3;
		bmp.x -= bmp.width/2;
		bmp.y -= bmp.height/2;
		bmp.smoothing = false;
		planetSprite.addChild(bmp);

		bmp = new Bitmap(Assets.getBitmapData(handPath));
		bmp.scaleX = 0.1;
		bmp.scaleY = -0.1;
		bmp.x -= bmp.width/2;
		bmp.y -= bmp.height/2;
		bmp.rotation = 90;
		bmp.x += 40;
		planetSprite.addChild(bmp);

		planet.cbTypes.add(planetType);

		return {body:planet,sprite:planetSprite};
	}

	function makeNewStick(){
		var stickBody = new Body(BodyType.DYNAMIC);
		var stick = new Polygon(Polygon.box(stickWidth, planetRadius+stickLength));
		stick.cbTypes.add(stickType);
		stickBody.shapes.add(stick);

		var stickSprite = new Sprite();
//		planetSprite.graphics.beginFill(0xccff77);
//		planetSprite.graphics.drawRect(-10,-10,20,20);
//		planetSprite.graphics.endFill();

		var bmp = new Bitmap(Assets.getBitmapData(handPath));
		bmp.scaleX = 0.1;
		bmp.scaleY = -0.1;
		bmp.x -= bmp.width/2;
		bmp.y -= bmp.height/2;
		bmp.rotation = 90;
		bmp.x += 40;
		bmp.y -= 50;
		stickSprite.addChild(bmp);

		return {body:stickBody,sprite:stickSprite};
	}

	function onStickStickCollide(cb:InteractionCallback){
		var b1:Body = cb.int1.castShape.body;
		var b2:Body = cb.int2.castShape.body;

		if (b2.compound == heroCompound){
			var b3 = b2;
			b2 = b1;
			b1 = b3;
		}

		if (b1.compound == heroCompound){
//			var bc2 = null;
//			var bs2 = null;
//			for (s in b2.shapes){
//				if (s.isCircle()) bc2 = s;
//				else bs2 = s;
//			}
//			var wp2 = b2.localPointToWorld(new Vec2(0,0));
//			var d = heroBody.worldPointToLocal(wp2);
//			b2.space = null;
//			heroBody.shapes.add(bc2.copy().translate(d));
//			heroBody.shapes.add(bs2.copy().translate(d));
			for (a in cb.arbiters){
				if (!a.isCollisionArbiter()) continue;
				var ca = a.collisionArbiter;
				for (cont in ca.contacts){
					//trace(cont);
				}
			}
			b1.compound.bodies.add(b2);
			var zero = new Vec2(0,0);
			var c1 = b1.localPointToWorld(zero);
			var c2 = b2.localPointToWorld(zero);
//			var c1 = heroBody.worldCOM;
//			var c2 = b2.worldCOM;
			var c3 = c2.add(c1);
			c3.muleq(0.5);
			var a1 = b1.worldPointToLocal(c3);
			var a2 = b2.worldPointToLocal(c3);
			for (s in b2.shapes){
				s.cbTypes.clear();
			}
			for (s in b1.shapes){
				s.cbTypes.clear();
			}
			var planetCount =0;
			for (body in b1.compound.bodies){
				for(sh in body.shapes){
					if (sh.isCircle()) planetCount++;
				}
			}
			for (body in b1.compound.bodies){
				body.gravMass = PLANET_MASS / Math.pow(planetCount,1.2);
			}
//			heroBody.compound.constraints.add(new WeldJoint(heroBody,b2,a1,a2, Math.PI));
			var constr = new WeldJoint(b1,b2,a1,a2, b2.rotation - b1.rotation);
			b1.compound.constraints.add(constr);
//			heroBody.angularVel = 10;


			var st = makeNewStick();

			var dir = b2.worldCOM.sub(b1.worldCOM).unit().mul(planetRadius);
			var pos = b2.worldCOM.add(dir);
			st.body.position = pos;
			st.body.rotation = Math.atan2(dir.y,dir.x) - Math.PI / 2;
			b1.compound.bodies.add(st.body);

			var cst = st.body.localPointToWorld(zero);
			var c2 = b2.localPointToWorld(zero);
//			var c1 = heroBody.worldCOM;
//			var c2 = b2.worldCOM;
			var c3 = c2.add(cst);
			c3.muleq(0.5);
			var ast = st.body.worldPointToLocal(c3);
			var a2 = b2.worldPointToLocal(c3);

			var constr = new WeldJoint(b2,st.body,a2,ast, st.body.rotation - b2.rotation);
			b2.compound.constraints.add(constr);
			addChild(st.sprite);
			planets.push(st);
		}
	}

	function onStickFloorCollide(cb:InteractionCallback){
//		if (cb.int1.castShape.body == heroBody)
//			heroBody.applyAngularImpulse(10000);
//		planet.position.setxy(100,100);
	}

	function updateGfxFromPhys(){
		for (p in planets){
			p.sprite.x = p.body.position.x;
			p.sprite.y = p.body.position.y;
			p.sprite.rotation = rad2deg(p.body.rotation);
		}

		x = - (Math.max(500,heroBody.worldCOM.x) - 500);
	}

	var leftKey:Bool = false;
	var rightKey:Bool = false;

	function enterFrameHandler(ev:Event):Void {
		if (rightKey)
			heroBody.angularVel = 10;
		else if (leftKey)
			heroBody.angularVel = -10;
		else
			heroBody.angularVel = 0;


// If the hand joint is active, then set its first anchor to be
// at the mouse coordinates so that we drag bodies that have
// have been set as the hand joint's body2.
		if (handJoint.active) {
			handJoint.anchor1.setxy(mouseX, mouseY);
		}



// Step forward in simulation by the required number of seconds.
		space.step(1 / stage.frameRate);

		updateGfxFromPhys();

// Render Space to the debug draw.
// We first clear the debug screen,
// then draw the entire Space,
// and finally flush the draw calls to the screen.
		if (DEBUG_DRAW){
			debug.clear();
			debug.draw(space);
			debug.flush();
		}
	}

	function clearGfx(){
		for (p in planets){
			removeChild(p.sprite);
		}
	}

	function keyDownHandler(ev:KeyboardEvent):Void {
		if (ev.keyCode == 82) { // 'R'
// space.clear() removes all bodies (and constraints of
// which we have none) from the space.
			space.clear();

			clearGfx();

			planets = [];

			setUp();
		}

		else if (ev.keyCode == 37){
			leftKey = true;
		}
		else if (ev.keyCode == 39){
			rightKey = true;
		}
	}

	function keyUpHandler(ev:KeyboardEvent):Void {
		if (ev.keyCode == 37){
			leftKey = false;
		}
		else if (ev.keyCode == 39){
			rightKey = false;
		}
	}






	function mouseDownHandler(ev:MouseEvent):Void {
// Allocate a Vec2 from object pool.
		var mousePoint = Vec2.get(mouseX, mouseY);

// Determine the set of Body's which are intersecting mouse point.
// And search for any 'dynamic' type Body to begin dragging.
		for (body in space.bodiesUnderPoint(mousePoint)) {
			if (!body.isDynamic()) {
				continue;
			}

// Configure hand joint to drag this body.
// We initialise the anchor point on this body so that
// constraint is satisfied.
//
// The second argument of worldPointToLocal means we get back
// a 'weak' Vec2 which will be automatically sent back to object
// pool when setting the handJoint's anchor2 property.
			handJoint.body2 = body;
			handJoint.anchor2.set(body.worldPointToLocal(mousePoint, true));

// Enable hand joint!
			handJoint.active = true;

			break;
		}

// Release Vec2 back to object pool.
		mousePoint.dispose();
	}

	function mouseUpHandler(ev:MouseEvent):Void {
// Disable hand joint (if not already disabled).
		handJoint.active = false;
	}
}