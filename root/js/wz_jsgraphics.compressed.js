var jg_ihtm,jg_ie,jg_fast,jg_dom,jg_moz,jg_n4=(document.layers&&typeof document.classes!="undefined");
function chkDHTM(x,i){
x=document.body||null;
jg_ie=x&&typeof x.insertAdjacentHTML!="undefined";
jg_dom=(x&&!jg_ie&&typeof x.appendChild!="undefined"&&typeof document.createRange!="undefined"&&typeof (i=document.createRange()).setStartBefore!="undefined"&&typeof i.createContextualFragment!="undefined");
jg_ihtm=!jg_ie&&!jg_dom&&x&&typeof x.innerHTML!="undefined";
jg_fast=jg_ie&&document.all&&!window.opera;
jg_moz=jg_dom&&typeof x.style.MozOpacity!="undefined";
}
function pntDoc(){
this.wnd.document.write(jg_fast?this.htmRpc():this.htm);
this.htm="";
}
function pntCnvDom(){
var x=this.wnd.document.createRange();
x.setStartBefore(this.cnv);
x=x.createContextualFragment(jg_fast?this.htmRpc():this.htm);
if(this.cnv){
this.cnv.appendChild(x);
}
this.htm="";
}
function pntCnvIe(){
if(this.cnv){
this.cnv.insertAdjacentHTML("BeforeEnd",jg_fast?this.htmRpc():this.htm);
}
this.htm="";
}
function pntCnvIhtm(){
if(this.cnv){
this.cnv.innerHTML+=this.htm;
}
this.htm="";
}
function pntCnv(){
this.htm="";
}
function mkDiv(x,y,w,h,a){
if(!a) a = 1;
//this.htm+="<div style=\"position:absolute;"+(  (jg_ie) ? "filter:alpha(opacity="+(a*100)+");zoom:1" : "opacity:"+a  )+";left:"+x+"px;top:"+y+"px;width:"+w+"px;height:"+h+"px;clip:rect(0,"+w+"px,"+h+"px,0);background-color:"+this.color+(!jg_moz?";overflow:hidden":"")+";\"></div>";
this.htm+="<div style=\"position:absolute;left:"+x+"px;top:"+y+"px;width:"+w+"px;height:"+h+"px;clip:rect(0,"+w+"px,"+h+"px,0);background-color:"+this.color+(!jg_moz?";overflow:hidden":"")+";\"></div>";
}
function mkDivIe(x,y,w,h){
this.htm+="%%"+this.color+";"+x+";"+y+";"+w+";"+h+";";
}
function mkDivPrt(x,y,w,h,a){
if(!a) a = 1;
this.htm+="<div style=\"position:absolute;"+(  (jg_ie) ? "filter:alpha(opacity="+(a*100)+");zoom:1" : "opacity:"+a  )+";border-left:"+w+"px solid "+this.color+";left:"+x+"px;top:"+y+"px;width:0px;height:"+h+"px;clip:rect(0,"+w+"px,"+h+"px,0);background-color:"+this.color+(!jg_moz?";overflow:hidden":"")+";\"></div>";
}
function mkLyr(x,y,w,h){
this.htm+="<layer "+"left=\""+x+"\" "+"top=\""+y+"\" "+"width=\""+w+"\" "+"height=\""+h+"\" "+"bgcolor=\""+this.color+"\"></layer>\n";
}
var regex=/%%([^;]+);([^;]+);([^;]+);([^;]+);([^;]+);/g;
function htmRpc(){
return this.htm.replace(regex,"<div style=\"overflow:hidden;position:absolute;background-color:"+"$1;left:$2;top:$3;width:$4;height:$5\"></div>\n");
}
function htmPrtRpc(){
return this.htm.replace(regex,"<div style=\"overflow:hidden;position:absolute;background-color:"+"$1;left:$2;top:$3;width:$4;height:$5;border-left:$4px solid $1\"></div>\n");
}
function mkRect(x,y,w,h){
var s=this.stroke;
this.mkDiv(x,y,w,s);
this.mkDiv(x+w,y,s,h);
this.mkDiv(x,y+h,w+s,s);
this.mkDiv(x,y+s,s,h-s);
}
function jsgStroke(){
this.DOTTED=-1;
}
var Stroke=new jsgStroke();
function jsGraphics(id,wnd){
this.setColor=new Function("arg","this.color = arg.toLowerCase();");
this.setStroke=function(x){
this.stroke=x;
this.drawRect=mkRect;
};
this.setPrintable=function(arg){
this.printable=arg;
if(jg_fast){
this.mkDiv=mkDivIe;
this.htmRpc=arg?htmPrtRpc:htmRpc;
}else{
this.mkDiv=jg_n4?mkLyr:arg?mkDivPrt:mkDiv;
}
};
this.setFont=function(fam,sz,sty){
this.ftFam=fam;
this.ftSz=sz;
this.ftSty=sty||Font.PLAIN;
};
this.fillRect=function(x,y,w,h,a){
this.mkDiv(x,y,w,h,a);
};
this.drawPolygon=function(x,y){
this.drawPolyline(x,y);
this.drawLine(x[x.length-1],y[x.length-1],x[0],y[0]);
};
this.clear=function(){
this.htm="";
if(this.cnv){
this.cnv.innerHTML=this.defhtm;
}
};
this.setStroke(1);
this.color="#000000";
this.htm="";
this.wnd=wnd||window;
if(!(jg_ie||jg_dom||jg_ihtm)){
chkDHTM();
}
if(typeof id!="string"||!id){
this.paint=pntDoc;
}else{
this.cnv=document.all?(this.wnd.document.all[id]||null):document.getElementById?(this.wnd.document.getElementById(id)||null):null;
this.defhtm=(this.cnv&&this.cnv.innerHTML)?this.cnv.innerHTML:"";
this.paint=jg_dom?pntCnvDom:jg_ie?pntCnvIe:jg_ihtm?pntCnvIhtm:pntCnv;
}
this.setPrintable(false);
}
function integer_compare(x,y){
return (x<y)?-1:((x>y)*1);
}