$(document).ready(function() {
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
    }
});
                
// Handle's menu selection and back button
window.onhashchange = function() {
    var newPage = location.hash;
    newPage = newPage.replace('#~','');

    $('menu li.selected').removeClass('selected').addClass('unselected');
    $('#' + newPage).removeClass('unselected').addClass('selected');

    $('div.content').removeClass('visible').addClass('hidden');
    setTimeout(function() {
        $('#content').load('html/' + newPage + '.html');
    }, 500);
    setTimeout(function() {
        $('#main-body').height($('#content').height());
    }, 530);
    setTimeout(function() {
        $('div.content').removeClass('hidden').addClass('visible');
    }, 650);    
    setTimeout(function() {
        $('#main-body').height($('#content').height());
    }, 680);
}