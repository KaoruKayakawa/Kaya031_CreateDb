USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[vi_MIXMATCHGRP_MST]') AND type in (N'V'))
DROP VIEW [dbo].[vi_MIXMATCHGRP_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vi_MIXMATCHGRP_MST]
AS
SELECT d.*, ISNULL(e.SMGM_TEKIYOYMD_END, CAST('9999/12/31 23:59:59' AS datetime)) AS SMGM_TEKIYOYMD_END
FROM (
	SELECT *
	FROM MIXMATCHGRP_MST_now
	WHERE SMGM_DELFG = 0) d
LEFT OUTER JOIN (
	SELECT c.SMGM_KCD, c.SMGM_HTCD, c.SMGM_MMNO, c.SMGM_TEKIYOYMD, DATEADD(second, -1, MIN(c.SMGM_TEKIYOYMD_END)) AS SMGM_TEKIYOYMD_END
	FROM (
		SELECT a.SMGM_KCD, a.SMGM_HTCD, a.SMGM_MMNO, a.SMGM_TEKIYOYMD, b.SMGM_TEKIYOYMD AS SMGM_TEKIYOYMD_END
		FROM (
			SELECT *
			FROM MIXMATCHGRP_MST_now
			WHERE SMGM_DELFG <> 1) a
		INNER JOIN (
			SELECT *
			FROM MIXMATCHGRP_MST_now
			WHERE SMGM_DELFG <> 1) b
		ON a.SMGM_KCD = b.SMGM_KCD
			AND a.SMGM_HTCD = b.SMGM_HTCD
			AND a.SMGM_MMNO = b.SMGM_MMNO
			AND a.SMGM_TEKIYOYMD < b.SMGM_TEKIYOYMD) c
	GROUP BY c.SMGM_KCD, c.SMGM_HTCD, c.SMGM_MMNO, c.SMGM_TEKIYOYMD) e
ON d.SMGM_KCD = e.SMGM_KCD
	AND d.SMGM_HTCD = e.SMGM_HTCD
	AND d.SMGM_MMNO = e.SMGM_MMNO
	AND d.SMGM_TEKIYOYMD = e.SMGM_TEKIYOYMD

GO
