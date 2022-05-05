USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_i_SHOHIN_MST_now]') AND type in (N'TR'))
DROP TRIGGER [dbo].[trg_i_SHOHIN_MST_now]
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
CREATE TRIGGER [dbo].[trg_i_SHOHIN_MST_now]
   ON  [dbo].[SHOHIN_MST_now]
   INSTEAD OF INSERT
AS 
BEGIN
	SET NOCOUNT ON;
	
	SELECT a.SSHM_UPDATECNT AS cnt_new, b.SSHM_UPDATECNT AS cnt_old, b.SSHM_DELFG AS delfg_old
	INTO #wk_trg_i_SHOHIN_MST_now_01
	FROM inserted a
	LEFT OUTER JOIN SHOHIN_MST_now b
	ON a.SSHM_KCD = b.SSHM_KCD
		AND a.SSHM_HTCD = b.SSHM_HTCD
		AND a.SSHM_SCD = b.SSHM_SCD
		AND a.SSHM_TEKIYOYMD = b.SSHM_TEKIYOYMD;

	IF (SELECT COUNT(*) FROM #wk_trg_i_SHOHIN_MST_now_01 WHERE (cnt_new = 0 AND cnt_old IS NOT NULL AND delfg_old <> 1) OR (cnt_new > 0 AND (cnt_new <> cnt_old OR cnt_old IS NULL))) > 0
	BEGIN
		RAISERROR(50001, 11, 1, N'SHOHIN_MST');
		
		RETURN;
	END

	DROP TABLE #wk_trg_i_SHOHIN_MST_now_01;

	SELECT a.*
	INTO #wk_trg_i_SHOHIN_MST_now_02
	FROM SHOHIN_MST_now a
	INNER JOIN inserted b
	ON a.SSHM_KCD = b.SSHM_KCD
		AND a.SSHM_HTCD = b.SSHM_HTCD
		AND a.SSHM_SCD = b.SSHM_SCD
		AND a.SSHM_TEKIYOYMD = b.SSHM_TEKIYOYMD;

	INSERT INTO SHOHIN_MST_old
	SELECT *
	FROM #wk_trg_i_SHOHIN_MST_now_02;

	DELETE FROM SHOHIN_MST_now
	FROM SHOHIN_MST_now a
	INNER JOIN #wk_trg_i_SHOHIN_MST_now_02 b
	ON a.SSHM_KCD = b.SSHM_KCD
		AND a.SSHM_HTCD = b.SSHM_HTCD
		AND a.SSHM_SCD = b.SSHM_SCD
		AND a.SSHM_TEKIYOYMD = b.SSHM_TEKIYOYMD;

	SELECT *
	INTO #wk_trg_i_SHOHIN_MST_now_03
	FROM inserted;

	UPDATE a
	SET a.SSHM_UPDATECNT = ISNULL(b.SSHM_UPDATECNT, 0) + 1
	FROM #wk_trg_i_SHOHIN_MST_now_03 a
	LEFT OUTER JOIN #wk_trg_i_SHOHIN_MST_now_02 b
	ON a.SSHM_KCD = b.SSHM_KCD
		AND a.SSHM_HTCD = b.SSHM_HTCD
		AND a.SSHM_SCD = b.SSHM_SCD
		AND a.SSHM_TEKIYOYMD = b.SSHM_TEKIYOYMD;
		
	-- 更新日時の設定（システム日時がメンテナンスされている場合も考慮）
	DECLARE @propName sysname = N'UPDATE_WITH_SHOHIN_MST__LastExecution_DateTime';
	DECLARE @lastExeDt datetime, @nowDt datetime = GETDATE();

	SELECT @lastExeDt = CAST(value AS datetime)
	FROM sys.extended_properties
	WHERE class= 1
		AND major_id = OBJECT_ID(N'[dbo].[SHOHIN_MST_now]')
		AND name = @propName;
		
	IF @lastExeDt IS NOT NULL
		IF @nowDt <= @lastExeDt
			SET @nowDt = DATEADD(second, 1, @lastExeDt);

	UPDATE #wk_trg_i_SHOHIN_MST_now_03
	SET SSHM_INYMD = @nowDt
	WHERE SSHM_UPDATECNT = 1;

	UPDATE #wk_trg_i_SHOHIN_MST_now_03
	SET SSHM_KOSINYMD = @nowDt;
	-- <- 更新日時の設定（システム日時がメンテナンスされている場合も考慮）

	INSERT INTO SHOHIN_MST_now
	SELECT *
	FROM #wk_trg_i_SHOHIN_MST_now_03;
	
	DROP TABLE #wk_trg_i_SHOHIN_MST_now_02;
	DROP TABLE #wk_trg_i_SHOHIN_MST_now_03;
END
GO

ALTER TABLE [dbo].[SHOHIN_MST_now] ENABLE TRIGGER [trg_i_SHOHIN_MST_now]
GO
