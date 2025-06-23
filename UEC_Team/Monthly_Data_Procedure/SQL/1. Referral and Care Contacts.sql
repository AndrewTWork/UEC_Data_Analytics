


/**

Add contact type and start data from april 2019

**/
 
			IF OBJECT_ID('Tempdb..#tempHOc') IS NOT NULL 
			dROP TABLE #tempHOc
			select
			distinct 
			h.UniqServReqID, 
			h.Der_Person_ID, 
			h.MHS501UniqID  

			into #tempHOc

			from [MESH_MHSDS].[MHS501HospProvSpell] h  with(nolock)
		 
   IF OBJECT_ID('Tempdb..#ExistRef') IS NOT NULL
DROP TABLE #ExistRef
 select 
 distinct
 UniqServReqID
 into #ExistRef
 from [PATLondon].[MH_Referrals_with_Care_Contacts_London]
 
DECLARE @fin_yearStart date 
--set @fin_yearStart = '2025-01-01'
set  @fin_yearStart = (select dateadd(month, 3, 
                           dateadd(year, 
                                   datepart(year, 
                                            dateadd(month, -3, getdate())) - 1900, 0)))

 
 IF OBJECT_ID('Tempdb..#CCPre') IS NOT NULL
DROP TABLE #CCPre
 SELECT 
	DISTINCT  
	cc.UniqServReqID
	
	into #CCPre

	FROM [MESH_MHSDS].[MHS201CareContact_ALL] cc with(nolock)

	LEFT JOIN [MESH_MHSDS].[MHSDS_SubmissionFlags] f with(nolock) on f.NHSEUniqSubmissionID = cc.NHSEUniqSubmissionID 
	left join [PATLondon].[Ref_Care_Contact_Consultation_Mechanism]cm with(nolock) on cm.Code = ConsMechanismMH
	inner join  [MESH_MHSDS].[MHS101Referral_All]g on g.UniqServReqID = cc.UniqServReqID
 
	WHERE cc.AttendStatus in ('5','6') -- attended contacts only
	AND (cc.ConsMechanismMH IN ('01', '02', '04') -- this is face to face, telephone or talk type
	OR (cc.UniqMonthID <1459 AND cc.ConsMechanismMH IN ('03')) -- these two are video but accounting for previous MHSDS versions
	OR (cc.UniqMonthID >=1459 AND cc.ConsMechanismMH IN ('11'))) 
	AND f.Der_IsLatest = 'Y'
	and cc.CareContDate >=   @fin_yearStart
	and 	(
	g.OrgIDProv  is not null 
	and 
	g.OrgIDProv in ('RAT','RKL','RPG','RQY','RRP','RV3','RV5','RWK','TAF','RKE','G6V2S')	
	)
 

 

IF OBJECT_ID('Tempdb..#tempUR') IS NOT NULL 
dROP TABLE #tempUR
 select 
 
 dt.[Financial Year] as [Referral Fin Year],
 dt.[Month Start Date] as [Referral Month],
 
 ROW_NUMBER() OVER (
PARTITION BY  a.UniqServReqID ,a.OrgIDProv
ORDER BY  a.UniqMonthID DEsc , a.UniqSubmissionID desc,st.UniqSubmissionID desc,st.Effective_From desc ) as RowOrder, -- July 2024 - added sequence from referred to service
 a.*,
 case when a.ReferRejectionDate is not null then 1 else null end as [REferral Rejected Flag],
 --st.ReferRejectionDate ,
 b.Der_Pseudo_NHS_Number ,
 b.LSOA2011 as [Patient LSOA],
 b.DefaultPostcode as [Patient PostCode],
 b.Gender,
 b.EmploymentNationalLatest,
 b.AccommodationNationalLatest,
 b.EthnicCategory,
 b.NHSDEthnicity,
 case when ho.MHS501UniqID is not null then 1 else null end as  'Inpatient Services Flag',
 case when c.Region_Code = 'Y56' then 'London Patient' else 'Out of London or Not Recorded' end as [Patietn Region],
 case when ltrim(rtrim(st.ServTeamTypeRefToMH)) IN ('A05','A06','A08','A09','A12','A13','A16','C03','C10') then 1 else null end as  [Core Community Service Team Flag - OLD],
  case when ltrim(rtrim(st.ServTeamTypeRefToMH)) ='A06' then 1 else null end as  [Core Community Service Team Flag],
