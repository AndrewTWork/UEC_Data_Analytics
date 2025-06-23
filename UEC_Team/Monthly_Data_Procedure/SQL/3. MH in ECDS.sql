 

  

		IF OBJECT_ID('Tempdb..#tempHO1') IS NOT NULL 
		dROP TABLE #tempHO1
		select
		distinct 
		h.UniqServReqID , 
		h.Der_Pseudo_NHS_Number,
		h.UniqHospProvSpellID,
		StartDateHospProvSpell,
		h.DischDateHospProvSpell,
		h.Provider_Name

		into #tempHO1

		from [PATLondon].[MH_Spells] h  with (nolock)
		WHere h.DischDateHospProvSpell is not null
		and 
		(
		h.Der_Pseudo_NHS_Number is not null
		and 
		h.Der_Pseudo_NHS_Number <> '0'
		and 
		h.Der_Pseudo_NHS_Number <>''
		)
 
		IF OBJECT_ID('Tempdb..#Prov') IS NOT NULL 
		dROP TABLE  #Prov
		select
		Distinct
			Parent_Organisation_Code,
			[Parent Organisation Name],
			[Parent Organisation Postcode],
			REPLACE([Parent Organisation Postcode], ' ', '') as [Parent Organisation Postcode No Gaps],
			[Parent Organisation Postcode District],
			[Parent Organisation yr2011 LSOA],
			[MH Trust Flag],
			[MH Provider Abbrev]

		into #Prov

		from [PATLondon].[Ref_Trusts_and_Sites]  a  with (nolock)
  
 
					
 IF OBJECT_ID('Tempdb..#SNOMED') IS NOT NULL 
dROP TABLE #SNOMED	

select *
into #SNOMED
from
(

SELECT  [Sheet_Name]
 
      ,[ECDS_Group1]
 
 
      ,[SNOMED_Code]
      ,[SNOMED_Description]
	    ,		ROW_NUMBER() OVER (
		PARTITION BY  [SNOMED_Code]
		ORDER BY  [Created_Date]desc) as RowOrder
      ,[SNOMED_TERM]
       
      ,[Valid_From]
      ,[Valid_To]
      
  FROM [UKHD_ECDS_TOS].[Code_Sets]
  --where [SNOMED_Code]= '422400008'

 where [SNOMED_Description] is not null

 
 )d where RowOrder = 1				
				
 
	 		Declare 
			@StartDate date , @EndDate date

			--set @StartDate ='2025-01-01'
	 
set @StartDate	=(select dateadd(month, 3, 
                         dateadd(year, 
                                 datepart(year, 
                                          dateadd(month, -3, getdate())) - 1900, 0)))

			

 IF OBJECT_ID('Tempdb..#tempED') IS NOT NULL 
