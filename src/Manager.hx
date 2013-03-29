import mt.deepnight.Buffer;
import mt.deepnight.SpriteLib;
import mt.deepnight.Tweenie;
import flash.display.MovieClip;
import flash.display.Sprite;
import flash.geom.Point;
import flash.ui.Keyboard;
import World;
import Type;

class GfxTiles extends flash.display.BitmapData {}
class DefaultFont extends flash.text.Font {}

typedef Hotspot = {
	var hit		: flash.display.Sprite;
	var spr		: Null<DSprite>;
	var name	: String;
	var act		: Hash<Dynamic>;
}

class Manager {//}
	static var SHOW_COLLISIONS = false;
	static var INAMES = new Hash();
	static var SOUNDS = mt.data.Sounds.directory("sfx");
	static var EXTENDED = true;
	
	//static var WALK = "Walk to";
	static var LOOK = "Look at";
	static var PICK = "Pick up";
	static var USE = "Use";
	static var ITEM = "Inventory";
	static var OPEN = "Open";
	static var CLOSE = "Close";
	static var REMEMBER = "Remember";
	static var HELP = "Help me";
	static var ABOUT = "About";
	
	static var FORMAT : flash.text.TextFormat;
	public static var WID = Std.int(flash.Lib.current.stage.stageWidth);
	public static var HEI = Std.int(flash.Lib.current.stage.stageHeight);
	public static var CWID = 8;
	public static var CHEI = 8;
	public static var ME : Manager;
	public static var UPSCALE = 3;
	public static var USE_SCALE2X = false;
	public static var UNIQ = 0;
	
	#if debug
	var debug		: mt.kiroukou.debug.Stats;
	#end
	
	var root		: flash.display.MovieClip;
	var buffer		: Buffer;
	var buffer2		: Buffer;
	var world		: World;
	var lib			: SpriteLib;
	var player		: Entity;
	var displace	: flash.display.BitmapData;
	var dispScale	: Float;
	var menu		: Null<flash.display.Sprite>;
	var popUp		: Null<flash.display.Sprite>;
	var dragStart	: Null<flash.geom.Point>;
	var drag		: flash.display.Sprite;
	var curName		: Null<flash.text.TextField>;
	var pending		: Null<String>;
	var actions		: List<flash.text.TextField>;
	var onArrive	: Null<Void->Void>;
	var afterPop	: Null<Void->Void>;
	var lastSpot	: Null<Hotspot>;
	var inventory	: List<String>;
	var triggers	: Hash<Int>;
	var roomBg		: DSprite;
	var snapshot	: flash.display.Bitmap;
	var invCont		: flash.display.Sprite;
	var invSep		: DSprite;
	var invSep2		: DSprite;
	var controlsCont: flash.display.Sprite;
	var heroFade	: DSprite;
	var footstep	: Float;
	
	var tw			: Tweenie;
	
	var popQueue	: List<String>;
	
	var hotSpots	: Array<Hotspot>;
	
	var playerPath	: Array<{x:Int, y:Int}>;
	var playerTarget: Null<{x:Int, y:Int}>;
	
	var fl_pause	: Bool;
	var fl_lockControls	: Bool;
	var fl_ending	: Bool;
	var skipClick	: Bool;
	
	var room		: String;
	
