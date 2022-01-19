declare @Now DateTime = GetDate(), @CollectionID varchar(8)
declare @MinRam int, @MinFreeDiskSpace int, @MinDiskSize int, @MinCPUSpeed int, @MinCPUCore int, @MinTPMVersion varchar(8)
declare @RecRam int, @RecFreeDiskSpace int, @RecDiskSize int, @RecCPUSpeed int, @RecCPUCore int, @RecTPMVersion varchar(8)

--https://www.microsoft.com/en-gb/windows/windows-11-specifications
set @CollectionID = 'P010002E' --Main Collection
set @MinRam = 4
set @MinFreeDiskSpace = 64
set @MinDiskSize = 64
set @MinCPUSpeed = 1000
set @MinCPUCore = 2
set @MinTPMVersion = '2.0'

set @RecRam = 8
set @RecFreeDiskSpace = 65
set @RecDiskSize = 220
set @RecCPUSpeed = 4000
set @RecCPUCore = 4
set @RecTPMVersion = '2.0'

select 
	tblRaw.ResourceID,
	tblRaw.[Device HostName],
	tblRaw.PrimaryUsers,
	tblRaw.[Last Logged User],
	tblRaw.[Last Account (AD)],
	tblRaw.[Last Account (Inventory)],
	tblRaw.LastActiveTime,
	tblRaw.LastActiveTimeDescription,
	tblRaw.CurrentStatus,
	tblRaw.[SCCM Managed],
	tblRaw.[Active Inventory],
	tblRaw.LastInventory,
	tblRaw.[Operating System],
	tblRaw.[Operating System Version],
	tblRaw.[Operating System Edition],
	tblRaw.[Build Version],
	tblRaw.BuildNumberDescription,
	tblRaw.OSBranchName,
	tblRaw.State,
	tblRaw.[OS Architecture],
	tblRaw.Manufacturer,
	tblRaw.Model,
	tblRaw.[Physical Architecture],
	tblRaw.[Physical CPU],
	tblRaw.CPUName,
	tblRaw.[Physical CPU Architecture],
	tblRaw.[Processor Speed (Mhz)],
	tblRaw.NumberOfCores,
	tblRaw.NumberOfLogicalProcessors,
	tblRaw.[Memory (GB)],
	tblRaw.[Disk Size (GB)],
	tblRaw.[Free Space (GB)],
	tblRaw.BIOSManufacturer,
	tblRaw.[TPM Version(s)],
	tblRaw.[TPM Active],
	tblRaw.[TPM Enabled],
	tblRaw.[TPM Owned],
	tblRaw.TPMVersion1,
	tblRaw.TPMVersion2,
	tblRaw.TPMVersion3,
	tblraw.[Secure Boot],
	tblraw.UEFI,
	isnull(tblRaw.MinReadinessMemory, '') as MinReadinessMemory,
	isnull(tblRaw.MinReadinessDisk, '') as MinReadinessDisk,
	isnull(tblRaw.MinReadinessDiskSpace, '') as MinReadinessDiskSpace,
	isnull(tblRaw.MinReadinessCPUSpeed, '') as MinReadinessCPUSpeed,
	isnull(tblRaw.MinReadinessCPUCore, '') as MinReadinessCPUCore,
	isnull(tblRaw.MinReadinessCPUArchitecture, '') as MinReadinessCPUArchitecture,
	isnull(tblRaw.MinReadinessSecureBoot, '') as MinReadinessSecureBoot,
	isnull(tblRaw.MinReadinessEUFI, '') as MinReadinessEUFI,
	isnull(tblRaw.MinReadinessTPM, '') as MinReadinessTPM,
	isnull(tblRaw.RecReadinessMemory, '') as RecReadinessMemory,
	isnull(tblRaw.RecReadinessDisk, '') as RecReadinessDisk,
	isnull(tblRaw.RecReadinessSpace, '') as RecReadinessSpace,
	isnull(tblRaw.RecReadinessCPUSpeed, '') as RecReadinessCPUSpeed,
	isnull(tblRaw.RecReadinessCPUCore, '') as RecReadinessCPUCore,
	isnull(tblRaw.RecReadinessCPUArchitecture, '') as RecReadinessCPUArchitecture,
	isnull(tblRaw.RecReadinessSecureBoot, '') as RecReadinessSecureBoot,
	isnull(tblRaw.RecReadinessEUFI, '') as RecReadinessEUFI,
	isnull(tblRaw.RecReadinessTPM, '') as RecReadinessTPM,

	Isnull(trim(Stuff(Coalesce(', ' + tblRaw.MinReadinessMemory, '') + Coalesce(', ' + tblRaw.MinReadinessDisk, '') + Coalesce(', ' + tblRaw.MinReadinessDiskSpace, '') + Coalesce(', ' + tblRaw.MinReadinessCPUSpeed, '') + Coalesce(', ' + tblRaw.MinReadinessCPUCore, '') + Coalesce(', ' + tblRaw.MinReadinessCPUArchitecture, '') + Coalesce(', ' + tblRaw.MinReadinessSecureBoot, '') + Coalesce(', ' + tblRaw.MinReadinessEUFI, '') + Coalesce(', ' + tblRaw.MinReadinessTPM, '') , 1, 1, '')), 'Ready for Windows 11') AS [MinimumRequirements],
	Isnull(trim(Stuff(Coalesce(', ' + tblRaw.RecReadinessMemory, '') + Coalesce(', ' + tblRaw.RecReadinessDisk, '') + Coalesce(', ' + tblRaw.RecReadinessSpace, '') + Coalesce(', ' + tblRaw.RecReadinessCPUSpeed, '') + Coalesce(', ' + tblRaw.RecReadinessCPUCore, '') + Coalesce(', ' + tblRaw.RecReadinessCPUArchitecture, '') + Coalesce(', ' + tblRaw.RecReadinessSecureBoot, '') + Coalesce(', ' + tblRaw.RecReadinessEUFI, '') + Coalesce(', ' + tblRaw.RecReadinessTPM, '') , 1, 1, '')), 'Ready for Windows 11') AS [RecommendedRequirements]