dROP TABLE #tempED

	SELECT 

	convert(varchar(255),a.Generated_Record_ID)+'|'+ convert(varchar(255),Unique_CDS_identifier)+'|'+ convert(varchar(255),Attendance_Unique_Identifier) +'|'+convert(varchar(255),EC_Ident) as [Unique Record ID]
	,a.Der_Pseudo_NHS_Number
 
	,EC_Ident
	,a.Generated_Record_ID
	,Unique_CDS_identifier
	,Attendance_Unique_Identifier
	,ROW_NUMBER() OVER (
	PARTITION BY  Der_Pseudo_NHS_Number ,Attendance_Unique_Identifier, a.Arrival_Date
	ORDER BY  a.Arrival_Date   ) as RowOrder
  
	,case 
		when Sex = '0' then 'Unknown'
		when sex = '1' then 'Male'
		when sex = '2' then 'Female'
		when sex = '9' then 'Not specified'
	end as Gender
 
    ,a.Age_At_Arrival as [Age at Arrival]
	,case 
	when (a.Age_At_Arrival <= 18 and a.Age_At_Arrival is not null) then 'CYP' 
	when (a.Age_At_Arrival > 18 and a.Age_At_Arrival is not null) then 'Adult' 
	else 'Missing/Invalid' end as [Age Group]
	,CASE 
		WHEN a.Age_At_Arrival BETWEEN 0 AND 11 THEN '0-11'  
		WHEN a.Age_At_Arrival BETWEEN 12 AND 17 THEN '12-17'
		WHEN a.Age_At_Arrival BETWEEN 18 AND 25 THEN '18-25'
		WHEN a.Age_At_Arrival BETWEEN 26 AND 64 THEN '26-64' 
		WHEN a.Age_At_Arrival >= 65 THEN '65+' 
		ELSE 'Missing/Invalid' 
	END as AgeCat 
	,ec.[Category] as [Broad Ethnic Category] 
	,ec.Main_Description as [Ethnic Category] 
	,case 
	when (ec.Main_Description = '' OR ec.Main_Description = 'Not stated' OR ec.Main_Description = 'Not known' OR  ec.Main_Description is null) then 'Not Known / Not Stated / Incomplete'
	when ec.Category = 'Asian or Asian British' then 'Asian'
	when ec.Category = 'Black or Black British' then 'Black'
	when ec.Main_Description in ('mixed','Any other ethnic group','White & Black Caribbean','Any other mixed background','Chinese') then 'Mixed/ Other'
	ELSE ec.[Category]
	END as [Derived Broad Ethnic Category] 
	,Index_Of_Multiple_Deprivation_Decile
	,Index_Of_Multiple_Deprivation_Decile_Description
	,Rural_Urban_Indicator
	,cast(null as float) as [Ethnic proportion per 100000 of London Borough 2020] 

	,null as [Known to MH Services Flag] 

	,cast(null as date) as [Last Completed IP Spell] 
	,cast(null as varchar(255)) as [IP Spell Provider Name] 
	,cast(null as varchar(255)) as [UniqHospProvSpellID] 
	,cast(null as varchar(255)) as [IP Spell UniqServReqID]
	,null as [ED Presentation within 28 days of Completed IP SPell] 
	,null as [Days between Completed IP Spell and ED Presentation] 
 
	,coalesce(a.PDS_General_Practice_Code,a.GP_Practice_Code ) as  GP_Practice_Code
	,gp.GP_Name as [Practice Name]
	,gp.PCDS_NoGaps as [GP Practice PostCode No Gaps] 
	,gp.[2019_CCG_Name] as [Patient GP Practice 2019 CCG Code]
	,GP.[Local_Authority] as [Patient GP Local Authority Name]
	 
	,GP.GP_Region_Name as [Patient GP Practice Region]
	,case
		when gpTm.Borough is null and GP.[Local_Authority] is not null then 'Out of London Borough'
		when gpTm.Borough is null and GP.[Local_Authority] is null then 'GP Practice Unknown'
		when gpTm.Borough is not null then 'London patient'
		end as [Borough Type]
	,gpTm.ICS as [Patient ICS]
	,gpTm.Trust as [Local MH Trust]
	,gp.Lower_Super_Output_Area_Code as [Patient GP 2011_LSOA]
	,gp.Middle_Super_Output_Area_Code as [Patient GP 2011_MS0A]
	,ac.[SNOMED_Description] as  Accommodation_Status_SNOMED_CT


	,Attendance_Postcode_District
	,Attendance_HES_CCG_From_Treatment_Origin
	,Attendance_HES_CCG_From_Treatment_Site_Code
	,Attendance_LSOA_Provider_Distance  --The distance, in miles, between the LSOA centroid of the patient's submitted postcode and the LSOA centroid of the provider.
	,Attendance_LSOA_Treatment_Site_Distance  --The distance between the LSOA centroid of the patient's submitted postcode and the LSOA centroid of the site of treatment.
	,ats.[SNOMED_Description] as AttendanceSource
	,Patient_Type
	,a.Der_Provider_Code 
	--local patient ID, provider code and activity date/time.
	,COALESCE(o1.Organisation_Name,'Missing/Invalid') AS Der_Provider_Name
	,a.Der_Provider_Site_Code 
	,pp.[Parent Organisation Postcode] as   [Provider PostCode]  
	,pp.[Parent Organisation Postcode District] as [Provider Postcode District]
	,pp.[Parent Organisation yr2011 LSOA]  as [Provider 2011 LSOA]
	,COALESCE(o2.Organisation_Name,'Missing/Invalid') AS Der_Provider_Site_Name
	,COALESCE(o3.Region_Code,'Missing/Invalid') AS Provider_Region_Code --- regions taken from CCG of provider rather than CCG of residence
	,COALESCE(o3.Region_Name,'Missing/Invalid') AS Provider_Region_Name
	,COALESCE(cc.New_Code,a.Attendance_HES_CCG_From_Treatment_Site_Code,'Missing/Invalid') AS Provider_CCGCode
	,COALESCE(o3.Organisation_Name,'Missing/Invalid') AS [Provider_CCG name]
	,tm.ICS as [Provider ICB]
	,COALESCE(o3.STP_Code,'Missing/Invalid') AS Provider_STPCode
	,COALESCE(o3.STP_Name,'Missing/Invalid') AS  [Provider STP name]
	,DATEADD(MONTH, DATEDIFF(MONTH, 0, Arrival_Date), 0) as  [Month Year]
	 
	,a.Arrival_Date 
	,ad.[Financial Year] as [ArrivalDate FY] 
	,DATEPART(HOUR, a.Arrival_Time) as [Arrival Hour]
	,CAST(ISNULL(a.Arrival_Time,'00:00:00') AS datetime) + CAST(a.Arrival_Date AS datetime) AS [Arrival Date Time]
	,am.[SNOMED_Description]  as [Arrival Mode]
	,a.EC_Initial_Assessment_Date
	,a.EC_Initial_Assessment_Time
	,a.EC_Initial_Assessment_Time_Since_Arrival	
	,a.EC_Departure_Date 
	,a.EC_Departure_Time
	,EC_Departure_Time_Since_Arrival as [EC_Departure_Time_Since_Arrival]
	,case 
	when [EC_Departure_Time_Since_Arrival] >= 0 AND [EC_Departure_Time_Since_Arrival] <= 240 THEN '0-4'
	when [EC_Departure_Time_Since_Arrival] is null then '0-4'
	when [EC_Departure_Time_Since_Arrival] > 240 and [EC_Departure_Time_Since_Arrival] <= 720 THEN '5-12' 
	when [EC_Departure_Time_Since_Arrival] > 720 and [EC_Departure_Time_Since_Arrival] <= 1440 then '12-24'
	when [EC_Departure_Time_Since_Arrival] > 1440 and [EC_Departure_Time_Since_Arrival] <= 2880 then '24-48'
	when [EC_Departure_Time_Since_Arrival] > 2880 and [EC_Departure_Time_Since_Arrival] <= 4320 then '48-72'
	when [EC_Departure_Time_Since_Arrival] > 4320 then  '>72' 
	else 'Not recorded'
	end as [Time Grouper]
	,CASE WHEN EC_Departure_Time_Since_Arrival > (60*6) THEN 1 ELSE 0 END as [6 Hour Breach] 
	,CASE WHEN EC_Departure_Time_Since_Arrival > (60*6) THEN (EC_Departure_Time_Since_Arrival - (60*6)) ELSE 0 END AS [Time over 6 Hours]
	,CASE WHEN EC_Departure_Time_Since_Arrival > (60*12) THEN 1 ELSE 0 END as [12 Hour Breach] 
	,CASE WHEN EC_Departure_Time_Since_Arrival > (60*12) THEN EC_Departure_Time_Since_Arrival - (60*12) ELSE 0 END AS [Time over 12 Hours]
	,CASE WHEN EC_Departure_Time_Since_Arrival >= (24*60) THEN 1 ELSE 0 END as [24hrs_breach]
	,a.EC_Seen_For_Treatment_Date
	,a.EC_Seen_For_Treatment_Time
	,a.EC_Seen_For_Treatment_Time_Since_Arrival
	,a.EC_Conclusion_Date
	,a.EC_Conclusion_Time
	,a.EC_Conclusion_Time_Since_Arrival
	
	,a.EC_Decision_To_Admit_Date
	,a.EC_Decision_To_Admit_Time
	,a.EC_Decision_To_Admit_Time_Since_Arrival

	,a.Decision_To_Admit_Receiving_Site
	,Decision_To_Admit_Treatment_Function_Code as [Decision To Admit Treatment Function Code]
	,tf.[Main_Description] as [Treatment Function Desc]
	,tf.[Category] as [Treatment Function Group]

 
	,a.EC_Chief_Complaint_SNOMED_CT as [MH ED Chief Complaint SNOMED Code]
	,cp.SNOMED_Description [MH ED Chief Complaint Description]
	,a.EC_Injury_Intent_SNOMED_CT as [MH ED Injury Intent SNOMED Code]
	,ii.SNOMED_Description  as [MH ED Injury Intent Description]

	,a.Der_EC_Diagnosis_All as [MH All ED SNOMED Diagnosis Codes]
	,COALESCE(LEFT(a.Der_EC_Diagnosis_All, NULLIF(CHARINDEX(',',a.Der_EC_Diagnosis_All),0)-1),a.Der_EC_Diagnosis_All) AS [MH Primary SNOMED Diagnosis Code]
	,pd.SNOMED_Description  as [MH Primary Diagnosis Description]
	,cast(null as varchar(20)) as [Secondary Diagnosis Code]
	,cast(null as varchar(300)) as [Secondary Diagnosis Description]
	,cast(null as varchar(20)) as [Third Diagnosis Code]
	,cast(null as varchar(300)) as [Third Diagnosis Description]
	,cast(null as varchar(20)) as [Fourth Diagnosis Code]
	,cast(null as varchar(300)) as [Fourth Diagnosis Description]

	,cast(null as int) as [Reduction in Inappropriate Flag]

	,cast(null as varchar(300)) as [Comorbidity_01]
	,cast(null as varchar(300)) as [Comorbidity_02]
	,cast(null as varchar(300)) as [Comorbidity_03]
	,cast(null as varchar(300)) as [Comorbidity_04]

	,cast(null as varchar(300)) as [Referred_To_Service_01]
    ,cast(null as date) as [Service_Request_Date_01]
    ,cast(null as varchar(8)) as [Service_Request_Time_01]
    ,cast(null as date) as [Service_Assessment_Date_01]
    ,cast(null as varchar(8)) as [Service_Assessment_Time_01]
    ,cast(null as varchar(300)) as [Referred_To_Service_02]
    ,cast(null as date) as [Service_Request_Date_02]
    ,cast(null as varchar(8)) as [Service_Request_Time_02]
    ,cast(null as date) as [Service_Assessment_Date_02]
    ,cast(null as varchar(8)) as [Service_Assessment_Time_02] 
	,cast(null as varchar(300)) as [Referred_To_Service_03]
    ,cast(null as date) as [Service_Request_Date_03]
    ,cast(null as varchar(8)) as [Service_Request_Time_03]
    ,cast(null as date) as [Service_Assessment_Date_03]
    ,cast(null as varchar(8)) as [Service_Assessment_Time_03]
	,cast(null as varchar(300)) as [Referred_To_Service_04]
    ,cast(null as date) as [Service_Request_Date_04]
    ,cast(null as varchar(8)) as [Service_Request_Time_04]
    ,cast(null as date) as [Service_Assessment_Date_04]
    ,cast(null as varchar(8)) as [Service_Assessment_Time_04]

	 ,dd.SNOMED_Description as  DischargeDestination
	,df.SNOMED_Description as [Discharge Followup Description]
	
	,CASE WHEN EC_Chief_Complaint_SNOMED_CT IN ('248062006' --- self harm
				,'272022009' --- depressive feelings 
				,'48694002' --- feeling anxious 
				,'248020004' --- behaviour: unsual 
				,'6471006' -- feeling suicidal
				,'7011001'
				,'366979004' --new depressive feelings code from Aril '22 (changed July 2024)
				)  THEN 1 ELSE 0 END as [Chief Complaint Flag]
	,CASE WHEN a.EC_Injury_Date IS NOT NULL THEN 1 ELSE 0 END as [Injury Flag]
	,CASE WHEN EC_Injury_Intent_SNOMED_CT = '276853009'THEN 1 ELSE 0 END as [Injury Intent Flag]
	,CASE WHEN COALESCE(LEFT(Der_EC_Diagnosis_All, NULLIF(CHARINDEX(',',Der_EC_Diagnosis_All),0)-1),Der_EC_Diagnosis_All) 
				IN ( 
					'52448006' --- dementia
					,'2776000' --- delirium 
					,'33449004' --- personality disorder
					,'72366004' --- eating disorder
					,'197480006' --- anxiety disorder
					,'35489007' --- depressive disorder
					,'13746004' --- bipolar affective disorder
					,'58214004' --- schizophrenia
					,'69322001' --- psychotic disorder
					,'397923000' --- somatisation disorder
					,'30077003' --- somatoform pain disorder
					,'44376007' --- dissociative disorder
					,'17226007' ---- adjustment disorder
					,'50705009'---- factitious disorder
					) THEN 1 ELSE 0 END as [Diagnosis Flag]
	,CASE 
			WHEN EC_Chief_Complaint_SNOMED_CT IN ('248062006' --- self harm
				,'272022009' --- depressive feelings 
				,'48694002' --- feeling anxious 
				,'248020004' --- behaviour: unsual 
				,'6471006' -- feeling suicidal
				,'7011001'
				,'366979004'--new  depressive feelings code added April 2022 - updated here in July 2024
				) THEN 1  --- hallucinations/delusions 
			WHEN EC_Injury_Intent_SNOMED_CT = '276853009' THEN 1 --- self inflicted injury 
			WHEN COALESCE(LEFT(Der_EC_Diagnosis_All, NULLIF(CHARINDEX(',',Der_EC_Diagnosis_All),0)-1),Der_EC_Diagnosis_All) 
				IN ( 
					'52448006' --- dementia
					,'2776000' --- delirium 
					,'33449004' --- personality disorder
					,'72366004' --- eating disorder
					,'197480006' --- anxiety disorder
					,'35489007' --- depressive disorder
					,'13746004' --- bipolar affective disorder
					,'58214004' --- schizophrenia
					,'69322001' --- psychotic disorder
					,'397923000' --- somatisation disorder
					,'30077003' --- somatoform pain disorder
					,'44376007' --- dissociative disorder
					,'17226007' ---- adjustment disorder
					,'50705009'---- factitious disorder
					) 
			THEN 1 
		ELSE 0 
		END as [Mental Health Presentation Flag]
	,CASE 
		WHEN EC_Injury_Intent_SNOMED_CT = '276853009' THEN 1
		WHEN EC_Chief_Complaint_SNOMED_CT = '248062006' THEN 1
		ELSE 0 
	END as [Self Harm Flag] 
	
