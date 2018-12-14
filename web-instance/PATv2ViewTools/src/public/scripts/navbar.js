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
        for (var i = 0; i < inputs.length; i++) {
            form_data.data.push({
                name: inputs[i].name,
                value: inputs[i].value,
                type: inputs[i].previousElementSibling.firstElementChild.innerText.replace(/[\(\)]/g, '')
            })
        }
        for (var i = 0; i < cmdParameters.length; i++) {
            form_data.base.push({
                [cmdParameters[i].getAttribute('name')]: cmdParameters[i].innerText
            })
        }

        $.ajax({
            url: '/script/execute/',
            type: 'POST',
            data: form_data,
            success: (data) => {
                $("#output_message").val(data.content)
            }
        })

        /*
         $.ajax({
             url: '/script/execute/',
             type: 'POST',
             data: form_data,
             success: (data) => {
                 console.log(data)
                 $("#output_message").val(data)
             }
         })
         */
    })

    $(document).ajaxError((event, xhr, options) => {
        $('#output_message').val('Error: unknown client request errror!');
        $('#output_message').val(xhr.responseText);
    });
})