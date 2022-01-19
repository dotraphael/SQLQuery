declare @Now DateTime = GetDate(), @CollectionID varchar(8)
declare @MinRam int, @MinFreeDiskSpace int, @MinDiskSize int, @MinCPUSpeed int, @MinTPMVersion varchar(8)
declare @RecRam int, @RecFreeDiskSpace int, @RecDiskSize int,  @RecCPUSpeed int, @RecTPMVersion varchar(8)

set @CollectionID = 'P010002E' --Main Collection
set @MinRam = 4
set @MinFreeDiskSpace = 65
set @MinDiskSize = 128
set @MinCPUSpeed = 1000
set @MinTPMVersion = '2.0'

set @RecRam = 8
set @RecFreeDiskSpace = 65
set @RecDiskSize = 220
set @RecCPUSpeed = 4000
set @RecTPMVersion = '2.0'

---Query
select distinct 
	rsy.ResourceID,
	rsy.Name0 as 'Device HostName',
	rsy.User_Domain0 + '\' + rsy.User_Name0 as 'Last Account (AD)',
	cs.UserName0 as 'Last Account (Inventory)',
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
	CPU.Name0, --check
	IsNull(CPU.NormSpeed0, 0) as 'Processor Speed (Mhz)',
	IsNull(CPU.NumberOfCores0, 0) as NumberOfCores,
	IsNull(CPU.NumberOfLogicalProcessors0, 0) as NumberOfLogicalProcessors,

	--Memory
	CONVERT(decimal(10,0),round(IsNull(mem.TotalPhysicalMemory0, 0) / 1024.0 / 1024.0,0)) as 'Memory (GB)',

	--Disk
	CONVERT(decimal(10,0),round(IsNull(dsk.Size0, 0) /1024.0,0)) as 'Disk Size (GB)',
	DSK.FreeSpace0 /1024 AS 'Free Space (GB)',

	--BIOS
	BIOS.Manufacturer0 AS BIOSManufacturer,
	
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

	TPM.PhysicalPresenceVersionInfo0 as TPMVersion1,
	TPM.SpecVersion0 as TPMVersion2,
	LEFT(TPM.SpecVersion0, CHARINDEX(',',TPM.SpecVersion0 )-1) AS TPMVersion3,
	
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

	--Windows 11 Readiness
	case 
		when mem.TotalPhysicalMemory0 is null then 'Information not available (Memory)'
		when dsk.Size0 is null then 'Information not available (Disk)'
		when dsk.FreeSpace0 is null then 'Information not available (Disk Space)'
		when CPU.MaxClockSpeed0 is null then 'Information not available (CPU Speed)'
		when FRM.SecureBoot0 is null then 'Information not available (Secure Boot)'
		when FRM.UEFI0 is null then 'Information not available (UEFI)'
		when tpm.SpecVersion0 is null then 'Information not available (TPM)'

		when (CPU.MaxClockSpeed0*CPU.NumberOfCores0) < @MinCPUSpeed then 'Upgrade required (CPU)'
		when CONVERT(decimal(10,0),round((IsNull(mem.TotalPhysicalMemory0, 0) / 1024.0 / 1024.0),0)) < @MinRam then 'Upgrade required (Memory)'
		when CONVERT(decimal(10,0),round((IsNull(dsk.Size0, 0) / 1024.0),0)) < @MinDiskSize then 'Upgrade required (Storage)'
		when CONVERT(decimal(10,0),round((IsNull(dsk.FreeSpace0, 0) / 1024.0),0)) < @MinFreeDiskSpace then 'Upgrade required (Storage Free Space)'

		when FRM.SecureBoot0 != 1 then 'Upgrade required (Secure Boot)'
		when FRM.UEFI0 != 1 then 'Upgrade required (UEFI)'
		WHEN LEFT(TPM.SpecVersion0, CHARINDEX(',',TPM.SpecVersion0 )-1) != @MinTPMVersion then 'Upgrade required (TPM)'


		else 'Ready for Windows 11'
	end as 'Minimum Windows 11 Readiness',

	case 
		when mem.TotalPhysicalMemory0 is null then 'Information not available (Memory)'
		when dsk.Size0 is null then 'Information not available (Disk)'
		when dsk.FreeSpace0 is null then 'Information not available (Disk Space)'
		when CPU.MaxClockSpeed0 is null then 'Information not available (CPU Speed)'
		when FRM.SecureBoot0 is null then 'Information not available (Secure Boot)'
		when FRM.UEFI0 is null then 'Information not available (UEFI)'
		when tpm.SpecVersion0 is null then 'Information not available (TPM)'

		when (CPU.MaxClockSpeed0*CPU.NumberOfCores0) < @RecCPUSpeed then 'Upgrade required (CPU)'
		when CONVERT(decimal(10,0),round((IsNull(mem.TotalPhysicalMemory0, 0) / 1024.0 / 1024.0),0)) < @RecRam then 'Upgrade required (Memory)'
		when CONVERT(decimal(10,0),round((IsNull(dsk.Size0, 0) / 1024.0),0)) < @RecDiskSize then 'Upgrade required (Storage)'
		when CONVERT(decimal(10,0),round((IsNull(dsk.FreeSpace0, 0) / 1024.0),0)) < @RecFreeDiskSpace then 'Upgrade required (Storage Free Space)'

		when FRM.SecureBoot0 != 1 then 'Upgrade required (Secure Boot)'
		when FRM.UEFI0 != 1 then 'Upgrade required (UEFI)'
		WHEN LEFT(TPM.SpecVersion0, CHARINDEX(',',TPM.SpecVersion0 )-1) != @MinTPMVersion then 'Upgrade required (TPM)'


		else 'Ready for Windows 11'
	end as 'Recommended Windows 11 Readiness'

	from v_R_System rsy 
	inner join v_FullCollectionMembership fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	inner join v_CH_ClientSummary chc on chc.ResourceID = rsy.ResourceID and DATEDIFF(dd, chc.LastActiveTime, @Now) <= 7

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
	rsy.Build01 LIKE '10.%' AND rsy.Operating_System_Name_and0 like '%workstation%' 
order by 1
