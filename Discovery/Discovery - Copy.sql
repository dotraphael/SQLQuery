declare @CollectionID varchar(8)
DECLARE @Now DateTime = GetDate()
set @CollectionID = 'P010002E'
/* Office 365 version table CM_SupportData..O365BuildToVersionMap - Generated using Invoke-RFLO365VersionToBuildMap.ps1 available at https://github.com/dotraphael/Tools */

DECLARE @tblBrowser TABLE
(Resourceid int, 
 Browser varchar(255)
)

insert into @tblBrowser
SELECT  isd.ResourceID, brs.Browser 
FROM fn_rbac_GS_INSTALLED_SOFTWARE('disabled') isd 
CROSS APPLY ( 
SELECT CASE WHEN isd.ProductName0 LIKE N'Google Chrome%' THEN N'chrome' 
            WHEN isd.ProductName0 LIKE N'Mozilla FireFox%' THEN N'firefox' 
            WHEN isd.ProductName0 LIKE N'Opera%' THEN N'opera' 
			WHEN isd.ProductName0 LIKE N'Microsoft Edge' THEN N'msedge' 
            ELSE isd.ProductName0 
    END 
) brs(Browser)
WHERE 
(isd.ProductName0 LIKE N'Microsoft Edge%' AND isd.SoftwareCode0 != N'microsoft edge update' AND isd.ProductName0 != N'Microsoft Edge Update Helper') 
OR isd.ProductName0 LIKE N'Google Chrome%' 
OR isd.ProductName0 LIKE N'Mozilla FireFox%' 
OR isd.ProductName0 LIKE N'Opera%' 


;with tblOfficeInventory (Architecture, ResourceID, ExcludedProduct, Products, Culture) as
(
select 'x86' as Architecture, oi.ResourceID, oi_01.value as ExcludedProduct, oi_02.value as Products, oi_03.value as Culture
from fn_rbac_GS_O365Inventory_Custom0('disabled') oi 
inner join fn_rbac_FullCollectionMembership('disabled') fcm on oi.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	OUTER APPLY STRING_SPLIT(oi.OfficeExcludedApps0,',') oi_01
	OUTER APPLY STRING_SPLIT(oi.OfficeProductReleaseIds0,',') oi_02
	OUTER APPLY STRING_SPLIT(oi.OfficeCulture0,',') oi_03
union all
select 'x64' as Architecture, oi.ResourceID, oi_01.value as ExcludedProduct, oi_02.value as Products, oi_03.value as Culture
from fn_rbac_GS_O365Inventory_Custom640('disabled') oi 
inner join fn_rbac_FullCollectionMembership('disabled') fcm on oi.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	OUTER APPLY STRING_SPLIT(oi.OfficeExcludedApps0,',') oi_01
	OUTER APPLY STRING_SPLIT(oi.OfficeProductReleaseIds0,',') oi_02
	OUTER APPLY STRING_SPLIT(oi.OfficeCulture0,',') oi_03
)

