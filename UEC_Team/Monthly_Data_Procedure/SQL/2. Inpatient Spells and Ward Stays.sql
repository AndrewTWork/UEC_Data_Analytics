 
----------------------------------------------------------------------------------------
 IF OBJECT_ID('Tempdb..#tempSPellURef') IS NOT NULL 
dROP TABLE #tempSPellURef
select
distinct

UniqServReqID

into #tempSPellURef
from [MESH_MHSDS].[MHS501HospProvSpell]
----------------------------------------------------------------------------------------

 IF OBJECT_ID('Tempdb..#tempRef') IS NOT NULL 
dROP TABLE #tempRef
select
distinct
a.UniqServReqID,
ReferralRequestReceivedDate,
[Referring Organisation],
[Referring Org Type],
[Referring Care Professional Staff Group],
[Source of REferral] as [Referral Source],
--[Type of Service Referred to],
[Primary Reason for Referral],
[Clinical Priority],
ServDischDate,
ReferRejectionDate

into #tempRef

  FROM [PATLondon].[MH_Referrals_with_Care_Contacts_London]a
  inner join #tempSPellURef b on b.UniqServReqID = a.UniqServReqID
 
 
----------------------------------------------------------------------------------------------


		IF OBJECT_ID('Tempdb..#TempDiagCodes') IS NOT NULL 
		dROP TABLE #TempDiagCodes
		SELECT  
		[ICD10_L4_Code]

		,LTrim(RTrim(Substring([ICD10_L4_Desc], CharIndex(': ', [ICD10_L4_Desc]) + 1, Len([ICD10_L4_Desc])))) as [ICD10_L4_Desc]
 
		,LTrim(RTrim(Substring([ICD10_L1_Desc], CharIndex(': ', [ICD10_L1_Desc]) + 1, Len([ICD10_L1_Desc])))) as [ICD10_L1_Desc]
 
		,LTrim(RTrim(Substring([ICD10_Chapter_Desc], CharIndex(': ', [ICD10_Chapter_Desc]) + 1, Len([ICD10_Chapter_Desc])))) as [ICD10_Chapter_Desc]
 

		into #TempDiagCodes

		FROM [PATLondon].[Ref_ClinCode_ICD10]
 
DECLARE @fin_yearStart date 

--set @fin_yearStart = '2025-01-01'
set @fin_yearStart = (select dateadd(month, 3, 
                           dateadd(year, 
                                   datepart(year, 
                                            dateadd(month, -3, getdate())) - 1900, 0)))

print @fin_yearStart 


		IF OBJECT_ID('Tempdb..#DiagAll') IS NOT NULL 
		dROP TABLE #DiagAll

		SELECT  
		[Person_ID]
		,[OrgIDProv]
		, ROW_NUMBER() OVER (
		PARTITION BY  [UniqServReqID]
		ORDER BY   UniqMonthID DEsc ,  UniqSubmissionID desc  ) as RowOrder
		,[UniqSubmissionID]
		,[UniqMonthID]
		,[RecordNumber]
		,[RowNumber]
		,[ServiceRequestId]
		,[DiagSchemeInUse]
		,[PrimDiag] as [ICD10_4 Diagnosis Code]
		,'Primary' as [Diagnosis Level]
		,b.ICD10_L4_Desc
		,b.ICD10_L1_Desc
		,b.ICD10_Chapter_Desc
		,[CodedDiagTimestamp] as [Diagnosis Time Stamp]
		,[UniqServReqID]
       
		,[NHSEUniqSubmissionID]
 
		,[Der_Person_ID]

		into #DiagAll

		FROM [MESH_MHSDS].[MHS604PrimDiag]a
		inner join  #TempDiagCodes b on b.[ICD10_L4_Code] = a.[PrimDiag] 
		where  convert(date,[CodedDiagTimestamp])>= @fin_yearStart
	 
		Union All

		SELECT  
		[Person_ID]
		,[OrgIDProv]
		, ROW_NUMBER() OVER (
		PARTITION BY  [UniqServReqID]
		ORDER BY   UniqMonthID DEsc ,  UniqSubmissionID desc  ) as RowOrder
		,[UniqSubmissionID]
		,[UniqMonthID]
		,[RecordNumber]
		,[RowNumber]
		,[ServiceRequestId]
		,[DiagSchemeInUse]
		,[SecDiag] as [ICD10_4 Diagnosis Code]
		,'Secondary' as [Diagnosis Level]
		,b.ICD10_L4_Desc
		,b.ICD10_L1_Desc
		,b.ICD10_Chapter_Desc
		,[CodedDiagTimestamp] as [Diagnosis Time Stamp]
		,[UniqServReqID]
       
		,[NHSEUniqSubmissionID]
 
		,[Der_Person_ID]
 
		FROM [MESH_MHSDS].[MHS605SecDiag]a
		inner join  #TempDiagCodes b on b.[ICD10_L4_Code] = a.[SecDiag] 
		where  convert(date,[CodedDiagTimestamp])>= @fin_yearStart
	 

		union all

		SELECT  
		 [Person_ID]
		,[OrgIDProv]
		, ROW_NUMBER() OVER (
		PARTITION BY  [UniqServReqID]
		ORDER BY   UniqMonthID DEsc ,  UniqSubmissionID desc  ) as RowOrder
		,[UniqSubmissionID]
		,[UniqMonthID]
		,[RecordNumber]
		,[RowNumber]
		,[ServiceRequestId]
		,[DiagSchemeInUse]
		,[ProvDiag] as [ICD10_4 Diagnosis Code]
		,'Provisional' as [Diagnosis Level]
		,b.ICD10_L4_Desc
		,b.ICD10_L1_Desc
		,b.ICD10_Chapter_Desc
		,[CodedProvDiagTimestamp] as [Diagnosis Time Stamp]
		,[UniqServReqID]
       
		,[NHSEUniqSubmissionID]
 
		,[Der_Person_ID]
 

		FROM [MESH_MHSDS].[MHS603ProvDiag]a
		inner join  #TempDiagCodes b on b.[ICD10_L4_Code] = a.[ProvDiag] 
		where  convert(date,[CodedProvDiagTimestamp])>= @fin_yearStart
	 

  delete from #DiagAll where RowOrder <> 1

 

		insert into [PATLondon].[MH_Referrals_Diagnoses] 
		select 
		* 
	 
		from #DiagAll a
		where not exists (
							select 
							[UniqServReqID],
							[Diagnosis Level] 
							from [PATLondon].[MH_Referrals_Diagnoses] x 
							where x.UniqServReqID = a.UniqServReqID 
							and x.[Diagnosis Level] = a.[Diagnosis Level]
						)


		update f
		set f.Der_Person_ID = g.Der_Person_ID,
		f.[Diagnosis Time Stamp] = g.[Diagnosis Time Stamp],
		f.[ICD10_4 Diagnosis Code] = g.[ICD10_4 Diagnosis Code],
		f.ICD10_Chapter_Desc = g.ICD10_Chapter_Desc,
		f.ICD10_L1_Desc = g.ICD10_L1_Desc,
		f.ICD10_L4_Desc = g.ICD10_L4_Desc,
		f.NHSEUniqSubmissionID = g.NHSEUniqSubmissionID,
		f.OrgIDProv = g.OrgIDProv,
		f.Person_ID = g.Person_ID,
		f.RecordNumber = g.RecordNumber,
		f.ServiceRequestId = g.ServiceRequestId,
		f.UniqSubmissionID = g.UniqSubmissionID

		from [PATLondon].[MH_Referrals_Diagnoses] f
		inner join #DiagAll g on g.UniqServReqID = f.UniqServReqID
									and g.UniqMonthID > f.UniqMonthID
									and g.[Diagnosis Level] = f.[Diagnosis Level]




		drop table #DiagAll
		 
 
