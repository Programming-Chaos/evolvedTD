var refresh = false;
$(document).ready(function() {
    checkReload();
});
                
var oldPage = location.hash.split('&');
oldPage = oldPage[0].replace('#~','');
// Handle's menu selection and back button
window.onhashchange = function() {
    var newPage = location.hash;
    newPage = newPage.replace('#~','');
    newPage = newPage.split('&');

    changePage(newPage[0]);
} 

function checkReload() {
    // Handle reload button
    var frag = location.hash.split("#");
    if (frag.length == 1) { //empty hash
        location.hash = '~home';
    }
    else {
        var page = location.hash;
        page = page.replace('#','');
        location.hash = '';
        location.hash = page; //initial hash
        refresh = true;
    }
}

function changePage(newPage) {
    if (oldPage != newPage || refresh) {
        // Load page
        $('menu li.selected').removeClass('selected');
        $('#' + newPage).addClass('selected');

        $('div.content').addClass('hidden');
        setTimeout(function() {
            $('#content').load('html/' + newPage + '.html');
        }, 300);
        setTimeout(function() {
            $('#main-body').height($('#content').height());
        }, 330);
        setTimeout(function() {
            $('div.content').removeClass('hidden');
        }, 400);    
        setTimeout(function() {
            $('#main-body').height($('#content').height());
        }, 430);

        oldPage = newPage;
        refresh = false;
    }  
}