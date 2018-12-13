$(function () {
    $('#commandsbar a:first').tab('show');
})
$('#commandsbar a').click(function (e) {
    e.preventDefault();
    $(this).tab('show');
})

$(function () {
    $(".command-form-area button").click(function (e) {
        var form_class = this.id.replace('-$__submit', '')
        var inputs = $('#' + form_class).find('input')
        var cmdParameters = $('#cmd-parameter').find('span')
        var form_data = {
            data: [],
            base: []
        }
        for (i = 0; i < inputs.length; i++) {
            form_data.data.push({
                name: inputs[i].name,
                value: inputs[i].value
            })
        }
        for (i = 0; i < cmdParameters.length; i++) {
            form_data.base.push({
                name: cmdParameters[i].getAttribute('name'),
                value: cmdParameters[i].innerText
            })
        }

        $.ajax({
            url: '/script/detail',
            type: 'GET',
            datatType: 'json',
            //data: JSON.parse(form_data),
            success: (data) => {
                $("#output_message").val(data)
            },
            error: (error) => {
                $("#output_message").val(err)
            }
        })

        $.ajax({
            url: '/script/execute',
            type: 'POST',
            datatType: 'json',
            data: JSON.parse(form_data),
            success: (data) => {
                $("#output_message").val(data)
            },
            error: (error) => {
                $("#output_message").val(err)
            }
        })
    })
})