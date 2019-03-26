// optimize the tab
$(function () {
    $('#commandsbar a:first').tab('show');
})
$('#commandsbar a').click(function (e) {
    e.preventDefault();
    $(this).tab('show');
})

// submit execution button
$(function () {

    var ajax_execute = function (form_data) {
        $.ajax({
            url: '/script/execute/',
            type: 'POST',
            data: form_data,
            success: (data) => {
                console.log(data.content)
                $("#output_message").text(data.content)
            }
        })
    }
    var ajax_upload = function (files_data, form_data, cb) {
        $.ajax({
            url: '/script/upload',
            type: 'POST',
            data: files_data,
            contentType: false,
            processData: false,
            success: (data) => {
                $("#output_message").text(data.content + ",but is still executing this command...\n")
                cb(form_data)
            },
            error: (error) => {
                $("#output_message").text('cannot get you given file.\n' + error)
            }
        })
    }
    $(".command-form-area button").click(function (e) {

        var form_class = this.id.replace('-$__submit', '')
        var required_field = $('#' + form_class).find('input[required],select[required]')
        if (required_field) {
            var flag = false
            required_field.each(function (index, ele) {
                if (!$(ele).val()) flag = true
            })
            if (flag) {
                $("#output_message").text('please input required parameters');
                return false
            }
        }
        var inputs = $('#' + form_class).find('input,select')
        var cmdParameters = $('#cmd-parameter').find('span')
        var form_data = {
                data: [],
                base: []
            },
            files_data = null;

        for (var i = 0; i < inputs.length; i++) {
            var params = {
                name: inputs[i].name,
                value: inputs[i].value,
                type: inputs[i].previousElementSibling.firstElementChild.innerText.replace(/[\(\)]/g, ''),
                isFile: inputs[i].type == 'file' ? true : false
            }
            if (params.isFile && inputs[i].files.length > 0) {
                if (!files_data) {
                    files_data = new FormData()
                }
                files_data.append(params.name, inputs[i].files[0])
            }
            form_data.data.push(params)
        }
        for (var i = 0; i < cmdParameters.length; i++) {
            form_data.base.push({
                [cmdParameters[i].getAttribute('name')]: cmdParameters[i].innerText
            })
        }

        // tips in 'execute output'
        $("#output_message").text('requests has been sent ,please waiting...')

        if (files_data) {
            ajax_upload(files_data, form_data, ajax_execute)
            //ajax_upload(files_data)
        } else {
            ajax_execute(form_data)
        }

    })

    $(document).ajaxError((event, xhr, options) => {
        $('#output_message').val('Error: unknown client request errror!');
        $('#output_message').val(xhr.responseText);
    });
})