INTO #tempED
FROM  [Reporting_MESH_ECDS].[EC_Core_Snapshot]  a
 

 left join
 (
 SELECT  
distinct 
[Organisation_Code]
,[Organisation_Name]
FROM  [UKHD_ODS].[All_Providers_SCD_1]
where   [Is_Latest] = 1
)o1 ON a.Provider_Code = o1.Organisation_Code --- providers 

left join
(
SELECT  
distinct
[Organisation_Code]
,[Organisation_Name]
FROM [UKHD_ODS].[NHS_Trust_Sites_Assets_And_Units_SCD_1]
where [Is_Latest] = 1
 ) o2 ON a.Site_Code_of_Treatment = o2.Organisation_Code --- sites
 
LEFT JOIN  [Internal_Reference].[ComCodeChanges_1] cc ON a.Attendance_HES_CCG_From_Treatment_Site_Code = cc.Org_Code 
LEFT JOIN [Reporting_UKHD_ODS].[Commissioner_Hierarchies] o3 ON COALESCE(cc.New_Code,a.Attendance_HES_CCG_From_Treatment_Site_Code) = o3.Organisation_Code --- CCG / STP / Region 
LEft join [PATLondon].[Ref_GP_Data] gp on gp.GP_Practice_Code = coalesce(a.PDS_General_Practice_Code,a.GP_Practice_Code )
left join [PATLondon].[Ref_Borough_Trust_Mapping]gpTm on gpTm.Borough = gp.Local_Authority

 
left join #SNOMED  pd  on pd.SNOMED_Code =  COALESCE(LEFT(a.Der_EC_Diagnosis_All, NULLIF(CHARINDEX(',',a.Der_EC_Diagnosis_All),0)-1),a.Der_EC_Diagnosis_All) 
left join #SNOMED  ac  on ac.SNOMED_Code = a.[Accommodation_Status_SNOMED_CT]
left join #SNOMED  ii  on ii.SNOMED_Code = a.EC_Injury_Intent_SNOMED_CT
left join #SNOMED cp on cp.SNOMED_Code = a.EC_Chief_Complaint_SNOMED_CT									 
left join #SNOMED am on am.SNOMED_Code = a.EC_Arrival_Mode_SNOMED_CT
left join #SNOMED ats on ats.SNOMED_Code = a.EC_Attendance_Source_SNOMED_CT
left join #SNOMED df on df.SNOMED_Code = a.Discharge_Follow_Up_SNOMED_CT
left join #SNOMED dd on dd.SNOMED_Code = a.Discharge_Destination_SNOMED_CT
left join [UKHD_Data_Dictionary].[Treatment_Function_Code_SCD_1] tf on tf.Main_Code_Text = a.Decision_To_Admit_Treatment_Function_Code
left join #Prov pp on pp.Parent_Organisation_Code = a.Der_Provider_Code
 
left join [PATLondon].[Ref_PostCode_to_Local_Authority]la on la.[PostCode No Gaps]= pp.[Parent Organisation Postcode No Gaps]
left join [PATLondon].[Ref_Borough_Trust_Mapping]tm on tm.Borough = la.Name

left join [UKHD_Data_Dictionary].[Ethnic_Category_Code_SCD_1]ec on ec.[Main_Code_Text] = a.Ethnic_Category and ec.is_latest = 1

Left join  [PATLondon].[DIM_Date]ad on ad.[Calendar Day] = a.Arrival_Date


 
          
WHERE a.EC_Department_Type = '01' --- Type 1 EDs only 
AND a.Arrival_Date >= @StartDate
and a.Arrival_Date <= @EndDate

AND (EC_Discharge_Status_SNOMED_CT IS NULL OR EC_Discharge_Status_SNOMED_CT  NOT IN ('1077031000000103','1077781000000101', '63238001')) --exclude streamed and Dead on arrival
AND ([EC_AttendanceCategory] IS NULL OR [EC_AttendanceCategory] in ('1','2','3'))   --exclude follow ups and Dead on arrival
and COALESCE(o3.Region_Name,'Missing/Invalid') = 'London'
 
 

delete  from  #tempED where RowOrder > 1
 
 IF OBJECT_ID('Tempdb..#tempComorb') IS NOT NULL 
dROP TABLE #tempComorb
 
SELECT  
    [EC_Ident],
    [Generated_Record_ID],
    [Comorbidity_01] = MIN(CASE WHEN y.rn = 1 THEN y.val END),
    [Comorbidity_02]= MIN(CASE WHEN y.rn = 2 THEN y.val END),
    [Comorbidity_03] = MIN(CASE WHEN y.rn = 3 THEN y.val END),
    [Comorbidity_04] = MIN(CASE WHEN y.rn = 4 THEN y.val END),
    [Comorbidity_05] = MIN(CASE WHEN y.rn = 5 THEN y.val END),
    [Comorbidity_06] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_07] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_08] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_09] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_10] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_11] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_12] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_13] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_14] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_15] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_16] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_17] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_18] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_19] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_20] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_21] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_22] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_23] = MIN(CASE WHEN y.rn = 6 THEN y.val END),
	[Comorbidity_24] = MIN(CASE WHEN y.rn = 6 THEN y.val END)

	into #tempComorb