from 
(
---Query
select distinct 
	rsy.ResourceID,
	rsy.Name0 as 'Device HostName',
	isnull(stuff((select ';'+umr.UniqueUserName from v_UserMachineRelation umr where umr.MachineResourceID = rsy.ResourceID FOR XML PATH('')), 1, 1, ''), '') as PrimaryUsers,
	isnull(scs.SystemConsoleUser0,'') as 'Last Logged User',
	isnull(rsy.User_Domain0 + '\' + rsy.User_Name0, '') as 'Last Account (AD)',
	isnull(cs.UserName0, '') as 'Last Account (Inventory)',
	chc.LastActiveTime,
	case
		when DATEDIFF(dd, chc.LastActiveTime, @Now) <= 1 then 'Today'
		when DATEDIFF(dd, chc.LastActiveTime, @Now) between 2 and 3 then 'in the last 3 days'
		when DATEDIFF(dd, chc.LastActiveTime, @Now) between 4 and 7 then 'in the last 7 days'
		when DATEDIFF(dd, chc.LastActiveTime, @Now) > 7 then 'Over 7 days'
		else 'Never'
	end as LastActiveTimeDescription,

	(
		select top 1 
		case cmcbs.CNIsOnline 
			when 1 then 'Online'
			else 'Offline'
		end as CurrentStatus	
		from 
			v_CollectionMemberClientBaselineStatus cmcbs 
		where 
			cmcbs.MachineID = rsy.resourceID 
		order by CNLastOfflineTime desc
	) as CurrentStatus,

	case rsy.Client0
		when 1 then 'Yes'
		else 'No'
	end as 'SCCM Managed',
	case 
		when chc.IsActiveHW is null then 'No'
		when chc.IsActiveHW = 0 then 'No'
		when chc.IsActiveHW = 1 then 'Yes'
	end as 'Active Inventory',
	case
		when DATEDIFF(dd, chc.LastHW, @Now) <= 7 then 'in the last 7 days'
		when DATEDIFF(dd, chc.LastHW, @Now) between 8 and 30 then 'in the last 30 days'
		when DATEDIFF(dd, chc.LastHW, @Now) between 31 and 90 then 'in the last 90 days'
		when DATEDIFF(dd, chc.LastHW, @Now) > 90 then 'Over 90 days'
		else 'Never'
	end as LastInventory,

	--Operating System
	IsNull(os.Caption0, rsy.Operating_System_Name_and0) as 'Operating System',
	case 
		when rsy.Operating_System_Name_and0 like '%10.%' then 'Windows 10'
		when os.Version0 like '10.%' then 'Windows 10'
		when os.Version0 like '6.1.%' then 'Windows 7'
		when os.Version0 like '6.2.%' then 'Windows 8'
		when os.Version0 like '6.3.%' then 'Windows 8.1'
		else 'Unknown'
	end as [Operating System Version],

	case os.OperatingSystemSKU0
		when 1 then 'Windows Ultimate'
		when 2 then 'Windows Home Basic'
		when 3 then 'Windows Home Premium'
		when 4 then 'Windows Enterprise'
		when 6 then 'Windows Business Edition'
		when 11 then 'Windows Starter Edition'
		when 27 then 'Windows Enterprise N'
		when 28 then 'Windows Ultimate N'
		when 48 then 'Windows Pro'
		when 49 then 'Windows Pro N'
		when 70 then 'Windows Enterprise E'
		when 72 then 'Windows Enterprise Evaluation'
		when 84 then 'Windows Enterprise N Evaluation'
		when 97 then 'Windows RT'
		when 98 then 'Windows Home N'
		when 99 then 'Windows Home China'
		when 100 then 'Windows Home Single Language'
		when 101 then 'Windows Home'
		when 103 then 'Windows Professional with Media Center'
		when 104 then 'Windows Mobile'
		when 121 then 'Windows Education'
		when 122 then 'Windows Education N'
		when 123 then 'Windows IoT Core'
		when 125 then 'Windows Enterprise LTSB'
		when 129 then 'Windows Enterprise LTSB Evaluation'
		when 126 then 'Windows Enterprise LTSB N'
		when 130 then 'Windows Enterprise LTSB N Evaluation'
		when 131 then 'Windows IoT Core Commercial'
		when 133 then 'Windows Mobile Enterprise'
		else ''
	end as [Operating System Edition],
	IsNull(os.Version0, '') as 'Build Version',
	case
		when os.Version0 not like '10.%' then ''
		when os.Version0 is null then ''
		when wsln.Value is null then 'Insider'
		else wsln.Value
	end as [BuildNumberDescription],
	case 
		when os.Version0 not like '10.%' then ''
		when (os.BuildNumber0 >= 18362 and rsy.OSBranch01 != 2) then 'Semi-Annual Channel' --no branch = 1 for 1903+ https://docs.microsoft.com/en-us/windows/client-management/mdm/policy-csp-update#update-branchreadinesslevel
		when (os.BuildNumber0 >= 18362 and rsy.OSBranch01 is null) then 'Semi-Annual Channel' --no branch = 1 for 1903+ https://docs.microsoft.com/en-us/windows/client-management/mdm/policy-csp-update#update-branchreadinesslevel
		when rsy.OSBranch01 = 0 then 'Semi-Annual Channel'
		when rsy.OSBranch01 = 1 then 'Semi-Annual Channel (Targeted)'
		when rsy.OSBranch01 = 2 then 'Long-Term Servicing Channel (LTSC)'
		else ''
	end as OSBranchName,
	case wss.State
		when 1 then 'Insider' --to be validated
		when 2 then 'Current'
		when 3 then 'Expire Soon'
		when 4 then 'Expired'
		else 'Unknown'
	end as State,
	IsNull(os.OSArchitecture0, '') as 'OS Architecture',

	--Hardware
	IsNull(cs.Manufacturer0, '') AS 'Manufacturer', 
	IsNull(cs.Model0, '') as 'Model', 
	IsNull(cs.SystemType0, '') as 'Physical Architecture',
	IsNull(cs.NumberOfProcessors0, '') as 'Physical CPU',

	--CPU
	Isnull(CPU.Name0, '') as CPUName, --check
	IsNull(CPU.AddressWidth0, '') as 'Physical CPU Architecture',
	IsNull(CPU.NormSpeed0, 0) as 'Processor Speed (Mhz)',
	IsNull(CPU.NumberOfCores0, 0) as NumberOfCores,
	IsNull(CPU.NumberOfLogicalProcessors0, 0) as NumberOfLogicalProcessors,

	--Memory
	CONVERT(decimal(10,0),round(IsNull(mem.TotalPhysicalMemory0, 0) / 1024.0 / 1024.0,0)) as 'Memory (GB)',

	--Disk
	isnull(CONVERT(decimal(10,0),round(IsNull(dsk.Size0, 0) /1024.0,0)), 0) as 'Disk Size (GB)',
	isnull(DSK.FreeSpace0 /1024, 0) AS 'Free Space (GB)',

	--BIOS
	IsNull(BIOS.Manufacturer0, '') AS BIOSManufacturer,
	
	--TPM
	IsNull(tpm.SpecVersion0, '') as 'TPM Version(s)',

	case TPM.IsActivated_InitialValue0
		when 0 then 'No'
		when 1 then 'Yes'
		else ''
	end as 'TPM Active',

	case TPM.IsEnabled_InitialValue0
		when 0 then 'No'
		when 1 then 'Yes'
		else ''
	end as 'TPM Enabled',

	case TPM.IsOwned_InitialValue0
		when 0 then 'No'
		when 1 then 'Yes'
		else ''
	end as 'TPM Owned',

	isnull(TPM.PhysicalPresenceVersionInfo0, '') as TPMVersion1,
	isnull(TPM.SpecVersion0, '') as TPMVersion2,
	isnull(LEFT(TPM.SpecVersion0, CHARINDEX(',',TPM.SpecVersion0 )-1), '') AS TPMVersion3,
	
	--Secure Boot/UEFI
	case frm.SecureBoot0
		when 0 then 'No'
		when 1 then 'Yes'
		else ''
	end as 'Secure Boot',
	case frm.UEFI0
		when 0 then 'No'
		when 1 then 'Yes'
		else ''
	end as 'UEFI',

	case
		when mem.TotalPhysicalMemory0 is null then 'Information not available (Memory)'
		when CONVERT(decimal(10,0),round((mem.TotalPhysicalMemory0 / 1024.0 / 1024.0),0)) < @MinRam then 'Upgrade required (Memory)'
		else null
	end as MinReadinessMemory,

	case
		when mem.TotalPhysicalMemory0 is null then 'Information not available (Memory)'
		when CONVERT(decimal(10,0),round((mem.TotalPhysicalMemory0 / 1024.0 / 1024.0),0)) < @RecRam then 'Upgrade required (Memory)'
		else null
	end as RecReadinessMemory,

	case
		when dsk.Size0 is null then 'Information not available (Disk)'
		when CONVERT(decimal(10,0),round((dsk.Size0 / 1024.0),0)) < @MinDiskSize then 'Upgrade required (Storage)'
		else null
	end as MinReadinessDisk,

	case
		when dsk.Size0 is null then 'Information not available (Disk)'
		when CONVERT(decimal(10,0),round((dsk.Size0 / 1024.0),0)) < @RecDiskSize then 'Upgrade required (Storage)'
		else null
	end as RecReadinessDisk,

	case
		when dsk.FreeSpace0 is null then 'Information not available (Disk Space)'
		when CONVERT(decimal(10,0),round((dsk.FreeSpace0 / 1024.0),0)) < @MinFreeDiskSpace then 'Upgrade required (Storage Free Space)'
		else null
	end as MinReadinessDiskSpace,

	case
		when dsk.FreeSpace0 is null then 'Information not available (Disk Space)'
		when CONVERT(decimal(10,0),round((dsk.FreeSpace0 / 1024.0),0)) < @RecFreeDiskSpace then 'Upgrade required (Storage Free Space)'
		else null
	end as RecReadinessSpace,

	case
		when CPU.MaxClockSpeed0 is null then 'Information not available (CPU Speed)'
		when (CPU.MaxClockSpeed0*CPU.NumberOfCores0) < @MinCPUSpeed then 'Upgrade required (CPU)'
		else null
	end as MinReadinessCPUSpeed,

	case
		when CPU.MaxClockSpeed0 is null then 'Information not available (CPU Speed)'
		when (CPU.MaxClockSpeed0*CPU.NumberOfCores0) < @RecCPUSpeed then 'Upgrade required (CPU)'
		else null
	end as RecReadinessCPUSpeed,

	case
		when CPU.NumberOfCores0 is null then 'Information not available (CPU core)'
		when CPU.NumberOfCores0 < @MinCPUCore then 'Upgrade required (CPU core)'
		else null
	end as MinReadinessCPUCore,

	case
		when CPU.NumberOfCores0 is null then 'Information not available (CPU core)'
		when CPU.NumberOfCores0 < @RecCPUCore then 'Upgrade required (CPU core)'
		else null
	end as RecReadinessCPUCore,

	case
		when CPU.AddressWidth0 is null then 'Information not available (CPU Architecture)'
		when CPU.AddressWidth0 != 64 then 'Upgrade required (CPU Architecture)'
		else null
	end as MinReadinessCPUArchitecture,

	case
		when CPU.AddressWidth0 is null then 'Information not available (CPU Architecture)'
		when CPU.AddressWidth0 != 64 then 'Upgrade required (CPU Architecture)'
		else null
	end as RecReadinessCPUArchitecture,

	case
		when FRM.SecureBoot0 is null then 'Information not available (Secure Boot)'
		when FRM.SecureBoot0 != 1 then 'Upgrade required (Secure Boot)'
		else null
	end as MinReadinessSecureBoot,

	case
		when FRM.SecureBoot0 is null then 'Information not available (Secure Boot)'
		when FRM.SecureBoot0 != 1 then 'Upgrade required (Secure Boot)'
		else null
	end as RecReadinessSecureBoot,

	case
		when FRM.UEFI0 is null then 'Information not available (UEFI)'
		when FRM.UEFI0 != 1 then 'Upgrade required (UEFI)'
		else null
	end as MinReadinessEUFI,

	case
		when FRM.UEFI0 is null then 'Information not available (UEFI)'
		when FRM.UEFI0 != 1 then 'Upgrade required (UEFI)'
		else null
	end as RecReadinessEUFI,

	case
		when tpm.SpecVersion0 is null then 'Information not available (TPM)'
		when LEFT(TPM.SpecVersion0, CHARINDEX(',',TPM.SpecVersion0 )-1) != @MinTPMVersion then 'Upgrade required (TPM)'
		else null
	end as MinReadinessTPM,

	case
		when tpm.SpecVersion0 is null then 'Information not available (TPM)'
		when LEFT(TPM.SpecVersion0, CHARINDEX(',',TPM.SpecVersion0 )-1) != @MinTPMVersion then 'Upgrade required (TPM)'
		else null
	end as RecReadinessTPM

	from v_R_System rsy 
	inner join v_FullCollectionMembership fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	inner join v_CH_ClientSummary chc on chc.ResourceID = rsy.ResourceID and DATEDIFF(dd, chc.LastActiveTime, @Now) <= 7

	left join v_GS_SYSTEM_CONSOLE_USER scs on scs.ResourceID = rsy.ResourceID
	left join V_GS_COMPUTER_SYSTEM cs on cs.ResourceID = rsy.ResourceID
	LEFT JOIN v_GS_OPERATING_SYSTEM OS ON OS.ResourceID = rsy.ResourceID
	left join vSMS_WindowsServicingStates wss on (wss.Build = os.Version0 and wss.Branch = 0)
	left join vSMS_WindowsServicingLocalizedNames wsln on wss.Name = wsln.Name


	LEFT JOIN v_GS_PC_BIOS AS BIOS ON BIOS.ResourceID = rsy.ResourceID
	LEFT JOIN v_GS_FIRMWARE as FRM on FRM.ResourceID = rsy.ResourceID
	LEFT JOIN v_GS_TPM as TPM on TPM.ResourceID = rsy.ResourceID
	LEFT JOIN v_GS_PROCESSOR CPU on CPU.ResourceID = rsy.ResourceID
	LEFT JOIN v_GS_LOGICAL_DISK DSK on DSK.ResourceID=rsy.ResourceID and DSK.DriveType0 = 3 and DSK.DeviceID0 = 'C:'

	left join v_GS_X86_PC_MEMORY mem on mem.ResourceID = rsy.ResourceID
WHERE
	rsy.Operating_System_Name_and0 like '%workstation%' 
) as tblRaw
order by 1