	var dm			: mt.DepthManager;
	
		
	public function new(r) {
		ME = this;
		root = r;
		root.addEventListener( flash.events.Event.ENTER_FRAME, main );
		tw = new Tweenie();
		actions = new List();
		fl_pause = false;
		fl_lockControls = false;
		fl_ending = false;
		skipClick = false;
		hotSpots = new Array();
		playerPath = new Array();
		inventory = new List();
		triggers = new Hash();
		popQueue = new List();
		dispScale = 0;
		footstep = 0;
		
		var g = root.graphics;
		g.beginFill(#if debug 0x0 #else 0x0 #end,1);
		g.drawRect(0,0,WID,HEI);
		g.endFill();
		
		INAMES.set("picture", "Old photograph");
		INAMES.set("picPart1", "photograph fragment (1)");
		INAMES.set("picPart2", "photograph fragment (2)");
		INAMES.set("picPart3", "photograph fragment (3)");
		INAMES.set("picPart3", "photograph fragment (3)");
		INAMES.set("chestKey", "Small copper key");
		INAMES.set("knife", "Blunt knife");
		INAMES.set("ring", "Wedding ring");
		INAMES.set("cupKey", "Large iron key");
		INAMES.set("broom", "Broom");
		INAMES.set("finalLetter", "A letter");

		dm = new mt.DepthManager(root);
		
		room = "cell";
		#if debug
		room = "park";
		//inventory.add("picPart1");
		triggers.set("phoneDropped",1);
		triggers.set("letterPop",1);
		//triggers.set("sinkClean",1);
		//inventory.add("broom");
		//inventory.add("knife");
		inventory.add("ring");
		inventory.add("chestKey");
		triggers.set("framed",1);
		triggers.set("foundChest",1);
		//triggers.set("sinkClean",1);
		//triggers.set("sinkOpen",1);
		#end
		
		FORMAT = new flash.text.TextFormat("04b03", 8, 0xffffff);
		//FORMAT.font = DefaultFont;

		buffer = new Buffer(110,108, UPSCALE, false, 0x0, USE_SCALE2X);
		dm.add(buffer.render,0);
		//var t = Buffer.makeMosaic(UPSCALE);
		var t = Buffer.makeScanline(0x0, UPSCALE);
		buffer.setTexture( t, 0.07, flash.display.BlendMode.OVERLAY, false );
		
		buffer2 = new Buffer(buffer.width,180, UPSCALE, true, 0x0, USE_SCALE2X);
		dm.add(buffer2.render,0);
		buffer2.setTexture( t, 0.07, flash.display.BlendMode.OVERLAY, true );
		
		haxe.Log.setColor(0xFFFF00);
		
		drag = buffer.dm.empty(99);
		
		Key.init();
		
		lib = new SpriteLib( new GfxTiles(0,0) );
		lib.defaultCenterX = 0;
		lib.defaultCenterY = 0;

		lib.setGroup("collision");
		lib.slice(0,16*2, 8,8);
		
		lib.setGroup("separator");
		lib.slice(0,16*3, 16*7,16, 2);

		lib.setGroup("cell");
		lib.slice(0,16*4, 16*7,16*5, 1, 4);
		
		lib.setGroup("picPart1");
		lib.slice(7*16,5*16, 16,16);
		lib.setGroup("calendar");
		lib.slice(7*16,6*16, 16,16);
		lib.setGroup("picPart3");
		lib.slice(7*16,7*16, 16,16);
		lib.setGroup("framed");
		lib.slice(7*16,8*16, 16,16);
		lib.setGroup("ringBack");
		lib.slice(8*16,6*16, 16,16);
		lib.setGroup("reflections");
		lib.slice(9*16,6*16, 16,16);
		lib.setGroup("sinkWater");
		lib.slice(8*16,5*16, 16,16, 4);
		lib.setAnim("flow", [0,1,2,3], [1]);

		lib.setGroup("kitchenDoor");
		lib.slice(7*16,10*16, 16,16);
		lib.setGroup("kitchenKnife");
		lib.slice(7*16,11*16, 16,16);
		lib.setGroup("kitchenTable");
		lib.slice(7*16,12*16, 16,16, 2);
		lib.setGroup("kitchenChest");
		lib.slice(7*16,13*16, 16,16, 2);
		lib.setGroup("cupDoors");
		lib.slice(8*16,10*16, 16,20);
		
		lib.setGroup("phone");
		lib.slice(7*16,15*16, 16,16);
		lib.setGroup("finalLetter");
		lib.slice(7*16,16*16, 16,16);

		lib.setGroup("player");
		lib.slice(0,0, 16,16, 16,2);
		lib.setAnim("wakeWait", [10], [1]);
		lib.setAnim("wakeUp", [10,11,12,13], [1,1,1,1]);
		lib.setAnim("standDown", [0], [1]);
		lib.setAnim("standUp", [5], [1]);
		lib.setAnim("walkDown", [0,1,2,1,0, 3,4,3], [1]);
		lib.setAnim("walkUp", [5,6,7,6,5, 8,9,8], [1]);
		lib.setAnim("read", [14,15], [25]);
		lib.setAnim("cry", [15,16, 17,18, 19], [20,70, 10,50, 100]);
		lib.setAnim("cry", [15,16, 17,18, 19], [5,5,5,5, 50]);
		lib.setAnim("afterCry", [20], [1]);
		
		lib.setGroup("heroFade");
		lib.slice(0,16*25, 12*16, 9*16);

		//water = new flash.display.Sprite();
		//var bmp = new flash.display.BitmapData(buffer.width, buffer.height, true, 0x0);
		//waterText = new flash.display.Bitmap(bmp, flash.display.PixelSnapping.ALWAYS, false);
		displace = new flash.display.BitmapData(buffer.width,buffer.height, true, 0x0);
		//water.addChild(waterText);
		//water.addChild( new flash.display.Bitmap(waterDisp, flash.display.PixelSnapping.ALWAYS, false) );
		//water.blendMode = flash.display.BlendMode.MULTIPLY;
		//water.alpha = 1;
		//buffer.dm.add(water, 8);
		//for(x in 0...Std.int(buffer.width/16)+1)
			//for(y in 0...Std.int(buffer.height/16)+1)
				//lib.drawIntoBitmap(waterText.bitmapData, x*16, y*16, "water");
		
		initWorld();
		
		player = new Entity(world, lib.getSprite("player"));
		player.spr.setCenter(0, 0);
		player.spr.setCenter(0.5, 0.95);
		player.moveTo(10,5);
		buffer.dm.add(player.spr, 5);
		
		var s = lib.getSprite("separator", 1);
		buffer2.dm.add(s, 3);
		invSep2 = s;

		var s = lib.getSprite("separator", 0);
		buffer2.addChild(s);
		s.y = buffer.height;
		invSep = s;

		root.stage.addEventListener(flash.events.MouseEvent.CLICK, onClick);
		root.stage.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, onMouseDown);
		root.stage.addEventListener(flash.events.MouseEvent.MOUSE_UP, onMouseUp);
		
		#if debug
		debug = new mt.kiroukou.debug.Stats();
		debug.x = WID-70;
		dm.add(debug,10);
		#end
		
		heroFade = lib.getSprite("heroFade");
		heroFade.setCenter(0.5, 0.5);
		heroFade.visible = false;
		buffer.dm.add(heroFade, 5);
		
		var x = 0;
		var y = 0;
		controlsCont = new flash.display.Sprite();
		dm.add(controlsCont, 1);
		var alist = [LOOK, USE, OPEN, REMEMBER, PICK, CLOSE, HELP];
		if( EXTENDED )
			alist.push(ABOUT);
		for(a in alist) {
			var tf = makeText(a);
			controlsCont.addChild(tf);
			tf.x = 11*UPSCALE + x*92;
			tf.y = 16*5*UPSCALE + y*17;
			if( a==ABOUT ) {
				tf.y+= 17;
				tf.x+=45;
				tf.textColor = 0x668275;
			}
			if( a==HELP ) {
				tf.y+= 17;
				if( EXTENDED )
					tf.x+=45;
				else
					tf.x+=92;
				tf.textColor = 0x668275;
			}
			tf.alpha = 0.6;
			tf.filters = [];
			tf.width = 46;
			var f = tf.getTextFormat();
			f.align = flash.text.TextFormatAlign.CENTER;
			tf.setTextFormat(f);
			tf.addEventListener(flash.events.MouseEvent.MOUSE_OVER, function(_) {
				if( !fl_lockControls )
					tf.alpha = 1;
			});
			tf.addEventListener(flash.events.MouseEvent.MOUSE_OUT, function(_) {
				if( tf.text!=pending )
					tf.alpha = 0.6;
			});
			tf.addEventListener(flash.events.MouseEvent.CLICK, function(_) {
				if( !fl_lockControls )
					setPending(a);
			});
			x++;
			if( x>=3 ) {
				x = 0;
				y++;
			}
			actions.add(tf);
		}
		
		//var tf = makeText("Stuck? Need help?");
		//tf.scaleX = tf.scaleY = 1;
		//controlsCont.addChild(tf);
		//tf.x = 11*UPSCALE;
		//tf.y = 16*5*UPSCALE + y*17;
		//tf.alpha = 0.6;
		//tf.filters = [];
		
		setPending();
		
		addHotSpots();
		updateInventory();
		
		SOUNDS.ambiant.play(0,9999);
		
		#if !debug
		// Intro
		root.alpha = 0;
		tw.create(root, "alpha", 1, 2000);
		dispScale = 0.5;
		tw.create(this, "dispScale", 0, TEaseOut, 5000);
		player.spr.playAnim("wakeWait");
		player.moveTo(10,4);
		player.update();
		pop("Day 4380");
		pop("!...12 years today.");
		pop("And still many to go in this cell.");
		pop("My cozy little world.");
		afterPop = function() {
			fl_pause = true;
			player.spr.playAnim("wakeUp", 1);
			player.spr.onEndAnim = function() player.spr.playAnim("standDown");
			//player.moveTo(10,5);
			//player.yr = 1;
			//player.update();
			var a = tw.create(player, "yr", 1, 300);
			a.onUpdate = function() {
				DSprite.updateAll();
				player.update();
			}
			a.onEnd = function() {
				unpause();
				SOUNDS.footstep1.play();
				player.moveTo(10,5);
				player.yr = 0;
				player.update();
			}
		}
		#end
	}
	
	function lockControls(l) {
		fl_lockControls = l;
		controlsCont.alpha = l ? 0.3 : 1;
		//invCont.alpha = l ? 0.4 : 1;
		//invSep.alpha = invCont.alpha;
		//invSep2.alpha = invCont.alpha;
		updateInventory();
	}
	
	function unpause() {
		fl_pause = false;
		lockControls(false);
		if( curName!=null )
			curName.visible = true;
	}
	
	
	function setPending(?a:String) {
		//if( fl_pause )
			//return;
		for( tf in actions ) {
			tf.alpha = 0.6;
			tf.filters = [];
		}
		if( a==HELP ) {
			getTip();
			return;
		}
		if( a==ABOUT ) {
			SOUNDS.select.play();
			pop("This game was completely developed by Sebastien \"deepnight\" Benard in 48h for the Ludum Dare competition (theme: \"Tiny World\").");
			pop("@Visit BLOG.DEEPNIGHT.NET for more games :)");
			return;
		}
		if( a!=pending )
			SOUNDS.select.play();
		if( a==null )
			a = LOOK;
		pending = a;
		for(tf in actions)
			if( tf.text==a ) {
				tf.alpha = 1;
				tf.filters = [ new flash.filters.GlowFilter(0x5E6F93,1, 4,4, 10) ];
			}
	}
	
	function movePlayer(cx,cy) {
		var pt = getClosest(cx,cy);
		if( pt==null || pt.x==player.cx && pt.y==player.cy )
			return false;
		playerPath = getPath(player.cx, player.cy, pt.x, pt.y);
		playerTarget = {x:cx,y:cy}
		return playerPath.length>0;
	}
	
	function setTrigger(k, ?n=1) {
		triggers.set(k,n);
		refreshWorld();
		if( k=="kitchenLeftOpen" || k=="kitchenRightOpen" )
			SOUNDS.door.play();
	}
	function getTrigger(k) {
		return if( triggers.exists(k) ) triggers.get(k) else 0;
	}
	function hasTrigger(k) {
		return getTrigger(k)!=0;
	}
	function hasTriggerSet(k) {
		if( getTrigger(k)!=0 )
			return true;
		else {
			setTrigger(k);
			return false;
		}
	}
	
	function hasItem(k) {
		for(i in inventory)
			if(i==k)
				return true;
		return false;
	}
	
