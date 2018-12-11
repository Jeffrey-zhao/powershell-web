$(function () {
    $('#commandsbar a:first').tab('show');
})
$('#commandsbar a').click(function (e) {
    e.preventDefault();
    $(this).tab('show');
})