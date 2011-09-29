var iBoxHistory = [];
var nextBox;

function newiBox(url, title, params){
    if($('ibox_wrapper').style.display == 'none'){
        iBoxHistory = [];
    }

    iBox.hide();

    if(iBoxHistory.length > 0){
      title = '<a href="javascript:void(0);" onclick="previBox()">Back</a>' + title;
    }

    nextBox = [url, title, params];
    setTimeout('doOpen()',200);
    iBoxHistory.push([url, title, params]);
}

function doOpen(){
    iBox.showURL(nextBox[0], nextBox[1], nextBox[2]);
}

function previBox(){
    if(iBoxHistory.length == 0){
        iBox.hide();
    } else {
        iBoxHistory.pop();
        args = iBoxHistory.pop();
        newiBox(args[0],args[1], args[2]);
    }
}

//This script will be called after the upload is done and user click on continue
function relocate(action, albumid){
window.location.reload();
}

startList = function() {
if (document.all&&document.getElementById) {
navRoot = document.getElementById("nav");
for (i=0; i<navRoot.childNodes.length; i++) {
node = navRoot.childNodes[i];
if (node.nodeName=="LI") {
node.onmouseover=function() {
this.className+=" over";
  }
  node.onmouseout=function() {
  this.className=this.className.replace(" over", "");
   }
   }
  }
 }
}
window.onload=startList;

function doDrawCircle(){

	var center = map.getCenter();

	var bounds = new GLatLngBounds();


	var circlePoints = Array();

	with (Math) {
		if (circleUnits == 'KM') {
			var d = circleRadius/6378.8;	// radians
		}
		else { //miles
			var d = circleRadius/3963.189;	// radians
		}

		var lat1 = (PI/180)* center.lat(); // radians
		var lng1 = (PI/180)* center.lng(); // radians

		for (var a = 0 ; a < 361 ; a++ ) {
			var tc = (PI/180)*a;
			var y = asin(sin(lat1)*cos(d)+cos(lat1)*sin(d)*cos(tc));
			var dlng = atan2(sin(tc)*sin(d)*cos(lat1),cos(d)-sin(lat1)*sin(y));
			var x = ((lng1-dlng+PI) % (2*PI)) - PI ; // MOD function
			var point = new GLatLng(parseFloat(y*(180/PI)),parseFloat(x*(180/PI)));
			circlePoints.push(point);
			bounds.extend(point);
		}

	}
}
