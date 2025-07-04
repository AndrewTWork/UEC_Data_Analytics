 
	
declare @StartDate  Date,@EndDate date
	set @StartDate = '2015-01-01'--convert(datetime, cast(year(dateadd(month, -3, (select min( convert(date,Date_Original_Approval)) from [ETL_Local_PROD].[dbo].[Cache-PatientDetailSpan]))) as varchar(10)) + '-04-01', 120)
	set @EndDate = dateadd(year,2,convert(datetime, cast(year(dateadd(year,1,dateadd(month, -3, getdate()))) as varchar(10)) + '-04-01', 120))
	--print Convert(varchar,(year(dateadd(month, 9, convert(date,dateadd(d,-1,@StartDate)) )) - 1)) + '/' + right(convert(varchar,(year(dateadd(month, 9, convert(date,dateadd(d,-1,@StartDate)) )))),2)
	--set @StartDate = convert(datetime, cast(year(dateadd(month, -3, getdate())) as varchar(10)) + '-04-01', 120)
	--set @EndDate =  dateadd(YEAR,1,dateadd(day,-1,@StartDate))
	--print @StartDate
	--print @EndDate
 
		if OBJECT_ID('[PATLondon].[DIM_Date]') is not null
		drop table [PATLondon].[DIM_Date] 
 
	
	;WITH cte AS 
	(
	SELECT 
	DATEPART(Day,@StartDate)as RowNumb,
	CONVERT(VARCHAR,@StartDate,112) as ID,
	@StartDate as [Calendar Day],
	DATEPART(WEEKDAY, @startdate) as [Week Day],
	DATEPART(DAY,@StartDate) as [Day of Month], 
	 CASE        
  WHEN DATEPART(DAY,@StartDate) = 1 THEN CAST(DATEPART(DAY,@StartDate) AS VARCHAR) + 'st'         
  WHEN DATEPART(DAY,@StartDate) = 2 THEN CAST(DATEPART(DAY,@StartDate) AS VARCHAR) + 'nd'         
  WHEN DATEPART(DAY,@StartDate) = 3 THEN CAST(DATEPART(DAY,@StartDate) AS VARCHAR) + 'rd'         
  ELSE CAST(DATEPART(DAY,@StartDate) AS VARCHAR) + 'th'    
  END as [DaySuffix], 
  DATENAME(dw, @StartDate) as [Day Of Week],     
   DATEPART(DAYOFYEAR,@StartDate) as [Day Of Year],    
    DATEPART(WEEK,@StartDate) as [Week Of Year],     
    DATEPART(WEEK,@StartDate) + 1 - DATEPART(WEEK,CAST(DATEPART(MONTH,@StartDate) AS VARCHAR) 
    + '/1/' + CAST(DATEPART(YEAR,@StartDate) AS VARCHAR)) as [Week Of Month],     
    DATEPART(MONTH,@StartDate) as [Month],     
    DATENAME(MONTH,@StartDate) as [Month Name], 
	convert(date,dateadd(month,-1,DATEADD(m, DATEDIFF(m, 0, @StartDate) + 1, 0)))  AS [Month Start Date],
	eomonth(@StartDate) as [Month End Date],
	 convert(date,convert(datetime, cast(year(dateadd(month, -3, @StartDate)) as varchar(10)) + '-04-01', 120)) as [Year Start Date],
	 convert(date,dateadd(YEAR,1,dateadd(day,-1, convert(datetime, cast(year(dateadd(month, -3, @StartDate)) as varchar(10)) + '-04-01', 120)))) as [Year End Date],
	 CASE DATEPART(QUARTER,@StartDate)   
	 WHEN 1 THEN 4       
    WHEN 2 THEN 1      
     WHEN 3 THEN 2        
     WHEN 4 THEN 3   
     END 
	 as [Quarter],     
    CASE DATEPART(QUARTER,@StartDate)         
    WHEN 1 THEN 'Fourth'        
    WHEN 2 THEN 'First'       
     WHEN 3 THEN 'Second'        
     WHEN 4 THEN 'Third'    
     END as [Quarter Name],     
     DATEPART(YEAR,@StartDate) as [Year] ,
	 Convert(varchar,(year(dateadd(month, 9, convert(date,@StartDate)) ) - 1)) + '/' 
	 + right(convert(varchar,(year(dateadd(month, 9, convert(date,@StartDate)) ))),2) as [Financial Year],
	 case when @StartDate = convert(date,dateadd(month,-1,DATEADD(m, DATEDIFF(m, 0, @StartDate) + 1, 0))) then 1 else 0 end as [Month Start Date Flag],
	 case when @StartDate = eomonth(@StartDate) then 1 else 0 end as [Month End Date Flag],
	 case when @StartDate = convert(date,convert(datetime, cast(year(dateadd(month, -3, @StartDate)) as varchar(10)) + '-04-01', 120)) then 1 else 0 end as [Fin Year Start Date Flag],
	 case when @StartDate = convert(date,dateadd(YEAR,1,dateadd(day,-1, convert(datetime, cast(year(dateadd(month, -3, @StartDate)) as varchar(10)) + '-04-01', 120)))) then 1 else 0 end as [Fin Year End Date Flag],
	 CASE WHEN DATENAME(WEEKDAY, @startdate) in ('Saturday', 'Sunday') THEN 1 ELSE 0 END as [Weekend Flag]
	-- ,
	--CASE WHEN @startdate IN (SELECT LOH.DateOfHoliday FROM [Informatics_Reporting].[dbo].[ListOfHolidays] LOH ) THEN 1 ELSE 0 END as [Holiday Flag]
	   
	UNION ALL

	SELECT
	RowNumb+1  ,--this is a field to be used with the for loop below
	CONVERT(VARCHAR,dateadd(day,1,[Calendar Day]),112) as ID, 
	dateadd(day,1,[Calendar Day]),
	DATEPART(WEEKDAY, dateadd(day,1,[Calendar Day])) ,
		DATEPART(DAY,dateadd(day,1,[Calendar Day])) , 
	 CASE        
  WHEN DATEPART(DAY,dateadd(day,1,[Calendar Day])) = 1 THEN CAST(DATEPART(DAY,dateadd(day,1,[Calendar Day])) AS VARCHAR) + 'st'         
  WHEN DATEPART(DAY,dateadd(day,1,[Calendar Day])) = 2 THEN CAST(DATEPART(DAY,dateadd(day,1,[Calendar Day])) AS VARCHAR) + 'nd'         
  WHEN DATEPART(DAY,dateadd(day,1,[Calendar Day])) = 3 THEN CAST(DATEPART(DAY,dateadd(day,1,[Calendar Day])) AS VARCHAR) + 'rd'         
  ELSE CAST(DATEPART(DAY,dateadd(day,1,[Calendar Day])) AS VARCHAR) + 'th'    
  END , 
  DATENAME(dw, dateadd(day,1,[Calendar Day])) as [Day Of Week],     
   DATEPART(DAYOFYEAR,dateadd(day,1,[Calendar Day])) as [Day Of Year],    
    DATEPART(WEEK,dateadd(day,1,[Calendar Day])) as [Week Of Year],     
    DATEPART(WEEK,dateadd(day,1,[Calendar Day])) + 1 - DATEPART(WEEK,CAST(DATEPART(MONTH,dateadd(day,1,[Calendar Day])) AS VARCHAR) 
    + '/1/' + CAST(DATEPART(YEAR,dateadd(day,1,[Calendar Day])) AS VARCHAR)) as [Week Of Month],     
    DATEPART(MONTH,dateadd(day,1,[Calendar Day])) as [Month],     
    DATENAME(MONTH,dateadd(day,1,[Calendar Day])) as [Month Name], 
	convert(date,dateadd(month,-1,DATEADD(m, DATEDIFF(m, 0, dateadd(day,1,[Calendar Day])) + 1, 0)))  AS [Month Start Date],
	eomonth(dateadd(day,1,[Calendar Day])) as [Month End Date],
	 convert(date,convert(datetime, cast(year(dateadd(month, -3, dateadd(day,1,[Calendar Day]))) as varchar(10)) + '-04-01', 120)) as [Year Start Date],
	 convert(date,dateadd(YEAR,1,dateadd(day,-1, convert(datetime, cast(year(dateadd(month, -3, dateadd(day,1,[Calendar Day]))) as varchar(10)) + '-04-01', 120)))) as [Year End Date],
	 CASE DATEPART(QUARTER,dateadd(day,1,[Calendar Day]))   
	 WHEN 1 THEN 4       
    WHEN 2 THEN 1      
     WHEN 3 THEN 2        
     WHEN 4 THEN 3   
     END 
	 as [Quarter],     
    CASE DATEPART(QUARTER,dateadd(day,1,[Calendar Day]))         
    WHEN 1 THEN 'Fourth'        
    WHEN 2 THEN 'First'       
     WHEN 3 THEN 'Second'        
     WHEN 4 THEN 'Third'    
     END as [Quarter Name],     
     DATEPART(YEAR,dateadd(day,1,[Calendar Day])) as [Year] ,
	 Convert(varchar,(year(dateadd(month, 9, convert(date,dateadd(day,1,[Calendar Day]))) ) - 1)) + '/' 
	 + right(convert(varchar,(year(dateadd(month, 9, convert(date,dateadd(day,1,[Calendar Day]))) ))),2),
	 case when dateadd(day,1,[Calendar Day]) = convert(date,dateadd(month,-1,DATEADD(m, DATEDIFF(m, 0, dateadd(day,1,[Calendar Day])) + 1, 0))) then 1 else 0 end as [Month Start Date Flag],
	 case when dateadd(day,1,[Calendar Day]) = eomonth(dateadd(day,1,[Calendar Day])) then 1 else 0 end as [Month End Date Flag],
	 case when dateadd(day,1,[Calendar Day]) = convert(date,convert(datetime, cast(year(dateadd(month, -3, dateadd(day,1,[Calendar Day]))) as varchar(10)) + '-04-01', 120)) then 1 else 0 end as [Fin Year Start Date Flag],
	 case when dateadd(day,1,[Calendar Day]) = convert(date,dateadd(YEAR,1,dateadd(day,-1, convert(datetime, cast(year(dateadd(month, -3, dateadd(day,1,[Calendar Day]))) as varchar(10)) + '-04-01', 120)))) then 1 else 0 end as [Fin Year End Date Flag],
	 CASE WHEN DATENAME(WEEKDAY, dateadd(day,1,[Calendar Day])) in ('Saturday', 'Sunday') THEN 1 ELSE 0 END as [Weekend Flag]
	 --,
	--CASE WHEN dateadd(day,1,[Calendar Day]) IN (SELECT LOH.DateOfHoliday FROM [Informatics_Reporting].[dbo].[ListOfHolidays] LOH ) THEN 1 ELSE 0 END as [Holiday Flag]

	FROM cte
	WHERE  [Calendar Day] <  dateadd(day,-1,@EndDate)
	)

	

	

	SELECT 
		ID,
		[Calendar Day],
		[Week Day],
		[Day of Month], 
		[DaySuffix], 
		[Day Of Week],     
		[Day Of Year],    
		[Week Of Year],     
		[Week Of Month],     
		[Month],     
		[Month Name], 
		[Month Start Date],
		[Month End Date],
		[Year Start Date],
		[Year End Date],
		[Quarter],     
		[Quarter Name],     
		[Year] ,
		[Financial Year],
		[Month Start Date Flag],
		[Month End Date Flag],
		[Fin Year Start Date Flag],
		[Fin Year End Date Flag],
		[Weekend Flag]
		--,
		--[Holiday Flag]
	into [PATLondon].[DIM_Date]
	FROM cte
	OPTION (MAXRECURSION 0)

	
	
ALTER TABLE [PATLondon].[DIM_Date]  ADD PK_DateKey int identity(1,1) not null

ALTER TABLE [PATLondon].[DIM_Date]
add CONSTRAINT  Date_PK  PRIMARY KEY CLUSTERED(PK_DateKey)

	  
