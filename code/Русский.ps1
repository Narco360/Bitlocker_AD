<# Полностью переведено на русский. Если заметите ошибки, пожалуйста, сообщите мне. #>

<#
.SYNOPSIS
Передача (резервное копирование) существующих ключей защиты Bitlocker в Azure AD (Intune)

.DESCRIPTION
Этот сценарий проверяет наличие существующих ключей восстановления и осуществляет передачу (резервное копирование) их в Azure AD.
Отлично подходит для перехода от MBAM на стороне клиента к использованию Intune и Azure AD для управления ключами Bitlocker.

.INPUTS
Нет

.NOTES
Версия : 1.0
Автор : Michael Mardahl
Twitter : @michael_mardahl
Блог : www.msendpointmgr.com
Дата создания: 11 января 2021 года
Цель/Изменение: Исходный сценарий
Лицензия : MIT (оставьте авторские права)
Перевод : NetcO https://github.com/Narco360

.EXAMPLE
Выполните сценарий от имени системы или администратора
.\Invoke-EscrowBitlockerToAAD.ps1

.NOTES
Если возникает несоответствие политики, вы можете получать ошибки от встроенной командлеты BackupToAAD-BitLockerKeyProtector.
Поэтому я обернул командлет в блок try/catch, чтобы подавить ошибку. Это означает, что вам придется вручную проверить, был ли ключ фактически передан.
Посетите MSEndpointMgr.com, чтобы найти решения для получения статистики отчетности по этому вопросу.

#>

#region declarations

$DriveLetter = $env:SystemDrive

#endregion declarations

#region functions

function Test-Bitlocker ($BitlockerDrive) {
# Проверяет, включен ли BitLocker на указанном диске
try {
Get-BitLockerVolume -MountPoint $BitlockerDrive -ErrorAction Stop
} catch {
Write-Output "BitLocker не найден на диске $BitlockerDrive. Завершение сценария!"
exit 0
}
}

function Get-KeyProtectorId ($BitlockerDrive) {
# Получает идентификатор ключа защитника диска
$BitLockerVolume = Get-BitLockerVolume -MountPoint $BitlockerDrive
$KeyProtector = $BitLockerVolume.KeyProtector | Where-Object { $_.KeyProtectorType -eq 'RecoveryPassword' }
return $KeyProtector.KeyProtectorId
}

function Invoke-BitlockerEscrow ($BitlockerDrive,$BitlockerKey) {
# Сохраняет ключ в Azure AD
try {
BackupToAAD-BitLockerKeyProtector -MountPoint $BitlockerDrive -KeyProtectorId $BitlockerKey -ErrorAction SilentlyContinue
Write-Output "Попытка сохранения ключа в Azure AD - Пожалуйста, проверьте вручную!"
exit 0

} catch 
{
Write-Error "Это никогда не должно происходить. Отладьте меня!"
exit 1
}
}

#endregion functions

#region execute

Test-Bitlocker -BitlockerDrive $DriveLetter
$KeyProtectorId = Get-KeyProtectorId -BitlockerDrive $DriveLetter
Invoke-BitlockerEscrow -BitlockerDrive $DriveLetter -BitlockerKey $KeyProtectorId

#endregion execute
