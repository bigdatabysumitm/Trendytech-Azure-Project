-- ==========================================
-- 7.1 Email Notification Integration
-- ==========================================

-- 1. Set context: Use ACCOUNTADMIN role, set database = DEV, warehouse = pipeline_warehouse
USE ROLE ACCOUNTADMIN;
USE DATABASE DEV;
USE WAREHOUSE pipeline_warehouse; -- Adjust to your exact warehouse name if needed (e.g., pipeline_wh)

-- 2. Create the notification integration
CREATE NOTIFICATION INTEGRATION IF NOT EXISTS email_notification_int
  TYPE = EMAIL
  ENABLED = TRUE
  COMMENT = 'email notification integration for pipeline health alerts';

-- 3. Verify your email (Snowflake requires email verification before sending messages)
-- Replace '<your_account_name>' with your Snowflake username/login name.
-- Once executed, check your email inbox and click the verification link.
CALL SYSTEM$START_USER_EMAIL_VERIFICATION('<your_account_name>');

-- 4. Test the email integration
-- Replace '<your_email>' with your verified email address.
-- Replace '<subject>' and '<body_text>' with your desired email subject and content.
CALL SYSTEM$SEND_EMAIL(
  'email_notification_int',
  '<your_email>',
  'Test Pipeline Alert',
  'This is a test notification email from Snowflake pipeline integration.'
);

-- 5. List integrations to confirm creation
SHOW INTEGRATIONS;
