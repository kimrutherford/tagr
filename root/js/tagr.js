function toggleDiv(elementId) {
    var element = document.getElementById(elementId);
    var display = element.style.display;

    if (display=='none') {
        element.style.display='block';
    }
    else {
        element.style.display='none';
    }
}