	function removeItem(k:String) {
		inventory.remove(k);
		updateInventory();
	
	}
	function addItem(k:String) {
		SOUNDS.pick.play();
		inventory.add(k);
		refreshWorld();
		if( hasItem("picPart1") && hasItem("picPart2") && hasItem("picPart3") && !hasTrigger("gotPicture") ) {
			removeItem("picPart1");
			removeItem("picPart2");
			removeItem("picPart3");
			addItem("picture");
			setTrigger("gotPicture");
			SOUNDS.success.play();
			pop("You assembled the 3 parts and now have restored the picture.");
		}
		updateInventory();
	}
	
	function updateInventory() {
		var old = if( invCont!=null ) invCont.alpha else 0;
		if( invCont!=null )
			invCont.parent.removeChild(invCont);
			
		invCont = new flash.display.Sprite();
		invCont.x = 20;
		invCont.y = 116*UPSCALE;
		invCont.alpha = old;
		dm.add(invCont, 1);
		
		var a = if( inventory.length==0 ) 0.3 else 1;
		//invCont.alpha = invSep.alpha = invSep2.alpha = a;
		tw.create(invCont, "alpha", a);
		tw.create(invSep, "alpha", a);
		tw.create(invSep2, "alpha", a);
		invSep2.y = invSep.y + Math.max(20, 14+inventory.length*6);
			
		var n = 1;
		for(i in inventory) {
			var name = INAMES.get(i);
			var tf = makeText( if(name!=null) name else "!!"+i+"!!" );
			tf.textColor = 0x957E51;
			var f = tf.getTextFormat();
			f.align = flash.text.TextFormatAlign.CENTER;
			tf.setTextFormat(f);
			//tf.scaleX = tf.scaleY = 1;
			tf.y = n*18;
			tf.width = 9*16;
			tf.filters = [
				//new flash.filters.GlowFilter(0xad9769, 0.3, 4,4, 10),
				new flash.filters.DropShadowFilter(2,90, 0xC8B899, 1,0,0, 10,1, true),
			];
			invCont.addChild(tf);
			n++;
		}
	}
	
	function runPending(hs:Hotspot) {
		if( fl_pause )
			return;
		if( fl_lockControls )
			return;
		if( pending==null )
			return;
			
		var a = pending;
		
		if( !hs.act.exists(a) )
			a = "all";
		
		if( hs.act.exists(a) ) {
			var resolve = function() {
				var r = hs.act.get(a);
				if( Type.typeof(r)==ValueType.TFunction ) {
					//closeActions();
					r();
				}
				else
					pop(r);
			}

			skipClick = true;
			var pt = buffer.globalToLocal(root.mouseX, root.mouseY);
			pt.x = Std.int(pt.x/CWID);
			pt.y = Std.int(pt.y/CHEI);
			if( movePlayer(pt.x, pt.y) )
				onArrive = resolve;
			else
				resolve();
		}
		else {
			switch(pending) {
				case LOOK	: pop("Not much to say.");
				case PICK	: pop("I don't need that.");
				case OPEN	: pop("I can't open that.");
				case CLOSE	: pop("What?");
				case USE	: pop("I have no use for that.");
				case REMEMBER: pop("This doesn't ring a bell...");
				
			}
		}
	}
	
	
	function getClosest(cx,cy) {
		//if( !world.collide(cx,cy) )
			//return {x:cx, y:cy}
		
		for( dist in 1...4)
			for( d in [{x:0,y:dist}, {x:-dist,y:0}, {x:dist,y:0}, {x:0,y:-dist} ] )
				if( !world.collide(cx+d.x, cy+d.y) )
					return {x:cx+d.x, y:cy+d.y}
					
		for( dist in 1...4)
			for( d in [{x:-dist,y:-dist}, {x:dist,y:-dist}, {x:dist,y:dist}, {x:-dist,y:dist}, ] )
				if( !world.collide(cx+d.x, cy+d.y) )
					return {x:cx+d.x, y:cy+d.y}
					
		return null;
	}
	
	public function getPath(x:Int,y:Int, tx:Int,ty:Int) {
		if ( world.collide(x,y) || world.collide(tx,ty) )
			return [];
		else
			return astar(x,y, tx,ty);
	}
	
	function astar(x,y, tx,ty, ?branch:Array<{x:Int,y:Int}>, ?tags:Array<Bool>, ?best:Array<{x:Int,y:Int}>, ?tries=0) : Array<{x:Int,y:Int}> {
		if ( branch==null )
			branch = new Array();
		if ( tags==null )
			tags = new Array();
		if ( best!=null && best.length<branch.length )
			return null;
		tags[getId(x,y)] = true;
		if (x==tx && y==ty)
			return branch;
			
		if( tries>1000)
			return null;
			
		var neig = new Array();
		if (tx<x)	neig.insert(0, { xd:-1,yd:0 } )	else neig.push( { xd:-1,yd:0 } );
		if (tx>x)	neig.insert(0, { xd:1,yd:0 } )	else neig.push( { xd:1,yd:0 } );
		if (ty<y)	neig.insert(0, { xd:0,yd:-1 } )	else neig.push( { xd:0,yd:-1 } );
		if (ty>y)	neig.insert(0, { xd:0,yd:1 } )	else neig.push( { xd:0,yd:1 } );
		
		for (n in neig) {
			var pt = { x:x+n.xd, y:y+n.yd };
			var id = getId(pt.x, pt.y);
			if ( tags[id]!=true && !world.collide(pt.x, pt.y) ) {
				tags[id] = true;
				var nextBranch = astar(pt.x, pt.y, tx,ty, branch.concat([{x:pt.x, y:pt.y}]), tags.copy(), best, tries+1);
				if ( nextBranch != null && (best==null || best.length>nextBranch.length) )
					best = nextBranch;
			}
		}
		return best;
	}

	inline function getId(x,y) {
		return y*world.wid + x;
	}
	
/*	function getPath(x,y, tx,ty, ?mark:IntHash<Bool>) {
		var id = getId(x,y);
		if( mark==null )
			mark = new IntHash();
		if( mark.exists(id) )
			return;
		var next = [];
		for( d in [{x:-1,y:0}, {x:1,y:0}, {x:0,y:-1}, {x:0,y:1}] ) {
			var next = {x:x+d.x, y:y+d.y};
			//if( !world.collide(fx+d.x, fy+d.y) )
				//next.push({x:fx+d.x, y:fy+d.y});
		}
		mark.set(id, true);
		
		//if( !world.collide(fx-1, fy) ) next.push({x:x-1, y
	}*/
	