--select distinct [Software Name], NormalisedName from (
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
	
	/*
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
	*/

	/*--Operating System
	IsNull(rsy.Operating_System_Name_and0, '') as 'Operating System',
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
	end as [Operating System Eddition],
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
	IsNull(os.OSArchitecture0, '') as 'OS Architecture'--,
	*/

	/* --Office
	IsNull(Replace(
	Replace(
	Replace(
	Replace(
	Replace(
	Replace(
	Replace(
	Replace(officepi.ProductName0, 
			'Microsoft Office Professional Plus ', ''), 
			'Microsoft Office 365 ProPlus', '365'), 
			'Microsoft Office Standard ', ''),
			'Microsoft 365 Apps for enterprise - en-us', '365'),
			'Microsoft 365', '365'), 
			'365 Apps for enterprise ',''),
			'- en-us',''), 
			'for enterprise ',''
	), '') as OfficeVersion,
	IsNull(officepi.Architecture0, '') as Architecture,
	case
		when officepi.ProductName0 like '%365%' then officepi.Channel0
		else ''
	end as O365Channel,
	case
		when officepi.ProductName0 like '%365%' then officepi.LicenseState0
		else ''
	end as O365LicenseState,
	IsNull(officepi.ProductName0, '') as ProductName,
	IsNull(officepi.ProductVersion0, '') as ProductVersion,
	IsNull(officeconfig.ClientCulture0, '') as Office365Language,
	IsNull(ovm.BuildNumber, '') as O365BuilNumber,
	case 
		when ovm.Status is null then ''
		when ovm.Status = 2 then 'Current'
		when ovm.Status = 3 then 'Expire Soon'
		when ovm.Status = 4 then 'Expired'
		else 'Unknown'
	end as O365Status,
	IsNull(officeinventory.ExcludedProduct, '') as O365ExcludedProduct,
	IsNull(officeinventory.Products, '') as O365Product,
	case officepi.IsProPlusInstalled0
		when 0 then 'Disabled'
		when 1 then 'Enabled'
		else ''
	end as 'Office 365 ProPlus Installed',
	case office.IsTelemetryEnabled0
		when 0 then 'Disabled'
		when 1 then 'Enabled'
		else ''
	end as 'Office Telemetry Enabled'--,
	*/

	/* --Office AddIn
	addin.Architecture0 as 'Architecture',
	addin.CompanyName0 as 'Company Name',
	addin.Description0 as ' Description',
	addin.FileName0 as 'File Name',
	addin.FileVersion0 as 'File Version',
	addin.FriendlyName0 as 'Friendly name',
	addin.OfficeApp0 as 'Office Application',
	addin.ProductName0 as 'Product Name',
	addin.ProductVersion0 as 'Product Version',
	addin.Type0 as 'Type'--,
	*/

	 --Software Names
	IsNull(adr.DisplayName0, adr.ProdID0) as 'Software Name', 
	IsNull(ns.NormalisedName, '') as NormalisedName,
	IsNull(adr.Publisher0, '') as 'Publisher', 
	IsNull(adr.Version0, '') as 'Version', 
	case 
		when sl.CategoryName is null then ''
		when sl.CategoryName = 'Not Identified' then ''
		when sl.CategoryName = 'Insufficient Data' then ''
		when sl.CategoryName = 'Unknown' then ''
		when sl.CategoryName = 'Uncategorized' then ''
		else sl.CategoryName
	end as 'Category', 
	case 
		when sl.FamilyName is null then ''
		when sl.FamilyName = 'Not Identified' then ''
		when sl.FamilyName = 'Insufficient Data' then ''
		when sl.FamilyName = 'Unknown' then ''
		when sl.FamilyName = 'Uncategorized' then ''
		else sl.FamilyName
	end as 'Family'--, 
	


	/* --Driver
	IsNull(pnp.DeviceID0, '') as 'DeviceID',
	IsNull(pnp.Manufacturer0, '') as 'Manufacturer',
	IsNull(pnp.Name0, '') as 'Name',
	IsNull(pnp.PNPDeviceID0, '') as 'PNP DeviceID'--,
	*/

	/*--Browser
	IsNull(bud.browsername0, '') as BrowserName,
	IsNull(bud.UsagePercentage0, 0) as UsagePercentage,
	case 
		when bud.browsername0 = 'iexplore' then 1
		when bud.BrowserName0 = 'MicrosoftEdgeCP' and os.Version0 like '10.%' then 1
		else IsNull((select distinct 1 from @tblBrowser brw where brw.ResourceID = rsy.ResourceID and brw.Browser = bud.browsername0),0)
	end as Installed,
	db.BrowserProgId0 as DefaultBrowser,
	dbd.DefaultBrowser as DefaultBrowserNormalised--,
	*/

	from fn_RBAC_R_System('disabled') rsy 
	inner join fn_rbac_FullCollectionMembership('disabled') fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	left join fn_rbac_GS_COMPUTER_SYSTEM('disabled') cs on cs.ResourceID = rsy.ResourceID and cs.Model0 not in ('Virtual Machine', 'VMware7,1')
	left join fn_rbac_GS_OPERATING_SYSTEM('disabled') os on os.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_X86_PC_MEMORY('disabled') mem on mem.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_LOGICAL_DISK('disabled') dsk on dsk.ResourceID = rsy.ResourceID and DriveType0 = 3 and DeviceID0 = 'C:'
	left join fn_rbac_GS_PROCESSOR('disabled') pc on pc.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_TPM('disabled') tpm on tpm.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_FIRMWARE('disabled') sf on sf.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_PNP_DEVICE_DRIVER('disabled') pnp on pnp.ResourceID = rsy.ResourceID and pnp.Name0 not like '\\%'  
	left join fn_rbac_GS_OFFICE_DEVICESUMMARY('disabled') office on office.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_OFFICE_ADDIN('disabled') addin on addin.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_OFFICE_PRODUCTINFO('disabled') officepi on officepi.ResourceID = rsy.ResourceID and officepi.ProductName0 in ('Microsoft Office Professional Plus 2016', 'Microsoft Office Standard 2016', 'Microsoft Office Standard 2013', 'Microsoft Office Professional Plus 2013', 'Microsoft 365 - en-us', 'Microsoft Office 365 ProPlus - en-us', 'Microsoft Office Professional Plus 2010', 'Microsoft Office Professional Plus 2019 - en-us', 'Microsoft 365 Apps for enterprise - en-us','Microsoft 365 for enterprise - en-us')
	left join fn_rbac_GS_OFFICE365PROPLUSCONFIGURATIONS('disabled') officeconfig on officepi.ResourceID = officeconfig.ResourceID
	left join tblOfficeInventory officeinventory on officeinventory.ResourceID = rsy.ResourceID and officeinventory.Products in ('O365ProPlusRetail')
	left join CM_SupportData..O365BuildToVersionMap ovm on ovm.VersionNumber = officepi.ProductVersion0 and ovm.Channel = officepi.Channel0
	left join vSMS_WindowsServicingStates wss on (wss.Build = os.Version0 and wss.Branch = 0)
	left join vSMS_WindowsServicingLocalizedNames wsln on wss.Name = wsln.Name
	left join fn_rbac_Add_Remove_Programs('disabled') adr on rsy.ResourceID = adr.ResourceID and adr.DisplayName0 not like 'Update for%' and adr.DisplayName0 is not null and adr.DisplayName0 <> '' and adr.DisplayName0 not like 'Security Update for%' and adr.DisplayName0 not like 'Definition Update for Microsoft%' and adr.DisplayName0 not like 'Hotfix for Microsoft%' and adr.DisplayName0 not like 'Service Pack%' and adr.DisplayName0 not like 'GDR % for SQL Server%' and adr.DisplayName0 not like 'Microsoft App Update for%'

	left join CM_SupportData..NormalisedSoftwares ns on ns.DisplayName0 = adr.DisplayName0 
	left join v_LU_SoftwareCode sc on sc.SoftwareCode = adr.ProdID0
	left join v_LU_SoftwareList sl on sc.softwareID = sl.softwareid
	left join fn_RBAC_CH_ClientSummary('disabled') chc on chc.ResourceID = rsy.ResourceID

	left join fn_rbac_GS_BROWSER_USAGE('disabled') bud on bud.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_DEFAULT_BROWSER('disabled') db on db.ResourceID = rsy.ResourceID
	left join v_DefaultBrowserData dbd on dbd.ResourceID = rsy.ResourceID
	--where  adr.ProdID0 like '7-zip%'
--and rsy.Client0  = 1 
--and os.OSArchitecture0 is null 
--) temp
--group by Manufacturer, Model
--order by adr.DisplayName0
--) temp where NormalisedName = ''
--and [Software Name] like 'microsoft office%'
order by 1