FROM [Reporting_MESH_ECDS].[MESH_ECDS_EC_Comorbidities]  t
  OUTER APPLY
    ( SELECT
          x.val,
          rn = ROW_NUMBER() OVER (ORDER BY rn)
      FROM
      ( VALUES 
        ([Comorbidity_01],1), ([Comorbidity_02],2), ([Comorbidity_03],3), ([Comorbidity_04],4), 
		([Comorbidity_05],5), ([Comorbidity_06],6), ([Comorbidity_07],7), ([Comorbidity_08],8),
		([Comorbidity_09],9), ([Comorbidity_10],10), ([Comorbidity_11],11), ([Comorbidity_12],12),
		([Comorbidity_13],13), ([Comorbidity_14],14), ([Comorbidity_15],15), ([Comorbidity_16],16),
		([Comorbidity_17],17), ([Comorbidity_18],18), ([Comorbidity_19],19), ([Comorbidity_20],20),
		([Comorbidity_21],21), ([Comorbidity_22],22), ([Comorbidity_23],23), ([Comorbidity_24],24)
      ) x (val, rn) 
      WHERE x.val IS NOT NULL
    ) y 

	where 
	 exists (
				select 
				[EC_Ident], 
				[Generated_Record_ID] 
				from #tempED x 
				where x.[EC_Ident] = t.[EC_Ident] 
 
				)
			AND

		  coalesce( [Comorbidity_01] ,[Comorbidity_02] ,[Comorbidity_03] ,[Comorbidity_04] ,
					[Comorbidity_05] ,[Comorbidity_06] ,[Comorbidity_07] ,[Comorbidity_08] ,
					[Comorbidity_09] ,[Comorbidity_10] ,[Comorbidity_11] ,[Comorbidity_12] ,
					[Comorbidity_13] ,[Comorbidity_14] ,[Comorbidity_15] ,[Comorbidity_16] ,
					[Comorbidity_17] ,[Comorbidity_18] ,[Comorbidity_19] ,[Comorbidity_20] ,
					[Comorbidity_21] ,[Comorbidity_22] ,[Comorbidity_23] ,[Comorbidity_24]
					) is not null
					AND 
		  coalesce( [Comorbidity_01] ,[Comorbidity_02] ,[Comorbidity_03] ,[Comorbidity_04] ,
					[Comorbidity_05] ,[Comorbidity_06] ,[Comorbidity_07] ,[Comorbidity_08] ,
					[Comorbidity_09] ,[Comorbidity_10] ,[Comorbidity_11] ,[Comorbidity_12] ,
					[Comorbidity_13] ,[Comorbidity_14] ,[Comorbidity_15] ,[Comorbidity_16] ,
					[Comorbidity_17] ,[Comorbidity_18] ,[Comorbidity_19] ,[Comorbidity_20] ,
					[Comorbidity_21] ,[Comorbidity_22] ,[Comorbidity_23] ,[Comorbidity_24]
					) <> ''
GROUP BY 
    t.[EC_Ident],
    t.[Generated_Record_ID] ;



	update f
	   set [Comorbidity_01] =  CASE WHEN [Comorbidity_01] = '' THEN null else [Comorbidity_01] END,
    [Comorbidity_02] =  CASE WHEN [Comorbidity_02] = '' THEN null else [Comorbidity_02] END,
    [Comorbidity_03] =  CASE WHEN [Comorbidity_03] = '' THEN null else [Comorbidity_03] END,
    [Comorbidity_04] =  CASE WHEN [Comorbidity_04] = '' THEN null else [Comorbidity_04] END,
    [Comorbidity_05] =  CASE WHEN [Comorbidity_05] = '' THEN null else [Comorbidity_05] END,
    [Comorbidity_06] =  CASE WHEN [Comorbidity_06] = '' THEN null else [Comorbidity_06] END,
	[Comorbidity_07] =  CASE WHEN [Comorbidity_07] = '' THEN null else [Comorbidity_07] END,
	[Comorbidity_08] =  CASE WHEN [Comorbidity_08] = '' THEN null else [Comorbidity_08] END,
	[Comorbidity_09] =  CASE WHEN [Comorbidity_09] = '' THEN null else [Comorbidity_09] END,
	[Comorbidity_10] =  CASE WHEN [Comorbidity_10] = '' THEN null else [Comorbidity_10] END,
	[Comorbidity_11] =  CASE WHEN [Comorbidity_11] = '' THEN null else [Comorbidity_11] END,
	[Comorbidity_12] =  CASE WHEN [Comorbidity_12] = '' THEN null else [Comorbidity_12] END,
	[Comorbidity_13] =  CASE WHEN [Comorbidity_13] = '' THEN null else [Comorbidity_13] END,
	[Comorbidity_14] =  CASE WHEN [Comorbidity_14] = '' THEN null else [Comorbidity_14] END,
	[Comorbidity_15] =  CASE WHEN [Comorbidity_15] = '' THEN null else [Comorbidity_15] END,
	[Comorbidity_16] =  CASE WHEN [Comorbidity_16] = '' THEN null else [Comorbidity_16] END,
	[Comorbidity_17] =  CASE WHEN [Comorbidity_17] = '' THEN null else [Comorbidity_17] END,
	[Comorbidity_18] =  CASE WHEN [Comorbidity_18] = '' THEN null else [Comorbidity_18] END,
	[Comorbidity_19] =  CASE WHEN [Comorbidity_19] = '' THEN null else [Comorbidity_19] END,
	[Comorbidity_20] =  CASE WHEN [Comorbidity_20] = '' THEN null else [Comorbidity_20] END,
	[Comorbidity_21] =  CASE WHEN [Comorbidity_21] = '' THEN null else [Comorbidity_21] END,
	[Comorbidity_22] =  CASE WHEN [Comorbidity_22] = '' THEN null else [Comorbidity_22] END,
	[Comorbidity_23] =  CASE WHEN [Comorbidity_23] = '' THEN null else [Comorbidity_23] END,
	[Comorbidity_24] =  CASE WHEN [Comorbidity_24] = '' THEN null else [Comorbidity_24] END


	from #tempComorb f

	insert into [PATLondon].[ECDS_Comorbidities_Cleaned] 
	select
	*
	from #tempComorb b
	where not exists (	select 
				[EC_Ident], 
				[Generated_Record_ID] 
				from [PATLondon].[ECDS_Comorbidities_Cleaned]  x 
				where x.[EC_Ident] = b.[EC_Ident] 
				and x.[Generated_Record_ID] = b.[Generated_Record_ID]
				)


	update z
	     set z.[Comorbidity_01] = b.snomed_description
	 
 
	from #tempED z
	inner join [PATLondon].[ECDS_Comorbidities_Cleaned]a on a.EC_Ident = z.EC_Ident 
	left join #SNOMED b on b.snomed_Code = a.Comorbidity_01
 
 	update z
	     set z.[Comorbidity_02] = b.snomed_description
    from #tempED z
	inner join [PATLondon].[ECDS_Comorbidities_Cleaned]a on a.EC_Ident = z.EC_Ident 
    left join #SNOMED b on b.snomed_Code = a.Comorbidity_02

 	update z
	     set z.[Comorbidity_03] = b.snomed_description
    from #tempED z
	inner join [PATLondon].[ECDS_Comorbidities_Cleaned]a on a.EC_Ident = z.EC_Ident 
    left join #SNOMED b on b.snomed_Code = a.Comorbidity_03

 	update z
	     set z.[Comorbidity_04] = b.snomed_description
    from #tempED z
	inner join [PATLondon].[ECDS_Comorbidities_Cleaned]a on a.EC_Ident = z.EC_Ident 
    left join #SNOMED b on b.snomed_Code = a.Comorbidity_04
 



	--select top 5000 * from #tempED
IF OBJECT_ID('Tempdb..#tempDiagCodes') IS NOT NULL 
dROP TABLE #tempDiagCodes

