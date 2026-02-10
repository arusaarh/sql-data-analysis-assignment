-- =======================================================
-- Question 1: PvP Match and Round Analysis
-- Goal: Calculate average round duration, average match duration, and average number of rounds per match
-- =======================================================

/* 
Step 1: Create a CTE "Rounds" with one row per Match+Round.
Some players report slightly different round times, so we take MAX to get a consistent value.
*/
WITH Rounds AS (
    SELECT 
        MatchId, 
        RoundNumber, 
        MAX(RoundTimeInSeconds) AS RoundTimeInSeconds
    FROM PlayerRoundsData
    GROUP BY MatchId, RoundNumber
),

/* 
Step 2: Aggregate rounds to get match-level metrics.
Count rounds and sum round times to get total match time.
*/
Matches AS (
    SELECT 
        MatchId,
        COUNT(*) AS RoundsCount,           -- Number of rounds in the match
        SUM(RoundTimeInSeconds) AS MatchTimeInSeconds  -- Total match time in seconds
    FROM Rounds
    GROUP BY MatchId
)

/* 
Step 3: Calculate final metrics:
- AvgRoundTimeInMinutes = total match time / total rounds / 60
- AvgMatchTimeInMinutes = total match time / total matches / 60
- AvgNumberOfRoundsPerMatch = total rounds / total matches
*/
SELECT 
    ROUND(SUM(MatchTimeInSeconds) / 60.0 / SUM(RoundsCount), 2) AS AvgRoundTimeInMinutes,  -- 3.38
    ROUND(SUM(MatchTimeInSeconds) / 60.0 / COUNT(*), 2) AS AvgMatchTimeInMinutes,          -- 7.62
    ROUND(SUM(RoundsCount) * 1.0 / COUNT(*), 2) AS AvgNumberOfRoundsPerMatch               -- 2.25
FROM Matches;

-- Notes:
-- Total rounds: 304, total matches: 135 → 304/135 = 2.25
-- Some matches have more rounds than the allowed maximum (up to 9), likely data inconsistencies.


-- =======================================================
-- Question 2: Filter Rounds with 8 Players Only
-- Goal: Create a table containing only rounds with exactly 8 players
-- =======================================================

/* 
Step 1: Identify rounds with exactly 8 players.
We group by MatchId + RoundNumber and use HAVING COUNT(*) = 8.
*/
-- Create a table for these “legit” rounds
CREATE TABLE LegitOccurrences AS
SELECT prd.*  -- Keep all columns from original table
FROM PlayerRoundsData prd
JOIN (
    SELECT 
        MatchId,
        RoundNumber
    FROM PlayerRoundsData
    GROUP BY MatchId, RoundNumber
    HAVING COUNT(*) = 8   -- Filter only rounds with exactly 8 players
) sq
ON prd.MatchId = sq.MatchId
AND prd.RoundNumber = sq.RoundNumber;

-- Notes:
-- Original table: 2000 records (includes rounds with <8 players)
-- LegitOccurrences table: 1216 records from 152 rounds
-- Some matches still have more than 3 rounds, as noted in Question 1


-- =======================================================
-- Question 3: Win Rate Analysis by Team Skill
-- Goal: Calculate win rates for strongest vs weakest teams per round
-- =======================================================

/* 
Step 1: Create a CTE "RoundsWithTeamSkills" to summarize each round:
- Sum PlayerSkill per team (Team0Skill and Team1Skill)
- Determine the winning team (0 or 1)
- Grouped by MatchId + RoundNumber to get one row per round
*/
WITH RoundsWithTeamSkills AS (
    SELECT
        MatchId,
        RoundNumber,
        SUM(CASE WHEN PlayerTeam = 0 THEN PlayerSkill ELSE 0 END) AS Team0Skill,
        SUM(CASE WHEN PlayerTeam = 1 THEN PlayerSkill ELSE 0 END) AS Team1Skill,
        CASE
            WHEN MAX(CASE WHEN PlayerTeam = 0 THEN RoundOutcome END) = 'Win' THEN 0
            WHEN MAX(CASE WHEN PlayerTeam = 1 THEN RoundOutcome END) = 'Win' THEN 1
            ELSE NULL  -- Rounds with no winner
        END AS WinningTeam
    FROM PlayerRoundsData
    GROUP BY MatchId, RoundNumber
)

