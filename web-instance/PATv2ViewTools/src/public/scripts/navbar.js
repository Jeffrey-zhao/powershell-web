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
    $(".command-form-area button").click(function (e) {

        var form_class = this.id.replace('-$__submit', '')
        var required_field=$('#'+form_class).find('input[required],select[required]')
        if(required_field){
            var flag=false
            required_field.each(function(index,ele){
                if(!$(ele).val()) flag=true
            })
            if(flag) return false
        }
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
        // tips in 'execute output'
        $("#output_message").text('requests has been sent ,please waiting...')
        $.ajax({
            url: '/script/execute/',
            type: 'POST',
            data: form_data,
            success: (data) => {
                console.log(data.content)
                $("#output_message").text(data.content)
            }
        })
    })

    $(document).ajaxError((event, xhr, options) => {
        $('#output_message').val('Error: unknown client request errror!');
        $('#output_message').val(xhr.responseText);
    });
})
