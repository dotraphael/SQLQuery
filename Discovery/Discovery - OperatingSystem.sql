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
	rsy.User_Domain0 + '\' + rsy.User_Name0 as 'Last Account (AD)',
	cs.UserName0 as 'Last Account (Inventory)',
	
	--Operating System
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
	IsNull(os.OSArchitecture0, '') as 'OS Architecture'--,

	from fn_RBAC_R_System('disabled') rsy 
	inner join fn_rbac_FullCollectionMembership('disabled') fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	left join V_GS_COMPUTER_SYSTEM cs on cs.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_OPERATING_SYSTEM('disabled') os on os.ResourceID = rsy.ResourceID
	left join vSMS_WindowsServicingStates wss on (wss.Build = os.Version0 and wss.Branch = 0)
	left join vSMS_WindowsServicingLocalizedNames wsln on wss.Name = wsln.Name
	left join fn_RBAC_CH_ClientSummary('disabled') chc on chc.ResourceID = rsy.ResourceID
order by 1