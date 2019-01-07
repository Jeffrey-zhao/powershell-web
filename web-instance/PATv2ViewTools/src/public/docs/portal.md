How to use this tool
> Introduction
    this is some descriptions about this tool
> Scripts
    1. List page
        > list all files and folders in 'CmdLets/Scripts'
        > if its type is file ,it shows 'File' in a 'Type' column of List table ,anthor type is 'Directory' that means 'Folder'
        > Column 'Read File' is checked, you can read this file content ,if not a file ,it is disabled
        > also clicking a cell of Column 'Name' will navigate to 'Function' page when 'Type' is file ,if not ,it will enter this folder on 'List' page
        > Column 'Relative Path' tells its full name and extensive
        > Note that: the key words 'List','Function','Command' is a link to different pages

    2. Function page
        > 'Function' page lists all functions in this script
        >  clicking a cell of Column 'Function Name',it iwll navigate to 'Command' page
        >  clicking label 'detail' to get function comment-help in Column 'Function Detail'
        >  clicking button 'Script Detail' to get script comment-help below or above the table 
        > in the section 'Detail' you can get all comment-help

    3. Command page
        > the page has three parts,including 'Command','Detail','Execute Output'
        > in 'Command' section: there are several paramerter set names which the function has,
          click different tabs and get different parameters list
            > parameter list: every parameter has name,type and required-input ,for an instance 'ServerPath (String)-(Mandatory)', if it is required to input, the input style is 'red' when not input or input error,the color 'green' means this field is ok
            > The most important is that keeps all parameters blacketing with single quotation marks if parameters have space
            > Button 'Send' will send your command with parameters to execute and its output or results will return in 'Execute Output' section
        > in 'Execute Output' section: it will show a command exectuing results or outputs
        > in 'Detail' section: it shows the command's comment help

> Gantts
  >Jog page
    it displays job's dependencies in a service
  >Template page
    > it  displa template's dependencies if include jobs in a service
    > the line bar is black that means it has no jobs ,if light blue,it has jobs
    > also these template could be grouped by several parts like 'Int','Prod','AlwaysProd','Dr'