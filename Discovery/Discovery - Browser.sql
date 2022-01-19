declare @CollectionID varchar(8)
DECLARE @Now DateTime = GetDate()
set @CollectionID = 'P010002E'

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
	
	--Browser
	IsNull(bud.browsername0, '') as BrowserName,
	IsNull(bud.UsagePercentage0, 0) as UsagePercentage,
	case 
		when bud.browsername0 = 'iexplore' then 1
		when bud.BrowserName0 = 'MicrosoftEdgeCP' and os.Version0 like '10.%' then 1
		else IsNull((select distinct 1 from @tblBrowser brw where brw.ResourceID = rsy.ResourceID and brw.Browser = bud.browsername0),0)
	end as Installed,
	db.BrowserProgId0 as DefaultBrowser,
	dbd.DefaultBrowser as DefaultBrowserNormalised--,
	
	from fn_RBAC_R_System('disabled') rsy 
	inner join fn_rbac_FullCollectionMembership('disabled') fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	left join fn_rbac_GS_OPERATING_SYSTEM('disabled') os on os.ResourceID = rsy.ResourceID
	left join fn_RBAC_CH_ClientSummary('disabled') chc on chc.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_BROWSER_USAGE('disabled') bud on bud.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_DEFAULT_BROWSER('disabled') db on db.ResourceID = rsy.ResourceID
	left join v_DefaultBrowserData dbd on dbd.ResourceID = rsy.ResourceID
order by 1
