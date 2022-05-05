USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_i_MIKEISAI_SCD_MST_now]') AND type in (N'TR'))
DROP TRIGGER [dbo].[trg_i_MIKEISAI_SCD_MST_now]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		kayakawa
-- Create date:
-- Description:	
-- =============================================
CREATE TRIGGER [dbo].[trg_i_MIKEISAI_SCD_MST_now]
   ON  [dbo].[MIKEISAI_SCD_MST_now]
   INSTEAD OF INSERT
AS 
BEGIN
	SET NOCOUNT ON;
	
	SELECT a.MKS_UPDATECNT AS cnt_new, b.MKS_UPDATECNT AS cnt_old, b.MKS_DELFG AS delfg_old
	INTO #wk_trg_i_MIKEISAI_SCD_MST_now_01
	FROM inserted a
	LEFT OUTER JOIN MIKEISAI_SCD_MST_now b
	ON a.MKS_KCD = b.MKS_KCD
		AND a.MKS_HTCD = b.MKS_HTCD
		AND a.MKS_SCD = b.MKS_SCD
		AND a.MKS_TEKIYOYMD = b.MKS_TEKIYOYMD;

	IF (SELECT COUNT(*) FROM #wk_trg_i_MIKEISAI_SCD_MST_now_01 WHERE (cnt_new = 0 AND cnt_old IS NOT NULL AND delfg_old = 0) OR (cnt_new > 0 AND (cnt_new <> cnt_old OR cnt_old IS NULL))) > 0
	BEGIN
		RAISERROR(50001, 11, 1, N'MIKEISAI_SCD_MST');
		
		RETURN;
	END

	DROP TABLE #wk_trg_i_MIKEISAI_SCD_MST_now_01;

	SELECT a.*
	INTO #wk_trg_i_MIKEISAI_SCD_MST_now_02
	FROM MIKEISAI_SCD_MST_now a
	INNER JOIN inserted b
	ON a.MKS_KCD = b.MKS_KCD
		AND a.MKS_HTCD = b.MKS_HTCD
		AND a.MKS_SCD = b.MKS_SCD
		AND a.MKS_TEKIYOYMD = b.MKS_TEKIYOYMD;

	INSERT INTO MIKEISAI_SCD_MST_old
	SELECT *
	FROM #wk_trg_i_MIKEISAI_SCD_MST_now_02;

	DELETE FROM MIKEISAI_SCD_MST_now
	FROM MIKEISAI_SCD_MST_now a
	INNER JOIN #wk_trg_i_MIKEISAI_SCD_MST_now_02 b
	ON a.MKS_KCD = b.MKS_KCD
		AND a.MKS_HTCD = b.MKS_HTCD
		AND a.MKS_SCD = b.MKS_SCD
		AND a.MKS_TEKIYOYMD = b.MKS_TEKIYOYMD;

	SELECT *
	INTO #wk_trg_i_MIKEISAI_SCD_MST_now_03
	FROM inserted;

	UPDATE a
	SET a.MKS_UPDATECNT = ISNULL(b.MKS_UPDATECNT, 0) + 1
	FROM #wk_trg_i_MIKEISAI_SCD_MST_now_03 a
	LEFT OUTER JOIN #wk_trg_i_MIKEISAI_SCD_MST_now_02 b
	ON a.MKS_KCD = b.MKS_KCD
		AND a.MKS_HTCD = b.MKS_HTCD
		AND a.MKS_SCD = b.MKS_SCD
		AND a.MKS_TEKIYOYMD = b.MKS_TEKIYOYMD;

	INSERT INTO MIKEISAI_SCD_MST_now
	SELECT *
	FROM #wk_trg_i_MIKEISAI_SCD_MST_now_03;

	DROP TABLE #wk_trg_i_MIKEISAI_SCD_MST_now_02;
	DROP TABLE #wk_trg_i_MIKEISAI_SCD_MST_now_03;
END
GO

ALTER TABLE [dbo].[MIKEISAI_SCD_MST_now] ENABLE TRIGGER [trg_i_MIKEISAI_SCD_MST_now]
GO
