REM Disabling TDTM triggers
start "Disable TDTM" /wait /b cci task run disable_tdtm_trigger_handlers --namespace hed

REM Organization Accounts
call sf data import bulk -s Account --file "bulk/data/InstitutionAccounts.csv" -w 10 --column-delimiter=COMMA
call sf apex run --file bulk/recordtypes/setInstitutionRecordType.apex

call sf data import bulk -s Account --file "bulk/data/CollegeAccounts.csv" -w 10 --column-delimiter=COMMA
call sf apex run --file bulk/recordtypes/setCollegeRecordType.apex
