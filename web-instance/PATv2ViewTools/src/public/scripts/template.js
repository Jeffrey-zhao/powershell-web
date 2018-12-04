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
        label: "template name",
        tree: true,
        resize: true,
        min_width: 150,
        width: 200
    },
        {
            name: "id",
            label: "template id",
            align: "center",
            resize: true
        }
    ];

    gantt.config.layout = {
        css: "gantt_container",
        cols: [{
            width: 300,
            min_width: 200,
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
    gantt.config.drag_resize = false;
    // gantt.config.drag_move = false;
    gantt.config.drag_progress = false;
    gantt.config.drag_links = false;

    gantt.templates.task_class = function (start, end, task) {
        var task_class = " gantt-" + (task.custom.status.toLowerCase())
        if (task.custom.group) {
            task_class += " gantt-group-" + (task.custom.group.toLowerCase())
        } else {
            task_class += " gantt-not-in-group "
        }
        return task_class;
    };

    // tooltip text
    var links
    gantt.templates.tooltip_text = function (start, end, task) {
        return "<b>Template Id:</b> " + task.id + "<br/>" +
            "<b>Template Name:</b> " + task.text + "<br/>" +
            "<b>Start date:</b> " + gantt.templates.tooltip_date_format(start) +
            "<br/><b>End date:</b> " + gantt.templates.tooltip_date_format(end) +
            "<br/><b>Status:</b>" + task.custom.status +
            "<br/><b>Next Templates:</b>" + task.custom.templateids +
            "<br/><b>Jobs:</b>" + showMessageInfo(task.custom.jobids.split(','));
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

    function showMessageInfo(arr) {
        var str = ''
        arr.forEach(function (item, index) {
            if ((index + 1) % 5 == 0) {
                str = str.substring(0, str.length - 1) + "<br/>"
            }
            str += item + ','
        })
        return str.substring(0, str.length - 1)
    }

    gantt.templates.task_text = function (start, end, task) {
        var length = task.text.length
        if (length >= 22) {
            return task.text.substring(0, length - 13) + "..."
        }
        return task.text;
    };
    gantt.attachEvent("onLinkDblClick", function (id, e) {
        return false;
    });

    gantt.templates.link_class = function () {
        return "gantt_line_shadow";
    }
    gantt.message({
        text: "<p>Group/Status Colors:</p>" +
            "<table class='tips'>" +
            "<thead>" +
            "<tr><th>Group</th><th>Color</th>" +
            "</thead>" +
            "<tbody>" +
            "<tr><td>Int</td><td class='gantt-group-int tag'></td>" +
            "<tr><td>Prod</td><td  class='gantt-group-prod tag'></td>" +
            "<tr><td>AlwaysProd</td><td class='gantt-group-alwaysprod tag'></td>" +
            "<tr><td>Dr</td><td class='gantt-group-dr tag'></td>" +
            "<tr><td>Not In Group</td><td class='gantt-not-in-group tag'></td>" +
            "</tbody>" +
            "<thead>" +
            "<tr><th>Status</th><th>Color</th>" +
            "</thead>" +
            "<tbody>" +
            "<tr><td>Has Jobs</td><td class='gantt-hasjobs tag'></td>" +
            "<tr><td>No Jobs</td><td  class='gantt-nojobs tag'></td>" +
            "</table>",
        expire: -1
    })
    messageIds = []
    gantt.attachEvent("onTaskClick", function (id) {
        // set task's links' style
        setTaskLinks(id)

        if (messageIds) {
            messageIds.forEach(function (item, index) {
                gantt.message.hide(item)
            })
        }
        var selectedTask = gantt.getTask(id)
        relatedTasks = (selectedTask.custom.jobs || [])
        if (relatedTasks) {
            messageIds = relatedTasks.map(x => x.id)
            relatedTasks.forEach(element => {
                gantt.message({
                    id: element.id,
                    type: element.status.toLowerCase(),// for gantt-'xxx' class
                    text: "<b>Job Id: </b>" + element.id +
                        "<br/><b>Name: </b>" + element.text +
                        "<br/><b>Start date: </b>" + element.start_date +
                        "<br/><b>Status: </b>" + element.status.toLowerCase() +
                        "<br/><b>SelectedServerList: </b>" + element.selectedServerList,
                    expire: -1
                });
            });
        }
    })
}());