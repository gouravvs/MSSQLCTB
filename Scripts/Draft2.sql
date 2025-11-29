
-- For safety: ensure runtime errors will rollbacks the whole transaction.
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- 1. DECLARE AND POPULATE THE REQUIRED TEMPARY TABLE (@ids)

-- Define the cutoff time 
DECLARE @CutoffTime DATETIMEOFFSET(7) = DATEADD(DAY, -7, SYSDATETIMEOFFSET());

-- Creating a temporary table variable to hold the IDs to delete (based on FRAUD_EVENT older than 7 days)
DECLARE @ids TABLE (
    ID UNIQUEIDENTIFIER PRIMARY KEY);
INSERT INTO @ids (ID)
SELECT id
FROM [dbo].[FRAUD_EVENT] WITH (NOLOCK)
WHERE EVENT_TIME < @CutoffTime;

-- check @ids table if nothing to delete, exit the script 
IF NOT EXISTS (SELECT 1 FROM @ids)
BEGIN
    PRINT 'No rows older than cutoff; nothing to delete.';
    RETURN;
END

-- 2. BATCH DELETE from child Table and parent table in same loop 

DECLARE @BatchSize INT = 5000;
DECLARE @RowsInBatch INT = 0;
WHILE 1 = 1
BEGIN
    SET @RowsInBatch = (SELECT COUNT(*) FROM @ids);
    IF @RowsInBatch = 0
        BREAK; -- nothing left to do

    BEGIN TRANSACTION;
        -- 1) delete IDs from FRAUD_EVENT table
        DELETE fe
        FROM dbo.FRAUD_EVENT fe
        WHERE fe.ID IN (
            SELECT TOP (@BatchSize) ID
            FROM @ids
            ORDER BY ID  
        );
        -- 2) delete IDs from FRAUD_BLOB table
         DELETE fb
        FROM dbo.FRAUD_BLOB fb
        WHERE fb.ID IN (
            SELECT TOP (@BatchSize) ID
            FROM @ids
            ORDER BY ID  
        );
        -- 3) remove these batch processed IDs from @ids table so the next loop sees fewer rows
        DELETE ids
        FROM @ids ids
        WHERE ids.ID IN (
            SELECT TOP (@BatchSize) ID
            FROM @ids
            ORDER BY ID  
        );
    COMMIT TRANSACTION;
    -- pause to reduce contention
    WAITFOR DELAY '00:00:00.050';
END