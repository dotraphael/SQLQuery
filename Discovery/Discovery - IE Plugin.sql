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

	--IE Plugin
	--iep.CLSID0,
	IsNull(iep.Description0,'') as PlugInDescription,
	IsNull(iep.Product0,'') as ProductName,
	IsNull(iep.ProductVersion0,'') as ProductVersion,
	IsNull(iep.Publisher0,'') as Publisher,
	IsNull(iep.Version0,'') as Version,
	IsNull(iep.FileVersion0,'') as FileVersion--,

	from fn_RBAC_R_System('disabled') rsy 
	inner join fn_rbac_FullCollectionMembership('disabled') fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	left join fn_RBAC_CH_ClientSummary('disabled') chc on chc.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_BROWSER_HELPER_OBJECT('disabled') iep on iep.ResourceID = rsy.ResourceID

--where
--rsy.ResourceID = 16777297
order by 1