Declare @EndDate Date, @LastDate Date, @DateSerial int
set @LastDate = (select max(StartDateHospProvSpell) from [MESH_MHSDS].[MHS501HospProvSpell_2] )
set @EndDate =   EOMONTH(@LastDate) 
set @DateSerial = (select UniqMonthID from [PATLondon].[Ref_Other_Dates] where MonthEndDate = @EndDate)
 

IF OBJECT_ID('Tempdb..#temp11') IS NOT NULL 
dROP TABLE #temp11

select 
distinct
 
ROW_NUMBER() OVER (
PARTITION BY  a.UNIQHOSPPROVSPELLID  
ORDER BY  a.UniqMonthID DEsc , a.UniqSubmissionID desc,gp.rowNumber desc ) as RowOrder,
gpd.GP_Name as GP_Practice_Name,
gpd.Local_Authority as [Local Authority Name],
gpd.PCDS_NoGaps as ODS_GPPrac_PostCode,
gpd.GP_Practice_Code as ODS_GPPrac_OrgCode  ,
coalesce(LEFT( gpd.Local_Authority, CHARINDEX('ICB ', gpd.Local_Authority + 'ICB ') - 1),[2019_CCG_Name]) as [Patient GP Practice CCG],
gpd.[GP_Region_Name] as [Patient GP Practice Region],
gpd.[2019_CCG_Name] as [2019 Patient GP Practice CCG],


a.RecordNumber,
a.UniqServReqID,
a.OrgIDProv,
b.Der_Person_ID,
a.Person_ID,
b.OrgIDCCGRes as [patients postcode ccg],
 COALESCE(o3.Organisation_Name,'Missing/Invalid') AS [CCG name by PatPostcode],
 o3.STP_Name as [STP name by PatPostcode],
 o3.Region_Name [Region name by PatPostcode],
 b.LSOA2011,
 LAD17NM as LAName,
 h.Trust as [Res MH Trust by PatPostcode],
 h.ICS as [ICB of Res MH Trust by PatPostcode],
 h.Borough as [ Borough Res MH Trust by PatPostcode],
coalesce(b.Der_Pseudo_NHS_Number,'') as Der_Pseudo_NHS_Number, 
EthnicCategory,
Gender,
prov.[ICD10_4 Diagnosis Code] as [Provisional Diag Code],
prov.[ICD10_L4_Desc] as [Prov. Diag Desc],
prov.[ICD10_Chapter_Desc] as [Prov. Diag Chapter],
prim.[ICD10_4 Diagnosis Code] as [Primary Diag Code],
prim.[ICD10_L4_Desc] as [Prim. Diag Desc],
prim.[ICD10_Chapter_Desc] as [Prim. Diag Chapter],
sec.[ICD10_4 Diagnosis Code] as [Secondary Diag Code],
sec.[ICD10_L4_Desc] as [Sec. Diag Desc],
sec.[ICD10_Chapter_Desc] as [Sec. Diag Chapter],
HospProvSpellID,
b.UniqMonthID,
a.UniqSubmissionID,
A.UNIQHOSPPROVSPELLID,
StartDateHospProvSpell,
StartTimeHospProvSpell  ,
A.SourceAdmMHHospProvSpell AS SourceAdmCodeHospProvSpell,
a.MethAdmMHHospProvSpell as AdmMethCodeHospProvSpell,
EstimatedDischDateHospProvSpell,
PlannedDischDateHospProvSpell ,
DischDateHospProvSpell,
DischTimeHospProvSpell ,
PlannedDestDisch,
destOfdischhospProvSpell,
CASE WHEN A.DischDateHospProvSpell IS NOT NULL THEN 'Closed'
	WHEN A.DischDateHospProvSpell IS NULL AND a.UniqMonthID >= @DateSerial THEN 'Open'
	WHEN A.DischDateHospProvSpell IS NULL AND a.UniqMonthID < @DateSerial THEN 'Inactive'
	END AS AdmissionCat,
