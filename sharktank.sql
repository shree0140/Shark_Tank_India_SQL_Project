USE shark_tank_india;

SELECT * FROM sharktank;   -- still does't show complete data as data encoded, thus using INLINE method to get complete data.
TRUNCATE TABLE sharktank;

-- importing data using INLINE method

LOAD DATA INFILE "D:/SHARK_TANK_INDIA_CLEAN_DATASET/sharktank_1.csv"
INTO TABLE sharktank
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

 

/* #	You Team must promote shark Tank India season 4,
 The senior come up with the idea to show highest funding domain wise so that new startups can be attracted,
 and you were assigned the task to show the same. */
 
 SELECT * FROM
	(
	SELECT   industry ,Total_Deal_Amount_in_lakhs, ROW_NUMBER() OVER(PARTITION BY industry ORDER BY  Total_Deal_Amount_in_lakhs DESC) AS 'industry_investment_rank' 
    FROM sharktank
	) AS a WHERE industry_investment_rank=1;


/* #	You have been assigned the role of finding the domain where female as pitchers have female to male pitcher ratio >70% */

SELECT * ,((Female_Presenter/Male_Presenter)*100) AS 'female_to_male_ratio' FROM
(
SELECT Industry, SUM(female_presenters) AS 'Female_Presenter', SUM(male_presenters) AS 'Male_Presenter' FROM sharktank
GROUP BY Industry HAVING Female_Presenter > 0  AND Male_Presenter > 0
) AS a WHERE ((Female_Presenter/Male_Presenter)*100) > 70;



/* #	You are working at marketing firm of Shark Tank India, 
you have got the task to determine volume of per season sale pitch made,
pitches who received offer and pitches that were converted.
Also show the percentage of pitches converted and percentage of pitches entertained.*/

 SELECT a.season_number , a.total_pitches , b.pitches_received, ((pitches_received/total_pitches)*100) AS 'percentage  pitches received', c.pitches_converted 
 ,((pitches_converted/pitches_received)*100) AS 'Percentage pitches converted' 
 FROM
(
       (
		 SELECT season_number , COUNT(startup_Name) AS 'Total_pitches' FROM sharktank GROUP BY season_number
	   ) AS a
	   INNER JOIN
	   (
		 SELECT season_number , COUNT(startup_name) AS 'Pitches_Received' FROM sharktank WHERE received_offer='yes' GROUP BY season_number
	   ) AS b
	   ON a.season_number = b.season_number
	   INNER JOIN 
	   (
		 SELECT season_number , COUNT(Accepted_offer) AS 'Pitches_Converted' FROM sharktank WHERE  Accepted_offer='Yes' GROUP BY  season_number
	   ) AS c
	   ON  b.season_number = c.season_number
);


/* #	As a venture capital firm specializing in investing in startups featured on a renowned entrepreneurship TV show, 
you are determining the season with the highest average monthly sales and identify the top 5 industries
 with the highest average monthly sales during that season to optimize investment decisions?*/
 
 SELECT * FROM sharktank;
 
 SET @SEASON = (SELECT season_number  FROM
 (
	SELECT  season_number , ROUND(AVG(monthly_sales_in_lakhs),2) AS 'average' FROM sharktank WHERE monthly_sales_in_lakhs!= 'Not_mentioned'
	GROUP BY season_number
 ) AS k
 ORDER BY average DESC
 LIMIT 1);
 
 SELECT @SEASON;
 
SELECT industry , ROUND(AVG(monthly_sales_in_lakhs),2) AS average FROM  sharktank WHERE season_number = @SEASON AND monthly_sales_in_lakhs!= 'Not_mentioned'
GROUP BY industry
ORDER BY average DESC
LIMIT 5;

