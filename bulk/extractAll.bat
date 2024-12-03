REM Organization Accounts
call sf data export bulk --query-file "bulk/query/InstitutionAccounts.soql" --output-file "bulk/data/InstitutionAccounts.csv" -w 10
call sf data export bulk --query-file "bulk/query/CollegeAccounts.soql" --output-file "bulk/data/CollegeAccounts.csv" -w 10