// copyright 2006 Dennis Hall
// this copyright notice must stay intact at all times.

function drag_select( container_id, type_of_selectable, callback_function ){
	
	var me = this;
	me.keyModifier = null;
	me.selectionModifier = "";
	var _length = 0;
	var SHIFT = 16;
	var CTRL = 17;
	var ALT = 18;
	var previousSelections = [];
	
	//ox and oy are the origin x and y :: the point where we begin making the selection box.
	//mx and my are the mouse x and y
	var ox = 0, oy = 0, mx = 0, my = 0, jg, IE = document.all ? true : false, originset = false, selectables = [];
	if (!IE) document.captureEvents(Event.MOUSEMOVE);

	add_container(container_id, type_of_selectable, callback_function);
	
	document.body.onmouseup = dontTrackTheMouse;
	document.onkeydown = setKeyModifier;
	document.onkeyup   = clearKeyModifier;
	
	//should be stored in an array of "selectables_containers"
	//.. so more than one group--defined by it's container--can be 'selectable'
	//var theOL=document.getElementById( container_id );
	
	
	//should CREATE, then append.. some tiny box
	var myCanvas = document.createElement('div');
	myCanvas.style.position = "absolute";
	myCanvas.style.top = "0";
	myCanvas.style.left = "0";
	myCanvas.style.width="1px";
	myCanvas.style.height="1px";
	myCanvas.style.fontsize="1px";
	myCanvas.id = "myCanvas";
	document.body.appendChild( myCanvas );
	jg = new jsGraphics("myCanvas");

	//for ie7 (and maybe ie6 with some help)
	var img = document.createElement('img');
	img.src = "blue.png";
	img.style.position = "absolute";
	img.style.display = "none";
	document.body.appendChild( img );
	
	function add_container( container_id, type_of_selectable, callback_function ){
		var container = document.getElementById(container_id);
		container.onmousedown = trackthemouse;
		container.onselectstart = function(){return false;};
		var elements = container.getElementsByTagName(type_of_selectable);
		selectables[_length] = {elements:elements, elxys:getpoints(elements, _length), selectionMask: [], f:callback_function};
		_length++;
	}
	
	//gets the 4 xy coordinate pairs of the rectangle defined by the screen rendering of all the selectable element
	function getpoints(elements, s){
		var points = [];
		var len = elements.length;
		(function loop( I ){
			if (I == len) return;
			var i = I;
			
			
			var el = elements[i];
			el.style.cursor = "default";
			el.onclick = function(e){
				clicked(s, i, e);
				/*console.log(s + ', '+i);selectables[j].selectionMask[i] = true;selectables[j].f(this, true);*/
			};
			var xy = getxy( el );
			points[i] = [xy[0], xy[1], xy[0]+el.offsetWidth, xy[1]+el.offsetHeight];
			
			
			loop(++I);
		})(0);

		return points;
	}
	
	function clicked(s, si, e){
		setSelectionModifier(e);
		setPreviousSelections();
		var elements = selectables[s].elements;
		var length = elements.length;
		for(var i=0;i<length;i++){
			isOverlapping = si == i;
			if(me.selectionModifier == ""){
				//console.log('no ctrl');
				selectables[s].selectionMask[i] = isOverlapping;
			} else {
				//console.log("yes ctrl");
				selectables[s].selectionMask[i] = (isOverlapping || previousSelections[s][i]) && !(isOverlapping && previousSelections[s][i]);
				//if(i==0) console.dir(previousSelections[s]);
			}
			selectables[s].f( elements[i], selectables[s].selectionMask[i] );
		}
	}

	function getxy(obj) {
		var curleft = 0, curtop = 0;
		if (obj.offsetParent) {
			curleft = obj.offsetLeft;
			curtop = obj.offsetTop;
			while (obj = obj.offsetParent) {
				curleft += obj.offsetLeft;
				curtop += obj.offsetTop;
			}
		}
		return [curleft,curtop];
	}
	
	function setSelectionModifier(e){
		if (!e) var e = window.event;
		if(e && e.ctrlKey){
			me.selectionModifier = "xor";
			return;
		}
		if(me.keyModifier == CTRL){
			me.selectionModifier = "xor";
		} else if(me.keyModifier == SHIFT){
			me.selectionModifier = "add";
		} else if(me.keyModifier == ALT){
			me.selectionModifier = "remove";
		} else {
			me.selectionModifier = "";
		}
	}
	
	
	function trackthemouse() {
		setSelectionModifier();
		document.onmousemove = mouseMoveEvent;
		img.style.width = '1px';
		img.style.height = '1px';
		img.style.display = "";
		return false;
	}
	
	function dontTrackTheMouse() {
		document.onmousemove = null;
		originset = false;
		img.style.display = "none";
		jg.clear();
	}
	
	function setKeyModifier(e) {
		//not checking if MORE THAN ONE key is held down!
		if(!e) var e = window.event;
		var code;
		if (e.keyCode) code = e.keyCode;
		else if (e.which) code = e.which;
		//console.log(code);
		me.keyModifier = code;
	}
	
	function clearKeyModifier() {
		me.keyModifier = null;
	}
	
	function setPreviousSelections(){
		var len = selectables.length;
		for(var s=0;s<len;s++){
			var len2 = selectables[s].elements.length;
			previousSelections[s] = [];
			for(var i=0;i<len2;i++){
				previousSelections[s][i] = selectables[s].selectionMask[i];
			}
		}
	}
	
	function mouseMoveEvent(e) {
		if (!e) var e = window.event;
		
		if(e && e.ctrlKey){
			me.selectionModifier = "xor";
		}
		
		if (e.pageX || e.pageY) {
			mx = e.pageX;
			my = e.pageY;
		}
		else if (e.clientX || e.clientY){
			mx = e.clientX + document.body.scrollLeft
				+ document.documentElement.scrollLeft;
			my = e.clientY + document.body.scrollTop
				+ document.documentElement.scrollTop;
		}

		if(!originset){
			ox = mx;
			oy = my;
			originset = true;
			
			setPreviousSelections();
			
			//console.dir(previousSelections);
			//console.log('setting origin');
			
			//return false;
		}
		
		var dx = (mx>ox) ? mx-ox : ox-mx;
		var dy = (my>oy) ? my-oy : oy-my;
		
		//if the mouse has BARELY been moved, assume it was an accident while attempting a click
		if( dx + dy < 3 ) return;
		
		//ul = upperleft, lr = lowerright (corners)
		var ul=[],lr=[];

		// the next 20 lines or so could probably be simplified a little more.
		if(ox>mx){
			ul[0] = mx;
			lr[0] = ox-mx;
		} else {
			ul[0] = ox;
			lr[0] = mx-ox;
		}
		if(oy>my){
			ul[1] = my;
			lr[1] = oy-my;
		} else {
			ul[1] = oy;
			lr[1] = my-oy;
		}
		
		var x2 = ul[0];
		var y2 = ul[1];
		var x3 = x2+lr[0];
		var y3 = y2+lr[1];
		
		var len = selectables.length;
		for(var s=0;s<len;s++){
		
			var elxy = selectables[s].elxys;
			var length = elxy.length;
			var elements = selectables[s].elements;
			
			for(var i=0;i<length;i++){
				// if selection area (= x2,y2, x3,y3) overlaps selectables[i]...
				var isOverlapping = !( (elxy[i][0]<x2 && elxy[i][2]<x2) || (elxy[i][0]>x3 && elxy[i][2]>x3) || (elxy[i][1]<y2 && elxy[i][3]<y2) || (elxy[i][1]>y3 && elxy[i][3]>y3) );
				
				if(me.selectionModifier == ""){
					//console.log('no ctrl');
					selectables[s].selectionMask[i] = isOverlapping;
				} else {
					//console.log("yes ctrl");
					selectables[s].selectionMask[i] = (isOverlapping || previousSelections[s][i]) && !(isOverlapping && previousSelections[s][i]);
					//if(i==0) console.dir(previousSelections[s]);
				}
				selectables[s].f( elements[i], selectables[s].selectionMask[i] );
			}
			
			
		}

		jg.clear();
		jg.setColor("#557799"); // blue
		jg.drawRect(ul[0], ul[1], lr[0], lr[1]);
		//if(!document.all) {
		//	jg.fillRect(++ul[0], ++ul[1], --lr[0], --lr[1], 0.3);
		//} else {
			img.style.top = ul[1] + 'px';
			img.style.left = ul[0] + 'px';
			img.style.width = dx + 'px';
			img.style.height = dy + 'px';
			//img.style.width = "100px";
			//img.style.height = "100px";
		//}
		jg.paint();
		return false;
	}
	
	//alert( selectables.length );
	//alert( selectables[0].elements[0].length );
	//alert( selectables[0].func );

}