/* #	As a data scientist at our firm, your role involves solving real-world challenges like 
 identifying industries with consistent increases in funds raised over multiple seasons.
 This requires focusing on industries where data is available across all three seasons.
 Once these industries are pinpointed, your task is to delve into the specifics, 
 analyzing the number of pitches made, offers received, and offers converted per season within each industry. */
 
 SELECT industry ,season_number , ROUND(SUM(total_deal_amount_in_lakhs),2) AS 'Total_deal_amout_per_season_per_industry' FROM sharktank
 GROUP BY industry ,season_number;
 
 WITH code_cte AS
 (
	SELECT 
		industry, 
		SUM(CASE WHEN season_number = 1 THEN total_deal_amount_in_lakhs END) AS 'season_1',
		SUM(CASE WHEN season_number = 2 THEN total_deal_amount_in_lakhs END) AS 'season_2',
		SUM(CASE WHEN season_number = 3 THEN total_deal_amount_in_lakhs END) AS 'season_3'
	FROM sharktank 
	GROUP BY industry 
	HAVING season_3 > season_2 AND season_2 > season_1 AND season_1 != 0
)


SELECT 
    
    a.season_number,
    a.industry,
    SUM(a.total_deal_amount_in_lakhs) AS 'Total_Deal_Amount_In_Lakhs',
    COUNT(a.startup_Name) AS Total,
    COUNT(CASE WHEN a.received_offer = 'Yes' THEN a.startup_Name END) AS Received,
    COUNT(CASE WHEN a.accepted_offer = 'Yes' THEN a.startup_Name END) AS Accepted
FROM sharktank AS a
JOIN code_cte AS c ON a.industry = c.industry
GROUP BY a.season_number, a.industry
ORDER BY season_number;  

/* #	Every shark wants to know in how much year their investment will be returned, 
so you must create a system for them, where shark will enter the name of the startup’s
 and the based on the total deal and equity given in how many years their principal
 amount will be returned and make their investment decisions. */

 

	DELIMITER $$
	CREATE PROCEDURE TOT( IN startup VARCHAR(100))
	BEGIN
	   CASE 
		  WHEN (SELECT Accepted_offer ='No' FROM sharktank WHERE startup_name = startup) THEN  SELECT 'Turn Over time cannot be calculated';
		 WHEN (SELECT Accepted_offer ='yes' AND Yearly_Revenue_in_lakhs = 'Not Mentioned' FROM sharktank WHERE startup_name= startup) THEN SELECT 'Previous data is not available';
		 ELSE
			 SELECT `startup_name`,`Yearly_Revenue_in_lakhs`,`Total_Deal_Amount_in_lakhs`,`Total_Deal_Equity_%`, 
			 ROUND(`Total_Deal_Amount_in_lakhs`/((`Total_Deal_Equity_%`/100)*`Yearly_Revenue_in_lakhs`),1) AS 'Principal_Regain_Years'
			 FROM sharktank WHERE Startup_Name= startup;
		
		END CASE;
	END
	$$
	DELIMITER ;



CALL tot('TagzFoods');

/* #  In the world of startup investing, we're curious to know which big-name investor,
 often referred to as "sharks," tends to put the most money into each deal on average. 
 This comparison helps us see who's the most generous with their investments and how they measure up against their fellow investors. */
 
 
