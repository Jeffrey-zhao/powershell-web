; (function () {
    gantt.config.xml_date = "%Y-%m-%d %H:%i:%s";
    //set lightbox not popup
    gantt.attachEvent("onBeforeLightbox", function (id) {
        return false;
    });
    gantt.config.open_tree_initially = true;
    gantt.config.scale_height = 30 * 2;
    gantt.config.min_column_width = 50;

    //set timeline header    
    gantt.config.scale_unit = "month";
    gantt.config.date_scale = "%F,%Y";
    gantt.config.subscales = [{
        unit: 'day',
        step: 1,
        date: '%j,%D'
    }];

    //set grid
    gantt.config.columns = [{
        name: "text",
        label: "job name",
        tree: true,
        resize: true,
        min_width: 150,
        width: 200
    },
        {
            name: "id",
            label: "job id",
            align: "center",
            resize: true
        },
        {
            name: "start_date",
            label: "Start time",
            align: "center",
            width: 80,
            resize: true
        }
    ];

    gantt.config.layout = {
        css: "gantt_container",
        cols: [{
            width: 400,
            min_width: 300,
            rows: [{
                view: "grid",
                scrollX: "gridScroll",
                scrollable: true,
                scrollY: "scrollVer"
            },
                {
                    view: "scrollbar",
                    id: "gridScroll",
                    group: "horizontal"
                }
            ]
        },
            {
                resizer: true,
                width: 1
            },
            {
                rows: [{
                    view: "timeline",
                    scrollX: "scrollHor",
                    scrollY: "scrollVer"
                },
                    {
                        view: "scrollbar",
                        id: "scrollHor",
                        group: "horizontal"
                    }
                ]
            },
            {
                view: "scrollbar",
                id: "scrollVer"
            }
        ]
    };

    // set task properties
    // gantt.config.drag_resize = false;
    // gantt.config.drag_move = false;
    gantt.config.drag_progress = false;
    gantt.config.drag_links = false;

    gantt.templates.task_class = function (start, end, task) {
        return task.status;
    };

    // tooltip text
    gantt.templates.tooltip_text = function (start, end, task) {
        return "<b>Job Id:</b> " + task.id + "<br/><b>Start date:</b> " +
            gantt.templates.tooltip_date_format(start) +
            "<br/><b>End date:</b> " + gantt.templates.tooltip_date_format(end) +
            "<br/><b>Status:</b>" + task.custom.status +
            "<br/><b>Next:</b>" + task.custom.jobids;
    };

    var taskLinks = new Map()

    function setTaskLinks(id) {
        if (!taskLinks.entries.length) {
            taskLinks.forEach(function (value, key) {
                value.forEach(function (value, index, links) {
                    var linkDom = document.querySelector("div[link_id='" + value + "']")
                    linkDom.classList.remove('gantt_task_links')
                })
            })
            taskLinks.clear()
        }

        var task = gantt.getTask(id)
        var links = [].concat(task.$source, task.$target)
        taskLinks.set(id, links)
        links.forEach(function (value, index, links) {
            var linkDom = document.querySelector("div[link_id='" + value + "']")
            linkDom.classList.add('gantt_task_links')
        })
    };
    gantt.templates.task_text = function (start, end, task) {
        return task.text
    };
    gantt.attachEvent("onLinkDblClick", function (id, e) {
        return false;
    });

    gantt.templates.link_class = function (link) {
        return "gantt_line_shadow";
    }
    gantt.attachEvent("onTaskClick", function (id) {
        // set task's links' style
        setTaskLinks(id)
    });

    gantt.message({
        text: "<p>Status Colors:</p>" +
        "<table class='tips'>" +
        "<thead>" +
        "<tr><th>Status</th><th>Color</th>" +
        "</thead>" +
        "<tbody>" +
        "<tr><td>New</td><td class='gantt-new'></td>" +
        "<tr><td>Pending</td><td  class='gantt-pending'></td>" +
        "<tr><td>Running</td><td class='gantt-running'></td>" +
        "<tr><td>ActionRequired</td><td class='gantt-actionrequired'></td>" +
        "<tr><td>Completed</td><td class='gantt-completed'></td>" +
        "<tr><td>Cancelled</td><td class='gantt-cancelled'></td>" +
        "<tr><td>Paused</td><td class='gantt-paused'></td>" +
        "<tr><td>Waiting</td><td class='gantt-waiting'></td>" +
        "<tr><td>TaskFailed</td><td class='gantt-taskfailed'></td>" +
        "</tbody>" +
        "</table>",
        expire: -1
    })
}());