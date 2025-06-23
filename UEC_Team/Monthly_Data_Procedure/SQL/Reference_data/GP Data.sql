 

	
			
			if object_id('Tempdb..#TempGP1') is not null				
			drop table #TempGP1
			SELECT 
			DISTINCT
			B.[GP_Code] AS GP_CODE
			,B.[GP_PCN_Code] AS GP_PCN_Code
			,B.[GP_PCN_Name] AS GP_PCN_Name
			,B.[GP_STP_Code] AS [GP_STP_Code]
			,Replace(B.[GP_STP_Name],' INTEGRATED CARE BOARD','')   AS GP_STP_Name
			,B.[GP_Region_Code] AS GP_Region_Code
			,Replace(B.[GP_Region_Name],' COMMISSIONING REGION','') AS GP_Region_Name
			,C.PRACTICE AS Practice_code	
			,C.[CCG2019_20_Q4] AS CCG1920
			,Replace(D.Organisation_Name,' CCG','')  AS [New CCG]
				 
			into #TempGP1

			FROM  [Reporting_UKHD_ODS].[GP_Hierarchies_All_1] B 	
			LEFT JOIN  [Internal_Reference].[RightCare_practice_CCG_pcn_quarter_lookup_1] C ON B.[GP_Code] COLLATE DATABASE_DEFAULT = C.Practice COLLATE DATABASE_DEFAULT
			LEFT JOIN [Reporting_UKHD_ODS].[Commissioner_Hierarchies] D ON D.Organisation_Code  COLLATE DATABASE_DEFAULT  = C.[CCG2019_20_Q4]  COLLATE DATABASE_DEFAULT
			
 

			if object_id('Tempdb..#TempGP2') is not null				
			drop table #TempGP2
			SELECT 
			DISTINCT 
			GP_PCN_Code, 
			GP_PCN_Name, 
			[New CCG], 
			COUNT(GP_PCN_NAME) AS GPS 
			into #TempGP2
			FROM #TempGP1 x
			GROUP BY 
			GP_PCN_Code, 
			GP_PCN_Name, 
			[New CCG]

			if object_id('Tempdb..#TempGP3') is not null				
			drop table #TempGP3
			SELECT 
			GP_PCN_Code, 
			GP_PCN_Name, 
			[New CCG],
			ROW_NUMBER() OVER (PARTITION BY GP_PCN_Code, GP_PCN_Name ORDER BY GPS DESC) AS LA_ORDER
			into #TempGP3
			FROM  #TempGP2 


 

					
			if object_id('Tempdb..#TempGP4') is not null				
			drop table #TempGP4
			SELECT 
			DISTINCT
			B.[GP_Code] AS GP_CODE
			,b.GP_Name
			,B.[GP_PCN_Code] AS GP_PCN_Code
			,B.[GP_PCN_Name] AS GP_PCN_Name
			,B.[GP_STP_Code] AS [GP_STP_Code]
			,Replace(B.[GP_STP_Name],' INTEGRATED CARE BOARD','')   AS GP_STP_Name
			,B.[GP_Region_Code] AS GP_Region_Code
			,Replace(B.[GP_Region_Name],' COMMISSIONING REGION','') AS GP_Region_Name
			,C.PRACTICE AS Practice_code	
			,C.[CCG2019_20_Q4] AS CCG1920
			,REPLACE([GP_Postcode] , ' ', '') as [PCDS_NoGaps]   
			,REPLACE(left([GP_Postcode],7) , ' ', '') as [PCDS_7] 
			,REPLACE(left([GP_Postcode],6) , ' ', '') as [PCDS_6] 
			,REPLACE(left([GP_Postcode],5) , ' ', '')as [PCDS_5] 
			,REPLACE(left([GP_Postcode],4)  , ' ', '')as [PCDS_4] 
			,ltrim(rtrim(left( [GP_Postcode] ,3))) as [PCDS_3] 
					 
		 
			,Z.[New CCG] AS [New CCG]
			,ROW_NUMBER() OVER (PARTITION BY GP_CODE ORDER BY CASE WHEN GP_PCN_Rel_End_Date IS NULL THEN 1 ELSE 0 END DESC, GP_PCN_Rel_End_Date DESC) AS GP_ORDER,
			cast(null as varchar(9)) as [Lower_Super_Output_Area_Code],
			cast(null as varchar(80)) as [Lower_Super_Output_Area_Name],
			cast(null as varchar(9)) as [Middle_Super_Output_Area_Code],
			cast(null as varchar(80)) as [Middle_Super_Output_Area_Name],
			cast(null as varchar(9)) as [Longitude],
			cast(null as varchar(9)) as [Latitude],
			cast(null as varchar(40)) as [Spatial_Accuracy]
			into  #TempGP4
			FROM  [Reporting_UKHD_ODS].[GP_Hierarchies_All_1] B 
			LEFT JOIN  [Internal_Reference].[RightCare_practice_CCG_pcn_quarter_lookup_1] C ON B.[GP_Code] COLLATE DATABASE_DEFAULT = C.Practice COLLATE DATABASE_DEFAULT
			LEft Join #TempGP3 z on z.GP_PCN_CODE = B.GP_PCN_CODE
					 
			where z.LA_ORDER = 1
 



			update f

			set f.[Lower_Super_Output_Area_Code] = g.[Lower_Super_Output_Area_Code],
			f.[Lower_Super_Output_Area_Name] = g.[Lower_Super_Output_Area_Name],
			f.[Middle_Super_Output_Area_Code] = g.[Middle_Super_Output_Area_Code],
			f.[Middle_Super_Output_Area_Name] = g.[Middle_Super_Output_Area_Name],
			f.[Longitude] = g.[Longitude],
			f.[Latitude] = g.[Latitude],
			f.[Spatial_Accuracy] = g.[Spatial_Accuracy]

			from #TempGP4  f
			inner join [UKHD_Other].[National_Statistics_Postcode_Lookup_SCD_1] g on REPLACE([Postcode_1] , ' ', '') = f.[PCDS_NoGaps]

		 


					 
										
			if object_id('[PATLondon].[Ref_GP_Data]') is not null				
			drop table [PATLondon].[Ref_GP_Data]
			select
			GP_CODE
			,Practice_code as [GP_Practice_Code]	
			,GP_Name
			,GP_PCN_Code
			,GP_PCN_Name
			,[GP_STP_Code]
			,GP_STP_Name
			,GP_Region_Code
			,GP_Region_Name
							
			,CCG1920
			,[PCDS_NoGaps]   
		 
			,la.Name as  [Local_Authority]
			,[Lower_Super_Output_Area_Code]
			,[Lower_Super_Output_Area_Name]
			,[Middle_Super_Output_Area_Code]
			,[Middle_Super_Output_Area_Name]
			,[Longitude]
			,[Latitude]
			,[Spatial_Accuracy]
			into [PATLondon].[Ref_GP_Data] 
			
			from #TempGP4 b
			left join [PATLondon].[Ref_PostCode_to_Local_Authority]la on la.[PostCode No Gaps] = [PCDS_NoGaps]

			where GP_ORDER = 1



			update gp
					set gp.[Local_Authority]	= coalesce(la2.Name,la3.Name,la4.Name,la5.Name)
			from [PATLondon].[Ref_GP_Data] gp
			inner join #TempGP4 gp4 on gp4.Practice_code = gp.GP_Practice_Code
		left join [PATLondon].[Ref_PostCode_to_Local_Authority]la2 on left(la2.[PostCode No Gaps],7)  = gp4.PCDS_7 --This is Reference I creates from the ONS Postcode file 
		left join [PATLondon].[Ref_PostCode_to_Local_Authority]la3 on left(la3.[PostCode No Gaps],6)  = gp4.PCDS_6 --It does exist in a form in this table (needs lookup for LA Name
		left join [PATLondon].[Ref_PostCode_to_Local_Authority]la4 on left(la4.[PostCode No Gaps],5)  = gp4.PCDS_5 --[UKHD_National_Stats_UPRN].[Lookup_SCD]
		left join [PATLondon].[Ref_PostCode_to_Local_Authority]la5 on left(la5.[PostCode No Gaps],4)  = gp4.PCDS_4
		where gp.[Local_Authority]is null



		IF OBJECT_ID('[PATLondon].[Ref_Trusts_and_Sites]') IS NOT NULL 
			dROP TABLE  [PATLondon].[Ref_Trusts_and_Sites]
			select 
			Distinct
			a.Parent_Organisation_Code,
			b.Organisation_Name as [Parent Organisation Name],
			b.Postcode as [Parent Organisation Postcode],
			left(b.Postcode,3) as [Parent Organisation Postcode District],
			c.[yr2011_LSOA] as  [Parent Organisation yr2011 LSOA],
			case when a.Parent_Organisation_Code in ('RAT','RKL','RPG','RQY','RRP','RV3','RV5','RWK','TAF')	then 1 else null end as [MH Trust Flag],
			cast(null as varchar(255)) as [MH Provider Abbrev],
			a.Organisation_Code as [Site Organisation Code],
			a.Organisation_Name as [Site Name],
			a.Postcode as [Site  Postcode],
			left(a.Postcode,3) as [Site Postcode District],
			d.[yr2011_LSOA] as  [Site yr2011 LSOA] 

			into [PATLondon].[Ref_Trusts_and_Sites]

			from [UKHD_ODS].[NHS_Trusts_SCD_1]b 
			left join [UKHD_ODS].[NHS_Trust_Sites_Assets_And_Units_SCD_1]a  on b.Organisation_Code = a.Parent_Organisation_Code and a.[Is_Latest] = 1
			left join [UKHD_ODS].[Postcode_Grid_Refs_Eng_Wal_Sco_And_NI_SCD_1]c on  REPLACE(c.[Postcode_8_chars] , ' ', '') =  REPLACE(b.Postcode , ' ', '') and c.[Is_Latest] = 1
			left join [UKHD_ODS].[Postcode_Grid_Refs_Eng_Wal_Sco_And_NI_SCD_1]d on  REPLACE(d.[Postcode_8_chars] , ' ', '') =  REPLACE(a.Postcode , ' ', '') and d.[Is_Latest] = 1
		
			where b.[Is_Latest] = 1
			
					update r
					    set r.[MH Provider Abbrev] = case
							when Parent_Organisation_Code = 'RAT' then 'NELFT'
							when Parent_Organisation_Code = 'RKL' then 'WLT'
							when Parent_Organisation_Code = 'RV3' then 'CNWL'
							when Parent_Organisation_Code = 'RPG' then 'OXLEAS'
							when Parent_Organisation_Code = 'RWK' then 'ELFT'
							when Parent_Organisation_Code = 'RRP' then 'BEH'
							when Parent_Organisation_Code = 'RQY' then 'SWLStG'
							when Parent_Organisation_Code = 'RV5' then 'SLAM'
							when Parent_Organisation_Code = 'TAF' then 'CANDI'
							else null end


					from [PATLondon].[Ref_Trusts_and_Sites] r



 