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

	--Baseline
	bl.CI_ID as [Baseline ID],
	dbo.fn_GetLocalizedCIName(1033,bl.CI_ID) as [Baseline Name], 
	bl.CIType_ID as [Baseline Type],
	case  /*https://msdn.microsoft.com/en-us/library/hh949383.aspx*/
		when bl.CIType_ID =  2 then 'Baseline'
		when bl.CIType_ID = 50 then 'Company Resource Access'
		when bl.CIType_ID is null then NULL
		else 'Unknown'
	end as [Baseline Type Description],
	bl.CIVersion as [Baseline Version], 

	asg.AssignmentID as [Deployment ID],
	asg.EnforcementEnabled as [Assignment Action],
	case 
		when asg.EnforcementEnabled = 0 then 'Monitor'
		when asg.EnforcementEnabled = 1 then 'Remediation'
		when asg.EnforcementEnabled is null then null
		else 'Unknown'
	end as [Assignment Action Description],
	dcmdet.ComplianceState as [Compliance State],
	case 
		when dcmdet.ComplianceState = 1 then 'Compliant'
		when dcmdet.ComplianceState = 3 then 'Non-Compliant'
		when dcmdet.ComplianceState = 4 then 'Error'
		when dcmdet.ComplianceState is null then null
		else 'Unknown'
	end as 'Compliance State Description',
	ccs.ErrorCount as [Error Count],
	err.ErrorCode as [Error Code],
	CONVERT(VARBINARY(4), err.ErrorCode) as [Error Code (Hex)],
	cs.ModelId as 'CI ID',
	cs.DisplayName as 'CI Name',
	cs.CIType_ID as 'CI Type',
	case 
		when cs.CIType_ID = 3 then 'Operating System'
		when cs.CIType_ID = 4 then 'General'
		when cs.CIType_ID = 5 then 'Application'
		when cs.CIType_ID = 7 then 'Uninterpreted'
		when cs.CIType_ID = 50 then 'company resource access'
		when cs.CIType_ID is null then null
		else 'Unknown'
	end as 'CI Type Description',
	cs.CIVersion as 'CI Version',
	cs.ComplianceState as 'CI Compliance State',
	cs.ComplianceStateName as 'CI Compliance State Description',
	cs.IsEnforced as 'CI Action',
	case 
		when cs.IsEnforced = 0 then 'Monitor'
		when cs.IsEnforced = 1 then 'Remediation'
		when cs.IsEnforced is null then null
		else 'Unknown'
	end as [CI Action Description],
	cs.LastComplianceErrorID as 'CI Last Compliance Error ID'--,
	
	from fn_RBAC_R_System('disabled') rsy 
	inner join fn_rbac_FullCollectionMembership('disabled') fcm on rsy.ResourceID = fcm.ResourceID and fcm.CollectionID = @CollectionID
	left join fn_RBAC_CH_ClientSummary('disabled') chc on chc.ResourceID = rsy.ResourceID
	left join vdcmdeploymentsystemdetails dcmdet on rsy.ResourceID = dcmdet.ResourceID 
	left join fn_rbac_ConfigurationItems('disabled') bl on dcmdet.BaselineID = bl.ModelName and bl.IsTombstoned=0 and bl.CIType_ID in (2) 
	left join v_CIAssignmentToCI targ on bl.CI_ID = targ.CI_ID
	left join v_CIAssignment asg on targ.AssignmentID = asg.AssignmentID
	left join v_CICurrentComplianceStatus ccs on ccs.CI_ID = bl.CI_ID and ccs.ResourceID = fcm.ResourceID
	left join v_CI_CurrentErrorDetails err on err.CurrentComplianceStatusID = ccs.CI_CurrentComplianceStatusID
	left join vSMS_CIRelation cirel on cirel.FromCIID = bl.CI_ID
	left join fn_rbac_ListCI_ComplianceState(1033, 'disabled') cs on cirel.ToCIID = cs.CI_ID and cs.ResourceID = rsy.ResourceID and cs.CIType_ID in (3, --ci Operating System
4, --ci general
5, --ci
7 --ci
) 
--where
--rsy.ResourceID = 16777246
order by 1
