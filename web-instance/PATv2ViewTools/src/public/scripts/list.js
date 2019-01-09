$(function () {
    $('.readfile').click(function (e) {
        var listfile = $(this).parent().parent().find('.listfile')[0]
        var checkbox = $(this).find(':checkbox')[0]
        if (checkbox.checked) {
            listfile.href = listfile.href.replace(/function/, 'readfile')
            listfile.title = 'file detail'
        } else {
            listfile.href = listfile.href.replace(/readfile/, 'function')
            listfile.title = 'function detail'
        }
    })

    $('.file-folder-name').click(function (e) {
        var type = $(this).prev().text().trim()
        var readFileCheckbox = $(this).parent().find('.readfile').find(':checkbox')[0]
        var path = $(this).next().text().trim()
        if (!RegExp(/.+\.ps1$/).test(path) && !readFileCheckbox.checked && type == 'File') {
            alert('please choose script file (*.ps1) to execute!!!')
            e.preventDefault()
        }
    })
})