	function addHotSpots() {
		for(hs in hotSpots) {
			hs.hit.parent.removeChild(hs.hit);
			if( hs.spr!=null )
				hs.spr.parent.removeChild(hs.spr);
		}
		hotSpots = new Array();
		
		if( room!="hell" ) {
			addSpot(16,27,26,7, "A rusty pipe");
			setAction(LOOK, "It brings me my daily water ration.");
			setAction(REMEMBER, "For as long I remember, water has always seeped out of this pipe.");
			setAction(USE, "It's useless, I can't fix it.");
			
			addSpot(9,39,7,17, "Iron door");
			setAction(LOOK,"12 years already... Once a day, they serve my food in a metal tray.");
			setAction(OPEN,"Guess what? It's locked.");
			setAction(CLOSE,"This door seems to be intended to remain closed for the rest of eternity.");
			setAction(PICK, "What?");
			setAction(REMEMBER,"This door was locked 12 years ago. Only once. Never opened since then. I can't even remember the color of the corridor walls behind.");
			
			addSpot(73,26,21,14, "My bed");
			setAction(LOOK, "It is almost as hard as the concrete ground.");
			setAction(USE, "No, I just woke up. ");
			if( room=="cell" )
				setAction(REMEMBER, "4380 nights spent in this bed.");
			else {
				setAction(REMEMBER, function() {
					changeRoom("cell");
				});
			}
		}
			
		if( room=="cell" ) {
			addSpot(49,25,14,14, "Steel table");
			setAction(LOOK, "Despite its aspect, this table isn't very stable.|But as everything down here, with time, you get used to it.");
			setAction(REMEMBER, "They gave me this table 2 or 3 years ago.|Before that, I used to lay on the floor or on my bed.");

			addSpot(51,28,6,4, "A pen");
			setAction(LOOK, "A simple black pen.");
			setAction(REMEMBER, "I didn't use it often...|Actually, I only wrote a letter or something...|Can't remember, but it was kind of... IMPORTANT.");
			setAction(PICK, "I don't think I will need it.");
			setAction(USE, "I don't have anything to write on.");

			if( !hasItem("picPart1") && !hasTrigger("gotPicture") ) {
				addSpot(57,24,6,7, "A torn photograph");
				setSprite( lib.getSprite("picPart1") );
				setAction(LOOK, "An old picture, totally torn...");
				setAction(REMEMBER, "I don't remember anything about this picture... I should look for the other parts.");
				setAction(PICK, function() {
					pop("You pick it up. The picture is incomplete (probably 3 parts).");
					addItem("picPart1");
				});
			}
			
			if( !hasTrigger("framed") ) {
				addSpot(52,22,5,6, "Empty frame");
				if( hasTrigger("gotPicture") )
					setAction(USE, function() {
						pop("You put the photograph back in its frame. It fits perfectly.");
						setTrigger("framed");
						SOUNDS.success.play();
						removeItem("picture");
					});
				else
					setAction(USE, "I don't have anything to put inside.");
				setAction(LOOK, "This frame is empty.|!Hmm... Where is the photograph?");
				setAction(REMEMBER, "I can't remember if I removed the frame content myself...");
				setAction(OPEN, "Nothing inside.");
			}
			else {
				addSpot(52,22,5,6, "A very old photograph");
				setSprite( lib.getSprite("framed") );
				setAction(LOOK, "The photograph is very old and damaged. The character on the picture is barely recognizable. A woman?");
				setAction(PICK, "No, this picture is in its place.");
				setAction(REMEMBER, function() {
					if( !hasTriggerSet("firstMemory") ) {
						pop("The photograph is very old and damaged. The character on the picture is barely recognizable. A woman?|...|Lydia?");
						afterPop = callback(changeRoom,"kitchen");
					}
					else
						changeRoom("kitchen");
				});
			}
			
			addSpot(20,32,20,19, "Stagnant water");
			setAction(LOOK, "The water slowly seeps through cracks into my world.");
			setAction(CLOSE, "I can't do anything to stop it.");
			setAction(PICK, "I will have plenty of water here soon enough.");
			
			addSpot(70,51,16,14, "Ray of light");
			setAction(LOOK, "A cold light falls upon my little world.");
			setAction(REMEMBER, "I won't feel anymore the sea breeze in my hairs.");
			setAction(PICK, "What?");
			
			if( !hasTrigger("calendar") ) {
				addSpot(40,20,8,9, "An old calendar");
				setSprite( lib.getSprite("calendar") );
				setAction(LOOK, "This calendar is from other times... Even the year print has almost completely disappeared.|!...Hey, is there some kind of hole behind it?");
				setAction(REMEMBER, "I think SOMEONE bought me this calendar when I was sent in here.");
				var f = function() {
					setTrigger("calendar");
					SOUNDS.smallHit.play();
					pop("As you pull the calendar, you reveal a hole hidden behind it...");
				}
				setAction(USE, f);
				setAction(OPEN, f);
			}
			else {
				addSpot(37,20,8,9, "Hidden hole");
				if( !hasItem("picPart2") && !hasTrigger("gotPicture")  )
					setAction(LOOK, function() {
						pop("You found the fragment of a torn photograph.");
						addItem("picPart2");
					});
				else
					setAction(LOOK, "This holes is empty.");
				setAction(CLOSE, "The calendar won't stay.");
				setAction(REMEMBER, "Did I make this hole? I can't remember.");
			}
			
			addSpot(59,61,21,13, "Unused bed base");
			setAction(LOOK, "It was never used. No one never got transfered in this cell, except me.");
			setAction(USE, "From time to time, I switch my beds. Just for a pleasant change.");
			setAction(REMEMBER, "I think it was already here when I was brought here.");
			
			if( !hasItem("picPart3") && !hasTrigger("gotPicture") ) {
				addSpot(88,25,5,6, "Some sort of paper");
				setSprite( lib.getSprite("picPart3") );
				setAction(LOOK, "The fragment of a torn photograph is hidden under the bolster.");
				setAction(REMEMBER, "How did it get there?");
				setAction(PICK, function() {
					pop("It's a fragment of a torn photograph.");
					addItem("picPart3");
				});
			}
			
			addSpot(56,39,7,9, "Chair");
			setAction(LOOK, "Rusted.");
			setAction(USE, "There is nothing to wait.");
			
			addSpot(14,64,8,12, "Sink");
			if( hasTrigger("sinkOpen") ) {
				var s = lib.getSprite("sinkWater");
				setSprite(s);
				s.x+=1;
				s.y+=3;
				s.playAnim("flow");
			}
			if( !hasTrigger("sinkClean") ) {
				setAction(PICK, "I need a tool or something.");
				setAction(LOOK, "A basic sink with an old faucet.|!Something is blocking the sink hole.");
				setAction(REMEMBER, "I remember that something felt in the hole.|...But what was it?");
				setAction(OPEN, "!No, something is blocking the hole.");
			}
			else {
				if( !hasTrigger("sinkOpen") )
					setAction(LOOK, "I try to keep it as clean as possible.");
				else
					setAction(LOOK, "The water is not exactly clear.");
				setAction(OPEN, function() {
					setTrigger("sinkOpen");
					SOUNDS.robinet.play();
				});
				setAction(CLOSE, function() {
					setTrigger("sinkOpen",0);
					SOUNDS.robinet.play();
				});
			}
			if( !hasTrigger("sinkOpen") )
				setAction(USE, "I need to open the water first.");
			if( hasTrigger("sinkClean") && hasTrigger("sinkOpen") ) {
				if( hasItem("cupKey") && !hasTrigger("washedKey") )
					setAction(USE, function() {
						pop("You wash the key, fussy ol'man.");
						setTrigger("washedKey");
					});
				else
					setAction(USE, "The water feels refreshing.");
			}
			else if( hasItem("knife") && !hasTrigger("sinkClean") )
				setAction(USE, function() {
					pop("Using the knife, you manage to remove the thing blocking the sink.");
					pop("You take out lots of dirt. Trapped inside, you find a KEY.");
					setTrigger("sinkClean");
					SOUNDS.success.play();
					addItem("cupKey");
				});
				
			addSpot(89,41,6,6, "Small wooden case");
			if( hasTrigger("ringBack") ) {
				var s = setSprite( lib.getSprite("ringBack") );
				s.x+=1;
				s.y+=1;
				setAction(REMEMBER, callback(changeRoom, "park"));
			}
			else
				setAction(REMEMBER, "I'm pretty sure it was not normally empty.|But where is its content?");
			if( !hasTrigger("ringBack") )
				setAction(LOOK, "It looks like some kind of jewel case. It is empty.");
			else
				setAction(LOOK, "Lydia's ring is back in its box. Why did I hide it?");
			setAction(PICK, "I prefer to let it here.");
			if( hasItem("ring") )
				setAction(USE, function() {
					pop("You put Lydia's ring back in its case.");
					SOUNDS.success.play();
					removeItem("ring");
					setTrigger("ringBack");
				});
		}
		
		
		if( room=="kitchen" ) {
			addSpot(49,20,5,6, "Old picture of a woman");
			setAction(LOOK, "A young and beautiful smiles at you, radiant with joy.");
			setAction(PICK, "No, this picture is in its place.");
			setAction(REMEMBER, function() {
				pop("Lydia...|As beautiful as in my memories.");
				if( EXTENDED )
					afterPop = callback(changeRoom,"cell");
			});
			
			addSpot(42,29,8,6, "Sideboard left door");
			if( hasTrigger("kitchenLeftOpen") ) {
				setSprite( lib.getSprite("kitchenDoor") );
				setAction(LOOK, "All kind of silverware, plates and things like that.");
				setAction(REMEMBER, "I used to be the chef of the house...");
			}
			setAction(OPEN, function() setTrigger("kitchenLeftOpen",1));
			setAction(CLOSE, function() setTrigger("kitchenLeftOpen",0));
			
			addSpot(70,51,12,13, "Warm ray of light");
			setAction(LOOK, "The warm feeling if pleasant and reassuring.");
			setAction(REMEMBER, "The kitchen used to be a room bathed in light.|I guess it's summer outside.");
			setAction(PICK, "What?");

			addSpot(51,29,8,6, "Sideboard right door");
			if( hasTrigger("kitchenRightOpen") ) {
				setSprite( lib.getSprite("kitchenDoor") );
				if( !hasTrigger("foundChest") ) {
					setAction(LOOK, function() {
						pop("Cups, thousands of spoons and a tea set.|!You also found a STEEL CHEST inside the sideboard.");
						afterPop = function() {
							setTrigger("foundChest");
							SOUNDS.hit.play();
						}
					});
				}
				else
					setAction(LOOK, "Cups, thousands of spoons and a tea set.");
				setAction(REMEMBER, "Lydia was really fond of tea...");
			}
			setAction(OPEN, function() setTrigger("kitchenRightOpen",1));
			setAction(CLOSE, function() setTrigger("kitchenRightOpen",0));
			
			addSpot(42,47,6,13, "My chair");
			setAction(LOOK, "My good old chair.");
			setAction(REMEMBER, "Years ago, I used to sit here, and wait for...|Well. something... I don'k know.|!But nothing ever happened.");
			setAction(USE, "Nah, I've spent too much time on this chair, at home...");
			
			addSpot(25,45,16,22, "Kitchen table");
			setAction(LOOK, "My sturdy kitchen table.|It will last longer than me.");
			setAction(REMEMBER, "Years ago, I used to sit here, and wait for...|Well. something... I don'k know.|!But nothing ever happened.");
			
			addSpot(18,24,8,14, "Lydia's chair");
			setAction(LOOK, "Nice chair");
			setAction(REMEMBER, "After Lydia's death, this chair stood in the corner of my kitchen.");
			
			if( !hasTrigger("rememberTable") ) {
				addSpot(31,48,10,13, "Tablecloth");
				setSprite( lib.getSprite("kitchenTable", 0) );
				setAction(LOOK, "Very old. And completely stained.|!As you touch the surface, you feel something underneath...");
				setAction(REMEMBER, "It's so old that I think Lydia even bought it before we met.|!I remember she had the habit to hide... SOMETHING underneath...");
				var f = function() {
					pop("You remove the tablecloth...");
					afterPop = function() {
						SOUNDS.smallHit.play();
						pop("...revealing a small key.");
						//setTrigger("foundKey");
						setTrigger("rememberTable");
						//afterPop = function() {
							//setTrigger("foundKey",0);
						//}
					}
				};
				setAction(USE, f);
				if( EXTENDED ) {
					setAction(PICK, f);
					setAction(OPEN, f);
				}
			}
			else {
				if( !hasTrigger("foundKey") ) {
					addSpot(34,47,6,6, "Small key");
					setSprite( lib.getSprite("kitchenTable", 1) );
					setAction(LOOK, "A small ornamented key is laying on the table. Probably made of copper.");
					setAction(REMEMBER, "I used to play for long hours with this key.|What was it used for?");
					setAction(PICK, function() {
						pop("You pick the ornamented key.");
						setTrigger("foundKey");
						addItem("chestKey");
					});
				}
			}
			
			if( hasTrigger("foundChest") ) {
				addSpot(40,34,13,11, "A steel chest");
				setSprite( lib.getSprite("kitchenChest", hasTrigger("openChest") ? 1 : 0) );
				if( !hasTrigger("openChest") )
					setAction(LOOK, "It seems sturdy. And it's locked.");
				else {
					if( hasTrigger("foundRing") )
						setAction(LOOK, "Completely empty.");
					else {
						setAction(LOOK, function() {
							pop("There is a single GOLD RING in it.|It's really beautiful.|There is \"L\" engraved in it.|You pick it up.");
							addItem("ring");
							setTrigger("foundRing");
						});
					}
					setAction(CLOSE, function() {
						setTrigger("openChest",0);
						SOUNDS.hit.play();
					});
				}
				setAction(REMEMBER, "I put something important in it...|And I wanted it to stay away from me.");
				if( hasTrigger("unlockedChest") )
					setAction(OPEN, function() {
						SOUNDS.smallHit.play();
						setTrigger("openChest");
					});
				else if( !hasItem("chestKey") )
					setAction(OPEN, "It's locked.");
				else {
					setAction(OPEN, function() {
						pop("You use the copper key...|It clicks and opens.");
						SOUNDS.smallHit.play();
						removeItem("chestKey");
						setTrigger("openChest");
						setTrigger("unlockedChest");
					});
				}
			}

			addSpot(23,54,10,8, "Food tray");
			setAction(LOOK, "Probably as old as me...|And as empty as me.");
			setAction(REMEMBER, "Once a day, they serve my meal in it.");
			addSpot(33,56,3,5, "Fork");
			setAction(LOOK, "It only has one prong left.");
			addSpot(31,50,4,4, "Spoon");
			setAction(LOOK, "Surprisingly, it's in a good state.");
			
			if( !hasItem("knife") ) {
				addSpot(25,48,6,6, "Knife");
				setSprite( lib.getSprite("kitchenKnife") );
				setAction(LOOK, "A basic steel knife. The edge became (or got) blunt.|Might be useful.");
				setAction(USE, "This won't cut anything... But it might become handy.");
				setAction(PICK, function() {
					pop("You pick it up.");
					addItem("knife");
				});
			}
			
			addSpot(86,53,12,25, "Cupboard");
			if( hasTrigger("openCup") ) {
				setSprite( lib.getSprite("cupDoors") ).x-=4;
				if( !hasItem("broom") )
					setAction(LOOK, function() {
						pop("The cupboard contains various chemicals and upkeep products.");
						pop("You find a medium sized broom in a corner, you take it.");
						addItem("broom");
					});
				else
					setAction(LOOK, "The cupboard contains various chemicals and upkeep products.");
			}
			else
				setAction(LOOK, "A large wooden cupboard with two doors.");
			setAction(REMEMBER, "It contains everything usefull to keep a kitchen tidy.|Lydia knew more about this stuff than me.");
			if( !hasTrigger("unlockedCup") && !hasItem("cupKey") )
				if( hasItem("chestKey") )
					setAction(OPEN, "!My key is too small for this lock.");
				else
					setAction(OPEN, "!It's locked.");
			else {
				if( !hasTrigger("unlockedCup") ) {
					setAction(OPEN, function() {
						setTrigger("openCup");
						SOUNDS.door.play();
						setTrigger("unlockedCup");
						removeItem("cupKey");
						pop("The key fits perfectly and the cupboard opens creaking.");
					});
				}
				else {
					setAction(OPEN, function() {
						setTrigger("openCup");
						SOUNDS.door.play();
					});
					setAction(CLOSE, function() {
						setTrigger("openCup",0);
						SOUNDS.door.play();
					});
				}
			}
		}
		
		if( room=="park" ) {
			addSpot(2,8,41,26, "Leaves");
			setAction(LOOK, "A peaceful leafy tree...");
			setAction(REMEMBER, "I wish I could hear the gentle sound of the wind passing through the leaves...|!But there is no wind here.");
			
			addSpot(50,23,23,14, "Wooden bench");
			setAction(LOOK, "Even if it seems as old as the trees, this bench looks welcoming.");
			setAction(REMEMBER, "Isn't that...|..the bench where I met Lydia?");
			setAction(USE, "!I.. don't feel comfortable with sitting on it.|I can't do it.");
			
			addSpot(71,50,14,14, "Pale ray of light");
			setAction(LOOK, "It feels surprisingly cold.");
			setAction(REMEMBER, "!This light is not exactly pleasant.|I guess it's winter outside.");
			
			addSpot(16,32,8,25, "Tree trunk");
			setAction(LOOK, "Things are engraved in it.|\"Forever\"|\"L & D\"|\"With love\"|...");
			setAction(REMEMBER, "I think I've written most of these words.");
			setAction(USE, "I could shake the branches, but the trunk won't move.");
			
			if( hasTrigger("letterPop") && !hasItem("finalLetter") ) {
				addSpot(69,41,7,7, "A letter");
				setSprite( lib.getSprite("finalLetter") );
				setAction(LOOK, "A letter.|The writing seems to be... mine.");
				setAction(REMEMBER, "Did I write this letter ?");
				var f = function() {
					addItem("finalLetter");
					heroFade.visible = true;
					heroFade.alpha = 0;
					tw.create(heroFade, "alpha", 0.5, TEaseIn, 1500);
					pop("You take the letter and start to read it.");
					player.spr.stopAnim(0);
					player.spr.playAnim("read");
					pop("@Dear myself,");
					afterPop = function() {
						changeRoom("cell");
					}
				}
				setAction(PICK, f);
				setAction(USE, f);
				setAction(OPEN, f);
			}
			
			if( !hasTrigger("phoneDropped") ) {
				addSpot(18,25,7,6, "???");
				setSprite( lib.getSprite("phone") );
				setAction(LOOK, "There is SOMETHING in the leaves.");
				setAction(REMEMBER, "!I can't see what it is from here.");
				if( !hasItem("broom") )
					setAction("all", "It's out of my reach.");
				else {
					var f = function() {
						setTrigger("phoneDropped");
						SOUNDS.hit.play();
						pop("Using your BROOM, you reach the object and push it to the ground.");
					}
					setAction(USE, f);
					setAction(PICK, f);
				}
			}
			else {
				addSpot(20,49,6,6, "Cellphone");
				setSprite( lib.getSprite("phone") );
				setAction(LOOK, "It's a cellphone, a quite common model.");
				setAction(REMEMBER, "It's mine.");
				setAction(PICK, "!No.|For some reason... I don't want to keep it...");
				setAction(OPEN, "No, I'm not much into technical things.");
				if( !hasTrigger("phoneCalled") )
					setAction(USE, function() {
						pop("As you press the WAKE button on the cellphone, a voice comes from it.");
						pop("It seems that someone is on the line...");
						pop("@Mr Belmont? .. Daniel Belmont?");
						pop("@Dr Prowell speaking...");
						pop("@...Is your wife Mme Lydia Belmont?...");
						pop("!I'm really sorry sir... but she...");
						pop("The cellphone abruptly cease to function.");
						setTrigger("phoneCalled");
						afterPop = callback(changeRoom,"hell");
					});
				else
					setAction(USE, "!It seems broken or something.");
			}
		}
		
		if( room=="hell" ) {
			
		}
	}
	
