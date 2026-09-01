param(
  [string]$FfmpegPath = "$PSScriptRoot/../.media-tools/node_modules/ffmpeg-static/ffmpeg.exe"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $FfmpegPath)) {
  throw "FFmpeg was not found at '$FfmpegPath'. Install the local media tools first."
}

$projectRoot = Resolve-Path "$PSScriptRoot/.."
$outputDir = Join-Path $projectRoot "assets/media"
$posterDir = Join-Path $projectRoot "assets/media/posters"
$workDir = Join-Path $projectRoot ".media-tools/work"
New-Item -ItemType Directory -Force $outputDir, $posterDir, $workDir | Out-Null

$jobs = @(
  @{
    Input = "1customsearch.mp4"
    Output = "custom-search.mp4"
    Poster = "custom-search.jpg"
    InitialSpeed = 2.4
    FinalSpeed = 1.6
    Segments = @(@(0.0, 11.6), @(13.0, 45.7), @(49.0, 65.7), @(89.0, 97.5), @(101.0, 122.2))
    CleanupSegments = @(@(0.0, 18.4), @(19.25, 20.65), @(21.05, 25.4), @(25.75, 26.9), @(27.75, 29.0), @(29.25, 37.9))
    PolishSegments = @(@(0.0, 2.9), @(3.5, 11.85), @(12.15, 12.6), @(12.9, 14.85), @(15.55, 15.85), @(16.45, 22.1))
  },
  @{
    Input = "1b-select_distance.mp4"
    Output = "distance-search.mp4"
    Poster = "distance-search.jpg"
    InitialSpeed = 2.2
    FinalSpeed = 1.45
    Segments = @(@(0.0, 17.5), @(68.0, 106.5))
    CleanupSegments = @(@(0.0, 7.65), @(8.0, 23.65), @(24.0, 25.55))
    PolishSegments = @(@(0.0, 4.9), @(5.5, 17.25))
  },
  @{
    Input = "2-browse properties.mp4"
    Output = "browse-properties.mp4"
    Poster = "browse-properties.jpg"
    InitialSpeed = 2.25
    FinalSpeed = 1.5
    Segments = @(@(0.0, 19.2), @(20.8, 23.5), @(25.0, 26.5), @(29.0, 31.5), @(33.0, 76.0))
    CleanupSegments = @(@(0.0, 6.6), @(17.15, 30.75))
    PolishSegments = @(,@(0.0, 9.95))
  },
  @{
    Input = "3-exploreneighbourhood-and-amenities.mp4"
    Output = "explore-context.mp4"
    Poster = "explore-context.jpg"
    InitialSpeed = 2.6
    FinalSpeed = 1.5
    Segments = @(@(0.0, 6.5), @(11.0, 30.0), @(53.0, 59.5), @(61.0, 97.5), @(100.0, 113.2), @(119.0, 129.5), @(131.0, 164.5), @(166.0, 173.0))
    CleanupSegments = @(@(0.0, 2.15), @(2.7, 31.9), @(34.9, 51.15))
    PolishSegments = @(@(0.0, 10.65), @(11.0, 16.15))
  },
  @{
    Input = "generate-property-report.mp4"
    Output = "property-report.mp4"
    Poster = "property-report.jpg"
    InitialSpeed = 2.0
    FinalSpeed = 1.45
    Segments = @(@(0.0, 3.0), @(41.0, 91.0), @(93.2, 95.7))
    CleanupSegments = @(@(0.0, 6.9), @(7.25, 9.65), @(10.0, 27.85))
    PolishSegments = @(,@(1.25, 18.25))
  },
  @{
    Input = "generate-area-report.mp4"
    Output = "area-snapshot.mp4"
    Poster = "area-snapshot.jpg"
    InitialSpeed = 2.0
    FinalSpeed = 1.45
    Segments = @(@(0.0, 2.0), @(119.0, 168.0))
    CleanupSegments = @(@(0.0, 0.95), @(1.75, 25.6))
    PolishSegments = @(@(0.75, 7.25), @(7.55, 10.65), @(10.9, 15.25), @(15.55, 17.0))
  }
)