CASE
when DischDateHospProvSpell is not null 
then DATEDIFF(DAY, startDateHospProvSpell, DischDateHospProvSpell)+1 
else null
end AS [HOSP_LOS],
case
when DischDateHospProvSpell is  null 
then DATEDIFF(day,A.StartDateHospProvSpell, coalesce(A.DischDateHospProvSpell,@EndDate) )+1 
else null
end as [HOSP_LOS at Last Update for Incomplete Spells],
a.SourceAdmMHHospProvSpell,
a.MethAdmMHHospProvSpell  
 
into #temp11
 from [MESH_MHSDS].[MHS501HospProvSpell_2]  a
 INNER JOIN [MESH_MHSDS].[MHSDS_SubmissionFlags_1]  s ON s.NHSEUniqSubmissionID = a.NHSEUniqSubmissionID AND s.Der_IsLatest = 'Y'
 left join [MESH_MHSDS].[MHS001MPI_2]b on b.Person_ID = a.Person_ID
											--and b.UniqSubmissionID = a.UniqSubmissionID
											and b.UniqMonthID = a.UniqMonthID
											and b.RecordNumber = a.RecordNumber
left join [MESH_MHSDS].[MHS002GP_2]gp on gp.RecordNumber = a.RecordNumber 
left join [PATLondon].[Ref_GP_Data] gpd on gpd.GP_Practice_Code = gp.GMPReg
left join [PATLondon].[MH_Referrals_Diagnoses]prov on prov.UniqServReqID = a.UniqServReqID and prov.[Diagnosis Level] = 'Provisional'
left join [PATLondon].[MH_Referrals_Diagnoses]prim on prim.UniqServReqID = a.UniqServReqID and prim.[Diagnosis Level] = 'Primary'
left join [PATLondon].[MH_Referrals_Diagnoses]sec  on sec.UniqServReqID = a.UniqServReqID and sec.[Diagnosis Level] = 'Secondary'
LEFT JOIN [Reporting_UKHD_ODS].[Commissioner_Hierarchies] o3 ON coalesce(b.OrgIDCCGRes,b.OrgIDSubICBLocResidence) = o3.Organisation_Code 
left join [PATLondon].[Ref_LSOAMap2] as la on la.LSOA11CD=b.LSOA2011
left join [PATLondon].[Ref_Borough_Trust_Mapping]h on h.Borough =la.[LAD17NM]
     
 
 delete from #temp11 where RowOrder <> 1
 
 

		IF OBJECT_ID('Tempdb..#WardAtAdmission') IS NOT NULL 
		dROP TABLE #WardAtAdmission
 
		select 
		distinct
		a.recordnumber,
		a.Der_Person_ID,
		a.Person_ID,

		null as WardStayOrder,
		ROW_NUMBER() OVER (
		PARTITION BY  a.UNIQHOSPPROVSPELLID , a.wardstayID
		ORDER BY a.UniqMonthID, a.UniqSubmissionID    asc 
		) as MonthRowOrder ,
		a.UniqMonthID,
		null as [Last Submission],
		a.UniqHospProvSpellID,
		a.UniqWardStayID,
		a.UniqSubmissionID  ,
		case
		WHEN  MHAdmittedPatientClass IN ('10','200','11','201','12','202') THEN 'Adult Acute (CCG commissioned)' 
		WHEN  MHAdmittedPatientClass IN ('13','203','14','204','15','16','17','18','19','20','21','22','205',
									'206','207','208','209','210','211','212','213') THEN 'Adult Specialist' 
		WHEN  MHAdmittedPatientClass IN ('23','24','25','26','27','28','29','30','31','32','33','34','300',
								'301','302','303','304','305','306','307','307','308','309','310','311') THEN 'CYP' 
		ELSE 'Missing/Invalid'  
		END as AdmissionTypeNHSE,
		CASE 
		WHEN MHAdmittedPatientClass in ('10') THEN 'Adult acute'
		WHEN MHAdmittedPatientClass in ('11') THEN 'Older adult acute'
		WHEN MHAdmittedPatientClass in ('12', '13', '14', '15', '17', '19', '20', '21', '22', '35', '36', '37', '38', '39', '40') THEN 'Adult specialist'
		WHEN MHAdmittedPatientClass in ('23', '24') THEN 'CYP acute'
		WHEN MHAdmittedPatientClass in ('25', '26', '27', '28', '29', '30' ,'31', '32', '33' ,'34') THEN 'CYP specialist'
		ELSE 'Unknown'
		end as AdmissionType_MHUEC, 

		HospitalBedTypeName,
		b.UniqServReqID,
		ISNULL(SpecialisedMHServiceCode, 'Non Specialised Service') AS SpecialisedMHServiceCode, -- Identify if and what specialised activity the spell relates to
		a.OrgIDProv,
		a.SiteIDOfWard as SiteIDOfTreat,
		a.WardType,
		a.WardIntendedSex as WardSexTypeCode,
		a.WardCode,
		 a.MHAdmittedPatientClass  as HospitalBedTypeMH,
		
		a.WardLocDistanceHome,
		cast(null as date) as Start_DateWardStay,
		cast(null as time) as Start_TimeWardStay,
		cast(null as date) as End_DateWardStay,
		cast(null as time) as End_TimeWardStay,
		BedDaysWSEndRP,
		Der_Age_at_StartWardStay ,      
		a.[EFFECTIVE_FROM],
		case 
		when bb.[Main_Code_Text] is not null 
		then coalesce(bb.[Main_Description_60_Chars], 'Not known (not recorded)') 
		else null
		end as [Main Reason for AWOL],
		[StartDateMHAbsWOLeave],
		[StartTimeMHAbsWOLeave],
		[EndDateMHAbsWOLeave],
		[EndTimeMHAbsWOLeave],
		[AWOLDaysEndRP] as [AWOL Days],
		[PoliceAssistArrDate],
		[PoliceAssistArrTime],
		[PoliceAssistReqDate],
		[PoliceAssistReqTime],
		[PoliceRestraintForceUsedInd],
	    [StartDateMHLeaveAbs],
        [StartTimeMHLeaveAbs],
		[EndDateMHLeaveAbs],
        [EndTimeMHLeaveAbs],
	    [LOADaysRP],
		case 
		when bbb.[Main_Code_Text] is not null
        then coalesce(bbb.[Main_Description_60_Chars], 'Not known (not recorded)') 
		else null
		end as [MHLeaveAbsEndReason]
		into #WardAtAdmission

		from [MESH_MHSDS].[MHS502WardStay_2] a
		 INNER JOIN [MESH_MHSDS].[MHSDS_SubmissionFlags_1] s ON s.NHSEUniqSubmissionID = a.NHSEUniqSubmissionID AND s.Der_IsLatest = 'Y'     
		inner join #temp11 b on b.UniqHospProvSpellID = a.UniqHospProvSpellID
							    and b.RecordNumber = a.RecordNumber 
		left join [MESH_MHSDS].[MHS516PoliceAssistanceRequest]par on par.[UniqWardStayID] = a.[UniqWardStayID]
															and par.[UniqHospProvSpellID] = a.[UniqHospProvSpellID]
															and par.[UniqServReqID] = a.[UniqServReqID]

		left join [MESH_MHSDS].[MHS511AbsenceWithoutLeave]awl on awl.[UniqWardStayID] = a.[UniqWardStayID]
															   and awl.[UniqHospProvSpellID] = a.[UniqHospProvSpellID]
															   and awl.[UniqServReqID] = a.[UniqServReqID]
		left join [UKHD_Data_Dictionary].[Mental_Health_Leave_Of_Absence_End_Reason_SCD_1]bb on bb.[Main_Code_Text] = awl.[MHAbsWOLeaveEndReason]
	    left join [MESH_MHSDS].[MHS510LeaveOfAbsence] loa on loa.[UniqWardStayID] = a.[UniqWardStayID]
														   and loa.[UniqHospProvSpellID] = a.[UniqHospProvSpellID]
														   and loa.[UniqServReqID] = a.[UniqServReqID]
		left join [UKHD_Data_Dictionary].[Mental_Health_Leave_Of_Absence_End_Reason_SCD]bbb on bbb.[Main_Code_Text] = loa.[MHLeaveAbsEndReason]
	 
		update f
		set f.[Last Submission] = 1

		from #WardAtAdmission f
		inner join 
		(
		select 
		 UniqWardStayID,
		UniqHospProvSpellID,
		Max(MonthRowORder) as LastSumbit 
		
		from #WardAtAdmission
		group by
	 UniqWardStayID,UniqHospProvSpellID
		)g on g.UniqWardStayID = f.UniqWardStayID
			and g.UniqHospProvSpellID = f.UniqHospProvSpellID
			and g.LastSumbit = f.MonthRowOrder


	delete  from #WardAtAdmission  where [Last Submission] is null


	update DT

	set dt.Start_DateWardStay = b.StartDateWardStay,
		dt.Start_TimeWardStay = b.StartTimeWardStay,
		dt.End_DateWardStay = b.EndDateWardStay,
		dt.End_TimeWardStay = b.EndTimeWardStay,
		dt.BedDaysWSEndRP = b.BedDaysWSEndRP,
		dt.Der_Age_at_StartWardStay = b.Der_Age_at_StartWardStay



	from #WardAtAdmission dt
	inner join [MESH_MHSDS].[MHS502WardStay_2] b on b.Der_Person_ID = dt.Der_Person_ID
													and b.UniqHospProvSpellID = dt.UniqHospProvSpellID
													and b.UniqMonthID = dt.UniqMonthID
													and b.UniqSubmissionID = dt.UniqSubmissionID
													and b.UniqServReqID = dt.UniqServReqID
													and b.UniqWardStayID = dt.UniqWardStayID




	 update r
		set r.WardStayOrder = g.WardStayOrder
	 from #WardAtAdmission r
		inner join 
		(
		select 
		UniqHospProvSpellID,
		UniqWardStayID,
			ROW_NUMBER() OVER (
		PARTITION BY  UNIQHOSPPROVSPELLID 
		ORDER BY Start_DateWardStay,Start_TimeWardStay  asc 
		) as WardStayOrder
		from #WardAtAdmission
	 
		)g on g.UniqHospProvSpellID = r.UniqHospProvSpellID
			and g.UniqWardStayID = r.UniqWardStayID
		 


		 --select top 5000 * from #WardAtAdmission




		 delete a  from [PATLondon].[MH_Ward_Stays]		a where exists
