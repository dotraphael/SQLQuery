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
	
	from fn_RBAC_R_System('disabled') rsy 
	inner join fn_rbac_FullCollectionMembership('disabled') fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	left join fn_rbac_Add_Remove_Programs('disabled') adr on rsy.ResourceID = adr.ResourceID and adr.DisplayName0 not like 'Update for%' and adr.DisplayName0 is not null and adr.DisplayName0 <> '' and adr.DisplayName0 not like 'Security Update for%' and adr.DisplayName0 not like 'Definition Update for Microsoft%' and adr.DisplayName0 not like 'Hotfix for Microsoft%' and adr.DisplayName0 not like 'Service Pack%' and adr.DisplayName0 not like 'GDR % for SQL Server%' and adr.DisplayName0 not like 'Microsoft App Update for%' and adr.DisplayName0 not like 'Hotfix%for SQL Server%'
	left join CM_SupportData..NormalisedSoftwares ns on ns.DisplayName0 = adr.DisplayName0 
	left join v_LU_SoftwareCode sc on sc.SoftwareCode = adr.ProdID0
	left join v_LU_SoftwareList sl on sc.softwareID = sl.softwareid
	left join fn_RBAC_CH_ClientSummary('disabled') chc on chc.ResourceID = rsy.ResourceID
order by 1