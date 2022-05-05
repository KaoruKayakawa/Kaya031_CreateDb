USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[trg_i_TENPO_SETNO_MST_now]') AND type in (N'TR'))
DROP TRIGGER [dbo].[trg_i_TENPO_SETNO_MST_now]
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
CREATE TRIGGER [dbo].[trg_i_TENPO_SETNO_MST_now]
   ON  [dbo].[TENPO_SETNO_MST_now]
   INSTEAD OF INSERT
AS 
BEGIN
	SET NOCOUNT ON;
	
	SELECT a.TSM_UPDATECNT AS cnt_new, b.TSM_UPDATECNT AS cnt_old, b.TSM_DELFG AS delfg_old
	INTO #wk_trg_i_TENPO_SETNO_MST_now_01
	FROM inserted a
	LEFT OUTER JOIN TENPO_SETNO_MST_now b
	ON a.TSM_KCD_1 = b.TSM_KCD_1
		AND a.TSM_TENSETNO = b.TSM_TENSETNO
		AND a.TSM_KCD_2 = b.TSM_KCD_2
		AND a.TSM_TENCD = b.TSM_TENCD
		AND a.TSM_TEKIYOYMD = b.TSM_TEKIYOYMD;

	IF (SELECT COUNT(*) FROM #wk_trg_i_TENPO_SETNO_MST_now_01 WHERE (cnt_new = 0 AND cnt_old IS NOT NULL AND delfg_old <> 1) OR (cnt_new > 0 AND (cnt_new <> cnt_old OR cnt_old IS NULL))) > 0
	BEGIN
		RAISERROR(50001, 11, 1, N'TENPO_SETNO_MST');
		
		RETURN;
	END

	DROP TABLE #wk_trg_i_TENPO_SETNO_MST_now_01;

	SELECT a.*
	INTO #wk_trg_i_TENPO_SETNO_MST_now_02
	FROM TENPO_SETNO_MST_now a
	INNER JOIN inserted b
	ON a.TSM_KCD_1 = b.TSM_KCD_1
		AND a.TSM_TENSETNO = b.TSM_TENSETNO
		AND a.TSM_KCD_2 = b.TSM_KCD_2
		AND a.TSM_TENCD = b.TSM_TENCD
		AND a.TSM_TEKIYOYMD = b.TSM_TEKIYOYMD;

	INSERT INTO TENPO_SETNO_MST_old
	SELECT *
	FROM #wk_trg_i_TENPO_SETNO_MST_now_02;

	DELETE FROM TENPO_SETNO_MST_now
	FROM TENPO_SETNO_MST_now a
	INNER JOIN #wk_trg_i_TENPO_SETNO_MST_now_02 b
	ON a.TSM_KCD_1 = b.TSM_KCD_1
		AND a.TSM_TENSETNO = b.TSM_TENSETNO
		AND a.TSM_KCD_2 = b.TSM_KCD_2
		AND a.TSM_TENCD = b.TSM_TENCD
		AND a.TSM_TEKIYOYMD = b.TSM_TEKIYOYMD;

	SELECT *
	INTO #wk_trg_i_TENPO_SETNO_MST_now_03
	FROM inserted;

	UPDATE a
	SET a.TSM_UPDATECNT = ISNULL(b.TSM_UPDATECNT, 0) + 1
	FROM #wk_trg_i_TENPO_SETNO_MST_now_03 a
	LEFT OUTER JOIN #wk_trg_i_TENPO_SETNO_MST_now_02 b
	ON a.TSM_KCD_1 = b.TSM_KCD_1
		AND a.TSM_TENSETNO = b.TSM_TENSETNO
		AND a.TSM_KCD_2 = b.TSM_KCD_2
		AND a.TSM_TENCD = b.TSM_TENCD
		AND a.TSM_TEKIYOYMD = b.TSM_TEKIYOYMD;

	INSERT INTO TENPO_SETNO_MST_now
	SELECT *
	FROM #wk_trg_i_TENPO_SETNO_MST_now_03;

	DROP TABLE #wk_trg_i_TENPO_SETNO_MST_now_02;
	DROP TABLE #wk_trg_i_TENPO_SETNO_MST_now_03;
END
GO

ALTER TABLE [dbo].[TENPO_SETNO_MST_now] ENABLE TRIGGER [trg_i_TENPO_SETNO_MST_now]
GO
