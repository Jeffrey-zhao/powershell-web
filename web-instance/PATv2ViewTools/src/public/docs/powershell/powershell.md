How to add powershell in scripts folder

1. add comments for script and function
    > SYNTAX FOR COMMENT-BASED HELP IN FUNCTIONS
      Comment-based help for a function can appear in one of three locations:

        > At the beginning of the function body.
        > At the end of the function body.
        > Before the Function keyword. There cannot be more than one blank line between the last line of the function help and the Function keyword.
    > SYNTAX FOR COMMENT-BASED HELP IN SCRIPTS
        Comment-based help for a script can appear in one of the following two locations in the script.

        > At the beginning of the script file. Script help can be preceded in the script only by comments and blank lines.

        > If the first item in the script body (after the help) is a function declaration, there must be at least two blank lines between the end of the script help and the function declaration. Otherwise,the help is interpreted as being help for the function, not help for the script.

        > At the end of the script file. However, if the script is signed, place Comment-based help at the beginning of the script file. The end of the script is occupied by the signature block.
    > if you want to get more details about how to add comments for script and function ,please click it: <a href='https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-6'> comment to script </a>

2. make all function parameters have [parameter] attribute ,also [type] like '[string]',[int],[datetime]
   now it includes type:
   >int / int[]
   >single / single[]
   >double / double[]
   >bool 
   >switch
   >string / string[]
   >object
   > if parameter is input[type=file] ,so add this attribute [alias('FilePath_xxx')],it means if add it,the portal will render to input [type=file],it satisfied regex('^FilePath_.+')
   > if parameter is enum like('Mon','Tue','Wen') ,so please add this attribute [validateSet('Mon','Tue','Wen')];it means it will render to select-option
3. function supports format like this below:
    > function function-name
        {
            [parameter()]
            [string] $parameter1,

            [parameter()]
            [string] $parameter2,
        }
    but not support it below:
    > function function-name([string] $parameter1,[string] $parameter2)
    {}
    >NOTE THAT :if you want to comment some codes ,please use '<##>',not use '#' ,it is good to use 'mulitply lines comment',if there are several functions , single line comment '#' will make funciton where after it not visible.
    
4. how to get comments from script for script and function
    get-help -name /path/to/script.ps1 -detailed  # for script comment
    get-help -name function-name -detailed  # for function but you should import it first

