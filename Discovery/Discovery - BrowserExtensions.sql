declare @CollectionID varchar(8)
DECLARE @Now DateTime = GetDate()
set @CollectionID = 'P010002E'

--select tbl.ScriptVersion, count(distinct resourceid) from (
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
	
	--Browser Extensions
	IsNull(usr.Full_User_Name0, '') as PossibleUser,
	IsNull(be.UserProfile0, '') as UserProfile,
	IsNull(be.BrowserName0, '') as BrowserName,
	IsNull(be.ExtensionID0, '') as ExtensionID,
	IsNull(be.ExtensionName0, '') as ExtensionName,
	IsNull(be.ExtensionVersion0, '') as ExtensionVersion,
	IsNull(be.URL0, '') as [URL],
	IsNull(be.URLFound0, '') as URLFound,
	IsNull(be.Category0, '') as Category,
	IsNull(be.OfferedBy0, '') as OfferedBy,
	IsNull(be.ScriptVersion0,'') as ScriptVersion--,
	
	from fn_RBAC_R_System('disabled') rsy 
	inner join fn_rbac_FullCollectionMembership('disabled') fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	left join fn_rbac_GS_OPERATING_SYSTEM('disabled') os on os.ResourceID = rsy.ResourceID
	left join fn_RBAC_CH_ClientSummary('disabled') chc on chc.ResourceID = rsy.ResourceID
	left join fn_rbac_GS_BROWSEREXTENSIONS('disabled') be on be.ResourceID = rsy.ResourceID
	left join fn_rbac_R_User('disabled') usr on be.UserProfile0 = usr.User_Name0
where be.ExtensionID0 = be.ExtensionName0 --AND 
--be.ScriptVersion0 = '0.7'
/*and be.ExtensionID0 not in ('aapocclcgogkmnckokdopfmhonfmgoek', --slides
'aohghmighlieiainnegkcijnfilokake', --docs
'apdfllckaahabafndbhieahigkjlhalf', --google drive
'bfgjjammlemhdcocpejaompfoojnjjfn', --PrinterLogic Extension v1.0.5.9, PrinterLogic Extension v1.0.5.8
'blpcfgokakmgnkcojhhkbfbldkacnbeo', --YouTube
'felcaaldnbdncclmgdcncolpebgiejap', --Sheets
'ghbmnnjooekpmoecnnnilnnbdlolhkhi', --Google Docs Offline
'jlhmfgmfgeifomenelglieieghnjghma', --Cisco Webex Extension
'ncgfdaipgceflkflfffaejlnjplhnbfn', --NHS Smartcard Tools
'nmmhkkegccagdldgiimedpiccmgmieda', --Chrome Web Store Payments
'pjkljhegncpnkpknbcohdijeoejaedia', --Gmail
'pkedcjkdefgpdelpbcmbmeomcjbeemfm', --Chrome Media Router
'glnpjglilkicbckjpbgcfkogebgllemb', --octa
'nfoelejpajdgdjldhnpaobkadhhhlmha', --google maps
--'kbfnbcaeplbcioakkpcpgfkobkghlhen', --Grammarly for Chrome
'efaidnbmnnnibpcajpcglclefindmkaj', --Adobe Acrobat
'coobgpohoikkiipiblmjeljniedjpjpf', --Google Search
''
)*/
--) tbl
--group by tbl.ScriptVersion
order by 1
