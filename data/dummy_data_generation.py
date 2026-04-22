import pandas as pd
from datetime import datetime, timedelta
import random

# --- SECTION 1: Generate Raw Access Log Data (df) ---

# 1. Define Parameters for Access Log Generation
start_date = datetime(2025, 11, 1)
end_date = datetime(2026, 3, 31)
num_employees = 37 # Number of employees who will have attendance records

# Generate random 4-digit Employee IDs for employees who will potentially have attendance
employee_ids = random.sample(range(1000, 9999), num_employees)

# Monthly Active Employee Logic Parameters
min_active_employees_ratio = 0.8  # Minimum 80% of employees active each month
max_active_employees_ratio = 1.0  # Maximum 100% of employees active each month

# Dynamic Employee Work Patterns
employee_work_patterns = {}
group_1_2_days_count = 10  # target 1-2 days/week
group_3_days_count = 15    # target 3 days/week
group_5_days_count = num_employees - group_1_2_days_count - group_3_days_count # The rest target 5 days/week

random.shuffle(employee_ids) # Shuffle to randomly assign employees to groups

employees_1_2_days = employee_ids[:group_1_2_days_count]
employees_3_days = employee_ids[group_1_2_days_count : group_1_2_days_count + group_3_days_count]
employees_5_days = employee_ids[group_1_2_days_count + group_3_days_count :]

for emp_id in employees_1_2_days:
    employee_work_patterns[emp_id] = random.choice([1, 2]) # Target 1 or 2 days a week
for emp_id in employees_3_days:
    employee_work_patterns[emp_id] = 3 # Target 3 days a week
for emp_id in employees_5_days:
    employee_work_patterns[emp_id] = 5 # Target 5 days a week

# Dictionary to store the generated weekly schedule for each employee
employee_weekly_schedule = {}

data = []
unique_id = 1
current_date = start_date

last_month = None
monthly_active_employees = set()

# 2. Generate the Raw Access Data
while current_date <= end_date:
    if current_date.month != last_month:
        last_month = current_date.month

        num_to_be_active = random.randint(
            int(num_employees * min_active_employees_ratio),
            int(num_employees * max_active_employees_ratio)
        )
        monthly_active_employees = set(random.sample(employee_ids, num_to_be_active))

        print(f"Month {current_date.strftime('%Y-%m')}: {len(monthly_active_employees)} employees active for attendance generation.")

    if current_date.weekday() == 0 or current_date == start_date:
        for emp_id in monthly_active_employees:
            target_days = employee_work_patterns.get(emp_id, 0)
            if target_days > 0:
                employee_weekly_schedule[emp_id] = random.sample(range(5), k=target_days)
            else:
                employee_weekly_schedule[emp_id] = []
        for emp_id in employee_ids:
            if emp_id not in monthly_active_employees:
                employee_weekly_schedule[emp_id] = []

    if current_date.weekday() < 5:
        daily_employees = []
        for emp_id in monthly_active_employees:
            if current_date.weekday() in employee_weekly_schedule.get(emp_id, []) and random.random() < 0.90:
                daily_employees.append(emp_id)

        if not daily_employees and monthly_active_employees:
            daily_employees = random.sample(list(monthly_active_employees), k=random.randint(1, min(5, len(monthly_active_employees))))

        for emp_id in daily_employees:
            num_badges = random.randint(1, 4)

            current_time = current_date.replace(
                hour=random.randint(7, 9),
                minute=random.randint(0, 59),
                second=random.randint(0, 59)
            )

            for _ in range(num_badges):
                time_inside = timedelta(
                    hours=random.randint(1, 3),
                    minutes=random.randint(0, 59)
                )
                date_out = current_time + time_inside

                data.append({
                    'UniqueID': unique_id,
                    'Date In': current_time.strftime('%Y-%m-%d %H:%M:%S'),
                    'Date Out': date_out.strftime('%Y-%m-%d %H:%M:%S'),
                    'UDF1': emp_id
                })

                unique_id += 1

                time_outside = timedelta(minutes=random.randint(15, 60))
                current_time = date_out + time_outside

    current_date += timedelta(days=1)