foreach ($job in $jobs) {
  $inputPath = Join-Path $projectRoot $job.Input
  $outputPath = Join-Path $outputDir $job.Output
  $posterPath = Join-Path $posterDir $job.Poster
  $intermediatePath = Join-Path $workDir ("initial-" + $job.Output)
  $cleanedPath = Join-Path $workDir ("cleaned-" + $job.Output)

  if (-not (Test-Path -LiteralPath $inputPath)) {
    throw "Source recording was not found: '$inputPath'"
  }

  $filterParts = @()
  $segmentLabels = @()

  for ($index = 0; $index -lt $job.Segments.Count; $index++) {
    $start = $job.Segments[$index][0]
    $end = $job.Segments[$index][1]
    $label = "s$index"
    $filterParts += "[0:v]trim=start=$start`:end=$end,setpts=PTS-STARTPTS,scale=1280:-2:flags=lanczos,fps=20[$label]"
    $segmentLabels += "[$label]"
  }

  $filterParts += "$($segmentLabels -join '')concat=n=$($job.Segments.Count):v=1:a=0,setpts=PTS/$($job.InitialSpeed),format=yuv420p[v]"
  $filter = $filterParts -join ";"

  & $FfmpegPath -hide_banner -loglevel warning -y -i $inputPath `
    -filter_complex $filter -map "[v]" -an `
    -c:v libx264 -preset medium -crf 26 -profile:v high -level 4.1 `
    -movflags +faststart $intermediatePath

  if ($LASTEXITCODE -ne 0) {
    throw "FFmpeg failed while processing '$($job.Input)'."
  }

  $cleanupFilterParts = @()
  $cleanupLabels = @()

  for ($index = 0; $index -lt $job.CleanupSegments.Count; $index++) {
    $start = $job.CleanupSegments[$index][0]
    $end = $job.CleanupSegments[$index][1]
    $label = "c$index"
    $cleanupFilterParts += "[0:v]trim=start=$start`:end=$end,setpts=PTS-STARTPTS[$label]"
    $cleanupLabels += "[$label]"
  }

  $cleanupFilterParts += "$($cleanupLabels -join '')concat=n=$($job.CleanupSegments.Count):v=1:a=0,setpts=PTS/$($job.FinalSpeed),format=yuv420p[v]"
  $cleanupFilter = $cleanupFilterParts -join ";"

  & $FfmpegPath -hide_banner -loglevel warning -y -i $intermediatePath `
    -filter_complex $cleanupFilter -map "[v]" -an `
    -c:v libx264 -preset medium -crf 26 -profile:v high -level 4.1 `
    -movflags +faststart $cleanedPath

  if ($LASTEXITCODE -ne 0) {
    throw "FFmpeg failed during final cleanup of '$($job.Input)'."
  }

  $polishFilterParts = @()
  $polishLabels = @()

  for ($index = 0; $index -lt $job.PolishSegments.Count; $index++) {
    $start = $job.PolishSegments[$index][0]
    $end = $job.PolishSegments[$index][1]
    $label = "p$index"
    $polishFilterParts += "[0:v]trim=start=$start`:end=$end,setpts=PTS-STARTPTS[$label]"
    $polishLabels += "[$label]"
  }

  $polishFilterParts += "$($polishLabels -join '')concat=n=$($job.PolishSegments.Count):v=1:a=0,format=yuv420p[v]"
  $polishFilter = $polishFilterParts -join ";"

  & $FfmpegPath -hide_banner -loglevel warning -y -i $cleanedPath `
    -filter_complex $polishFilter -map "[v]" -an `
    -c:v libx264 -preset medium -crf 26 -profile:v high -level 4.1 `
    -movflags +faststart $outputPath

  if ($LASTEXITCODE -ne 0) {
    throw "FFmpeg failed during polish of '$($job.Input)'."
  }

  & $FfmpegPath -hide_banner -loglevel warning -y -ss 0.35 -i $outputPath `
    -frames:v 1 -update 1 -q:v 3 $posterPath

  if ($LASTEXITCODE -ne 0) {
    throw "FFmpeg failed while creating the poster for '$($job.Input)'."
  }
}

Write-Host "Created $($jobs.Count) optimized demo loops in '$outputDir'."
