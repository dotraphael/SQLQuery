declare @CollectionID varchar(8)
DECLARE @Now DateTime = GetDate()
set @CollectionID = 'P010002E'
/* Office 365 version table CM_SupportData..O365BuildToVersionMap - Generated using Invoke-RFLO365VersionToBuildMap.ps1 available at https://github.com/dotraphael/Tools */

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
	
	 --Office
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

	from fn_RBAC_R_System('disabled') rsy 
	inner join fn_rbac_FullCollectionMembership('disabled') fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	left join fn_rbac_GS_OFFICE_DEVICESUMMARY('disabled') office on office.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_OFFICE_PRODUCTINFO('disabled') officepi on officepi.ResourceID = rsy.ResourceID and officepi.ProductName0 in ('Microsoft Office Professional Plus 2016', 'Microsoft Office Standard 2016', 'Microsoft Office Standard 2013', 'Microsoft Office Professional Plus 2013', 'Microsoft 365 - en-us', 'Microsoft Office 365 ProPlus - en-us', 'Microsoft Office Professional Plus 2010', 'Microsoft Office Professional Plus 2019 - en-us', 'Microsoft 365 Apps for enterprise - en-us','Microsoft 365 for enterprise - en-us')
	left join fn_rbac_GS_OFFICE365PROPLUSCONFIGURATIONS('disabled') officeconfig on officepi.ResourceID = officeconfig.ResourceID
	left join tblOfficeInventory officeinventory on officeinventory.ResourceID = rsy.ResourceID and officeinventory.Products in ('O365ProPlusRetail')
	left join CM_SupportData..O365BuildToVersionMap ovm on ovm.VersionNumber = officepi.ProductVersion0 and ovm.Channel = officepi.Channel0
	left join fn_RBAC_CH_ClientSummary('disabled') chc on chc.ResourceID = rsy.ResourceID
order by 1