# Create initial DataFrame 'df' from generated attendance data
df = pd.DataFrame(data)
df = df.sort_values(by='Date In').reset_index(drop=True)
df['UniqueID'] = range(1, len(df) + 1)
print(f"Successfully generated {len(df)} raw access records!")

# --- SECTION 2: Generate Employee_Data.csv and AccessLogs_Data.csv ---

# Generate Employee Data
unique_employee_ids_with_attendance = df['UDF1'].unique()

employee_data_list = []

# Lists for generating synthetic data
first_names_male = ['John', 'Michael', 'David', 'James', 'Robert', 'William', 'Richard']
first_names_female = ['Mary', 'Jennifer', 'Linda', 'Patricia', 'Elizabeth', 'Susan', 'Jessica']
last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez']
genders = ['Male', 'Female']
countries = ['USA', 'Canada', 'UK', 'Australia', 'Germany', 'France']
regions = ['North', 'South', 'East', 'West', 'Central']
departments = ['HR', 'Finance', 'Engineering', 'Sales', 'Marketing', 'Operations', 'IT']

for emp_id in unique_employee_ids_with_attendance:
    gender = random.choice(genders)
    if gender == 'Male':
        first_name = random.choice(first_names_male)
    else:
        first_name = random.choice(first_names_female)

    last_name = random.choice(last_names)
    country = random.choice(countries)
    region = random.choice(regions)
    department = random.choice(departments)
    years_in_company = random.randint(1, 20)
    age = random.randint(22, 65)

    employee_data_list.append({
        'EmployeeID': emp_id,
        'FirstName': first_name,
        'LastName': last_name,
        'Gender': gender,
        'Country': country,
        'Region': region,
        'Department': department,
        'NumberOfYearsInCompany': years_in_company,
        'Age': age
    })

df_employees = pd.DataFrame(employee_data_list)

# Add 2 employees with no attendance records
existing_employee_ids_in_df = set(df_employees['EmployeeID'].unique())
new_employee_ids_for_no_attendance = []
while len(new_employee_ids_for_no_attendance) < 2:
    new_id = random.randint(1000, 9999)
    if new_id not in existing_employee_ids_in_df and new_id not in new_employee_ids_for_no_attendance:
        new_employee_ids_for_no_attendance.append(new_id)

print(f"Adding employees with no attendance to Employee_Data.csv: {new_employee_ids_for_no_attendance}")

new_employees_data = []
for emp_id in new_employee_ids_for_no_attendance:
    gender = random.choice(genders)
    if gender == 'Male':
        first_name = random.choice(first_names_male)
    else:
        first_name = random.choice(first_names_female)

    last_name = random.choice(last_names)
    country = random.choice(countries)
    region = random.choice(regions)
    department = random.choice(departments)

    years_in_company = random.randint(1, 20)
    age = random.randint(22, 65)

    new_employees_data.append({
        'EmployeeID': emp_id,
        'FirstName': first_name,
        'LastName': last_name,
        'Gender': gender,
        'Country': country,
        'Region': region,
        'Department': department,
        'NumberOfYearsInCompany': years_in_company,
        'Age': age
    })

df_employees = pd.concat([df_employees, pd.DataFrame(new_employees_data)], ignore_index=True)

df_employees.to_csv('Employee_Data.csv', index=False)
print(f"Successfully generated {len(df_employees)} employee records in 'Employee_Data.csv'!")

# Generate Combined Access Timestamps CSV
combined_timestamps = []

for index, row in df.iterrows():
    combined_timestamps.append({
        'UDF1': row['UDF1'],
        'Timestamp': row['Date In'],
        'EventType': 'IN'
    })
    combined_timestamps.append({
        'UDF1': row['UDF1'],
        'Timestamp': row['Date Out'],
        'EventType': 'OUT'
    })

df_combined_timestamps = pd.DataFrame(combined_timestamps)
df_combined_timestamps['Timestamp'] = pd.to_datetime(df_combined_timestamps['Timestamp'])
df_combined_timestamps = df_combined_timestamps.sort_values(by='Timestamp').reset_index(drop=True)

df_combined_timestamps.to_csv('AccessLogs_Data.csv', index=False)
print(f"Successfully generated {len(df_combined_timestamps)} combined access timestamp records in 'AccessLogs_Data.csv'!")