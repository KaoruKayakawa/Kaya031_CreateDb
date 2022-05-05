USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_i_TYUMON_KNR_MST_now]') AND type in (N'TR'))
DROP TRIGGER [dbo].[trg_i_TYUMON_KNR_MST_now]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		kayakawa
-- Create date:
-- Description:	
-- Update:		2022-02-07　kayakawa
-- =============================================
CREATE TRIGGER [dbo].[trg_i_TYUMON_KNR_MST_now]
   ON  [dbo].[TYUMON_KNR_MST_now]
   INSTEAD OF INSERT
AS 
BEGIN
	SET NOCOUNT ON;
	
	SELECT a.STKF_UPDATECNT AS cnt_new, b.STKF_UPDATECNT AS cnt_old, b.STKF_DELFG AS delfg_old
	INTO #wk_trg_i_TYUMON_KNR_MST_now_01
	FROM inserted a
	LEFT OUTER JOIN TYUMON_KNR_MST_now b
	ON a.STKF_KCD = b.STKF_KCD
		AND a.STKF_HTCD = b.STKF_HTCD
		AND a.STKF_SCD = b.STKF_SCD
		AND a.STKF_STR = b.STKF_STR
		AND a.STKF_END = b.STKF_END
		AND a.STKF_TEKIYOYMD = b.STKF_TEKIYOYMD;

	IF (SELECT COUNT(*) FROM #wk_trg_i_TYUMON_KNR_MST_now_01 WHERE (cnt_new = 0 AND cnt_old IS NOT NULL AND delfg_old <> 1) OR (cnt_new > 0 AND (cnt_new <> cnt_old OR cnt_old IS NULL))) > 0
	BEGIN
		RAISERROR(50001, 11, 1, N'TYUMON_KNR_MST');
		
		RETURN;
	END

	DROP TABLE #wk_trg_i_TYUMON_KNR_MST_now_01;

	SELECT a.*
	INTO #wk_trg_i_TYUMON_KNR_MST_now_02
	FROM TYUMON_KNR_MST_now a
	INNER JOIN inserted b
	ON a.STKF_KCD = b.STKF_KCD
		AND a.STKF_HTCD = b.STKF_HTCD
		AND a.STKF_SCD = b.STKF_SCD
		AND a.STKF_STR = b.STKF_STR
		AND a.STKF_END = b.STKF_END
		AND a.STKF_TEKIYOYMD = b.STKF_TEKIYOYMD;

	INSERT INTO TYUMON_KNR_MST_old
	SELECT *
	FROM #wk_trg_i_TYUMON_KNR_MST_now_02;

	DELETE FROM TYUMON_KNR_MST_now
	FROM TYUMON_KNR_MST_now a
	INNER JOIN #wk_trg_i_TYUMON_KNR_MST_now_02 b
	ON a.STKF_KCD = b.STKF_KCD
		AND a.STKF_HTCD = b.STKF_HTCD
		AND a.STKF_SCD = b.STKF_SCD
		AND a.STKF_STR = b.STKF_STR
		AND a.STKF_END = b.STKF_END
		AND a.STKF_TEKIYOYMD = b.STKF_TEKIYOYMD;

	SELECT *
	INTO #wk_trg_i_TYUMON_KNR_MST_now_03
	FROM inserted;

	UPDATE a
	SET a.STKF_UPDATECNT = ISNULL(b.STKF_UPDATECNT, 0) + 1
	FROM #wk_trg_i_TYUMON_KNR_MST_now_03 a
	LEFT OUTER JOIN #wk_trg_i_TYUMON_KNR_MST_now_02 b
	ON a.STKF_KCD = b.STKF_KCD
		AND a.STKF_HTCD = b.STKF_HTCD
		AND a.STKF_SCD = b.STKF_SCD
		AND a.STKF_STR = b.STKF_STR
		AND a.STKF_END = b.STKF_END
		AND a.STKF_TEKIYOYMD = b.STKF_TEKIYOYMD;
		
	-- 更新日時の設定（システム日時がメンテナンスされている場合も考慮）
	DECLARE @propName sysname = N'UPDATE_WITH_TYUMON_KNR_MST__LastExecution_DateTime';
	DECLARE @lastExeDt datetime, @nowDt datetime = GETDATE();

	SELECT @lastExeDt = CAST(value AS datetime)
	FROM sys.extended_properties
	WHERE class= 1
		AND major_id = OBJECT_ID(N'[dbo].[TYUMON_KNR_MST_now]')
		AND name = @propName;
		
	IF @lastExeDt IS NOT NULL
		IF @nowDt <= @lastExeDt
			SET @nowDt = DATEADD(second, 1, @lastExeDt);

	UPDATE #wk_trg_i_TYUMON_KNR_MST_now_03
	SET STKF_INYMD = @nowDt
	WHERE STKF_UPDATECNT = 1;

	UPDATE #wk_trg_i_TYUMON_KNR_MST_now_03
	SET STKF_KOSINYMD = @nowDt;
	-- <- 更新日時の設定（システム日時がメンテナンスされている場合も考慮）

	INSERT INTO TYUMON_KNR_MST_now
	SELECT *
	FROM #wk_trg_i_TYUMON_KNR_MST_now_03;

	DROP TABLE #wk_trg_i_TYUMON_KNR_MST_now_02;
	DROP TABLE #wk_trg_i_TYUMON_KNR_MST_now_03;
END
GO

ALTER TABLE [dbo].[TYUMON_KNR_MST_now] ENABLE TRIGGER [trg_i_TYUMON_KNR_MST_now]
GO
