$assetRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../audio/third_party'))
[xml]$projectAudio = Get-Content -LiteralPath (Join-Path $assetRoot 'creature_sounds/Sound FX.aup')
$clipIndex = 0
foreach ($track in $projectAudio.audacityproject.wavetrack) {
    $clipIndex++
    $block = $track.sequence.waveblock.simpleblockfile
    $bytes = [System.IO.File]::ReadAllBytes((Join-Path $assetRoot ('creature_sounds/Sound FX_data/' + $block.filename)))
    # Audacity 1.2 little-endian AU blocks: encoding 3 is signed 16-bit PCM.
    if ([System.BitConverter]::ToUInt32($bytes, 12) -ne 3) { throw 'Unexpected AU encoding' }
    $offset = [System.BitConverter]::ToInt32($bytes, 4)
    $count = [int]$block.len
    $pcm = New-Object byte[] ($count * 2)
    [Array]::Copy($bytes, $offset, $pcm, 0, $pcm.Length)
    $destination = Join-Path $assetRoot ('creature_{0:00}.wav' -f $clipIndex)
    $writer = [System.IO.BinaryWriter]::new([System.IO.File]::Create($destination))
    try {
        $writer.Write([System.Text.Encoding]::ASCII.GetBytes('RIFF'))
        $writer.Write([int](36 + $pcm.Length))
        $writer.Write([System.Text.Encoding]::ASCII.GetBytes('WAVEfmt '))
        $writer.Write([int]16)
        $writer.Write([int16]1)
        $writer.Write([int16]1)
        $writer.Write([int]44100)
        $writer.Write([int]88200)
        $writer.Write([int16]2)
        $writer.Write([int16]16)
        $writer.Write([System.Text.Encoding]::ASCII.GetBytes('data'))
        $writer.Write([int]$pcm.Length)
        $writer.Write($pcm)
    } finally { $writer.Dispose() }
    Write-Output ('Exported creature_{0:00}.wav: {1:0.00}s' -f $clipIndex, ($count / 44100.0))
}