(select b.[UniqHospProvSpellID] from #WardAtAdmission b where b.[UniqHospProvSpellID] = a.[UniqHospProvSpellID] )  

IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('[PATLondon].[MH_Ward_Stays]') AND NAME ='ix_WardStay_Num')
DROP INDEX ix_WardStay_Num ON [PATLondon].[MH_Ward_Stays]	

insert into [PATLondon].[MH_Ward_Stays]	

select 
*
 	
from #WardAtAdmission


   CREATE INDEX ix_WardStay_Num ON [PATLondon].[MH_Ward_Stays] ( UniqHospProvSpellID,UniqWardStayID,  Der_Person_ID, WardStayOrder)

 

delete a  from [PATLondon].[MH_Spells]		a where exists
(select b.[UniqHospProvSpellID] from #temp11 b where b.[UniqHospProvSpellID] = a.[UniqHospProvSpellID] )  

IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('[PATLondon].[MH_Spells]') AND NAME ='ix_Spell_Num')
DROP INDEX ix_Spell_Num ON [PATLondon].[MH_Spells]	

 
insert into [PATLondon].[MH_Spells]	

select 
a.[UniqMonthID] ,
a.[UniqHospProvSpellID] ,
a.UniqSubmissionID,
a.[Person_ID]  ,
a.[Der_Person_ID] ,
a.[Der_Pseudo_NHS_Number] ,
ODS_GPPrac_OrgCode,
[GP_Practice_Name],
[ODS_GPPrac_PostCode],
[Local Authority Name],
[2019 Patient GP Practice CCG] as [2019 GP CCG NAME],
[Patient GP Practice Region],