/* 
Step 2: Calculate win rates:
- StrongestTeamWinRate: % of rounds where the more skilled team won
- WeakestTeamWinRate: % of rounds where the less skilled team won
- Exclude rounds with no winner or equal team skills
*/
SELECT
    (SUM(
        CASE
            WHEN Team0Skill > Team1Skill AND WinningTeam = 0 THEN 1
            WHEN Team1Skill > Team0Skill AND WinningTeam = 1 THEN 1
            ELSE 0
        END
    ) / COUNT(*)) * 100 AS StrongestTeamWinRate,

    (SUM(
        CASE
            WHEN Team0Skill < Team1Skill AND WinningTeam = 0 THEN 1
            WHEN Team1Skill < Team0Skill AND WinningTeam = 1 THEN 1
            ELSE 0
        END
    ) / COUNT(*)) * 100 AS WeakestTeamWinRate
FROM RoundsWithTeamSkills
WHERE WinningTeam IS NOT NULL
  AND Team0Skill <> Team1Skill;


-- =======================================================
-- Question 4: Win Percentage by Team Skill Buckets
-- Goal: Calculate win percentage for teams grouped by skill buckets
-- =======================================================

/* 
Step 1: Create RoundsWithTeamSkills CTE
- Summarize each round with team skills and winning team
- Same logic as Question 3
*/
WITH RoundsWithTeamSkills AS (
    SELECT
        MatchId,
        RoundNumber,
        SUM(CASE WHEN PlayerTeam = 0 THEN PlayerSkill ELSE 0 END) AS Team0Skill,
        SUM(CASE WHEN PlayerTeam = 1 THEN PlayerSkill ELSE 0 END) AS Team1Skill,
        CASE
            WHEN MAX(CASE WHEN PlayerTeam = 0 THEN RoundOutcome END) = 'Win' THEN 0
            WHEN MAX(CASE WHEN PlayerTeam = 1 THEN RoundOutcome END) = 'Win' THEN 1
            ELSE NULL
        END AS WinningTeam
    FROM PlayerRoundsData
    GROUP BY MatchId, RoundNumber
),

/* 
Step 2: Create TeamsWithSkillAndWin CTE
- Separate each team into rows with TeamSkill and IsWin
- UNION ALL combines team 0 and team 1
*/
TeamsWithSkillAndWin AS (
    SELECT Team0Skill AS TeamSkill,
           CASE WHEN WinningTeam = 0 THEN 1 ELSE 0 END AS IsWin
    FROM RoundsWithTeamSkills

    UNION ALL

    SELECT Team1Skill AS TeamSkill,
           CASE WHEN WinningTeam = 1 THEN 1 ELSE 0 END AS IsWin
    FROM RoundsWithTeamSkills
),

/* 
Step 3: Assign teams to skill buckets (0-2k, 2k-4k, etc.)
- Includes both winning and losing teams
*/
TeamsWithSkillBucket AS (
    SELECT
        TeamSkill,
        IsWin,
        CASE
            WHEN TeamSkill <= 2000 THEN '0 to 2000'
            WHEN TeamSkill <= 4000 THEN '2001 to 4000'
            WHEN TeamSkill <= 6000 THEN '4001 to 6000'
            WHEN TeamSkill <= 8000 THEN '6001 to 8000'
            ELSE '8001+' 
        END AS SkillBucket
    FROM TeamsWithSkillAndWin
)

/* 
Step 4: Calculate WinPercentage per skill bucket
- Round to 2 decimals
*/
SELECT
    SkillBucket,
    ROUND(100 * SUM(IsWin) / COUNT(*), 2) AS WinPercentage
FROM TeamsWithSkillBucket
GROUP BY SkillBucket;

-- Notes:
-- Observed that teams with 9000+ skill are essentially unbeatable,
-- except when both teams are 9000+, so for practical purposes, the 9000+ bucket has 100% win rate.


-- =======================================================
-- Question 5: Add Map Names to MapVotingData
-- Goal: Join map names to the MapVotingData table for all 3 maps
-- =======================================================

/* 
Step: Join MapVotingData with dimension_pvpmaps table to get MapName for each MapID
- Using LEFT JOIN to preserve rows even if map name is missing
- Adds Map1Name, Map2Name, Map3Name columns
*/
SELECT 
    Date,
    DateId,

    mvd.Map1DBID,
    dpm.MapName AS Map1Name,  -- Map 1 name
    Map1FinalVotes,
    Map1Outcome,

    mvd.Map2DBID,
    dpm2.MapName AS Map2Name, -- Map 2 name
    Map2FinalVotes,
    Map2Outcome,

    mvd.Map3DBID,
    dpm3.MapName AS Map3Name, -- Map 3 name
    Map3FinalVotes,
    Map3Outcome
FROM MapVotingData mvd
LEFT JOIN dimension_pvpmaps dpm  ON mvd.Map1DBID = dpm.MapDBID
LEFT JOIN dimension_pvpmaps dpm2 ON mvd.Map2DBID = dpm2.MapDBID
LEFT JOIN dimension_pvpmaps dpm3 ON mvd.Map3DBID = dpm3.MapDBID;

-- Notes:
-- No missing map names were found after the join


