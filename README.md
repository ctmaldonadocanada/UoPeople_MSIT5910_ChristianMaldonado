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
- **`/data`** – Data files and generation scripts

## Getting Started

1. Clone the repository
2. Review SQL scripts in `/sql`
3. Execute scripts in order: staging_transform → dimensions → facts → etl