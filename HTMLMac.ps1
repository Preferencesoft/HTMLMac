Function WriteHTML([string]$text)
{
    $Global:result += $text
}

Function WriteLineHTML([string]$text)
{
    $Global:result += ("{0}`r`n" -f $text)
}

Function IncludeCR([string]$file)
{
    $c=("{0}`r`n" -f ((Get-Content $file) -join "`r`n"))
    $Global:result += $c
}

Function Include([string]$file)
{
    $c=((Get-Content $file) -join "`r`n")
    $Global:result += $c
}

Function IncludeUTF8([string]$file)
{
    $tmp = New-TemporaryFile
    $c=((Get-Content $file) -join "`r`n")
    Out-File $tmp -inputobject $c -encoding Unicode
    $c=("{0}`r`n" -f ((Get-Content $file) -join "`r`n"))
    del $tmp
    $Global:result += $c
}


Function PygmentizeFile([string]$file)
{
    $tmp = New-TemporaryFile
    C:\Python\Python36-32\Scripts\pygmentize.exe -f html -o $tmp $file
    $c = (Get-Content $tmp.FullName) -join "`r`n"
    del $tmp.FullName
    $Global:result += $c
}

Function Pygmentize([string]$lexer, [string]$text)
{
    $tmp1 = New-TemporaryFile
    $tmp2 = New-TemporaryFile
    Out-File $tmp1 -inputobject $text -encoding UTF8;
    C:\Python\Python36-32\Scripts\pygmentize.exe -l $lexer -f html -o $tmp2 $tmp1
    $c = (Get-Content $tmp2.FullName) -join "`r`n"
    del $tmp1.FullName
    del $tmp2.FullName
    $Global:result += $c
}

Function ExpandMacros([string]$text)
{
    $Global:num = 0
    $Global:err = ""
    $c= [regex]::Replace($text,"<!\-\-PS(.*?)(PS|)\-\->", {
    param($word)
    $Global:num++
    $Global:code += "try {"
    $Global:code += "`$Global:result=`"`";`r`n"
    $Global:code += $word.Groups[1].Value 
    $Global:code += "`r`n"
    $Global:code +="`$Global:ResultList.Add(`$Global:result) | Out-Null;`r`n"
    $Global:code += "}`r`ncatch {`$Global:err = `$error[0].Exception.GetType().FullName;}"
    if ($word.Groups[2].Value -ne "PS") {
        "<!--PS{0}--><!--+Begin+-->{1}<!--+End+-->" -f $word.Groups[1].Value, $Global:num
    } else {
        "<!--PS{0}PS-->`r`n<!--+Begin+-->{1}<!--+End+-->" -f $word.Groups[1].Value, $Global:num
    }
    }, "SingleLine")
    $Global:ResultList = [System.Collections.ArrayList]@()
    $script = $ExecutionContext.InvokeCommand.NewScriptBlock($Global:code)
    & $script | Out-Null
    $Global:num = 0
    $c= [regex]::Replace($c,"<!\-\-\+Begin\+\-\->(.*?)<!\-\-\+End\+\-\->", {
    param($word)
    "<!--+Begin+-->{0}<!--+End+-->" -f ($Global:ResultList[$Global:num++])
    }, "SingleLine")
    if ($Global:err -ne "") {
        return $text
    } else {
        return $c
    }
}

Function ReduceMacros([string]$text)
{
    $c= [regex]::Replace($text,"\r\n<!\-\-\+Begin\+\-\->(.*?)<!\-\-\+End\+\-\->", {
    param($word)
    ""
    }, "SingleLine")
    $c= [regex]::Replace($c,"<!\-\-\+Begin\+\-\->(.*?)<!\-\-\+End\+\-\->", {
    param($word)
    ""
    }, "SingleLine")
    return $c
}

$htm_dir="./"
$Global:encoding = "UTF8"
$files = get-childitem $htm_dir | where {$_.extension -eq ".aspx"}
foreach ($file in $files)
{
    $c=(Get-Content $file) -join "`r`n"
    $c=ReduceMacros $c
    $Global:code = ""
    $c=ExpandMacros $c
    if ($Global:err -ne "") {
        echo $Global:err
    }
    Out-File $file -inputobject $c -encoding $Global:encoding;
}