SELECT 
EC_Ident,
[Unique Record ID],
[MH All ED SNOMED Diagnosis Codes], 
ltrim(rtrim([Diag1])) AS [Diag1], 
cast(null as varchar(300)) as [Diag 1 Description],
ltrim(rtrim([Diag2])) AS [Diag2], 
cast(null as varchar(300)) as [Diag 2 Description],
ltrim(rtrim([Diag3])) AS [Diag3], 
cast(null as varchar(300)) as [Diag 3 Description],
ltrim(rtrim([Diag4])) AS [Diag4],
cast(null as varchar(300)) as [Diag 4 Description]
into #tempDiagCodes
FROM ( 
	 SELECT 
	 EC_Ident,
	 [Unique Record ID],
	 [MH All ED SNOMED Diagnosis Codes], 
	 'Diag'+ CAST(ROW_NUMBER()OVER(PARTITION BY EC_Ident,[Unique Record ID] ORDER BY EC_Ident) AS VARCHAR) AS Col, 
	 Split.value 
	 FROM #tempED AS Emp 

	 CROSS APPLY String_split([MH All ED SNOMED Diagnosis Codes],',') AS Split 
	  --where emp.RowOrder = 1
	 ) 
	 AS tbl

	Pivot (Max(Value) FOR Col IN ([Diag1],[Diag2],[Diag3],[Diag4])

) AS Pvt

delete from #tempDiagCodes where coalesce(diag2,diag3,diag4) = null

update d
set d.[Diag 2 Description] = a.SNOMED_Description
from #tempDiagCodes d
inner join #SNOMED a on a.snomed_Code = d.Diag2

update d
set d.[Diag 3 Description] = a.SNOMED_Description
from #tempDiagCodes d
inner join #SNOMED a on a.snomed_Code = d.Diag3

update d
set d.[Diag 4 Description] = a.SNOMED_Description
from #tempDiagCodes d
inner join #SNOMED a on a.snomed_Code = d.Diag4
 

update edd
set edd.[Secondary Diagnosis Description] = b.[Diag 2 Description],
	edd.[Secondary Diagnosis Code] = b.Diag2,
	edd.[Third Diagnosis Description] = b.[Diag 3 Description],
	edd.[Third Diagnosis Code] = b.Diag3,
	edd.[Fourth Diagnosis Description] = b.[Diag 4 Description],
	edd.[Fourth Diagnosis Code] = b.Diag4
from #tempED edd
inner join #tempDiagCodes b on b.EC_Ident = edd.EC_Ident
 

IF OBJECT_ID('Tempdb..#tempRefToServ') IS NOT NULL 
dROP TABLE #tempRefToServ
 
SELECT  
       [EC_Ident] 
	  ,[Generated_Record_ID] 
	  ,[Referred_To_Service_01]
      ,[Service_Request_Date_01]
      ,[Service_Request_Time_01]
      ,[Service_Assessment_Date_01]
      ,[Service_Assessment_Time_01]
      ,[Referred_To_Service_02]
      ,[Service_Request_Date_02]
      ,[Service_Request_Time_02]
      ,[Service_Assessment_Date_02]
      ,[Service_Assessment_Time_02] 
	  ,[Referred_To_Service_03]
      ,[Service_Request_Date_03]
      ,[Service_Request_Time_03]
      ,[Service_Assessment_Date_03]
      ,[Service_Assessment_Time_03]
	  ,[Referred_To_Service_04]
      ,[Service_Request_Date_04]
      ,[Service_Request_Time_04]
      ,[Service_Assessment_Date_04]
      ,[Service_Assessment_Time_04]
	into #tempRefToServ
	 
FROM  [Reporting_MESH_ECDS].[MESH_ECDS_EC_PatientReferredTo] t
  OUTER APPLY
    ( SELECT
          x.val,
          rn = ROW_NUMBER() OVER (ORDER BY rn)
      FROM
      ( VALUES 
        ([Referred_To_Service_01],1), ([Service_Request_Date_01],2), ([Service_Request_Time_01],3), ([Service_Assessment_Date_01],4), 
		([Service_Assessment_Time_01],5), ([Referred_To_Service_02],6), ([Service_Request_Date_02],7), ([Service_Request_Time_02],8),
		([Service_Assessment_Date_02],9), ([Service_Assessment_Time_02],10), ([Referred_To_Service_03],11), ([Service_Request_Date_03],12), 
		([Service_Request_Time_03],13),([Service_Assessment_Date_03],14), ([Service_Assessment_Time_03],15), ([Referred_To_Service_04],16), 
		([Service_Request_Date_04],17), ([Service_Request_Time_04],18),([Service_Assessment_Date_04],19), ([Service_Assessment_Time_04],20)
      ) x (val, rn) 
      WHERE x.val IS NOT NULL
    ) y 

	where exists (
				select 
				[EC_Ident]
 
				from #tempED x 
				where x.[EC_Ident] = t.[EC_Ident] 
 
				)
			AND

		  coalesce([Referred_To_Service_01] ,[Referred_To_Service_02] ,[Referred_To_Service_03],[Referred_To_Service_04]) is not null
					AND 
		  coalesce([Referred_To_Service_01] ,[Referred_To_Service_02] ,[Referred_To_Service_03],[Referred_To_Service_04]) <> ''