gpd.GP_Practice_Code as ODS_GPPrac_OrgCode,
gpd.PCDS_NoGaps  as ODS_GPPrac_PostCode,
gpd.GP_Code as [MPI GP Code],

ORef.Name as [Referring Organisation],
ORef.role as [Referring Org Type],
rtd.serviceTypeName as [Type of Service REferred to],
sor.Description as [Source of Referral] , 
CASE 
		WHEN a.SourceOfReferralMH = 'H1' THEN 'Emergency Department'
		WHEN a.SourceOfReferralMH = 'H2' THEN 'Acute Secondary Care' 
		WHEN a.SourceOfReferralMH IN ('A1','A2','A3','A4') THEN 'Primary Care' 
		WHEN a.SourceOfReferralMH IN ('B1','B2') THEN 'Self' 
		WHEN a.SourceOfReferralMH IN ('E1','E2','E3','E4','E5','E6') THEN 'Justice' 
		WHEN a.SourceOfReferralMH IN ('F1','F2','F3','G1','G2','G3','G4','I1','I2','M1','M2','M3','M4','M5','M6','M7','C1','C2','C3','D1','D2','N3') THEN 'Other'
		WHEN a.SourceOfReferralMH = 'P1' THEN 'Internal' 
		ELSE 'Missing/Invalid'
	END as [Source of Referral - Derived],
	 CASE 
		WHEN a.SourceOfReferralMH = 'H1' THEN 'Emergency Department'
		WHEN a.SourceOfReferralMH = 'H2' THEN 'Acute Secondary Care' 
		ELSE 'Other'
		END as [Source of Referral - Simplified], 
case 
when [ClinRespPriorityType] = '1' then 'Emergency'
when [ClinRespPriorityType] in( '2','U') then 'Urgent'
when [ClinRespPriorityType] = '3' then 'Routine'
when [ClinRespPriorityType] = '4' then 'Very Urgent'
else 'Unknown'
end as [Clinical Response Priority Type],
pg.Description as [Referring Care Professional Staff Group],
oop.Description as [Reason for Out of Area Referral],

 
COALESCE( b.OrgIDSubICBLocResidence, b.OrgIDCCGRes )  as OrgIDCCGRes,
 
cc.New_Code,
sf.Der_IsLatest 
 into #tempUR

 FROM [MESH_MHSDS].[MHS101Referral_ALL]a with(nolock)
 Left JOIN [MESH_MHSDS].[MHSDS_SubmissionFlags] sf with(nolock) ON sf.NHSEUniqSubmissionID = a.NHSEUniqSubmissionID AND sf.Der_IsLatest = 'Y'
 left JOIN [MESH_MHSDS].[MHS102ServiceTypeReferredTo] st with(nolock) ON st.RecordNumber = a.RecordNumber AND a.UniqServReqID = st.UniqServReqID
LEFT JOIN [MESH_MHSDS].[MHS902ServiceTeamDetails] AS rtd ON rtd.[UniqCareProfTeamLocalID] = a.[UniqCareProfTeamLocalID] AND rtd.[UniqMonthID] = a.[UniqMonthID]
 
 left join [PATLondon].[DIM_Date] dt with(nolock) on dt.[Calendar Day] = a.ReferralRequestReceivedDate
 left join [MESH_MHSDS].[MHS001MPI]b with(nolock) on b.Person_ID = a.Person_ID
											and b.UniqSubmissionID = a.UniqSubmissionID
											and b.UniqMonthID = a.UniqMonthID
											and b.RecordNumber = a.RecordNumber

 
 

left join [MESH_MHSDS].[MHS002GP_All]gp with(nolock) on gp.RecordNumber = b.RecordNumber 
													  and gp.UniqSubmissionID = a.UniqSubmissionID
left join [PATLondon].[Ref_GP_Data] gpd on gpd.GP_Practice_Code = gp.GMPReg   -- GMPCodeReg
LEFT JOIN [Internal_Reference].[ComCodeChanges_1] cc  with(nolock) ON cc.Org_Code = COALESCE( b.OrgIDSubICBLocResidence, b.OrgIDCCGRes )
LEFT JOIN [Reporting_UKHD_ODS].[Commissioner_Hierarchies] c  with(nolock) ON COALESCE(cc.New_Code,b.OrgIDCCGRes,b.OrgIDSubICBLocResidence) = c.Organisation_Code
LEFT JOIN #tempHOc ho ON ho.Der_Person_ID = a.Der_Person_ID 
							and ho.UniqServReqID = a.UniqServReqID