SELECT sharkname, ROUND(AVG(investment),2)  AS 'average_investment_in_lakhs', ROUND(SUM(investment),2) AS 'total_investment_in_lakhs' FROM
(
SELECT `Namita_Investment_Amount_in_lakhs_` AS 'investment', 'Namita' AS sharkname FROM sharktank WHERE `Namita_Investment_Amount_in_lakhs_` > 0
UNION ALL
SELECT `Vineeta_Investment_Amount_in_lakhs` AS 'investment', 'Vineeta' AS sharkname FROM sharktank WHERE `Vineeta_Investment_Amount_in_lakhs` > 0
UNION ALL
SELECT `Anupam_Investment_Amount_in_lakhs` AS 'investment', 'Anupam' AS sharkname FROM sharktank WHERE `Anupam_Investment_Amount_in_lakhs` > 0
UNION ALL
SELECT `Aman_Investment_Amount_in_lakhs_` AS 'investment', 'Aman' AS sharkname FROM sharktank WHERE `Aman_Investment_Amount_in_lakhs_` > 0
UNION ALL
SELECT `Peyush_Investment_Amount_in_lakhs` AS 'investment', 'peyush' AS sharkname FROM sharktank WHERE `Peyush_Investment_Amount_in_lakhs` > 0
UNION ALL
SELECT `Amit_Investment_Amount_in_lakhs` AS 'investment', 'Amit' AS sharkname FROM sharktank WHERE `Amit_Investment_Amount_in_lakhs` > 0
UNION ALL
SELECT `Ashneer_Investment_Amount` AS 'investment', 'Ashneer' AS sharkname FROM sharktank WHERE `Ashneer_Investment_Amount` > 0
) AS a GROUP BY sharkname;


SELECT * FROM sharktank;

/* #	Develop a stored procedure that accepts inputs for the season number and the name of a shark.
 The procedure will then provide detailed insights into the total investment made by that specific
 shark across different industries during the specified season.
 Additionally, it will calculate the percentage of their investment
 in each sector relative to the total investment in that year, 
 giving a comprehensive understanding of the shark's investment distribution and impact.*/

DELIMITER $$
CREATE PROCEDURE getseasoninvestment(IN season INT, IN sharkname VARCHAR(100))
BEGIN
      
    CASE 
		WHEN sharkname = 'namita' THEN
            SET @total = (SELECT  SUM(`Namita_Investment_Amount_in_lakhs_`) FROM sharktank WHERE Season_Number= season );
            SELECT Industry, ROUND(SUM(`Namita_Investment_Amount_in_lakhs_`),2)AS 'sum' ,ROUND(((SUM(`Namita_Investment_Amount_in_lakhs_`)/@total)*100),2) AS 'Percent' FROM sharktank WHERE season_Number = season AND `Namita_Investment_Amount_in_lakhs_` > 0
            GROUP BY industry;
        WHEN sharkname = 'Vineeta' THEN
            SET @total = (SELECT  SUM(`Vineeta_Investment_Amount_in_lakhs`) FROM sharktank WHERE Season_Number= season );
            SELECT industry,ROUND(SUM(`Vineeta_Investment_Amount_in_lakhs`),2) AS 'sum',ROUND(((SUM(`Vineeta_Investment_Amount_in_lakhs`)/@total)*100),2)AS 'Percent' FROM sharktank WHERE season_Number = season AND `Vineeta_Investment_Amount_in_lakhs` > 0
            GROUP BY industry;
        WHEN sharkname = 'Anupam' THEN
            SET @total = (SELECT  SUM(`Anupam_Investment_Amount_in_lakhs`) FROM sharktank WHERE Season_Number= season );
            SELECT industry,ROUND(SUM(`Anupam_Investment_Amount_in_lakhs`),2) AS 'sum',ROUND(((SUM(`Anupam_Investment_Amount_in_lakhs`)/@total)*100),2) AS 'Percent' FROM sharktank WHERE season_Number = season AND `Anupam_Investment_Amount_in_lakhs` > 0
            GROUP BY Industry;
        WHEN sharkname = 'Aman' THEN
            SET @total = (SELECT  SUM(`Aman_Investment_Amount_in_lakhs_`) FROM sharktank WHERE Season_Number= season );
            SELECT industry,ROUND(SUM(`Aman_Investment_Amount_in_lakhs_`),2) AS 'sum',ROUND(((SUM(`Aman_Investment_Amount_in_lakhs_`)/@total)*100),2) AS 'Percent'  FROM sharktank WHERE season_Number = season AND `Aman_Investment_Amount_in_lakhs_` > 0
			GROUP BY Industry;
        WHEN sharkname = 'Peyush' THEN
			 SET @total = (SELECT  SUM(`Peyush_Investment_Amount_in_lakhs`) FROM sharktank WHERE Season_Number= season );
             SELECT industry,ROUND(SUM(`Peyush_Investment_Amount_in_lakhs`),2) AS 'sum' ,ROUND(((SUM(`Peyush_Investment_Amount_in_lakhs`)/@total)*100),2) AS 'Percent' FROM sharktank WHERE season_Number = season AND `Peyush_Investment_Amount_in_lakhs` > 0
             GROUP BY Industry;
        WHEN sharkname = 'Amit' THEN
			  SET @total = (SELECT  SUM(`Amit_Investment_Amount_in_lakhs`) FROM sharktank WHERE Season_Number= season );
              SELECT industry,ROUND(SUM(`Amit_Investment_Amount_in_lakhs`),2) AS 'sum' ,ROUND(((SUM(`Amit_Investment_Amount_in_lakhs`)/@total)*100),2) AS 'Percent'  WHERE season_Number = season AND `Amit_Investment_Amount_in_lakhs` > 0
             GROUP BY Industry;
        WHEN sharkname = 'Ashneer' THEN
            SET @total = (SELECT  SUM(`Ashneer_Investment_Amount`) FROM sharktank WHERE Season_Number= season );
            SELECT industry,ROUND(SUM(`Ashneer_Investment_Amount`),2) AS 'sum' ,ROUND(((SUM(`Ashneer_Investment_Amount`)/@total)*100),2) AS 'Percent'FROM sharktank WHERE season_Number = season AND `Ashneer_Investment_Amount` > 0
			GROUP BY Industry;
        ELSE
            SELECT 'Invalid shark name';
    END CASE;
    