GROUP BY 
    t.[EC_Ident],
    t.[Generated_Record_ID] 
		  ,[Referred_To_Service_01]
      ,[Service_Request_Date_01]
      ,[Service_Request_Time_01]
      ,[Service_Assessment_Date_01]
      ,[Service_Assessment_Time_01]
      ,[Referred_To_Service_02]
      ,[Service_Request_Date_02]
      ,[Service_Request_Time_02]
      ,[Service_Assessment_Date_02]
      ,[Service_Assessment_Time_02] 
	  ,[Referred_To_Service_03]
      ,[Service_Request_Date_03]
      ,[Service_Request_Time_03]
      ,[Service_Assessment_Date_03]
      ,[Service_Assessment_Time_03]
	  ,[Referred_To_Service_04]
      ,[Service_Request_Date_04]
      ,[Service_Request_Time_04]
      ,[Service_Assessment_Date_04]
      ,[Service_Assessment_Time_04];



	update f
	   set [Referred_To_Service_01] =  CASE WHEN [Referred_To_Service_01] = '' THEN null else [Referred_To_Service_01] END,
			[Service_Request_Date_01] =  CASE WHEN [Service_Request_Date_01] = '' THEN null else [Service_Request_Date_01] END,
			[Service_Request_Time_01] =  CASE WHEN [Service_Request_Time_01] = '' THEN null else [Service_Request_Time_01] END,
			[Service_Assessment_Date_01] =  CASE WHEN [Service_Assessment_Date_01] = '' THEN null else [Service_Assessment_Date_01] END,
			[Service_Assessment_Time_01] =  CASE WHEN [Service_Assessment_Time_01] = '' THEN null else [Service_Assessment_Time_01] END,

			[Referred_To_Service_02] =  CASE WHEN [Referred_To_Service_02] = '' THEN null else [Referred_To_Service_02] END,
			[Service_Request_Date_02] =  CASE WHEN [Service_Request_Date_02] = '' THEN null else [Service_Request_Date_02] END,
			[Service_Request_Time_02] =  CASE WHEN [Service_Request_Time_02] = '' THEN null else [Service_Request_Time_02] END,
			[Service_Assessment_Date_02] =  CASE WHEN [Service_Assessment_Date_02] = '' THEN null else [Service_Assessment_Date_02] END,
			[Service_Assessment_Time_02] =  CASE WHEN [Service_Assessment_Time_02] = '' THEN null else [Service_Assessment_Time_02] END,

			[Referred_To_Service_03] =  CASE WHEN [Referred_To_Service_03] = '' THEN null else [Referred_To_Service_03] END,
			[Service_Request_Date_03] =  CASE WHEN [Service_Request_Date_03] = '' THEN null else [Service_Request_Date_03] END,
			[Service_Request_Time_03] =  CASE WHEN [Service_Request_Time_03] = '' THEN null else [Service_Request_Time_03] END,
			[Service_Assessment_Date_03] =  CASE WHEN [Service_Assessment_Date_03] = '' THEN null else [Service_Assessment_Date_03] END,
			[Service_Assessment_Time_03] =  CASE WHEN [Service_Assessment_Time_03] = '' THEN null else [Service_Assessment_Time_03] END,

			[Referred_To_Service_04] =  CASE WHEN [Referred_To_Service_04] = '' THEN null else [Referred_To_Service_04] END,
			[Service_Request_Date_04] =  CASE WHEN [Service_Request_Date_04] = '' THEN null else [Service_Request_Date_04] END,
			[Service_Request_Time_04] =  CASE WHEN [Service_Request_Time_04] = '' THEN null else [Service_Request_Time_04] END,
			[Service_Assessment_Date_04] =  CASE WHEN [Service_Assessment_Date_04] = '' THEN null else [Service_Assessment_Date_04] END,
			[Service_Assessment_Time_04] =  CASE WHEN [Service_Assessment_Time_04] = '' THEN null else [Service_Assessment_Time_04] END  


	from #tempRefToServ f

 
	
	update z

		set	  [Referred_To_Service_01] = b.snomed_description,
			  [Service_Request_Date_01]= x.[Service_Request_Date_01],
			  [Service_Request_Time_01]= x.[Service_Request_Time_01],
			  [Service_Assessment_Date_01]= x.[Service_Assessment_Date_01],
			  [Service_Assessment_Time_01]= x.[Service_Assessment_Time_01]
		


	  from #tempED z
	  inner join #tempRefToServ x on x.[EC_Ident] = z.[EC_Ident]
	  left join #SNOMED b on b.snomed_Code = x.[Referred_To_Service_01]


	  	update z

		set	  [Referred_To_Service_02] = b.snomed_description,
			  [Service_Request_Date_02]= x.[Service_Request_Date_02],
			  [Service_Request_Time_02]= x.[Service_Request_Time_02],
			  [Service_Assessment_Date_02]= x.[Service_Assessment_Date_02],
			  [Service_Assessment_Time_02]= x.[Service_Assessment_Time_02]
		


	  from #tempED z
	  inner join #tempRefToServ x on x.[EC_Ident] = z.[EC_Ident]
	  left join #SNOMED b on b.snomed_Code = x.[Referred_To_Service_02]
	  where x.[Referred_To_Service_02] is not null

	  	update z

		set	  [Referred_To_Service_03] = b.snomed_description,
			  [Service_Request_Date_03]= x.[Service_Request_Date_03],
			  [Service_Request_Time_03]= x.[Service_Request_Time_03],
			  [Service_Assessment_Date_03]= x.[Service_Assessment_Date_03],
			  [Service_Assessment_Time_03]= x.[Service_Assessment_Time_03]
		


	  from #tempED z
	  inner join #tempRefToServ x on x.[EC_Ident] = z.[EC_Ident]
	  left join #SNOMED b on b.snomed_Code = x.[Referred_To_Service_04]
	  where x.[Referred_To_Service_04] is not null
	  	  	update z

		set	  [Referred_To_Service_04] = b.snomed_description,
			  [Service_Request_Date_04]= x.[Service_Request_Date_04],
			  [Service_Request_Time_04]= x.[Service_Request_Time_04],
			  [Service_Assessment_Date_04]= x.[Service_Assessment_Date_04],
			  [Service_Assessment_Time_04]= x.[Service_Assessment_Time_04]
		


	  from #tempED z
	  inner join #tempRefToServ x on x.[EC_Ident] = z.[EC_Ident]
	  left join #SNOMED b on b.snomed_Code = x.[Referred_To_Service_04]
	  where x.[Referred_To_Service_04] is not null
	
	
 

		IF OBJECT_ID('Tempdb..#tempEDDiagCodes') IS NOT NULL 
		drop table #tempEDDiagCodes  
		SELECT 
		[EC_Ident],
		[Unique Record ID],
		 null as [REduction in Inappropriate Flag],
		[MH All ED SNOMED Diagnosis Codes],
		[Diag1],
		a.SNOMED_Description as [Diag 1 Description],
		null as [Diag 1 MH Flag],
		[Diag2],
		b.SNOMED_Description as [Diag 2 Description],
		null as [Diag 2 MH Flag],
		[Diag3],
		c.SNOMED_Description as [Diag 3 Description],
		null as [Diag 3 MH Flag],
		[Diag4],
		d.SNOMED_Description as [Diag 4 Description],
		null as [Diag 4 MH Flag],
		[Diag5],
		e.SNOMED_Description as [Diag 5 Description],
		null as [Diag 5 MH Flag],
		[Diag6],
		f.SNOMED_Description as [Diag 6 Description],
		null as [Diag 6 MH Flag],
		[Diag7],
		g.SNOMED_Description as [Diag 7 Description],
		null as [Diag 7 MH Flag], 
		[Diag8],
		h.SNOMED_Description as [Diag 8 Description],
		null as [Diag 8 MH Flag],
		[Diag9],
		i.SNOMED_Description as [Diag 9 Description],
		null as [Diag 9 MH Flag],
		[Diag10],
		j.SNOMED_Description as [Diag 10 Description],
		null as [Diag 10 MH Flag],
		[Diag11],
		k.SNOMED_Description as [Diag 11 Description],
		null as [Diag 11 MH Flag],
		[Diag12],
		l.SNOMED_Description as [Diag 12 Description],
		null as [Diag 12 MH Flag], 
		[Diag13],
		m.SNOMED_Description as [Diag 13 Description],
		null as [Diag 13 MH Flag],
		[Diag14],
		n.SNOMED_Description as [Diag 14 Description] ,
		null as [Diag 14 MH Flag] 
		 
		into #tempEDDiagCodes  

		FROM ( 
		SELECT 
		[EC_Ident],
		[Unique Record ID], 
		[MH All ED SNOMED Diagnosis Codes],
		'Diag'+ CAST(ROW_NUMBER()OVER(PARTITION BY [Unique Record ID] ORDER BY [Unique Record ID]) AS VARCHAR) AS Col, 
		Split.value 
		FROM #tempED AS Emp 
		CROSS APPLY String_split([MH All ED SNOMED Diagnosis Codes],',') AS Split 
 
		) 
		AS tbl
		Pivot (Max(Value) FOR Col IN ([Diag1],[Diag2],[Diag3],[Diag4],[Diag5],[Diag6],[Diag7],[Diag8],[Diag9],[Diag10],[Diag11],[Diag12],[Diag13],[Diag14])
		) AS Pvt

		left join #SNOMED a on a.SNOMED_Code = ltrim(rtrim(Diag1))
		left join #SNOMED b on b.SNOMED_Code = ltrim(rtrim(Diag2))
		left join #SNOMED c on c.SNOMED_Code = ltrim(rtrim(Diag3))
		left join #SNOMED d on d.SNOMED_Code = ltrim(rtrim(Diag4))
		left join #SNOMED e on e.SNOMED_Code = ltrim(rtrim(Diag5))
		left join #SNOMED f on f.SNOMED_Code = ltrim(rtrim(Diag6))
		left join #SNOMED g on g.SNOMED_Code = ltrim(rtrim(Diag7))
		left join #SNOMED h on h.SNOMED_Code = ltrim(rtrim(Diag8))
		left join #SNOMED i on i.SNOMED_Code = ltrim(rtrim(Diag9))
		left join #SNOMED j on j.SNOMED_Code = ltrim(rtrim(Diag10))
		left join #SNOMED k on k.SNOMED_Code = ltrim(rtrim(Diag11))
		left join #SNOMED l on l.SNOMED_Code = ltrim(rtrim(Diag12))
		left join #SNOMED m on m.SNOMED_Code = ltrim(rtrim(Diag13))
		left join #SNOMED n on n.SNOMED_Code = ltrim(rtrim(Diag14))
	 

	--select * from  #tempEDDiagCodes

		IF OBJECT_ID('Tempdb..#tempMHDiag') IS NOT NULL 
		drop table #tempMHDiag
		select
		*
		into #tempMHDiag
		from 
		(
		select '52448006'  as DCode--- dementia
		union all  select '2776000' --- delirium 
		union all  select '33449004' --- personality disorder
		union all  select '72366004' --- eating disorder
		union all  select '197480006' --- anxiety disorder
		union all  select '35489007' --- depressive disorder
		union all  select '13746004' --- bipolar affective disorder
		union all  select '58214004' --- schizophrenia
		union all  select '69322001' --- psychotic disorder
		union all  select '397923000' --- somatisation disorder
		union all  select '30077003' --- somatoform pain disorder
		union all  select '44376007' --- dissociative disorder
		union all  select '17226007' ---- adjustment disorder
		union all  select '50705009'---- factitious disorder

 
		)s

 

	update dig
		set dig.[Diag 1 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag1]))

		update dig
		set dig.[Diag 2 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag2]))

		update dig
		set dig.[Diag 3 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag3]))

		update dig
		set dig.[Diag 4 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag4]))

		update dig
		set dig.[Diag 5 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag5]))

		update dig
		set dig.[Diag 6 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag6]))

		update dig
		set dig.[Diag 7 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag7]))

		update dig
		set dig.[Diag 8 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag8]))

		update dig
		set dig.[Diag 9 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag9]))

		update dig
		set dig.[Diag 10 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag10]))

		update dig
		set dig.[Diag 11 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag11]))

		update dig
		set dig.[Diag 12 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag12]))

		update dig
		set dig.[Diag 13 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag13]))

		update dig
		set dig.[Diag 14 MH Flag] = 1
	 from #tempEDDiagCodes dig
	inner join #tempMHDiag a on a.DCode = ltrim(rtrim([Diag14]))


		update f

			set [REduction in Inappropriate Flag] = case when [Diag 1 MH Flag] = 1 and [Diag 2 Description] is null then 1 else null end

		from  #tempEDDiagCodes f

		
		update MHD

		set mhd.[Reduction in Inappropriate Flag] = edc.[REduction in Inappropriate Flag],
			mhd.[Secondary Diagnosis Code] = edc.Diag2,
			mhd.[Secondary Diagnosis Description] = edc.[Diag 2 Description],
			mhd.[Third Diagnosis Code] = edc.Diag3,
			mhd.[Third Diagnosis Description] = edc.[Diag 3 Description],
			mhd.[Fourth Diagnosis Code] = edc.Diag4,
			mhd.[Fourth Diagnosis Description] = edc.[Diag 4 Description]

		from #tempED MHD
		inner join #tempEDDiagCodes edc on edc.EC_Ident = MHD.EC_Ident






		insert into [PATLondon].[ECDS_Presentation_Diagnosis_Codes_and_Descriptions]
		
		select * from #tempEDDiagCodes a
		where not exists
					(
					select 
					EC_Ident 
					from [PATLondon].[ECDS_Presentation_Diagnosis_Codes_and_Descriptions]x 
					where x.ec_ident = a.EC_Ident
					)


 




					delete f from [PATLondon].[ECDS_All_Presentations_London]f where Arrival_Date >= @StartDate


		  
