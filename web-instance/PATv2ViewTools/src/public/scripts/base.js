// function detail
$(function () {
    $('.function-line-detail').click(function (e) {
        var children = $(this).parent().children()
        var funcName = children[1].firstElementChild.innerText
        var path = $('.fn_file_path').text()

        $.ajax({
            url: '/script/detail?filepath=' + path + "&fn=" + funcName,
            type: 'GET',
            success: (data) => {
                $('.function-detail').find('pre').text(data.content)
            }
        })
    });

    $('.fn-script-detail').click(function (e) {
        var path = $('.fn_file_path').text()
        $.ajax({
            url: '/script/detail?filepath=' + path,
            type: 'GET',
            success: (data) => {
                $('.function-detail').find('pre').text(data.content)
            }
        })
    })
})