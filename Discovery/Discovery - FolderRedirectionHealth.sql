declare @CollectionID varchar(8)
DECLARE @Now DateTime = GetDate()
set @CollectionID = 'P010002E'

--Note: Enable the Folder Redirection Health Class (SMS_FolderRedirectionHealth) in the Client Settings and select all required fields to be inventoried. 

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
	
	--Folder Redirection Health
	Isnull(fr.FolderName0,'') as FolderName,
	case fr.HealthStatus0
		when 0 then 'Healthy'
		when 1 then 'Caution'
		when 2 then 'Unhealthy'
		else ''
	end as 'HealthStatus',
	case
		when DATEDIFF(dd, fr.LastSuccessfulSyncTime0, @Now) <= 7 then 'in the last 7 days'
		when DATEDIFF(dd, fr.LastSuccessfulSyncTime0, @Now) between 8 and 30 then 'in the last 30 days'
		when DATEDIFF(dd, fr.LastSuccessfulSyncTime0, @Now) between 31 and 90 then 'in the last 90 days'
		when DATEDIFF(dd, fr.LastSuccessfulSyncTime0, @Now) > 90 then 'Over 90 days'
		when fr.LastSuccessfulSyncTime0 is null then ''
		else 'Never'
	end as LastSuccessfulSyncTime,
	case fr.LastSyncStatus0
		when 0 then 'Healthy'
		when 1 then 'Caution'
		when 2 then 'Unhealthy'
		else ''
	end as 'LastSyncStatus',
	case
		when DATEDIFF(dd, fr.LastSyncTime0, @Now) <= 7 then 'in the last 7 days'
		when DATEDIFF(dd, fr.LastSyncTime0, @Now) between 8 and 30 then 'in the last 30 days'
		when DATEDIFF(dd, fr.LastSyncTime0, @Now) between 31 and 90 then 'in the last 90 days'
		when DATEDIFF(dd, fr.LastSyncTime0, @Now) > 90 then 'Over 90 days'
		when fr.LastSyncTime0 is null then ''
		else 'Never'
	end as LastSyncTime,
	case fr.OfflineAccessEnabled0
		when 0 then 'Disabled'
		when 1 then 'Enabled'
		else ''
	end as 'OfflineAccessEnabled',
	Isnull(fr.OfflineFileNameFolderGUID0, '') as OfflineFileNameFolderGUID,
	case fr.Redirected0
		when 0 then 'Disabled'
		when 1 then 'Enabled'
		else ''
	end as 'Redirected'--,

	from fn_RBAC_R_System('disabled') rsy 
	inner join fn_rbac_FullCollectionMembership('disabled') fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	left join fn_rbac_GS_OPERATING_SYSTEM('disabled') os on os.ResourceID = rsy.ResourceID
	left join fn_RBAC_CH_ClientSummary('disabled') chc on chc.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_FOLDER_REDIRECTION_HEALTH('disabled') fr on fr.ResourceID = rsy.ResourceID
order by 13 desc



--select * from fn_rbac_GS_FOLDER_REDIRECTION_HEALTH('disabled')