insert into [PATLondon].[ECDS_All_Presentations_London]
		select 
* 
 
from #tempED
 
 drop table #tempED
  
 

 
 IF OBJECT_ID('Tempdb..#tempRef') IS NOT NULL 
dROP TABLE #tempRef
 
 select 
 
 ROW_NUMBER() OVER (
PARTITION BY  a.UniqServReqID ,a.OrgIDProv
ORDER BY  a.UniqMonthID DEsc , a.UniqSubmissionID desc ) as RowOrder,
a.UniqServReqID,
 sor.Description as [Source of Referral] ,
 a.ReferralRequestReceivedDate,
 a.ServDischDate,
 st.ReferRejectionDate,
 b.Der_Pseudo_NHS_Number 
 into #tempRef

 FROM [MESH_MHSDS].[MHS101Referral_2]a with(nolock)
 inner JOIN [MESH_MHSDS].[MHSDS_SubmissionFlags_1] sf with(nolock) ON sf.NHSEUniqSubmissionID = a.NHSEUniqSubmissionID AND sf.Der_IsLatest = 'Y'
 left JOIN [MESH_MHSDS].[MHS102ServiceTypeReferredTo_2] st with(nolock) ON st.RecordNumber = a.RecordNumber AND a.UniqServReqID = st.UniqServReqID
 left join [PATLondon].[DIM_Date] dt with(nolock) on dt.[Calendar Day] = a.ReferralRequestReceivedDate
 left join [MESH_MHSDS].[MHS001MPI_2]b with(nolock) on b.Person_ID = a.Person_ID
											and b.UniqSubmissionID = a.UniqSubmissionID
											and b.UniqMonthID = a.UniqMonthID
											and b.RecordNumber = a.RecordNumber
 
