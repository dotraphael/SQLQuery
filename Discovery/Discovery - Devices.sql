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
	
	--Devices
	IsNull(cs.Manufacturer0, '') AS 'Manufacturer', 
	IsNull(cs.Model0, '') as 'Model', 
	IsNull(cs.SystemType0, '') as 'Physical Architecture',
	IsNull(cs.NumberOfProcessors0, '') as 'Physical CPU',
	IsNull(pc.MaxClockSpeed0, 0) as 'Processor Speed (Mhz)',
	CONVERT(decimal(10,0),round(IsNull(mem.TotalPhysicalMemory0, 0) / 1024.0 / 1024.0,0)) as 'Memory (GB)',
	CONVERT(decimal(10,0),round(IsNull(dsk.Size0, 0) /1024.0,0)) as 'Disk Size (GB)',
	IsNull(tpm.SpecVersion0, '') as 'TPM Version',
	case sf.SecureBoot0
		when 0 then 'Disabled'
		when 1 then 'Enabled'
		else ''
	end as 'Secure Boot',
		case sf.UEFI0
		when 0 then 'Disabled'
		when 1 then 'Enabled'
		else ''
	end as 'UEFI',
	IsNull(pc.NumberOfCores0, 0) as NumberOfCores,
	IsNull(pc.NumberOfLogicalProcessors0, 0) as NumberOfLogicalProcessors,
	case 
		when mem.TotalPhysicalMemory0 is null then 'Information not available'
		when dsk.Size0 is null then 'Information not available'
		when pc.MaxClockSpeed0 is null then 'Information not available'
		when (pc.MaxClockSpeed0*pc.NumberOfCores0) < 1000 then 'Upgrade required (CPU)'
		when CONVERT(decimal(10,0),round((IsNull(mem.TotalPhysicalMemory0, 0) / 1024.0 / 1024.0),0)) < 2 then 'Upgrade required (Memory)'
		when CONVERT(decimal(10,0),round((IsNull(dsk.Size0, 0) / 1024.0),0)) < 32 then 'Upgrade required (Storage)'
		when tpm.SpecVersion0 is null then 'Upgrade may be required (TPM)'
		else 'Ready for Windows 10'
	end as 'Windows 10 Readiness',
	case 
		when mem.TotalPhysicalMemory0 is null then 'Information not available'
		when dsk.Size0 is null then 'Information not available'
		when pc.MaxClockSpeed0 is null then 'Information not available'
		when (pc.MaxClockSpeed0*pc.NumberOfCores0) < 4000 then 'Upgrade required (CPU)'
		when CONVERT(decimal(10,0),round((IsNull(mem.TotalPhysicalMemory0, 0) / 1024.0 / 1024.0),0)) < 4 then 'Upgrade required (Memory)'
		when CONVERT(decimal(10,0),round((IsNull(dsk.FreeSpace0, 0) / 1024.0),0)) < 4 then 'Upgrade required (Storage)'
		when IsNull(pc.NumberOfCores0, 0) < 2 then 'Upgrade required (CPU)'
		else 'Ready for Office 365'
	end as 'Office 365 Readiness',
	case 
		when mem.TotalPhysicalMemory0 is null then 'Information not available'
		when dsk.Size0 is null then 'Information not available'
		when pc.MaxClockSpeed0 is null then 'Information not available'
		when (pc.MaxClockSpeed0*pc.NumberOfCores0) < 4000 then 'Upgrade required (CPU)'
		when CONVERT(decimal(10,0),round((IsNull(mem.TotalPhysicalMemory0, 0) / 1024.0 / 1024.0),0)) < 8 then 'Upgrade required (Memory)'
		when CONVERT(decimal(10,0),round((IsNull(dsk.Size0, 0) / 1024.0),0)) < 220 then 'Upgrade required (Storage)' --using 220 because of the other partitions
		when tpm.SpecVersion0 is null then 'Upgrade may be required (TPM)'
		else 'Ready'
	end as 'Recommended Readiness'--,

	from fn_RBAC_R_System('disabled') rsy 
	inner join fn_rbac_FullCollectionMembership('disabled') fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	left join fn_rbac_GS_COMPUTER_SYSTEM('disabled') cs on cs.ResourceID = rsy.ResourceID and cs.Model0 not in ('Virtual Machine', 'VMware7,1')
	left join fn_rbac_GS_OPERATING_SYSTEM('disabled') os on os.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_X86_PC_MEMORY('disabled') mem on mem.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_LOGICAL_DISK('disabled') dsk on dsk.ResourceID = rsy.ResourceID and DriveType0 = 3 and DeviceID0 = 'C:'
	left join fn_rbac_GS_PROCESSOR('disabled') pc on pc.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_TPM('disabled') tpm on tpm.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_FIRMWARE('disabled') sf on sf.ResourceID = rsy.ResourceID
	left join fn_RBAC_CH_ClientSummary('disabled') chc on chc.ResourceID = rsy.ResourceID
order by 1