	function addSpot(x,y,w,h, name:String) {
		var hs : Hotspot = {
			hit		: null,
			spr		: null,
			name	: name,
			act		: new Hash(),
		}
		hotSpots.push(hs);
		
		var pt = buffer.localToGlobal(x,y);
		var hit = new flash.display.Sprite();
		dm.add(hit,1);
		hit.x = pt.x;
		hit.y = pt.y;
		hs.hit = hit;
		var g = hit.graphics;
		g.beginFill(0x00ff00, 0.);
		g.drawRect(0,0, w*UPSCALE, h*UPSCALE);
		g.endFill();
		
		hit.addEventListener(flash.events.MouseEvent.CLICK, function(e) {
			runPending(hs);
		});
		hit.addEventListener(flash.events.MouseEvent.MOUSE_OVER, function(_) {
			//hit.alpha = 0.1;
			showName(name);
			
		});
		hit.addEventListener(flash.events.MouseEvent.MOUSE_OUT, function(_) {
			//hit.alpha = 0;
			hideName();
		});
		
		lastSpot = hs;
		return hs;
	}
	
	function getTip() {
		SOUNDS.help.play();
		var tip =
		if( !hasTriggerSet("usedTip") ) {
			pop("You can use this option to get help if you are stuck in the game. But please, don't use too much!");
			pop("!Each time you click on HELP, you will get the solution to current situation.");
		}
		if( !hasTrigger("framed") && !hasItem("picture") )
			pop("You should first concentrate on finding the 3 photo fragments.");
		else if( EXTENDED && !hasTrigger("framed") && hasItem("picture") )
			pop("Put the photograph back in its frame. To do this, select USE and click on the EMPTY FRAME (you never need to click on the inventory).");
		else if( !hasTrigger("goKitchen") )
			pop("You can sometime use REMEMBER on things to dive in past memories.");
		else if( !hasTrigger("rememberTable") )
			pop("You should check the table in the kitchen...");
		else if( !hasTrigger("foundRing") )
			pop("You must find something PRECIOUS hidden in the kitchen.");
		else if( EXTENDED && !hasTrigger("teleportedBackCell") )
			pop("To come back to your cell, you can use REMEMBER on your bed or on the photograph.");
		else if( EXTENDED && !hasTrigger("sinkClean") && !hasItem("cupKey") && !hasItem("knife") )
			pop("You forgot something else on the kitchen table.");
		else if( !hasTrigger("sinkClean") && !hasItem("cupKey") )
			pop("You should pay attention to the sink in your cell.");
		else if( !hasItem("broom") )
			pop("You need to use your KEY somewhere.");
		else if( EXTENDED && !hasTrigger("goPark") )
			pop("You need to use the RING somewhere. I remember there was a small wooden case near my bed...");
		else if( !hasTrigger("phoneDropped") )
			pop("You should take advantage of the length of the BROOM in the park...");
		else if( EXTENDED && !hasTrigger("phoneCalled") )
			pop("Now you reached the thing in the leaves, you should USE it.");
		else if( EXTENDED && !hasItem("finalLetter") )
			pop("I saw a letter in the park. It wasn't there at the beginning, was it?");
		else
			pop("!I can't help you right now, sorry. It's up to you!");
	}
	
