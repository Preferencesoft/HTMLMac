Function Latex2Png {
Param(
  [string]$equation,
  [string]$pngFile
)

$pdftopng="C:\texlive\2015\bin\win32\pdftopng.exe "
$pdftex="C:\texlive\2015\bin\win32\pdflatex.exe "
$pdfcrop="C:\texlive\2015\bin\win32\pdfcrop.exe "
$pngFileName=[System.IO.Path]::GetFileNameWithoutExtension($pngFile)
$texfile = $pngFileName+".tex"
$logfile = $pngFileName+".log"
$auxfile = $pngFileName+".aux"
$pdffile = $pngFileName+".pdf"
$pdfcropfile = $pngFileName+"-crop.pdf"
$pngroot=$pngFileName
$template=@"
\documentclass[12pt]{article}
\pagestyle{empty}
\begin{document}
eqn
\end{document}
"@
$s=$template -replace "eqn", $equation
Out-File $texfile -inputobject $s -encoding ASCII;
invoke-expression $pdftex$texfile;
invoke-expression $pdfcrop$pdffile;
invoke-expression $pdftopng$pdfcropfile" "$pngroot
if (Test-Path -Path $texfile) {
  del $texfile
}
if (Test-Path -Path $logfile) {
 del $logfile
}
if (Test-Path -Path $auxfile) {
 del $auxfile
}
if (Test-Path -Path $pdffile) {
 del $pdffile
}
if (Test-Path -Path $pdfcropfile) {
 del $pdfcropfile
}
if (Test-Path -Path $pngroot"-000001.png") {
 copy $pngroot"-000001.png" $pngFile
 del $pngroot"-000001.png"
}
}

Function LaTex([string]$equation)
{
	$strCounter = (++$Global:eqnCounter).ToString()
	$strCounter="0000000".Remove(6-$strCounter.length)+$strCounter
	$fileName = ([System.IO.Path]::GetFileNameWithoutExtension($Global:currentFile)) -replace "\-", ""
    $fileName = $Global:png_dir + $fileName + $strCounter + ".png"
    Latex2Png $equation $fileName
    $h = "<img src=`"{0}`" alt=`"`" />" -f $fileName
    $Global:result += $h
}

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


Function PygmentizeFile([string]$file, [Parameter(Mandatory=$False)][string]$lexer)
{
    $tmp = New-TemporaryFile
	if ([string]::IsNullOrEmpty($lexer)) {
		C:\Python\Python36-32\Scripts\pygmentize.exe -f html -o $tmp $file		
	} else {
		C:\Python\Python36-32\Scripts\pygmentize.exe -l $lexer -f html -o $tmp $file
	}
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
    $Global:code = ""
    $Global:eqnCounter = 0
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
    #$script >> ".\toto.txt"
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

$Global:htm_dir="./"
$Global:png_dir="./Images/"
$Global:encoding = "UTF8"
$files = get-childitem $htm_dir | where {$_.extension -eq ".aspx"}
foreach ($Global:currentFile in $files)
{
    $c=(Get-Content $Global:currentFile) -join "`r`n"
    $c=ReduceMacros $c
    $c=ExpandMacros $c
    if ($Global:err -ne "") {
        echo $Global:err
    }
    Out-File $Global:currentFile -inputobject $c -encoding $Global:encoding;
}