gen.Main_Description as [Gender] ,
ec.[Main_Description] as [Ethnic Category] ,
ec.[Category]as [Broad Ethnic Category] ,
case 
when (ec.[Main_Description] = '' OR ec.[Main_Description] = 'Not stated' OR ec.[Main_Description] = 'Not known' OR  ec.[Main_Description] is null) then 'Not Known / Not Stated / Incomplete'
when ec.Category = 'Asian or Asian British' then 'Asian'
when ec.Category = 'Black or Black British' then 'Black'
when ec.[Main_Description] in ('mixed','Any other ethnic group','White & Black Caribbean','Any other mixed background','Chinese') then 'Mixed/ Other'
ELSE ec.[Category]
END as [Derived Broad Ethnic Category],
[patients postcode ccg],
[CCG name by PatPostcode],
[STP name by PatPostcode],
[Region name by PatPostcode],
a.LSOA2011,

LAName as [Pat Postcode Lan Name],
[Res MH Trust by PatPostcode],
[ICB of Res MH Trust by PatPostcode],
[ Borough Res MH Trust by PatPostcode],
a.[OrgIDProv] ,
o1.Organisation_Name as [Provider_Name]   ,
pt.[Postcode] as [Provider_PostCode],
tm.ICS as [Provider ICS Full Name],
tm.ICB as [Provider ICS Abbrev] ,
o1.Region_Name as [Provider Region Name],
d.[Organisation_Name] as [Admission Site Name],
 
CASE 
WHEN o1.ODS_Organisation_Type = 'NHS TRUST' THEN 'NHS TRUST'
WHEN o1.ODS_Organisation_Type = 'CARE TRUST' THEN 'NHS TRUST' 
WHEN o1.ODS_Organisation_Type IN ('INDEPENDENT SECTOR HEALTHCARE PROVIDER','INDEPENDENT SECTOR H/C PROVIDER SITE','NON-NHS ORGANISATION') THEN 'NON-NHS TRUST' 
ELSE 'Missing/Invalid'  
END as Provider_Type,
COALESCE(o2.Region_Code,'Missing/Invalid') AS Region_Code, --- regions taken from CCG rather than provider 
COALESCE(o2.Region_Name,'Missing/Invalid') AS Region_Name,
COALESCE(cc.New_Code,s.OrgIDCCGRes,'Missing/Invalid') AS CCGCode,
COALESCE(o2.Organisation_Name,'Missing/Invalid') AS [CCG name],
COALESCE(o2.STP_Code,'Missing/Invalid') AS STPCode,
COALESCE(o2.STP_Name,'Missing/Invalid') AS [STP name],
CASE WHEN s.AgeRepPeriodStart < 18 THEN '0-17'
WHEN s.AgeRepPeriodStart BETWEEN 18 AND 24 THEN '18-24'
WHEN s.AgeRepPeriodStart BETWEEN 25 AND 34 THEN '25-34'
WHEN s.AgeRepPeriodStart BETWEEN 35 AND 44 THEN '35-44'
WHEN s.AgeRepPeriodStart BETWEEN 45 AND 54 THEN '45-54'
WHEN s.AgeRepPeriodStart BETWEEN 55 AND 64 THEN '55-64'
WHEN s.AgeRepPeriodStart > 64 THEN '65+' 
ELSE 'Missing/Invalid' END AS AgeBand, -- Create age bands
ref.[AgeServReferRecDate] ,
CASE 
WHEN ref.AgeServReferRecDate BETWEEN 0 AND 17 THEN '0-17' 
WHEN ref.AgeServReferRecDate >=18 THEN '18+' 
END as [AgeCat]  ,
a.[UniqServReqID]  ,
ref.ReferralRequestReceivedDate,
convert(Date,DATEADD(month, DATEDIFF(month, 0, convert(Date,ref.ReferralRequestReceivedDate)), 0)) as [RefMonth]  ,
cast(null as varchar(400)) as [Referring Organisation],
cast(null as varchar(400)) as [Referring Org Type],
cast(null as varchar(400)) as [Referring Care Professional Staff Group],
cast(null as varchar(400)) as [Referral Source],
cast(null as varchar(400)) as [Primary Reason for Referral],
cast(null as varchar(255)) as [Clinical Priority],
cast(null as float) as [Ethnic proportion per 100000 of London Borough 2020],
cast(null as float) as [Ethnic proportion per 100000 of England 2020],
a.[RecordNumber] ,
[Provisional Diag Code],
[Prov. Diag Desc],
[Prov. Diag Chapter],
[Primary Diag Code],
[Prim. Diag Desc],
[Prim. Diag Chapter],
[Secondary Diag Code],
[Sec. Diag Desc],
[Sec. Diag Chapter],
[StartDateHospProvSpell] ,
[StartTimeHospProvSpell] ,
DATEADD(MONTH, DATEDIFF(MONTH, 0,[StartDateHospProvSpell]), 0)  as [Adm_MonthYear]  ,
[SourceAdmCodeHospProvSpell] ,
CASE WHEN [SourceAdmCodeHospProvSpell] = '19' THEN 'Usual place of residence'
WHEN [SourceAdmCodeHospProvSpell] = '29' THEN 'Temporary place of residence'
WHEN [SourceAdmCodeHospProvSpell] IN ('37', '40', '42') THEN 'Criminal setting'
WHEN [SourceAdmCodeHospProvSpell] IN ('49', '51', '52', '53') THEN 'NHS healthcare provider'
WHEN [SourceAdmCodeHospProvSpell] = '87' THEN 'Independent sector healthcare provider' 
WHEN [SourceAdmCodeHospProvSpell] IN ('55', '56', '66', '88') THEN 'Other'
WHEN [SourceAdmCodeHospProvSpell] = NULL THEN 'Null'
ELSE 'Missing/Invalid' END AS SourceOfAdmission, -- Create source of admission groups
moa.description as [Der_AdmissionMethod]  ,
[HospitalBedTypeMH]  ,
b.SpecialisedMHServiceCode as [Specialised Service Code for Initial Ward Admission],
  CASE 
