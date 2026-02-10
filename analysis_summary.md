# Analysis Summary

## Key Findings

- **Average Round & Match Duration (Q1)**  
  - Avg round: 3.38 min, avg match: 7.62 min, avg rounds per match: 2.25  
  - Some matches have more than 3 rounds (data inconsistency).

- **Rounds with 8 Players Only (Q2)**  
  - Filtered 1216 records from 152 rounds (original: 2000).  
  - Matches with extra rounds still exist.

- **Win Rate by Team Skill (Q3)**  
  - Strongest teams win most rounds, but weaker teams occasionally win.  
  - Excluded rounds with no winner or equal team skills.

- **Win Percentage by Skill Buckets (Q4)**  
  - Higher skill → higher win %.  
  - Teams with 9000+ skill effectively unbeatable.

- **Map Names Join (Q5)**  
  - Added names for Map1-3 using LEFT JOINs.  
  - No missing map names.

- **Automated View Creation (Q6)**  
  - PySpark script executes `createviewquery` from `big_exposition_tool`.  
  - Automates SQL view creation.

## Data Notes
- Some matches exceed max rounds (more than 3).  
- Player-reported round times may vary; MAX used for consistency.  
- Rare cases of high-skill teams losing against equally skilled teams.

