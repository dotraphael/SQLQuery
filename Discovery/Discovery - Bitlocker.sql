declare @CollectionID varchar(8)
DECLARE @Now DateTime = GetDate()
set @CollectionID = 'P010002E'

	select distinct 
	rsy.ResourceID,
	rsy.Name0 as 'Device HostName',
	case rsy.Client0
		when 1 then 'Enabled'
		else 'Disabled'
	end as 'SCCM Managed',
	case 
		when chc.IsActiveHW is null then 'Disabled'
		when chc.IsActiveHW = 0 then 'Disabled'
		when chc.IsActiveHW = 1 then 'Enabled'
	end as 'Active Inventory',
	case
		when DATEDIFF(dd, chc.LastHW, @Now) <= 7 then 'in the last 7 days'
		when DATEDIFF(dd, chc.LastHW, @Now) between 8 and 30 then 'in the last 30 days'
		when DATEDIFF(dd, chc.LastHW, @Now) between 31 and 90 then 'in the last 90 days'
		when DATEDIFF(dd, chc.LastHW, @Now) > 90 then 'Over 90 days'
		else 'Never'
	end as LastInventory,
	
	--Bitlocker
	IsNull(bl.DriveLetter0,'') as DriveLetter,
	case 
		when bl.Compliant0 is null then 'Disabled'
		when bl.Compliant0 = 0 then 'Disabled'
		when bl.Compliant0 = 1 then 'Enabled'
	end as 'BitLocker Compliant',
	--IsNull(bl.EncryptionMethod0,'') as EncryptionMethod, --https://docs.microsoft.com/en-us/windows/win32/secprov/getencryptionmethod-win32-encryptablevolume
	case 
		when bl.EncryptionMethod0 is null then 'None'
		when bl.EncryptionMethod0 = 0 then 'None'
		when bl.EncryptionMethod0 = 1 then 'AES_128_WITH_DIFFUSER'
		when bl.EncryptionMethod0 = 2 then 'AES_256_WITH_DIFFUSER'
		when bl.EncryptionMethod0 = 3 then 'AES_128'
		when bl.EncryptionMethod0 = 4 then 'AES_256'
		when bl.EncryptionMethod0 = 5 then 'HARDWARE_ENCRYPTION'
		when bl.EncryptionMethod0 = 6 then 'XTS_AES_128'
		when bl.EncryptionMethod0 = 7 then 'XTS_AES_256'
		when bl.EncryptionMethod0 = -1 then 'UNKNOWN'
	end as 'EncryptionMethod',
	--IsNull(bl.ConversionStatus0,'') as ConversionStatus, --https://docs.microsoft.com/en-us/windows/win32/secprov/getconversionstatus-win32-encryptablevolume
	case 
		when bl.ConversionStatus0 is null then ''
		when bl.ConversionStatus0 = 0 then 'FullyDecrypted'
		when bl.ConversionStatus0 = 1 then 'FullyEncrypted'
		when bl.ConversionStatus0 = 2 then 'EncryptionInProgress'
		when bl.ConversionStatus0 = 3 then 'DecryptionInProgress'
		when bl.ConversionStatus0 = 4 then 'EncryptionPaused'
		when bl.ConversionStatus0 = 5 then 'DecryptionPaused'
	end as 'ConversionStatus',

	--IsNull(bl.BitlockerPersistentVolumeId0,'') as BitlockerPersistentVolumeId,
	--IsNull(bl.DeviceId0,'') as DeviceId,
	IsNull(bl.EnforcePolicyDate0,'') as EnforcePolicyDate,
	case 
		when bl.IsAutoUnlockEnabled0 is null then ''
		when bl.IsAutoUnlockEnabled0 = 0 then 'Disabled'
		when bl.IsAutoUnlockEnabled0 = 1 then 'Enabled'
	end as 'IsAutoUnlockEnabled',
	IsNull(bl.KeyProtectorTypes0,'') as KeyProtectorTypes, --https://docs.microsoft.com/en-us/windows/win32/secprov/getkeyprotectortype-win32-encryptablevolume
	/*
	case 
		when bl_01.Value is null then ''
		when bl_01.Value = 0 then 'Unknown'
		when bl_01.Value = 1 then 'Trusted Platform Module (TPM)'
		when bl_01.Value = 2 then 'External key'
		when bl_01.Value = 3 then 'Numerical password'
		when bl_01.Value = 4 then 'TPM And PIN'
		when bl_01.Value = 5 then 'TPM And Startup Key'
		when bl_01.Value = 6 then 'TPM And PIN And Startup Key'
		when bl_01.Value = 7 then 'Public Key'
		when bl_01.Value = 8 then 'Passphrase'
		when bl_01.Value = 9 then 'TPM Certificate'
		when bl_01.Value = 10 then 'CryptoAPI Next Generation (CNG) Protector'
	end as 'KeyProtectorType',
	*/

	--IsNull(bl.MbamPersistentVolumeId0,'') as MbamPersistentVolumeId,
	--IsNull(bl.MbamVolumeType0,'') as MbamVolumeType,
	IsNull(bl.NoncomplianceDetectedDate0,'') as NoncomplianceDetectedDate,
	case 
		when bl.ProtectionStatus0 is null then 'Disabled'
		when bl.ProtectionStatus0 = 0 then 'Disabled'
		when bl.ProtectionStatus0 = 1 then 'Enabled'
	end as 'ProtectionStatus',
	IsNull(bl.ReasonsForNonCompliance0,'') as ReasonsForNonCompliance--, --https://docs.microsoft.com/en-us/microsoft-desktop-optimization-pack/mbam-v25/determining-why-a-device-receives-a-noncompliance-message
	/*
0 - Cipher strength not AES 256.
1 - MBAM Policy requires this volume to be encrypted but it is not.
2 - MBAM Policy requires this volume to NOT be encrypted, but it is.
3 - MBAM Policy requires this volume use a TPM protector, but it does not.
4 - MBAM Policy requires this volume use a TPM+PIN protector, but it does not.
5 - MBAM Policy does not allow non TPM machines to report as compliant.
6 - Volume has a TPM protector but the TPM is not visible (booted with recover key after disabling TPM in BIOS?).
7 - MBAM Policy requires this volume use a password protector, but it does not have one.
8 - MBAM Policy requires this volume NOT use a password protector, but it has one.
9 - MBAM Policy requires this volume use an auto-unlock protector, but it does not have one.
10 - MBAM Policy requires this volume NOT use an auto-unlock protector, but it has one.
11 - Policy conflict detected preventing MBAM from reporting this volume as compliant.
12 - A system volume is needed to encrypt the OS volume but it is not present.
13 - Protection is suspended for the volume.
14 - AutoUnlock unsafe unless the OS volume is encrypted.
15 - Policy requires minimum cypher strength is XTS-AES-128 bit, actual cypher strength is weaker than that.
16 - Policy requires minimum cypher strength is XTS-AES-256 bit, actual cypher strength is weaker than that.
	*/
	
	from fn_RBAC_R_System('disabled') rsy 
	inner join fn_rbac_FullCollectionMembership('disabled') fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	left join fn_rbac_GS_OPERATING_SYSTEM('disabled') os on os.ResourceID = rsy.ResourceID
	left join fn_RBAC_CH_ClientSummary('disabled') chc on chc.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_BITLOCKER_DETAILS('disabled') bl on bl.ResourceID = rsy.ResourceID
	--	OUTER APPLY STRING_SPLIT(bl.KeyProtectorTypes0,',') bl_01
order by 1