WHEN  HospitalBedTypeMH IN ('10','200','11','201','12','202') THEN 'Adult Acute (CCG commissioned)' 
WHEN  HospitalBedTypeMH IN ('13','203','14','204','15','16','17','18','19','20','21','22','205',
							'206','207','208','209','210','211','212','213') THEN 'Adult Specialist' 
WHEN  HospitalBedTypeMH IN ('23','24','25','26','27','28','29','30','31','32','33','34','300',
							'301','302','303','304','305','306','307','307','308','309','310','311') THEN 'CYP' 
ELSE 'Missing/Invalid'  
END as[BedType_Category]  ,
ISNULL(scdb.Description,'Missing/Invalid') AS [BedType] ,
CASE WHEN hs.OrgIDComm IN ('13N', '13R', '13V', '13X', '13Y', '14C', '14D', '14E', '14F', '14G', '85J', '27T', '14A', '14E', '14G', '14F', '13R','L5H9Q',
'N8S0C','Q7O8U','X8H3R','P7L6U','F3I2L','S7T0C','Z1U2L','C9Z7X','F9H5S','K5B5Y','S6Z6H','J3T7D','I0H0N','O5V1Z','E2S1E','A8R9E','S5L0S','N5T4E','O6H3T',
'I2T5F','K4Z4O','Z0X9Q','B9Q0L','I3Q3V','X4I1M','N9S3D','D8D1G','Z4P6N','D4U5V','P9W2J','L4H0W','B5S8O','G1U9X','X6C7V','C8S2X','R7G8O','H3F5A','I4B8X',
'X4L0A','B0N9F','N5E8H','M4X2K','A3Y0R','W6B3O','O1N4A','Z0B3G') THEN 'Yes'
ELSE 'No' END AS SpecCommCode,  
[EstimatedDischDateHospProvSpell] ,
[PlannedDischDateHospProvSpell] ,
pdd.[Description] AS [Planned Discharge Destination] ,
[DischDateHospProvSpell]  ,
[DischTimeHospProvSpell]  ,
dd.[Description] AS [Discharge Destination]  ,
ROW_NUMBER()OVER(PARTITION BY A.Person_ID,  A.[UniqHospProvSpellID] ORDER BY REF.RecordNumber DESC) [RN] ,
CASE 
WHEN DischDateHospProvSpell is not null and ([HOSP_LOS] >=1 AND [HOSP_LOS]   <8)  THEN 'Up to 1 week'
WHEN DischDateHospProvSpell is not null and ([HOSP_LOS] >=8 AND [HOSP_LOS]   <15)  THEN 'BTWn 1 and 2 wks'
WHEN DischDateHospProvSpell is not null and ([HOSP_LOS] >=15 AND [HOSP_LOS]  <31) THEN 'Btwn 2wks and 1mth'
WHEN DischDateHospProvSpell is not null and ([HOSP_LOS] >=31 AND [HOSP_LOS]  <91) THEN 'BTWn 1 mth and 3mths'
WHEN DischDateHospProvSpell is not null and ([HOSP_LOS] >=91 AND [HOSP_LOS]  <181) THEN 'BTWn 3 mths and 6 mths'
WHEN DischDateHospProvSpell is not null and ([HOSP_LOS] >=181 AND [HOSP_LOS] <366) THEN 'BTWn 6 mths and 1 yr'
WHEN DischDateHospProvSpell is not null and ([HOSP_LOS] >=366) THEN '1 yr and above'
eND aS [loS Tranche],
Case
WHEN DischDateHospProvSpell is not null and ([HOSP_LOS]   >=60 and [HOSP_LOS]  < 90)  THEN 'Stranded'
when DischDateHospProvSpell is not null and ([HOSP_LOS]   >=90) then 'Super Stranded'
Else null
End as 'Stranded_Status',
 [HOSP_LOS],
 [HOSP_LOS at Last Update for Incomplete Spells],
a.AdmissionCat AS Der_HospSpellStatus ,
null as [Male Psychosis 18-44 Flag],
null as [Male Personality Disorder 18-44 Flag],
null as [BiPolar Flag],
CAST(null as varchar(255)) as UniqMHActEpisodeID,
CAST(null as varchar(255)) as SectionType,
CAST(null as varchar(255)) as [NHS LEgal Status Description],
cast(null as date) as [Legal Status Start Date],
cast(null as time) as [Legal Status Start Time],
cast(null as date) as [Legal Status End Date],
cast(null as time) as [Legal Status End Time],
CAST(null as varchar(255)) as [Linked S136 Prior to Adm],
CAST(null as varchar(255)) as [Known to MH Services Flag],
null as [AWOL FLag],
cast(null as varchar(100)) as [AWOL Wardstay ID],
cast(null as varchar(100)) as [Admission Type]

 --into [PATLondon].[MH_Spells]	
from  #temp11 a    
left join #WardAtAdmission b on b.UniqHospProvSpellID = a.UniqHospProvSpellID and b.wardstayorder = 1
 
left join [MESH_MHSDS].[MHS001MPI_2]s on s.Der_Person_ID = a.Der_Person_ID
		and s.UniqSubmissionID = a.UniqSubmissionID
		and s.UniqMonthID = a.UniqMonthID
		and s.RecordNumber = a.RecordNumber
LEFT JOIN [Reporting_UKHD_ODS].[Provider_Hierarchies] o1 ON a.OrgIDProv = o1.Organisation_Code 
LEFT JOIN [Internal_Reference].[ComCodeChanges_1]cc ON s.OrgIDCCGRes = cc.Org_Code
-- Temporary fix before 2021 CCGs come into effect 
LEFT JOIN [Reporting_UKHD_ODS].[Commissioner_Hierarchies] o2 ON COALESCE(cc.New_Code,s.OrgIDCCGRes) = o2.Organisation_Code
left join [MESH_MHSDS].[MHS101Referral_1]ref on ref.UniqServReqID = a.UniqServReqID
							and ref.RecordNumber = a.RecordNumber
							and ref.UniqMonthID = a.UniqMonthID
							and ref.UniqSubmissionID = a.UniqSubmissionID
