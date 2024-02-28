-- Alter Player Details Table
ALTER TABLE "player_details" 
ALTER COLUMN L1_Status TYPE VARCHAR(30);

ALTER TABLE "player_details" 
ALTER COLUMN L2_Status TYPE VARCHAR(30);

ALTER TABLE "player_details" 
ALTER COLUMN P_ID TYPE INT;




-- Drop unknown columns in Level Details Table
ALTER TABLE "level_details" 
DROP COLUMN IF EXISTS myunknowncolumn;

-- Alter Level Details Table
ALTER TABLE "level_details" 
ALTER COLUMN Dev_Id TYPE VARCHAR(10);

ALTER TABLE "level_details" 
ALTER COLUMN Difficulty TYPE VARCHAR(15);

ALTER TABLE "level_details" 
ADD PRIMARY KEY (P_ID, Dev_id, start_datetime);


-->>  Q1) Extract P_ID,Dev_ID,PName and Difficulty_level of all players 
SELECT pd.P_ID, ld.Dev_ID, pd.PName, ld.Difficulty
FROM player_details pd 
LEFT JOIN level_details ld
ON pd.P_ID = ld.P_ID
WHERE ld.P_ID IS NOT NULL;




-->> every difficulty level is distruduted in equally and accept low difficulty level

--> 2 Find Level1_code wise Avg_Kill_Count where lives_earned is 2 and atleast
--    3 stages are crossed

 SELECT 
      L1_code , AVG(Kill_Count) AS Avg_Kill_Count
FROM 
      level_details as l
	  join player_details as p on l.P_ID= p.P_ID
WHERE 
      lives_earned = 2
GROUP BY
      L1_code
HAVING
      COUNT(DISTINCT stages_crossed) >= 3;

--->>

--> 3 Find the total number of stages crossed at each diffuculty level
-- where for Level2 with players use zm_series devices. Arrange the result
-- in decsreasing order of total number of stages crossed.
SELECT Difficulty, SUM(Stages_Crossed) AS Total_Stages_Crossed
FROM Level_Details
WHERE Dev_ID IN 
(SELECT DISTINCT Dev_ID FROM Level_Details WHERE Dev_ID like 'zm%') and level = 2
GROUP BY Difficulty
ORDER BY Total_Stages_Crossed DESC;

--> Analysis - For players at level 2 and using zm series device total crossed stages at different difficulties level are - Diificult = 46, Medium = 35, Low = 15

--->Extract P_ID and the total number of unique dates for those players 
-- who have played games on multiple days.
 SELECT P_ID, COUNT(DISTINCT start_datetime) AS Unique_Dates_Count
FROM level_details
GROUP BY P_ID
HAVING COUNT(DISTINCT start_datetime) > 1;

--> every p_id have different count of uniques dates

--->Find P_ID and level wise sum of kill_counts where kill_count
-- is greater than avg kill count for the Medium difficulty.
SELECT P_ID, Level, SUM(kill_count) AS Total_Kill_Count
FROM Level_Details
WHERE Difficulty = 'Medium'
GROUP BY P_ID, Level
HAVING SUM(kill_count) > (SELECT AVG(kill_count) FROM Level_Details
 WHERE Difficulty = 'Medium');

--> here we can see p_id which are having level 1 are greater and kills counts are also gretr than level 2.

--Q6)Find Level and its corresponding Level code wise sum of lives earned 
-- excluding level 0. Arrange in asecending order of level.

SELECT l.Level, pd.L1_Code,pd.L2_Code, SUM(l.Lives_Earned) AS Total_Lives_Earned
FROM Level_Details as l 
LEFT JOIN player_details as pd ON l.P_ID = pd.p_id
WHERE Level <> '0'
GROUP BY l.Level, pd.L1_Code, pd.L2_Code
order by l.Level, pd.L1_Code, pd.L2_Code;

--> Both level have different lives earned according to both l1 and l2 code but level2 have highest number of lives earned with respect to codes 

-- Q7) Find Top 3 score based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well. 
WITH RankedScores AS (
    SELECT Dev_ID, Difficulty, Score,
           ROW_NUMBER() OVER (PARTITION BY Dev_ID, Difficulty ORDER BY Score ASC) AS ScoreRank
    FROM Level_Details
)
SELECT Dev_ID, Difficulty, Score
FROM RankedScores
WHERE ScoreRank <= 3
order by Dev_Id,Difficulty,ScoreRank desc
;

--> THIS QUESTION IS LEFT 
-->Q8) Find first_login datetime for each device id
SELECT Dev_ID, MIN(start_datetime) AS First_Login_Datetime
FROM Level_Details
GROUP BY Dev_ID;

