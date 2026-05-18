# MSIT 5910-01 Capstone Project
# Christian Maldonado
# Design and Development of an Integrated Data Pipeline for Monitoring Return-to-Office Compliance Using Access Logs and HR Data 

## Overview
ETL for data warehouse with staging, dimensions, facts, and tests.

## Folder Structure

- **`/sql`** – SQL scripts organized by layer
  - `staging_transform/` – Objects related to StagingDB and TransformDB
  - `dimensions/` – Dimension tables
  - `facts/` – Fact tables
  - `etl/` – Extract, transform, load scripts
  - `tests/` – Test queries
  - `workflow/` – workflow and scheduling module
- **`/data`** – Data files and generation scripts
- **`/visualization module`** – Power BI desktop rbix reports (comparing 3 reports: integrated RTO versus siloed access logs data or siloed HR employee data) 

## Getting Started

## To install everything in your SQL server:

1. Clone the repository
2. Review SQL scripts in `/sql`
3. Execute scripts in order: staging_transform → dimensions → facts → etl (extract, transform, load)
4. Execute script in workflow folder to create the scheduling. Make sure you have installed SQL Server Agent feature.
5. Run the Agent Job.
6. You may choose to create a new dataset by using the dummy_data_generation.py in data folder. Tweak the code based on your needs. If not, you may use the csv files in the same folder.
7. Open the pbix Power BI reports and compare the RTO Dashboard to the 2 other reports to determine if attendance/return-to-office insights are achieved between integrated and siloed.