LEFT JOIN [MESH_MHSDS].[MHS001MPI_2] mp on mp.RecordNumber = a.RecordNumber
left join [Reporting_UKHD_ODS].[Commissioner_Hierarchies]t on t.Organisation_Code = mp.OrgIDCCGRes

left join [UKHD_Data_Dictionary].[Ethnic_Category_Code_SCD_1]ec with (nolock) on ec.[Main_Code_Text] = mp.NHSDEthnicity
left join [UKHD_Data_Dictionary].[Person_Gender_Code_SCD_1]gen  with (nolock)on gen.[Main_Code_Text] = mp.Gender

 
left join [PATLondon].[Ref_Method_of_Admission]moa on moa.code = a.AdmMethCodeHospProvSpell
LEFT JOIN [PATLondon].[Ref_Mental_Health_Admitted_Patient_Classification] scdb ON b.HospitalBedTypeMH = scdb.[Code] 
--[UKHD_Data_Dictionary].[Mental_Health_Admitted_Patient_Classification_SCD_1]
left join [PATLondon].[Ref_Discharge_Destination]pdd on cast(pdd.code as varchar(10)) =  PlannedDestDisch 
left join [PATLondon].[Ref_Discharge_Destination]dd on cast(dd.code as varchar(10)) =  destOfdischhospProvSpell 
LEFT JOIN [MESH_MHSDS].[MHS512HospSpellComm] hs ON hs.RecordNumber = a.RecordNumber AND hs.UniqHospProvSpellID = a.UniqHospProvSpellID -- Get specialised activity information for each admission / hospital spell, for each month. May be bringing in duplicates via multiple ward stays, but 'duplicates' flag and select distinct in metrics will void these.
left join [UKHD_ODS].[NHS_Trust_Sites_Assets_And_Units_SCD]d on d.[Organisation_Code] = b.SiteIDOfTreat and d.[Is_Latest] = 1
left join [UKHD_ODS].[NHS_Trusts_SCD]pt on pt.[Organisation_Code] = a.OrgIDProv and pt.[Is_Latest] = 1
 
left join [PATLondon].[Ref_ICS_Trust_Mapping]tm on tm.Site = o1.Organisation_Name 

 
 delete from  [PATLondon].[MH_Spells]	where rn <>1

 
  
   CREATE INDEX ix_Spell_Num ON [PATLondon].[MH_Spells] ( UniqHospProvSpellID,  Der_Person_ID, [StartDateHospProvSpell])

 

 update r 
 
		set r.[Male Psychosis 18-44 Flag] = 1
 
 
 from [PATLondon].[MH_Spells] r
  where
  
  (
 charindex('psychosis',[Prov. Diag Desc])>0 OR 
 charindex('psychosis',[Prim. Diag Desc])>0 OR 
 charindex('psychosis',[Sec. Diag Desc])>0
 )
 AND
 ([AgeServReferRecDate] >= 18 and [AgeServReferRecDate] <= 44)
 AND
 Gender = 'Male'



  update r 
 
		set r.[Male Personality Disorder 18-44 Flag] = 1
 
 
 from [PATLondon].[MH_Spells] r
  where 
 (
 charindex('personality',[Prov. Diag Desc])>0 OR 
 charindex('personality',[Prim. Diag Desc])>0 OR 
 charindex('personality',[Sec. Diag Desc])>0
 )
 AND
 ([AgeServReferRecDate] >= 18 and [AgeServReferRecDate] <= 44)
 AND
 Gender = 'Male'




   update r 
 
		set r.[BiPolar Flag] = 1
 
 
 from [PATLondon].[MH_Spells] r
 where 
 (
 charindex('bipolar',[Prov. Diag Desc])>0 OR 
 charindex('bipolar',[Prim. Diag Desc])>0 OR 
 charindex('bipolar',[Sec. Diag Desc])>0
 )


  
	 
	update y


	set y.[Ethnic proportion per 100000 of London Borough 2020] = cast((1/NULLIF(ep.Value,0))* 100000  as float),
	    y.[Ethnic proportion per 100000 of England 2020] = cast((1/NULLIF(ee.Value,0))*100000 as float)

	from [PATLondon].[MH_Spells]y 
	left join [PATLondon].[Ref_Ethnicity_2020_Census_Population_by_London_Borough]ep on ep.[Broad Ethnic Category] = y.[Derived Broad Ethnic Category]
																										and ep.[Borough with NHS Pref] = y.[Local Authority Name]
	left join [PATLondon].[Ref_Ethnicity_2020_Census_Population_by_England_Region]ee on ee.Ethnicity = y.[Derived Broad Ethnic Category]
 

update ws
		set ws.[AWOL Flag] = 1,
		ws.[AWOL WardStay ID] = g.UniqWardStayID

from [PATLondon].[MH_Spells]ws
inner join [PATLondon].[MH_Ward_Stays] g on g.UniqHospProvSpellID = ws.UniqHospProvSpellID
									   and g.StartDateMHAbsWOLeave is not null
																									
IF OBJECT_ID('Tempdb..#IPSpells') IS NOT NULL 
dROP TABLE #IPSpells

select
distinct
Der_Pseudo_NHS_Number ,
[DischDateHospProvSpell]

into #IPSpells

