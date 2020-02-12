$buildFile = "$PSScriptRoot\meta\moduleversion.buildnumber"

if (! (Test-Path $buildFile -PathType Leaf)) {
    "0" > $buildFile
}

$build = cat $buildFile
$build = [int]::Parse($build)
$build++
"0.1.{0}.{1:yyyyMMdd}" -f $build, [datetime]::now
$build > $buildFile