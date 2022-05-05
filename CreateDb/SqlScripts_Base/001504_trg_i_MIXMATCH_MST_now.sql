USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_i_MIXMATCH_MST_now]') AND type in (N'TR'))
DROP TRIGGER [dbo].[trg_i_MIXMATCH_MST_now]
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
CREATE TRIGGER [dbo].[trg_i_MIXMATCH_MST_now]
   ON  [dbo].[MIXMATCH_MST_now]
   INSTEAD OF INSERT
AS 
BEGIN
	SET NOCOUNT ON;
	
	SELECT a.SMIM_UPDATECNT AS cnt_new, b.SMIM_UPDATECNT AS cnt_old, b.SMIM_DELFG AS delfg_old
	INTO #wk_trg_i_MIXMATCH_MST_now_01
	FROM inserted a
	LEFT OUTER JOIN MIXMATCH_MST_now b
	ON a.SMIM_KCD = b.SMIM_KCD
		AND a.SMIM_HTCD = b.SMIM_HTCD
		AND a.SMIM_MMNO = b.SMIM_MMNO
		AND a.SMIM_SCD = b.SMIM_SCD
		AND a.SMIM_TEKIYOYMD = b.SMIM_TEKIYOYMD;

	IF (SELECT COUNT(*) FROM #wk_trg_i_MIXMATCH_MST_now_01 WHERE (cnt_new = 0 AND cnt_old IS NOT NULL AND delfg_old <> 1) OR (cnt_new > 0 AND (cnt_new <> cnt_old OR cnt_old IS NULL))) > 0
	BEGIN
		RAISERROR(50001, 11, 1, N'MIXMATCH_MST');
		
		RETURN;
	END

	DROP TABLE #wk_trg_i_MIXMATCH_MST_now_01;

	SELECT a.*
	INTO #wk_trg_i_MIXMATCH_MST_now_02
	FROM MIXMATCH_MST_now a
	INNER JOIN inserted b
	ON a.SMIM_KCD = b.SMIM_KCD
		AND a.SMIM_HTCD = b.SMIM_HTCD
		AND a.SMIM_MMNO = b.SMIM_MMNO
		AND a.SMIM_SCD = b.SMIM_SCD
		AND a.SMIM_TEKIYOYMD = b.SMIM_TEKIYOYMD;

	INSERT INTO MIXMATCH_MST_old
	SELECT *
	FROM #wk_trg_i_MIXMATCH_MST_now_02;

	DELETE FROM MIXMATCH_MST_now
	FROM MIXMATCH_MST_now a
	INNER JOIN #wk_trg_i_MIXMATCH_MST_now_02 b
	ON a.SMIM_KCD = b.SMIM_KCD
		AND a.SMIM_HTCD = b.SMIM_HTCD
		AND a.SMIM_MMNO = b.SMIM_MMNO
		AND a.SMIM_SCD = b.SMIM_SCD
		AND a.SMIM_TEKIYOYMD = b.SMIM_TEKIYOYMD;

	SELECT *
	INTO #wk_trg_i_MIXMATCH_MST_now_03
	FROM inserted;

	UPDATE a
	SET a.SMIM_UPDATECNT = ISNULL(b.SMIM_UPDATECNT, 0) + 1
	FROM #wk_trg_i_MIXMATCH_MST_now_03 a
	LEFT OUTER JOIN #wk_trg_i_MIXMATCH_MST_now_02 b
	ON a.SMIM_KCD = b.SMIM_KCD
		AND a.SMIM_HTCD = b.SMIM_HTCD
		AND a.SMIM_MMNO = b.SMIM_MMNO
		AND a.SMIM_SCD = b.SMIM_SCD
		AND a.SMIM_TEKIYOYMD = b.SMIM_TEKIYOYMD;
		
	-- 更新日時の設定（システム日時がメンテナンスされている場合も考慮）
	DECLARE @propName sysname = N'UPDATE_WITH_MIXMATCHGRP_MST__LastExecution_DateTime';		-- グループとひとまとまりの処理により、パラメータはグループ テーブルに保存されている
	DECLARE @lastExeDt datetime, @nowDt datetime = GETDATE();

	SELECT @lastExeDt = CAST(value AS datetime)
	FROM sys.extended_properties
	WHERE class= 1
		AND major_id = OBJECT_ID(N'[dbo].[MIXMATCHGRP_MST_now]')
		AND name = @propName;
		
	IF @lastExeDt IS NOT NULL
		IF @nowDt <= @lastExeDt
			SET @nowDt = DATEADD(second, 1, @lastExeDt);

	UPDATE #wk_trg_i_MIXMATCH_MST_now_03
	SET SMIM_INYMD = @nowDt
	WHERE SMIM_UPDATECNT = 1;

	UPDATE #wk_trg_i_MIXMATCH_MST_now_03
	SET SMIM_KOSINYMD = @nowDt;
	-- <- 更新日時の設定（システム日時がメンテナンスされている場合も考慮）

	INSERT INTO MIXMATCH_MST_now
	SELECT *
	FROM #wk_trg_i_MIXMATCH_MST_now_03;

	DROP TABLE #wk_trg_i_MIXMATCH_MST_now_02;
	DROP TABLE #wk_trg_i_MIXMATCH_MST_now_03;
END
GO

ALTER TABLE [dbo].[MIXMATCH_MST_now] ENABLE TRIGGER [trg_i_MIXMATCH_MST_now]
GO
