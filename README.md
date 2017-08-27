 HTMLMac
Script in PowerShell which allows to create static PowerShell macros in an HTML page, ...

When coding in HTML, some tasks like including another HTML file in the page, create a table, a LaTex equation etc. can be tedious.
There are of course solutions like dynamically creating inclusions, code conversions, etc. on the server side.

But this solution will statically generate code in the same HTML page. This script makes possible executing PowerShell statements, placed in the comments of the page.

In the HTML or ASPX page, let's place the following comment:

    <!--PS WriteLine "<p>Hello World</p>"-->
    
After executing the script, the content of the page will change and immediately after the comment, new HTML code will appear:

    <!--PS WriteLine "<p>Hello World</p>"--><!--+Begin+--><p>Hello World</p><!--+End+-->
    