--> Analysis - There are total 10 devices. About 80% of the devices have started on 12-Oct-22 and rest started on 11-Oct-22 

-- Q9) Find Top 5 score based on each difficulty level and Rank them in 
-- increasing order using Rank. Display dev_id as well.
WITH RankedScores AS (
    SELECT Dev_ID, Difficulty, Score,
           RANK() OVER (PARTITION BY Difficulty ORDER BY Score ASC) AS ScoreRank
    FROM Level_Details
)
SELECT Dev_ID, Difficulty, Score
FROM RankedScores
WHERE ScoreRank <= 5;

--> Analysis - Highest score for difficulty level 

-- Q10) Find the device ID that is first logged in(based on start_datetime) 
-- for each player(p_id). Output should contain player id, device id and 
-- first login datetime.
WITH FirstLogin AS (
    SELECT P_ID, Dev_ID, start_datetime,
           ROW_NUMBER() OVER (PARTITION BY P_ID ORDER BY start_datetime) AS LoginRank
    FROM Level_Details
)
SELECT P_ID, Dev_ID, start_datetime AS First_Login_Datetime
FROM FirstLogin
WHERE LoginRank = 1;

--> HERE WE HAVE DATA ACCORDING TO INCREASING ORDER WHERE DEVICE IS START 

--Q11) For each player and date, how many kill_count played so far by the player. That is, the total number of games played
-- by the player until that date.
-- a) window function
-- b) without window function

-->A with windows funtions
SELECT 
     p_id, start_datetime, kill_count,
       SUM(kill_count) OVER (PARTITION BY P_ID ORDER BY start_datetime) AS Total_Kill_Count
FROM 
    Level_Details;

---> B Windows funtions
 
SELECT
    A.p_id,
    A.start_datetime,
    A.kill_count,
    (SELECT SUM(B.kill_count)
     FROM Level_Details B
     WHERE B.p_id = A.p_id AND B.start_datetime <= A.start_datetime) AS GamesPlayedSoFar
FROM Level_Details as A
ORDER BY A.P_ID, A.start_datetime;

--> according to both questions windows funtions are more easier then without funtions 

--> 12 Find the cumulative sum of an stages crossed over a start_datetime 
-- for each player id but exclude the most recent start_datetim
SELECT t1.P_ID, t1.start_datetime, t1.stages_crossed,
       SUM(t2.stages_crossed) AS Cumulative_Stages_Crossed
FROM Level_Details t1
JOIN Level_Details t2
    ON t1.P_ID = t2.P_ID
    AND t1.start_datetime >= t2.start_datetime
WHERE t1.start_datetime < (SELECT MAX(start_datetime) FROM Level_Details WHERE P_ID = t1.P_ID)
GROUP BY t1.P_ID, t1.start_datetime, t1.stages_crossed
ORDER BY t1.P_ID, t1.start_datetime;

-->13Extract top 3 highest sum of score for each device id and the corresponding player_id
WITH RankedScores AS (
    SELECT Dev_ID, P_ID, SUM(Score) AS Total_Score,
           RANK() OVER (PARTITION BY Dev_ID ORDER BY SUM(Score) DESC) AS Rank
    FROM Level_Details
    GROUP BY Dev_ID, P_ID
)
SELECT Dev_ID, P_ID, Total_Score
FROM RankedScores
WHERE Rank < 3;




-- Q14) Find players who scored more than 50% of the avg score scored by sum of 
-- scores for each player_id

WITH PlayerAvgScores AS (
    SELECT P_ID, SUM(Score) AS AvgScore
    FROM Level_Details
    GROUP BY P_ID
)
SELECT P_ID 
FROM PlayerAvgScores
WHERE AvgScore * 0.5 < (SELECT SUM(Score) FROM Level_Details WHERE P_ID = PlayerAvgScores.P_ID);


-- Q15) Create a stored procedure to find top n headshots_count based on each dev_id and Rank them in increasing order
-- using Row_Number. Display difficulty as well.

-- Create the stored procedure

CREATE OR REPLACE FUNCTION GetTopNHeadshots(N INT) RETURNS TABLE (
    P_ID INT,
    Dev_ID VARCHAR(10),
    Difficulty VARCHAR(50),
    Headshots_Count INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        P_ID,
        Dev_ID,
        Difficulty,
        Headshots_Count
    FROM (
        SELECT
            P_ID,
            Dev_ID,
            Difficulty,
            Headshots_Count,
            ROW_NUMBER() OVER (PARTITION BY Dev_ID ORDER BY Headshots_Count ASC) AS Rank
        FROM
            level_details
    ) AS RankedHeadshots
    WHERE
        Rank <= N;
END;
$$ LANGUAGE plpgsql;