	function changeRoom(k:String) {
		var from = room;
		var d = #if debug 1000; #else 5000; #end
		if( snapshot!=null ) {
			snapshot.bitmapData.dispose();
			snapshot.parent.removeChild(snapshot);
		}
		snapshot = new flash.display.Bitmap( buffer.clone() );
		buffer.dm.add(snapshot, 99);
		tw.create(snapshot, "alpha", 0, TEaseIn, d*0.8).onEnd = function() {
			snapshot.bitmapData.dispose();
		}
		
		var onTeleport = null;
		room = k;
		switch( k ) {
			case "cell" :
				setTrigger("teleportedBackCell");
				player.moveTo(10,5);
				if( hasItem("finalLetter") && !hasTriggerSet("finalMonologue") )
					onTeleport = function() {
						pop("@I write this letter while I'm still conscious and sane.");
						pop("@Lydia used to say that, getting older, I was becoming more and more scatterbrain.");
						pop("!She was damn right.");
						pop("@My memories are fading away. And with them, my guilt for the things that led me into this cell.");
						pop("!But I will also forget Lydia.");
						pop("@My tender and beloved Lydia... This can't possibly happen. I must cherish her memory.");
						pop("@I must remember the pain. Cry for her... Again and again...");
						pop("@That's why I set up all of this paper chase for you. For me.");
						pop("@I'm losing my mind. I'm seeing things, places.");
						pop("@That's not the first time you discover this letter. And it won't be the last one.");
						pop("@We must remember Lydia.");
						pop("@Set everything up for us,  when you will forget again.");
						pop("@Make sure that Lydia will always live in our tiny world.");
						pop("@- Daniel.");
						afterPop = function() {
							lockControls(true);
							fl_pause = true;
							fl_ending = true;
							controlsCont.visible = false;
							invCont.visible = false;
							tw.create(heroFade, "alpha", 1, TEase, 5000);
							player.spr.playAnim("cry",1);
							player.spr.onEndAnim = function() {
								player.spr.playAnim("afterCry");
								tw.terminate(heroFade);
								tw.create(heroFade, "alpha", 0.7, TEaseOut, 500);
								haxe.Timer.delay(function() {
									tw.create(root, "alpha", 0, TEaseIn, 1000).onEnd = credits;
								}, 2000);
							}
						}
					}
			case "kitchen" :
				player.moveTo(5,5);
				if( !hasTriggerSet("goKitchen") )
					onTeleport = function() {
						pop("My kitchen. Exactly like I left it.");
					}
			case "park" :
				if( from!="hell" )
					player.moveTo(10,5);
				else
					player.moveTo(player.cx,5);
				if( !hasTriggerSet("goPark") )
					onTeleport = function() {
						pop("...|!The Arthur park.");
					}
			case "hell" :
				player.moveTo(10,6);
		}
		
		SOUNDS.teleport.play();
		initWorld();
		player.world = world;
		playerPath = new Array();
		playerTarget = null;
		onArrive = null;
		lockControls(true);
		
		tw.create(this, "dispScale", 1, TEaseIn, d*0.6).onEnd = function() {
			tw.create(this, "dispScale", 0.3, TEaseOut, d*0.4).onEnd = function() {
				//if( room!="hell" )
					tw.create(this, "dispScale", 0, TEaseIn, #if debug 500 #else 6000 #end);
				//else
					//tw.create(this, "dispScale", 0.05, TEaseIn, #if debug 500 #else 6000 #end);
				lockControls(false);
				if( onTeleport!=null )
					onTeleport();
			}
		}
	}
	
	function credits() {
		invCont.visible = controlsCont.visible = false;
		root.alpha = 1;
		buffer.kill();
		buffer2.kill();
		var list = [
			"Thank you for playing!",
			"Feel free to comment at BLOG.DEEPNIGHT.NET :)",
		];
		if( EXTENDED )
			list = list.concat([
				"\"Memento XII\"",
				"A 48h Ludum Dare game by Sebastien Benard",
			]);
		var n = 0;
		for(t in list) {
			var tf = makeText(t);
			root.addChild(tf);
			tf.x = 20;
			tf.y = 20 + 16*n;
			tf.alpha = 0;
			var tmp = n;
			haxe.Timer.delay(function() {
				tw.create(tf, "alpha", tmp==0 ? 1 : 0.7, TEaseIn, 1000);
			}, 2000*n);
			n++;
		}
	}
	
	function setSprite(s:DSprite) {
		lastSpot.spr = s;
		buffer.dm.add(s,2);
		var pt = buffer.globalToLocal(lastSpot.hit.x, lastSpot.hit.y);
		s.x = pt.x;
		s.y = pt.y;
		return s;
	}
	function setAction(a:String, effect:Dynamic) {
		lastSpot.act.set(a, effect);
	}
	
	function initWorld() {
		world = new World();
		world.removeRectangle(2,4, 10,6);
		var frame = 0;
		switch(room) {
			case "cell" :
				frame = 0;
				world.addCollision(6,4, 2,1);
				world.addCollision(7,5);
				world.addCollision(11,5, 1,2);
		
				world.addCollision(9,4, 3,1);
		
				world.addCollision(2,7, 1,3);
				world.addCollision(7,8, 3,2);
				
			case "kitchen" :
				frame = 1;
				world.addCollision(2,4);
				world.addCollision(5,4, 3,1);
				world.addCollision(9,4, 3,1);
				world.addCollision(3,6, 2,2);
				world.addCollision(5,6);
				world.addCollision(10,7, 2,3);
				world.addCollision(11,6);
			
			case "park" :
				frame = 2;
				world.addCollision(9,4, 3,1);
				world.addCollision(2,4, 2,1);
				world.addCollision(2,5, 1,2);
				world.addCollision(2,7);
				
			case "hell" :
				frame = 3;
				world.addCollision(9,4, 3,1);
		}

		if( roomBg!=null )
			roomBg.parent.removeChild(roomBg);
		roomBg = lib.getSprite("cell", frame);
		if( room=="cell" ) {
			var r = lib.getSprite("reflections");
			roomBg.addChild(r);
			r.alpha = 0;
			r.x = 24;
			r.y = 32;
			var loop = null;
			loop = function() {
				tw.create(r, "alpha", 1, TLinear, 1000).onEnd = function() {
					tw.create(r, "alpha", 0, TLinear, 1000).onEnd = loop;
				}
			}
			loop();
		}
		buffer.dm.add( roomBg, 1 );
		for(x in 0...world.wid)
			for(y in 0...world.hei) {
				#if debug
				if( SHOW_COLLISIONS && world.collide(x,y) ) {
					var s = lib.getSprite("collision");
					buffer.dm.add(s, 10);
					s.x = x*CWID;
					s.y = y*CHEI;
					s.alpha = 0.2;
				}
				#end
			}
		refreshWorld();
	}
	
	function refreshWorld() {
		addHotSpots();
	}
	
	
	function onMouseDown(e) {
		if( fl_pause )
			return;
		#if debug
		var pt = buffer.globalToLocal(root.mouseX, root.mouseY);
		dragStart = new flash.geom.Point(pt.x, pt.y);
		#end
	}
	
	function onMouseUp(e) {
		if( fl_pause )
			return;
		#if debug
		var pt = buffer.globalToLocal(root.mouseX, root.mouseY);
		if( pt.x!=dragStart.x || pt.y!=dragStart.y ) {
			var s = dragStart.x+","+dragStart.y+","+(pt.x-dragStart.x+1)+","+(pt.y-dragStart.y+1);
			flash.system.System.setClipboard( s );
		}
		dragStart = null;
		#end
	}
	
	function onClick(e) {
		if( skipClick || fl_ending )
			return;
		if( fl_pause ) {
			unpause();
			closePop();
			return;
		}
		
		if( fl_lockControls )
			return;
			
		onArrive = null;
		var pt = buffer.globalToLocal(root.mouseX, root.mouseY);
		pt.x = Std.int(pt.x/CWID);
		pt.y = Std.int(pt.y/CHEI);
		if( !world.collide(pt.x, pt.y) )
			movePlayer(pt.x, pt.y);
	}
	
	function hideName() {
		if( curName!=null )
			curName.parent.removeChild(curName);
		curName = null;
	}
	
	function showName(str:String) {
		hideName();
		//if( pending!=null )
			//str = pending.toUpperCase()+": "+str;
		var tf = makeText(str);
		tf.x = Std.int( 16*7 * UPSCALE*0.5 - tf.textWidth*tf.scaleX*0.5 );
		tf.textColor = 0xB8BAC9;
		tf.x = root.mouseX+5;
		tf.y = root.mouseY-16;
		tf.alpha = 0;
		tw.create(tf, "alpha", 1, TEaseOut, 400);
		//tf.y = 9 * UPSCALE;
		dm.add(tf,1);
		tf.mouseEnabled = false;
		curName = tf;
		curName.visible = !fl_pause && !fl_lockControls;
	}
	
	//function closeActions() {
		//if( menu!=null ) {
			//menu.parent.removeChild(menu);
			//menu = null;
		//}
	//}
	
	//function actionMenu(hs:Hotspot) {
		//closeActions();
		//if( fl_pause )
			//return;
		//menu = new flash.display.Sprite();
		//root.addChild(menu);
		//menu.x = Std.int(root.mouseX+10);
		//menu.y = Std.int(root.mouseY);
		//var y = 0.;
		//
		//for(a in [LOOK, PICK, USE]) {
			//var s = makeButton(a);
			//s.y = Std.int(y);
			//menu.addChild(s);
			//if( hs.act.exists(a) ) {
				//var res = hs.act.get(a);
				//if( Type.typeof(res)==ValueType.TFunction )
					//s.addEventListener(flash.events.MouseEvent.CLICK, function(_) {
						//closeActions();
						//res();
					//});
				//else
					//s.addEventListener(flash.events.MouseEvent.CLICK, function(e) pop(res) );
			//}
			//y+=s.height-6;
		//}
	//}
	
	function makeText(str:String, ?multiLine=false) {
		var tf = new flash.text.TextField();
		tf.defaultTextFormat = FORMAT;
		tf.multiline = multiLine;
		tf.wordWrap = multiLine;
		tf.selectable = false;
		tf.width = 150;
		tf.height = 300;
		tf.text = str;
		tf.antiAliasType = flash.text.AntiAliasType.NORMAL;
		tf.embedFonts = true;
		tf.sharpness = 400;
		tf.scaleX = tf.scaleY = 2;
		tf.width = tf.textWidth+5;
		tf.height = tf.textHeight+5;
		tf.filters = [ new flash.filters.GlowFilter(0x0,1, 4,4, 10) ];
		tf.filters = [ new flash.filters.GlowFilter(0x0,1, 4,4, 10) ];
		return tf;
	}
	
	function closePop(?nextQueue=true) {
		if( popUp!=null ) {
			popUp.parent.removeChild(popUp);
			popUp = null;
		}
		if( nextQueue && popQueue.length==0 && afterPop!=null )  {
			var cb = afterPop;
			afterPop = null;
			cb();
		}
		else
			if( nextQueue && popQueue.length>0 )
				pop( popQueue.pop() );
	}
	
	function pop(str:String) {
		if( popUp!=null ) {
			popQueue.add(str);
			return;
		}
		if( str.indexOf("|")>0 ) {
			var parts = str.split("|");
			str = parts[0];
			for(i in 1...parts.length)
				popQueue.add(parts[i]);
		}
		var col = 0x4F58C8;
		var tcol = 0xFFFFFF;
		if( str.charAt(0)=="!" ) {
			col = 0x9E0C0C;
			str = str.substr(1);
		}
		if( str.charAt(0)=="@" ) {
			col = 0x4B5F56;
			tcol = 0xA7BAB1;
			str = str.substr(1);
		}
		skipClick = true;
		lockControls(true);
		if( curName!=null )
			curName.visible = false;
		//closeActions();
		closePop(false);
		var s = new flash.display.Sprite();
		var tf = makeText(str, true);
		tf.textColor = tcol;
		tf.x+= 10;
		tf.y+= 10;
		tf.filters = [];
		s.addChild(tf);
		var g = s.graphics;
		g.beginFill(col, 1);
		g.drawRect(0,0, tf.textWidth*tf.scaleX+25, tf.textHeight*tf.scaleX+25);
		s.filters = [
			new flash.filters.GlowFilter(0xffffff,1, 4,4, 10,1, true),
			new flash.filters.GlowFilter(0x0,1, 4,4, 10),
		];
		dm.add(s,2);
		
		s.x = Std.random(100) + 16*2*UPSCALE;
		if( s.x<5 ) s.x = 5;
		if( s.x+s.width+5>=WID ) s.x = WID-s.width-5;
		
		s.y = if( player.cy>=6 ) Std.random(30)+20 else Std.random(30)+CHEI*6*UPSCALE;
		if( s.y<5 ) s.y = 5;
		if( s.y+s.height+5>=HEI) s.y = HEI-s.height-5;
		
		fl_pause = true;
		popUp = s;
	}
	
	
	function main(_) {
		skipClick = false;
		tw.update();
		
		if( dispScale==0 )
			buffer.postFilters = [];
		else {
			var spd = 0.1; // * (1-dispScale);
			displace.perlinNoise(50,30, 3, 0, true, false, 7, true, [new flash.geom.Point(-spd*UNIQ++,-spd*UNIQ), new flash.geom.Point(-spd*UNIQ++,-2*spd*UNIQ), new flash.geom.Point(0.5*spd*UNIQ++,1.5*spd*UNIQ)]);
			buffer.postFilters = [
				new flash.filters.DisplacementMapFilter(displace, new flash.geom.Point(0,0), 1, 1, dispScale*13,dispScale*15, flash.filters.DisplacementMapFilterMode.WRAP, 0, 1)
			];
			var recal = dispScale<0.2 ? 0. : (dispScale-0.2)/0.8;
			buffer.render.x = -13*recal;
			buffer.render.y = -15*recal;
		}
		
		if( !fl_pause && !fl_ending ) {
			
			#if debug
			if( dragStart!=null ) {
				var g = drag.graphics;
				g.clear();
				g.lineStyle(1, 0xFFFF00, 1, true, flash.display.LineScaleMode.NONE);
				var pt = buffer.globalToLocal(root.mouseX, root.mouseY);
				g.beginFill(0xFF0000,0.5);
				g.drawRect(dragStart.x, dragStart.y, pt.x-dragStart.x, pt.y-dragStart.y);
			}
			#end
			
			var sx = 0.15;
			var sy = 0.1;
			#if debug
				sx*=2.5;
				sy*=2.5;
			#end
			if( playerPath.length>0 ) {
				var t = playerPath[0];
				if( player.cx<t.x ) player.dx = sx;
				else if( player.cx>t.x ) player.dx = -sx;
				else if( player.cy<t.y ) player.dy = sy;
				else if( player.cy>t.y ) player.dy = -sy;
				else playerPath.shift();
				if( player.dx==0 && player.dy==0 && playerPath.length==0 && onArrive!=null ) {
					onArrive();
					onArrive = null;
					if( playerTarget!=null )
						player.lookAt(playerTarget.x, playerTarget.y);
					playerTarget = null;
				}
			}
			if( player.dx==0 && player.xr<0.5-sx)
				player.dx = sx*1.25;
			if( player.dx==0 && player.xr>0.5+sx)
				player.dx = -sx*1.25;
				
			if( player.dy==0 && player.yr<0.5-sy )
				player.dy = sy;
			if( player.dy==0 && player.yr>0.5+sy )
				player.dy = -sy;
				
			if( player.dx==0 && player.dy==0 && playerPath.length==0 ) {
				if( player.spr.isPlaying("walkUp") || player.spr.isPlaying("walkDown") ) {
					footstep = 0;
					if( player.dirY==-1 )
						player.spr.playAnim("standUp");
					else
						player.spr.playAnim("standDown");
				}
			}
			else {
				footstep--;
				if( footstep<=0 ) {
					if( Std.random(3)==0 )
						SOUNDS.footstep1.play();
					else
						SOUNDS.footstep2.play();
					footstep = 6;
				}
				if( !player.spr.isPlaying("read") )
					if( player.dirY==-1 )
						player.spr.playAnim("walkUp");
					else
						player.spr.playAnim("walkDown");
			}
			//if( Key.isDown(Keyboard.LEFT) )
				//player.dx = -s;
			//if( Key.isDown(Keyboard.RIGHT) )
				//player.dx = s;
			//if( Key.isDown(Keyboard.UP) )
				//player.dy = -s*0.7;
			for(a in [LOOK, USE, OPEN, CLOSE, REMEMBER, PICK])
				if( Key.isToggled(a.charCodeAt(0)) )
					setPending(a);
			//if( Key.isDown(Keyboard.DOWN) )
				//player.dy = s*0.7;
			if( room=="hell" && player.cx<=6 ) {
				pop("!Lydia!!!");
				setTrigger("letterPop");
				afterPop = callback(changeRoom,"park");
			}
			
			player.update();
			DSprite.updateAll();
		}
		
		if( hasItem("finalLetter") )
			DSprite.updateAll();
		
		if( curName!=null ) {
			//if( curName.x>=WID-curName.width )
				//curName.x = root.mouseX - 6 - curName.width;
			//else
				curName.x = root.mouseX+6;
			curName.y = root.mouseY+12;
		}
		buffer.update();
		buffer2.update();
		heroFade.x = player.spr.x;
		heroFade.y = player.spr.y-4;
		
		#if debug
		debug.custom.text = player.cx+","+player.cy;
		#end
	}
}
