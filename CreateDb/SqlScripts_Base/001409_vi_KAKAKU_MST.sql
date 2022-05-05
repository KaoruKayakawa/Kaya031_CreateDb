USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[vi_KAKAKU_MST]') AND type in (N'V'))
DROP VIEW [dbo].[vi_KAKAKU_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vi_KAKAKU_MST]
AS
SELECT d.*, ISNULL(e.SKAK_TEKIYOYMD_END, CAST('9999/12/31 23:59:59' AS datetime)) AS SKAK_TEKIYOYMD_END
FROM (
	SELECT *
	FROM KAKAKU_MST_now
	WHERE SKAK_DELFG = 0) d
LEFT OUTER JOIN (
	SELECT c.SKAK_KCD, c.SKAK_HTCD, c.SKAK_SCD, c.SKAK_KIKAKUCD, c.SKAK_TEKIYOYMD, DATEADD(second, -1, MIN(c.SKAK_TEKIYOYMD_END)) AS SKAK_TEKIYOYMD_END
	FROM (
		SELECT a.SKAK_KCD, a.SKAK_HTCD, a.SKAK_SCD, a.SKAK_KIKAKUCD, a.SKAK_TEKIYOYMD, b.SKAK_TEKIYOYMD AS SKAK_TEKIYOYMD_END
		FROM (
			SELECT *
			FROM KAKAKU_MST_now
			WHERE SKAK_DELFG <> 1) a
		INNER JOIN (
			SELECT *
			FROM KAKAKU_MST_now
			WHERE SKAK_DELFG <> 1) b
		ON a.SKAK_KCD = b.SKAK_KCD
			AND a.SKAK_HTCD = b.SKAK_HTCD
			AND a.SKAK_SCD = b.SKAK_SCD
			AND a.SKAK_KIKAKUCD = b.SKAK_KIKAKUCD
			AND a.SKAK_TEKIYOYMD < b.SKAK_TEKIYOYMD) c
	GROUP BY c.SKAK_KCD, c.SKAK_HTCD, c.SKAK_SCD, c.SKAK_KIKAKUCD, c.SKAK_TEKIYOYMD) e
ON d.SKAK_KCD = e.SKAK_KCD
	AND d.SKAK_HTCD = e.SKAK_HTCD
	AND d.SKAK_SCD = e.SKAK_SCD
	AND d.SKAK_KIKAKUCD = e.SKAK_KIKAKUCD
	AND d.SKAK_TEKIYOYMD = e.SKAK_TEKIYOYMD

GO