left join [UKHD_ODS_API].[vwOrganisation_SCD_IsLatestEqualsOneWithRole] ORef with(nolock) on Oref.ODS_Code = a.OrgIDReferringOrg
left join [PATLondon].[Ref_Referring_Care_Professional_Staff_Group]pg with(nolock) on pg.Code = a.ReferringCareProfessionalStaffGroup
left join [PATLondon].[Ref_Source_Of_Referral_for_Mental_Health_Services]sor with(nolock)  on sor.Code = a.SourceOfReferralMH
left join [PATLondon].[Ref_Reason_for_Out_Of_Area_Referral]oop with(nolock) on  cast(oop.Code as varchar(255))  =  a.ReasonOAT 
left join #ExistRef er on er.UniqServReqID = a.UniqServReqID 
 

 WHERE ( er.UniqServReqID is null )
 AND

 (
	(
	a.OrgIDProv  is not null 
	and 
	a.OrgIDProv in ('RAT','RKL','RPG','RQY','RRP','RV3','RV5','RWK','TAF','RKE','G6V2S')	
	)
	AND
	(
	A.ReferralRequestReceivedDate >=  @fin_yearStart
	)
)
OR a.UniqServReqID  in (select distinct UniqServReqID from #CCPre)
 


  delete from #tempUR  where RowOrder <> 1

 
 --------------------------------------------------------------------------------------------------------------------------------------------------
 IF OBJECT_ID('Tempdb..#CC') IS NOT NULL
DROP TABLE #CC
 SELECT 
	DISTINCT  
	 ROW_NUMBER() OVER (
PARTITION BY  cc.UniqServReqID , CareContDate,CareContTime,ConsMechanismMH
ORDER BY   cc.UniqSubmissionID desc ) as RowOrder,
	cc.UniqServReqID
	,cc.RecordNumber
	,cc.Der_Person_ID
	,ServTeamTypeRefToMH
	,coalesce(r.[Type of Service REferred to],stt.Description) as [Type of Service Referred to]
	,CareContDate
	,ReferralRequestReceivedDate
	,CareContTime
	,cc.UniqSubmissionID
	,cc.MHS201UniqID
	,cc.AttendStatus
	,ConsMechanismMh
	,CASE 
	WHEN ConsMechanismMH IN ('01', '02', '04') THEN 'face to face, telephone or talk type'
	WHEN 
	(CC.UniqMonthID <1459 AND ConsMechanismMH = '03')
	OR
	(cc.UniqMonthID >=1459 AND ConsMechanismMH ='11')
	 THEN 'video'
	 eND AS ContactTypeDesc
	,cm.Description as ContactTypeSubCategory
	,cc.UniqMonthID
		,CASE 
		WHEN cc.AttendStatus IN ('5','6') AND ([ConsMechanismMH] IN ('01', '02', '04', '11') 
		OR CC.OrgIDProv = 'DFC' AND [ConsMechanismMH] IN ('05','09', '10', '13')) 
		THEN 1 ELSE NULL 
	END AS [Der_Contact]
	,CASE 
		WHEN cc.AttendStatus IN ('5','6') AND [ConsMechanismMH] IN ('01', '02', '04', '11') 
		THEN 1 ELSE NULL 
	END AS [Der_DirectContact]
	,CASE 
		WHEN cc.AttendStatus IN ('5','6') AND [ConsMechanismMH] IN ('01', '11') 
		THEN 1 ELSE NULL 
	END AS [Der_FacetoFaceContact]
	,NULL AS [Face to Face Order]

	into #CC

	FROM [MESH_MHSDS].[MHS201CareContact_All] cc

	LEFT JOIN [MESH_MHSDS].[MHSDS_SubmissionFlags] f on f.NHSEUniqSubmissionID = cc.NHSEUniqSubmissionID 
	left join [PATLondon].[Ref_Care_Contact_Consultation_Mechanism]cm on cm.Code = ConsMechanismMH
	INNER JOIN (
				SELECT 
				DISTINCT 
				UniqServReqID, 
				Der_Person_ID,
				[Type of Service REferred to],
				ReferralRequestReceivedDate 
				FROM #tempUR 
				where ReferralRequestReceivedDate is not null
				) r ON r.UniqServReqID = cc.UniqServReqID 
					AND r.Der_Person_ID = cc.Der_Person_ID
					and r.ReferralRequestReceivedDate <= cc.CareContDate
 	left join  [MESH_MHSDS].[MHS102ServiceTypeReferredTo]srf 
										on  srf.UniqServReqID = cc.UniqServReqID						 
										and srf.UniqMonthID = cc.UniqMonthID
										and srf.UniqSubmissionID = cc.UniqSubmissionID 									
   left join [PATLondon].[Ref_Care_Contact_Service_or_Team_Type_Referred_to]stt with(nolock) on stt.Code = srf.ServTeamTypeRefToMH		 

	WHERE cc.AttendStatus in ('5','6') -- attended contacts only
	AND (cc.ConsMechanismMH IN ('01', '02', '04') -- this is face to face, telephone or talk type
	OR (cc.UniqMonthID <1459 AND cc.ConsMechanismMH IN ('03')) -- these two are video but accounting for previous MHSDS versions
	OR (cc.UniqMonthID >=1459 AND cc.ConsMechanismMH IN ('11'))) 
	AND f.Der_IsLatest = 'Y'
	


 
 delete FROM #CC where RowOrder >1
 

 
 DEclare @MaxDate date
 select @MaxDate = (select Max(ReferralRequestReceivedDate) from #tempUR) --'2023-05-31'

 
 IF OBJECT_ID('Tempdb..#RefCC') IS NOT NULL
DROP TABLE #RefCC


select
DISTINCT  
d.UniqServReqID,
d.Der_Person_ID,
d.Der_Pseudo_NHS_Number,
d.[Patient LSOA],
d.[Patient PostCode],
d.OrgIDCCGRes,
d.EmploymentNationalLatest,
d.AccommodationNationalLatest,
ec.[Category] as [Broad Ethnic Category],
case 
	when (d.AgeServReferRecDate <= 18 and d.AgeServReferRecDate is not null) then 'CYP' 
	when (d.AgeServReferRecDate > 18 and d.AgeServReferRecDate is not null) then 'Adult' 
	else 'Missing/Invalid' end as [Age Group],
	CASE 
		WHEN d.AgeServReferRecDate BETWEEN 0 AND 11 THEN '0-11'  
		WHEN d.AgeServReferRecDate BETWEEN 12 AND 17 THEN '12-17'
		WHEN d.AgeServReferRecDate BETWEEN 18 AND 25 THEN '18-25'
		WHEN d.AgeServReferRecDate BETWEEN 26 AND 64 THEN '26-64' 
		WHEN d.AgeServReferRecDate >= 65 THEN '65+' 
		ELSE 'Missing/Invalid' 
	END as AgeCat ,
case 
  when (ec.[Main_Description] = '' OR ec.[Main_Description] = 'Not stated' OR ec.[Main_Description] = 'Not known' OR  ec.[Main_Description] is null) then 'Not Known / Not Stated / Incomplete'
  when ec.Category = 'Asian or Asian British' then 'Asian'
  when ec.Category = 'Black or Black British' then 'Black'
  when ec.[Main_Description] in ('mixed','Any other ethnic group','White & Black Caribbean','Any other mixed background','Chinese') then 'Mixed/ Other'
	ELSE ec.[Category]
END as [Derived Broad Ethnic Category],
cast(null as float) as [Ethnic proportion per 100000 of London Borough 2020],
cast(null as float) as [Ethnic proportion per 100000 of England 2020],
gen.[Main_Description]  as Gender,
ec.[Main_Description] as [Ethnic Category],
gpd.[GP_Name] as [Registered GP Practice Name],
gpd.[Local_Authority] as [Registered GP Local Authority Name],
gpd.[2019_CCG_Name] as [2019 GP CCG NAME],
gpd.[GP_Region_Name] as  [Registered GP Region],
d.ODS_GPPrac_OrgCode,
[Inpatient Services Flag],
[Patietn Region] as [MPI Patient Region],
[MPI GP Code],
ServTeamTypeRefToMH as Service_Team_Type_Code,
[Core Community Service Team Flag],
[Core Community Service Team Flag - OLD],
case 
	when  d.ClinRespPriorityType = '1' then 'Emergency'
	when d.ClinRespPriorityType in ('2','U') then 'Urgent/serious'
	when d.ClinRespPriorityType = '3' then 'Routine'
	when d.ClinRespPriorityType = '4' then 'Very Urgent'
	else 'Not Recorded'
End as [Clinical Priority]
,c.[Type of Service REferred to]
,d.AgeServReferRecDate as [Age at Referral]
,d.SourceOfReferralMH
,d.[Source of Referral]
,d.[Source of Referral - Derived]
,d.[Source of Referral - Simplified]
,pm.Description as [Primary Reason for Referral]
,d.OrgIDProv 
,e.[Organisation_Name] as Provider
,d.OrgIDReferringOrg   as OrgIDReferring
 	,[Referring Organisation]
	,[Referring Org Type]
	,[Referring Care Professional Staff Group]
	,[Reason for Out of Area Referral]
	,[FirstContactEverDate]
 ,d.ReferralRequestReceivedDate
 ,ReferralRequestReceivedTime
,c.CareContDate
,c.CareContTime
,d.ServDischDate
,d.[REferral Rejected Flag] as [Referral Rejection Flag]
,d.ReferRejectionDate
,c.ContactTypeDesc
,ContactTypeSubCategory
,Der_Contact
,[Der_DirectContact]
,[Der_FacetoFaceContact]
,null as [Face to Face Order]

,DATEDIFF(day,d.ReferralRequestReceivedDate,c.CareContDate) as [Days Between Referral and Care Contact]
,DATEDIFF(day,d.ReferralRequestReceivedDate,coalesce(d.ReferRejectionDate,d.ServDischDate,@MaxDate)) as [Days Between Referral and Date Referral Closed or Date of Last Extract]
,ROW_NUMBER() OVER (PARTITION BY d.Der_Person_ID, d.UniqServReqID ORDER BY c.carecontdate ASC, c.careconttime ASC, c.MHS201UniqID ASC) AS Der_ContactOrder


into #RefCC

from #tempUR d
left join #CC c on c.UniqServReqID = d.UniqServReqID 
										AND c.Der_Person_ID = d.Der_Person_ID 
										and c.ReferralRequestReceivedDate = d.ReferralRequestReceivedDate
										and c.CareContDate >= d.ReferralRequestReceivedDate
left join
			(
			SELECT  
			distinct
			[Organisation_Code]
			,[Organisation_Name]
			FROM  [UKHD_ODS].[All_Providers_SCD_1]
			where   [Is_Latest] = 1
		
			)e on e.[Organisation_Code] = d.OrgIDProv 

left join [PATLondon].[Ref_GP_Data] gpd with(nolock) on gpd.GP_Practice_Code = d.ODS_GPPrac_OrgCode
left join [PATLondon].[Ref_Primary_Reason_For_Referral]pm with(nolock) on pm.Code = d.PrimReasonReferralMH
left join [UKHD_Data_Dictionary].[Ethnic_Category_Code_SCD_1]ec with (nolock) on ec.[Main_Code_Text] = d.NHSDEthnicity and ec.is_latest = 1
left join [UKHD_Data_Dictionary].[Person_Gender_Code_SCD_1]gen  with (nolock)on gen.[Main_Code_Text] = d.Gender  and gen.is_latest = 1

where d.ReferralRequestReceivedDate is not  null

 

IF OBJECT_ID('Tempdb..#F2FOrder') IS NOT NULL
DROP TABLE #F2FOrder
 SELECT 
	DISTINCT  
	UniqServReqID,
	Der_ContactOrder,
	 ROW_NUMBER() OVER (
PARTITION BY   UniqServReqID  
ORDER BY   Der_ContactOrder    ) as RowOrder 

into #F2FOrder

 from #RefCC a
 where   a.Der_FacetoFaceContact is not null
  

  update f

  set f.[Face to Face Order] = g.RowOrder


  from  #RefCC f
  inner join #F2FOrder g on g.UniqServReqID = f.UniqServReqID
						and g.Der_ContactOrder = f.Der_ContactOrder
 -----------------------------------------

 update g

	set g.provider = h.[Name]

 from #RefCC g
 left join [UKHD_ODS].[All_Codes_1]h with(nolock) on h.code = g.OrgIDProv
 where g.provider is null


 update g

	set g.[Referring Organisation] = h.[Name],
		g.[Referring Org Type] = h.role

 from #RefCC g
 left join [UKHD_ODS_API].[vwOrganisation_SCD_IsLatestEqualsOneWithRole] h with(nolock) on h.[ODS_code] = g.OrgIDReferring
 where g.[Referring Organisation] is null

 

		update f
		set f.Der_ContactOrder = null
		from #RefCC f
		where CareContDate is null

--replace existing data for new cohort  
delete a  from [PATLondon].[MH_Referrals_with_Care_Contacts_London]a where exists
(
select 
b.UniqServReqID 
from #RefCC b 
where b.UniqServReqID = a.UniqServReqID 

 

IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('[PATLondon].[MH_Referrals_with_Care_Contacts_London]') AND NAME ='ix_Ref_Cont')
DROP INDEX ix_Ref_Cont ON [PATLondon].[MH_Referrals_with_Care_Contacts_London]


Insert into [PATLondon].[MH_Referrals_with_Care_Contacts_London]
	 select 
	 cast(null as BigInt) as [Overall Order]
	 ,a.UniqServReqID
	,a.Der_Person_ID
	,a.Der_Pseudo_NHS_Number
	,a.[Patient LSOA]
	,a.[Patient PostCode]
	,a.Gender
	,a.[Age at Referral]
	,a.[Age Group] as [Age Group at Referral]
	,a.AgeCat as [Age Category at Referral]
	,a.[Ethnic Category]
	,a.[Broad Ethnic Category]
	,a.[Derived Broad Ethnic Category]
	,a.[Ethnic proportion per 100000 of London Borough 2020]
	,a.[Ethnic proportion per 100000 of England 2020]
	,a.EmploymentNationalLatest
	,a.AccommodationNationalLatest
	,coalesce(a.ODS_GPPrac_OrgCode,a.[MPI GP Code]) as [Registered GP Practice OrgCode]
	,a.[Registered GP Practice Name]
	,a.[Registered GP Local Authority Name]
	,a.[2019 GP CCG NAME] as [2019 Registered GP CCG NAME]
	,OrgIDCCGRes 
	,[Registered GP Region]
    ,a.ReferralRequestReceivedDate
	,a.ReferRejectionDate
	,a.ServDischDate
	,a.SourceOfReferralMH
	,a.[Source of Referral]
	,a.[Source of Referral - Derived]
	,a.[Source of Referral - Simplified]
	 
	,a.[Primary Reason for Referral]
	,a.[Clinical Priority]
	,Service_Team_Type_Code
	,a.[Type of Service REferred to] as [Type of Service Referred to]
	,[Referring Organisation]
	,[Referring Org Type]
	,[Referring Care Professional Staff Group]
	,[Reason for Out of Area Referral]
	,[FirstContactEverDate]
	,a.Provider as [Referred to Provider]
	,b.ICS as [Referred to MH Trust ICS Full Name]
	,b.ICB as [Referred to MH Trust ICS Abbrev] 
    ,a.[Core Community Service Team Flag] as [Community Mental Health Team Flag]
	,a.[Core Community Service Team Flag - OLD] as [Core Community Services Flag]
	,a.[Inpatient Services Flag] as [Referral linked to Inpatient Spell Flag]
	,a.CareContDate
	,a.CareContTime
	,a.ContactTypeDesc as [Cotact Type Group]
	,a.ContactTypeSubCategory as [Contact Type Sub Category]
	,a.Der_ContactOrder as [Care Contact Order]
	,a.[Days Between Referral and Care COntact] as [Days Between Referral and Care Contact]
	,null as [Days since previous Care Contact for this referral]
	,a.[Days Between Referral and Date Referral Closed or Date of Last Extract]
	,[Der_Contact]
	,[Der_DirectContact]
	,[Der_FacetoFaceContact]
	,[Face to Face Order]
	,[ReferralRequestReceivedTime]
	,cast(null as bigint) as Der_Direct_Contact_Order
	,Cast(null as varchar(300)) as [Initial referred to Service]
	--into  [PATLondon].[MH_Referrals_with_Care_Contacts_London]
	 from #RefCC a
	 left join [PATLondon].[Ref_Provider_to_ICS_Mapping]b on b.Site = a.Provider

 

	 order by UniqServReqID, ReferralRequestReceivedDate,coalesce(Der_ContactOrder ,1)
 
 
Update f 

set f.[Community Mental Health Team Flag] = null

from [PATLondon].[MH_Referrals_with_Care_Contacts_London]f
 
where f.ReferralRequestReceivedDate >= @fin_yearStart

update g
set g.[Community Mental Health Team Flag] = 1

from [PATLondon].[MH_Referrals_with_Care_Contacts_London]g
 
where [Type of Service REferred to] = 'Community Mental Health Team - Functional'
and g.ReferralRequestReceivedDate >= @fin_yearStart
 

update g
set g.[Core Community Services Flag] = null

from [PATLondon].[MH_Referrals_with_Care_Contacts_London]g
 
 where g.ReferralRequestReceivedDate >= @fin_yearStart



update g
set g.[Core Community Services Flag] = 1

from [PATLondon].[MH_Referrals_with_Care_Contacts_London]g
 
where service_team_type_code in ('A05','A06','A08','A09','A12','A13','A16','C03','C10')
and g.ReferralRequestReceivedDate >= @fin_yearStart
 
 
 Update f

		set f.[Overall Order] = g.OverAllOrder

		from [PATLondon].[MH_Referrals_with_Care_Contacts_London] f
		inner join
					(
 
					Select
					g.UniqServReqID,
					Der_Person_ID,
					ReferralRequestReceivedDate,
					coalesce([Care Contact Order],1) as [Care Contact Order] ,
					(ROW_NUMBER() OVER (  ORDER BY ReferralRequestReceivedDate,g.UniqServReqID ,coalesce([Care Contact Order],1))) AS OverAllOrder  --+ @LastORder AS OverAllOrder

					from [PATLondon].[MH_Referrals_with_Care_Contacts_London]g
					 


					)g on g.UniqServReqID = f.UniqServReqID and coalesce(g.[Care Contact Order],1) = coalesce(f.[Care Contact Order],1)
  


 CREATE INDEX ix_Ref_Cont ON [PATLondon].[MH_Referrals_with_Care_Contacts_London]([Overall Order],UniqServReqID, Der_Person_ID, ReferralRequestReceivedDate)

 
 
	DECLARE @id BIGINT
	SET @id = 0

	UPDATE [PATLondon].[MH_Referrals_with_Care_Contacts_London]

		SET @id = [Overall Order] = @id + 1
		update x
		set x.[Days since previous Care Contact for this referral] = case 
																		when  
																			 (x.[Care Contact Order] is not null and x.[Care Contact Order] > 1)
																			 
																		Then DATEDIFF(day,a.CareContDate,x.CareContDate)
																		else null
																		End
		
	from [PATLondon].[MH_Referrals_with_Care_Contacts_London] x	
 
	LEFT JOIN [PATLondon].[MH_Referrals_with_Care_Contacts_London]a on  a.[Overall Order] = x.[Overall Order] - 1
																	     and a.UniqServReqID = x.UniqServReqID
 
 	update y

	set y.[Ethnic proportion per 100000 of London Borough 2020] = (1/NULLIF(cast(ep.Value as float),0))*100000,
	    y.[Ethnic proportion per 100000 of England 2020] = (1/NULLIF(cast(ee.Value as float),0))*100000

	from [PATLondon].[MH_Referrals_with_Care_Contacts_London] y 
 
	left join [PATLondon].[Ref_Ethnicity_2020_Census_Population_by_London_Borough]ep on ep.[Broad Ethnic Category] = y.[Derived Broad Ethnic Category]
																										and ep.[Borough with NHS Pref] = y.[Registered GP Local Authority Name]
	left join [PATLondon].[Ref_Ethnicity_2020_Census_Population_by_England_Region]ee on ee.Ethnicity = y.[Derived Broad Ethnic Category]
																									and  ee.Area = y.[Registered GP Region]
	where y.[Ethnic proportion per 100000 of London Borough 2020] is null

 

 	DROP TABLE #CC
	DROP TABLE #RefCC
	dROP TABLE #tempUR
	drop table #tempHOc
	drop table #CCPre
	 

  