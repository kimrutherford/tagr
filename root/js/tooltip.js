/*
 * Image preview script
 * powered by jQuery (http://www.jquery.com)
 *
 * written by Alen Grakalic (http://cssglobe.com)
 *
 * for more info visit http://cssglobe.com/post/1695/easiest-tooltip-and-image-preview-using-jquery
 *
 */

this.imagePreview = function(){
  /* CONFIG */

    xOffset = 10;
    yOffset = -30;

    // these 2 variable determine popup's distance from the cursor
    // you might want to adjust to get the right result

  /* END CONFIG */
  $("img.preview").hover(function(e){
    this.t = this.title;
    this.title = "";
    var c = (this.t != "") ? "<br/>" + this.t : "";
    var src = this.src.replace(/(\d+)x\1./,"240x240.");

    $("body").append("<div id='preview'><div id='previewImg'><img src='"+ src +"' alt='Image preview' /></div><div id='previewDesc'>"+ c +"</div></div>");
    $("#preview")
      .css("top",(e.pageY + yOffset) + "px")
      .css("left",(e.pageX + xOffset) + "px")
      .fadeIn("fast");
    },
  function(){
    this.title = this.t;
    $("#preview").remove();
    });
  $("img.preview").mousemove(function(e){
    $("#preview")
      .css("top",(e.pageY + yOffset) + "px")
      .css("left",(e.pageX + xOffset) + "px");
  });
};


// starting the script on page load
$(document).ready(function(){
  imagePreview();
});