left join [PATLondon].[Ref_Source_Of_Referral_for_Mental_Health_Services]sor with(nolock)  on sor.Code = a.SourceOfReferralMH
left join [PATLondon].[MH_ALL_ED_Referrals]plr on plr.UniqServReqID = a.UniqServReqID
 

	 WHERE
	 A.ReferralRequestReceivedDate >=  @StartDate  
	 and plr.UniqServReqID is null

	delete from #tempRef where RowOrder <> 1
 

	delete a  from [PATLondon].[MH_ALL_ED_Referrals]a where exists (select x. UniqServReqID from #tempRef x where x.UniqServReqID = a.UniqServReqID)

	IF EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('[PATLondon].[MH_ALL_ED_Referrals]') AND NAME ='ix_ED_Referral')
	DROP INDEX ix_ED_Referral ON [PATLondon].[MH_ALL_ED_Referrals]

  
		insert into  [PATLondon].[MH_ALL_ED_Referrals]
		select 
		distinct
		RowOrder,
		UniqServReqID,
		convert(date,ReferralRequestReceivedDate) as ReferralRequestReceivedDate,
		[Source of Referral],
		convert(date,ServDischDate) as ServDischDate,
		convert(date,ReferRejectionDate) as ReferRejectionDate,
		Der_Pseudo_NHS_Number,
		null as  der_Is_Latest
 
		from #tempRef
		


		 CREATE INDEX ix_ED_Referral ON [PATLondon].[MH_ALL_ED_Referrals] ( UniqServReqID, Der_Pseudo_NHS_Number,ReferralRequestReceivedDate)


 
 
	 update x

	 set x.[Known to MH Services Flag] = case
										--when (datediff(day, ccc.ReferralRequestReceivedDate,convert(date,x.Arrival_Date) )= 0 and ccc.[Source of Referral] <> 'Acute Secondary Care: Emergency Care Department' )
										--then 1
										when 
										   ( (datediff(day, ccc.ReferralRequestReceivedDate,convert(date,x.Arrival_Date) )>= 0) and datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date,x.Arrival_Date)) <=6  )		
										   then 1							 
										When
											(
												(datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date,x.Arrival_Date))>6 )
											and (ServDischDate is null or (ServDischDate > Arrival_Date))
											and (ReferRejectionDate is null or (ReferRejectionDate > Arrival_Date))
											)
									 
										  then 1 
										else null
										end
										,


	x.[Derived Broad Ethnic Category] = case when  [Ethnic Category] is null and x.[Derived Broad Ethnic Category] is null then 'Not Known / Not Stated / Incomplete' else x.[Derived Broad Ethnic Category] end


	 from [PATLondon].[ECDS_All_Presentations_London]x
	left join [PATLondon].[MH_ALL_ED_Referrals] ccc on ccc.Der_Pseudo_NHS_Number = x.Der_Pseudo_NHS_Number	
													and ccc.ReferralRequestReceivedDate <= x.Arrival_Date
	where x.Arrival_Date >= @StartDate
	
 

 

	update f

		 set f.[Known to MH Services Flag] = case
											  when ccc.[Source of Referral] = 'Acute Secondary Care: Emergency Care Department'  
													then null
												else f.[Known to MH Services Flag]
											End

	from [PATLondon].[ECDS_All_Presentations_London]f
	inner join [PATLondon].[MH_ALL_ED_Referrals]ccc on ccc.Der_Pseudo_NHS_Number = f.Der_Pseudo_NHS_Number	
													and convert(date,ccc.ReferralRequestReceivedDate)  = convert(date,f.Arrival_Date)
	where f.Arrival_Date >= @StartDate

	update f

		 set f.[Known to MH Services Flag] = 1

	from [PATLondon].[ECDS_All_Presentations_London]f
	inner join [PATLondon].[MH_ALL_ED_Referrals] ccc on ccc.Der_Pseudo_NHS_Number = f.Der_Pseudo_NHS_Number	

	where 
	(
	datediff(day, ccc.ReferralRequestReceivedDate,convert(date,f.Arrival_Date)) > 0
	and 
	datediff(month, ccc.ReferralRequestReceivedDate,convert(date,f.Arrival_Date)) <=6
	)
	and ccc.[Source of Referral] = 'Acute Secondary Care: Emergency Care Department'  
	and f.Arrival_Date >= @StartDate												 

 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 --07/05/2025 added new columns to see what difference extending "Known" out to 24 months makes.

 


  update x

	 set x.[KnownInLast24Months] = case
										--when (datediff(day, ccc.ReferralRequestReceivedDate,convert(date,x.Arrival_Date) )= 0 and ccc.[Source of Referral] <> 'Acute Secondary Care: Emergency Care Department' )
										--then 1
										when 
										   ( (datediff(day, ccc.ReferralRequestReceivedDate,convert(date,x.Arrival_Date) )>= 0) and datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date,x.Arrival_Date)) <=24  )		
										   then 1							 
										When
											(
												(datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date,x.Arrival_Date))>24 )
											and (ServDischDate is null or (ServDischDate > Arrival_Date))
											and (ReferRejectionDate is null or (ReferRejectionDate > Arrival_Date))
											)
									 
										  then 1 
										else null
										end
										
	 from [PATLondon].[ECDS_All_Presentations_London]x
	left join [PATLondon].[MH_ALL_ED_Referrals] ccc on ccc.Der_Pseudo_NHS_Number = x.Der_Pseudo_NHS_Number	
													and ccc.ReferralRequestReceivedDate <= x.Arrival_Date
	where x.Arrival_Date >= @StartDate
	
 


	update f

		 set f.[KnownInLast24Months] = case
											  when ccc.[Source of Referral] = 'Acute Secondary Care: Emergency Care Department'  
													then null
												else f.[KnownInLast24Months]
											End

	from [PATLondon].[ECDS_All_Presentations_London]f
	inner join [PATLondon].[MH_ALL_ED_Referrals]ccc on ccc.Der_Pseudo_NHS_Number = f.Der_Pseudo_NHS_Number	
													and convert(date,ccc.ReferralRequestReceivedDate)  = convert(date,f.Arrival_Date)
	where f.Arrival_Date >= @StartDate

	update f

		 set f.[KnownInLast24Months] = 1

	from [PATLondon].[ECDS_All_Presentations_London]f
	inner join [PATLondon].[MH_ALL_ED_Referrals] ccc on ccc.Der_Pseudo_NHS_Number = f.Der_Pseudo_NHS_Number	

	where 
	(
	datediff(day, ccc.ReferralRequestReceivedDate,convert(date,f.Arrival_Date)) > 0
	and 
	datediff(month, ccc.ReferralRequestReceivedDate,convert(date,f.Arrival_Date)) <=24
	)
	and ccc.[Source of Referral] = 'Acute Secondary Care: Emergency Care Department'  
	and f.Arrival_Date >= @StartDate												 




	---Previously known

	

  update x

	 set x.[PreviouslyKnown] = case
										when 
										   ( (datediff(day, ccc.ReferralRequestReceivedDate,convert(date,x.Arrival_Date) )>= 0) and datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date,x.Arrival_Date)) >24  )		
										   then 1							 
										When
											(
												(datediff(MONTH,ccc.ReferralRequestReceivedDate,convert(date,x.Arrival_Date))>24 )
											and (ServDischDate is null or (ServDischDate > Arrival_Date))
											and (ReferRejectionDate is null or (ReferRejectionDate > Arrival_Date))
											)
									 
										  then 1 
										else null
										end
										
	 from [PATLondon].[ECDS_All_Presentations_London]x
	left join [PATLondon].[MH_ALL_ED_Referrals] ccc on ccc.Der_Pseudo_NHS_Number = x.Der_Pseudo_NHS_Number	
													and ccc.ReferralRequestReceivedDate <= x.Arrival_Date
	where x.Arrival_Date >= @StartDate
	
 

 --22/04/2024 12:07 - up to here...


	update f

		 set f.[PreviouslyKnown] = case
											  when ccc.[Source of Referral] = 'Acute Secondary Care: Emergency Care Department'  
													then null
												else f.[PreviouslyKnown]
											End

	from [PATLondon].[ECDS_All_Presentations_London]f
	inner join [PATLondon].[MH_ALL_ED_Referrals]ccc on ccc.Der_Pseudo_NHS_Number = f.Der_Pseudo_NHS_Number	
													and convert(date,ccc.ReferralRequestReceivedDate)  = convert(date,f.Arrival_Date)
	where f.Arrival_Date >= @StartDate

	update f

		 set f.[PreviouslyKnown] = 1

	from [PATLondon].[ECDS_All_Presentations_London]f
	inner join [PATLondon].[MH_ALL_ED_Referrals] ccc on ccc.Der_Pseudo_NHS_Number = f.Der_Pseudo_NHS_Number	

	where 
	(
	datediff(day, ccc.ReferralRequestReceivedDate,convert(date,f.Arrival_Date)) > 0
	and 
	datediff(month, ccc.ReferralRequestReceivedDate,convert(date,f.Arrival_Date)) >24
	)
	and ccc.[Source of Referral] = 'Acute Secondary Care: Emergency Care Department'  
	and f.Arrival_Date >= @StartDate												 

 




	
	update y

	set y.[Ethnic proportion per 100000 of London Borough 2020] =  cast((1/NULLIF(convert(float,ep.Value),0)) as float) *100000   

	from [PATLondon].[ECDS_All_Presentations_London]y 
	left join [PATLondon].[Ref_Ethnicity_2020_Census_Population_by_London_Borough]ep on ep.[Broad Ethnic Category] = y.[Derived Broad Ethnic Category]
																										and ep.Borough= y.[Patient GP Local Authority Name]

	where y.[Ethnic proportion per 100000 of London Borough 2020]is null

DROP INDEX ix_ED_Attendance ON [PATLondon].[ECDS_All_Presentations_London]

CREATE INDEX ix_ED_Attendance ON [PATLondon].[ECDS_All_Presentations_London] ([Unique Record ID], EC_Ident, Unique_CDS_identifier, [arrival date time])
 	

 


		update f
		set  f.[Last Completed IP Spell] = (select Max(DischDateHospProvSpell) from #tempHO1 z where z.DischDateHospProvSpell < f.Arrival_Date and z.Der_Pseudo_NHS_Number = f.Der_Pseudo_NHS_Number  )

		from [PATLondon].[ECDS_All_Presentations_London]f
		inner join #tempHO1 g on g.Der_Pseudo_NHS_Number = f.Der_Pseudo_NHS_Number
		where f.Der_Pseudo_NHS_Number is not null
		and f.Arrival_Date >= @StartDate

 

		update f
		set  f.[IP Spell Provider Name] = g.Provider_Name,
		f.[UniqHospProvSpellID] = g.UniqHospProvSpellID,
		f.[IP Spell UniqServReqID] = g.UniqServReqID

		from [PATLondon].[ECDS_All_Presentations_London]f
		inner join #tempHO1 g on g.Der_Pseudo_NHS_Number = f.Der_Pseudo_NHS_Number
		and g.DischDateHospProvSpell = f.[Last Completed IP Spell]
		and f.Arrival_Date >= @StartDate
 
		update s

		set s.[Days between Completed IP Spell and ED Presentation] = DATEDIFF(day,[Last Completed IP Spell],Arrival_Date),
		s.[ED Presentation within 28 days of Completed IP SPell]=  case when DATEDIFF(day,[Last Completed IP Spell],Arrival_Date) <=28 then 1 else null end

		from [PATLondon].[ECDS_All_Presentations_London]s 
		where [Last Completed IP Spell] is not null
		and s.Arrival_Date >= @StartDate



 