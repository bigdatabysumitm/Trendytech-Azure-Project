-- =========================================================
-- 7.2 Pipeline Health Alert
-- =========================================================

-- 1. Ensure the BRONZE schema exists and set context
CREATE SCHEMA IF NOT EXISTS FLOW_DB.BRONZE;
USE ROLE ACCOUNTADMIN;
USE DATABASE FLOW_DB;
USE SCHEMA BRONZE;

-- 2. Create the pipeline health alert
CREATE OR REPLACE ALERT FLOW_DB.BRONZE.pipeline_health_alert
  WAREHOUSE = FLOW_ETL_WH
  SCHEDULE = '5 MINUTE'
  IF (EXISTS (
    -- Check 1: Bronze Snowpipe failures in the last 1 hour
    SELECT 1
    FROM TABLE(FLOW_DB.INFORMATION_SCHEMA.COPY_HISTORY(
      TABLE_NAME => 'FLOW_DB.BRONZE.RAW_ORDERS',
      START_TIME => DATEADD(hour, -1, CURRENT_TIMESTAMP())
    ))
    WHERE STATUS != 'LOADED'

    UNION ALL

    -- Check 2: Silver task failures in the last 1 hour
    SELECT 1
    FROM TABLE(FLOW_DB.INFORMATION_SCHEMA.TASK_HISTORY(
      SCHEDULED_TIME_RANGE_START => DATEADD(hour, -1, CURRENT_TIMESTAMP())
    ))
    WHERE STATE = 'FAILED'
      AND DATABASE_NAME = 'FLOW_DB'

    UNION ALL

    -- Check 3: Gold dynamic table failures in the last 5 minutes
    SELECT 1
    FROM TABLE(FLOW_DB.INFORMATION_SCHEMA.DYNAMIC_TABLE_REFRESH_HISTORY())
    WHERE SCHEMA_NAME = 'GOLD'
      AND STATE = 'FAILED'
      AND REFRESH_START_TIME >= DATEADD(minute, -5, CURRENT_TIMESTAMP())
  ))
  THEN CALL SYSTEM$SEND_EMAIL(
    'email_notification_int',
    'aliskstats6@gmail.com',
    'Pipeline Alert - FlowBridge Project',
    'Warning: One or more failures detected in the FlowBridge data pipeline.\n\nPlease check the Bronze, Silver, or Gold layers via Snowsight Monitoring > Query/Task History.'
  );

-- 3. Activate the alert (Alerts are created in a suspended state by default)
ALTER ALERT FLOW_DB.BRONZE.pipeline_health_alert RESUME;

-- 4. Verify that the alert has been created and started successfully
SHOW ALERTS IN DATABASE FLOW_DB;

-- 5. Review the alert execution history for the last 1 hour
SELECT *
FROM TABLE(FLOW_DB.INFORMATION_SCHEMA.ALERT_HISTORY(
  SCHEDULED_TIME_RANGE_START => DATEADD(hour, -1, CURRENT_TIMESTAMP())
))
ORDER BY SCHEDULED_TIME DESC
LIMIT 10;