from [PATLondon].[MH_Spells]
where Der_Pseudo_NHS_Number is not null

 

 
		
  	 update x

	 set x.[Known to MH Services Flag] = case
									 
										when 
										   ( datediff(day, ccc.ReferralRequestReceivedDate,convert(date,x.StartDateHospProvSpell) )>= 0 
										 and datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date,x.StartDateHospProvSpell)) <=6  

										 )		
										   then 1							 
										When
											(
												(datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date, StartDateHospProvSpell))>6 )
											and (ccc.ServDischDate is null or (ccc.ServDischDate > StartDateHospProvSpell))
											and (ReferRejectionDate is null or (ReferRejectionDate > StartDateHospProvSpell))
											)
									 
										  then 1 
										else null
										end 

	 from [PATLondon].[MH_Spells] x
	left join #tempRef ccc on ccc.UniqServReqID = x.UniqServReqID	
	and ccc.ReferralRequestReceivedDate <= x.StartDateHospProvSpell

	

	update f

		 set f.[Known to MH Services Flag] = case
											  when ccc.[Referral Source] = 'Acute Secondary Care: Emergency Care Department'  
													then null
												else f.[Known to MH Services Flag]
											End

	 from [PATLondon].[MH_Spells] f
	inner join #tempRef ccc on ccc.UniqServReqID = f.UniqServReqID	
	and convert(date,ccc.ReferralRequestReceivedDate)  = f.StartDateHospProvSpell


	update f

		 set f.[Known to MH Services Flag] = 1

	 from [PATLondon].[MH_Spells] f
	inner join #tempRef ccc on ccc.UniqServReqID = f.UniqServReqID	

	where 
	(
	datediff(day, ccc.ReferralRequestReceivedDate,convert(date,f.StartDateHospProvSpell)) > 0
	and 
	datediff(month, ccc.ReferralRequestReceivedDate,convert(date,f.StartDateHospProvSpell)) <=6
	)
	and ccc.[Referral Source] = 'Acute Secondary Care: Emergency Care Department'  

---------------------------------------------------------------------------------------------------------------------------------------------
--New Known and Previously Known columns added 07/05/2025
---------------------------------------------------------------------------------------------------------------------------------------------

		
  	 update x

	 set x.[KnownInLast24Months] = case
									 
										when 
										   ( datediff(day, ccc.ReferralRequestReceivedDate,convert(date,x.StartDateHospProvSpell) )>= 0 
										   and datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date,x.StartDateHospProvSpell)) <=24  
										   )		
										   then 1							 
										When
											(
												(datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date, StartDateHospProvSpell))>24 )
											and (ServDischDate is null or (ServDischDate > StartDateHospProvSpell))
											and (ReferRejectionDate is null or (ReferRejectionDate > StartDateHospProvSpell))
											)
									 
										  then 1 
										else null
										end 

	 from [PATLondon].[MH_Spells] x
	left join #tempRef ccc on ccc.UniqServReqID = x.UniqServReqID	
	and ccc.ReferralRequestReceivedDate <= x.StartDateHospProvSpell

	

	update f

		 set f.[KnownInLast24Months] = case
											  when ccc.[Referral Source] = 'Acute Secondary Care: Emergency Care Department'  
													then null
												else f.[KnownInLast24Months]
											End

	 from [PATLondon].[MH_Spells] f
	inner join #tempRef ccc on ccc.UniqServReqID = f.UniqServReqID	
	and convert(date,ccc.ReferralRequestReceivedDate)  = f.StartDateHospProvSpell


	update f

		 set f.[KnownInLast24Months] = 1

	 from [PATLondon].[MH_Spells] f
	inner join #tempRef ccc on ccc.UniqServReqID = f.UniqServReqID	

	where 
	(
	datediff(day, ccc.ReferralRequestReceivedDate,convert(date,f.StartDateHospProvSpell)) > 0
	and 
	datediff(month, ccc.ReferralRequestReceivedDate,convert(date,f.StartDateHospProvSpell)) <=24
	)
	and ccc.[Referral Source] = 'Acute Secondary Care: Emergency Care Department'  




	--Previously Known

	update x

	 set x.PreviouslyKnown = case
									 
										when 
										   ( datediff(day, ccc.ReferralRequestReceivedDate,convert(date,x.StartDateHospProvSpell) )>= 0 
										   and datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date,x.StartDateHospProvSpell)) >24  
										   )		
										   then 1							 
										When
											(
												(datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date, StartDateHospProvSpell))> 24 )
											and (ServDischDate is null or (ServDischDate > StartDateHospProvSpell))
											and (ReferRejectionDate is null or (ReferRejectionDate > StartDateHospProvSpell))
											)
									 
										  then 1 
										else null
										end 

	 from [PATLondon].[MH_Spells] x
	left join #tempRef ccc on ccc.UniqServReqID = x.UniqServReqID	
	and ccc.ReferralRequestReceivedDate <= x.StartDateHospProvSpell

	
	update f

		 set f.PreviouslyKnown = case
											  when ccc.[Referral Source] = 'Acute Secondary Care: Emergency Care Department'  
													then null
												else f.PreviouslyKnown
											End

	 from [PATLondon].[MH_Spells] f
	inner join #tempRef ccc on ccc.UniqServReqID = f.UniqServReqID	
	and convert(date,ccc.ReferralRequestReceivedDate)  = f.StartDateHospProvSpell


	update f

		 set f.PreviouslyKnown = 1

	 from [PATLondon].[MH_Spells] f
	inner join #tempRef ccc on ccc.UniqServReqID = f.UniqServReqID	

	where 
	(
	datediff(day, ccc.ReferralRequestReceivedDate,convert(date,f.StartDateHospProvSpell)) > 0
	and 
	datediff(month, ccc.ReferralRequestReceivedDate,convert(date,f.StartDateHospProvSpell)) >24
	)
	and ccc.[Referral Source] = 'Acute Secondary Care: Emergency Care Department'  




---------------------------------------------------------------------------------------------------------------------------------------------

	drop table #tempRef


	update f
	set f.NewLOS = 	CASE
						when DischDateHospProvSpell is not null 
						then DATEDIFF(DAY, startDateHospProvSpell, DischDateHospProvSpell) 
						else null
						end  


	from [PATLondon].[MH_Spells] f

	 