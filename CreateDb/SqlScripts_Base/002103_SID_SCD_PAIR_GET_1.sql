USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SID_SCD_PAIR_GET_1]') AND type in (N'P'))
DROP PROCEDURE [dbo].[SID_SCD_PAIR_GET_1]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- ====================================================
-- 名称			: SID_SCD_PAIR_GET_1
-- 機能			: 一時テーブル [#wt_SID_SCD_PAIR_GET_1_1] に設定された SID の変換レコードを取得する。
--					: 変換レコードが存在しない場合は、新規に作成する。
-- 引き数		: 
-- 戻り値		: 
-- 作成日		: 2021/12/14  作成者 : 茅川
-- ====================================================
CREATE PROCEDURE [dbo].[SID_SCD_PAIR_GET_1]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @ErrMessage nvarchar(4000), @ErrSeverity int, @ErrState int;
	DECLARE @TranCnt int;

	BEGIN TRY
		SET @TranCnt = @@TRANCOUNT;

		IF @TranCnt > 0
			SAVE TRANSACTION svpt_SID_SCD_PAIR_GET_1_1;
		ELSE 
			BEGIN TRANSACTION;
	END TRY
	BEGIN CATCH
		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState);
	END CATCH

	BEGIN TRY
		WITH
			t1 AS (
				SELECT DISTINCT SSP_SID
				FROM #wt_SID_SCD_PAIR_GET_1_1
			)
		SELECT
			t1.SSP_SID,
			t2.SSP_SCD,
			t2.SSP_INYMD
		INTO #wt_SID_SCD_PAIR_GET_1_2
		FROM t1
		LEFT OUTER JOIN SID_SCD_PAIR t2
		ON t1.SSP_SID = t2.SSP_SID;

		SELECT *
		INTO #wt_SID_SCD_PAIR_GET_1_2_1
		FROM #wt_SID_SCD_PAIR_GET_1_2
		WHERE SSP_SCD IS NOT NULL;

		SELECT *, ROW_NUMBER() OVER (ORDER BY SSP_SID) AS order_no
		INTO #wt_SID_SCD_PAIR_GET_1_2_2
		FROM #wt_SID_SCD_PAIR_GET_1_2
		WHERE SSP_SCD IS NULL;

		WITH
			t1 AS (
				SELECT 0 AS num
				UNION ALL 
				SELECT num + 1
				FROM t1 
				WHERE num < 9999
			),
			t2 AS (
				SELECT 1 AS num
				UNION ALL 
				SELECT num + 1
				FROM t2 
				WHERE num < 999
			)
		SELECT
			t1.num + t2.num * 10000 AS SCD
		INTO #wt_SID_SCD_PAIR_GET_1_3
		FROM t1
		CROSS JOIN t2
		OPTION ( MAXRECURSION 10000 );

		DECLARE @now datetime = GETDATE();
		
		WITH
			t2 AS (
				SELECT a.SCD, ROW_NUMBER() OVER (ORDER BY a.SCD) AS order_no
				FROM #wt_SID_SCD_PAIR_GET_1_3 a
				LEFT OUTER JOIN SID_SCD_PAIR b
				ON a.SCD = b.SSP_SCD
				WHERE b.SSP_SCD IS NULL
			)
		SELECT t1.SSP_SID, t2.SCD AS SSP_SCD, @now AS SSP_INYMD
		INTO #wt_SID_SCD_PAIR_GET_1_4
		FROM #wt_SID_SCD_PAIR_GET_1_2_2 t1
		LEFT OUTER JOIN t2
		ON t1.order_no = t2.order_no;

		INSERT INTO SID_SCD_PAIR
		SELECT *
		FROM #wt_SID_SCD_PAIR_GET_1_4;

		SELECT *
		FROM #wt_SID_SCD_PAIR_GET_1_2_1
		UNION ALL
		SELECT *
		FROM #wt_SID_SCD_PAIR_GET_1_4;
		
		IF @TranCnt = 0
            COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF @TranCnt = 0  
            ROLLBACK TRANSACTION;
		ELSE IF XACT_STATE() <> -1
			ROLLBACK TRANSACTION svpt_SID_SCD_PAIR_GET_1_1;

		SET @ErrMessage = ERROR_MESSAGE();
        SET @ErrSeverity = ERROR_SEVERITY();
        SET @ErrState = ERROR_STATE();
  
        RAISERROR (@ErrMessage, @ErrSeverity, @ErrState );
	END CATCH
END
GO
