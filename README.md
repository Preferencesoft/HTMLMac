HTMLMac

***HTMLMac*** is a *PowerShell* script which allows to create static *PowerShell* macros in an *HTML* page, ...

When coding in *HTML*, some tasks like including another *HTML* file in the page, create a table, a *LaTex* equation etc. can be tedious. 
There are of course solutions like dynamically creating inclusions, code conversions, etc. on the server side.

But this solution will statically generate code in the same *HTML* page. This script makes possible executing *PowerShell* statements, placed in the comments of the page.

In the *HTML* or *ASPX* page, let's place the following comment:

    <!--PS WriteLine "<p>Hello World</p>"-->
    
After executing the script, the content of the page will change and immediately after the comment, new *HTML* code will appear:

    <!--PS WriteLine "<p>Hello World</p>"--><!--+Begin+--><p>Hello World</p><!--+End+-->
    
Here is another example in which a PS is placed at the end of the comment so that the code generated in the next line and not on the same.

    <!--PS WriteLine "<p>Hello World</p>"PS-->
    
After executing the script:

    <!--PS WriteLine "<p>Hello World</p>"PS-->
    <!--+Begin+--><p>Hello World</p><!--+End+-->

This is to make the generated code more readable when it does not need to be placed inline. The interest of the begin and end comments before and after the generated code is to be able to easily update this code if the macros comments are modified.

## Recommendations

* Make sure that your *HTML* or *ASPX* pages have a *UTF8* encoding with Windows line terminators (crLR)
* Avoid start or end comments errors. The script is still in beta and it uses regular expressions for the analysis of the comments.

## Additional PowerShell commands

The following commands have been specially created to include text, the contents of a file, ...
* WriteHTML "text"
* WriteLineHTML "text" (add a CR at the end)
* Include "path_of_a_file"
* Pygmentize "lexer" "code_to_pygmentize"
* PygmentizeFile "path_of_a_file"

These last two commands assume that you have installed Python and Pygment on your computer and changed the path directly in the script.

## To do

* <del>I intend to add commands to insert mathematical formulas,</del> in the file **HTMLMacLatex.ps1**
* better detect any errors, 
* allow to add customized functions,
* write another script modifying only the given file or only the files specified in other file.
