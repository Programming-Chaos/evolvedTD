$(document).ready(function() {
    // Initial page content
    var initPage = location.hash.replace('#~','').split('&');
    $('#' + initPage[1]).addClass('selected');
    $('#info').load('html/' + initPage[0] + '/' + initPage[1] + '.html');

    // Handle tab selections
    $('section.left li.tab').not('selected').click(function() {
        var $this = $(this);
        var page = location.hash.split('&');

        // Change the hash to load the content
        location.hash = page[0] + '&' + $this.attr('id');

    });
});

window.onhashchange = function() {
    var newPage = location.hash;
    newPage = newPage.replace('#~','');
    newPage = newPage.split('&');

    changePage(newPage[0]);

    if (newPage.length > 1) {
        // Replace selected tab
        $('section.left li.tab.selected').removeClass('selected');
        $('#' + newPage[1]).addClass('selected');

        // Change loaded content
        $('section.right').addClass('hidden');
        setTimeout(function() {
            $('#info').load('html/' + newPage[0] + '/' + newPage[1] + '.html');
        }, 500);
        setTimeout(function() {
            $('section.right').removeClass('hidden');
        }, 530);    
    }

    // Handle content-block height
    setTimeout(function() {
        var leftH  = $('section.content-block.left').height(),
            rightH = $('section.content-block.right').height();
        
        if (rightH > leftH) {
            $('#main-body').height(rightH);
        }
        else if (leftH > rightH) {
            $('#main-body').height(leftH);
        }
    }, 530);
}