END $$
DELIMITER ;


DROP PROCEDURE getseasoninvestment;
CALL getseasoninvestment(2, 'Aman');

/* #	In the realm of venture capital, we're exploring which shark possesses 
the most diversified investment portfolio across various industries. 
By examining their investment patterns and preferences, 
we aim to uncover any discernible trends or strategies
that may shed light on their decision-making processes and investment philosophies.*/

SELECT sharkname, 
COUNT(DISTINCT industry) AS 'unique industy',
COUNT(DISTINCT CONCAT(pitchers_city,' ,', pitchers_state)) AS 'unique locations' FROM 
(
		SELECT Industry, Pitchers_City, Pitchers_State, 'Namita'  AS sharkname FROM sharktank WHERE  `Namita_Investment_Amount_in_lakhs_` > 0
		UNION ALL
		SELECT Industry, Pitchers_City, Pitchers_State, 'Vineeta'  AS sharkname FROM sharktank WHERE `Vineeta_Investment_Amount_in_lakhs` > 0
		UNION ALL
		SELECT Industry, Pitchers_City, Pitchers_State, 'Anupam'  AS sharkname FROM sharktank WHERE  `Anupam_Investment_Amount_in_lakhs` > 0 
		UNION ALL
		SELECT Industry, Pitchers_City, Pitchers_State, 'Aman'  AS sharkname FROM sharktank WHERE `Aman_Investment_Amount_in_lakhs_` > 0
		UNION ALL
		SELECT Industry, Pitchers_City, Pitchers_State, 'Peyush'  AS sharkname FROM sharktank WHERE   `Peyush_Investment_Amount_in_lakhs` > 0
		UNION ALL
		SELECT Industry, Pitchers_City, Pitchers_State, 'Amit'  AS sharkname FROM sharktank WHERE `Amit_Investment_Amount_in_lakhs` > 0
		UNION ALL
		SELECT Industry, Pitchers_City, Pitchers_State, 'Ashneer'  AS sharkname FROM sharktank WHERE  `Ashneer_Investment_Amount` > 0 
) AS a		
GROUP BY sharkname 
ORDER BY  'unique industry' DESC ,'unique location' DESC ;