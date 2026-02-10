# =======================================================
# Question 6: Automated View Creation using PySpark
# Goal: Execute SQL queries stored in a table to create views
# =======================================================

# Import dependencies
from pyspark.sql import SparkSession

# Initialize Spark session with Hive support
spark = SparkSession.builder \
    .appName('big_exposition_tool_automated_process') \
    .enableHiveSupport() \
    .getOrCreate()

# Execute SQL query to get all rows from 'big_exposition_tool' table
queryResult = spark.sql("SELECT * FROM big_exposition_tool")

# Initialize list to store each 'createviewquery'
views = []

# Loop through each row in the query result
for i in range(len(queryResult.collect())):
    # Append the 'createviewquery' column (as string) to the views list
    views.append(str(queryResult.collect()[i].createviewquery))

# Execute each query in the views list to create SQL views
for i in range(len(views)):
    spark.sql(views[i])

# Stop the Spark session
spark.stop()

# Notes:
# - The 'createviewquery' column contains SQL statements to create views
# - This script automates the creation of views stored in the 'big_exposition_tool' table
