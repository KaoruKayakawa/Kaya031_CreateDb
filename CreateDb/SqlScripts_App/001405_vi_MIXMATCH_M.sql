USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[vi_MIXMATCH_M]') AND type in (N'V'))
DROP VIEW [dbo].[vi_MIXMATCH_M]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vi_MIXMATCH_M]
AS
SELECT d.*, ISNULL(e.MIM_TEKIYOYMD_END, CAST('9999/12/31 23:59:59' AS datetime)) AS MIM_TEKIYOYMD_END
FROM (
	SELECT *
	FROM MIXMATCH_M_now
	WHERE MIM_DELFG = 0) d
LEFT OUTER JOIN (
	SELECT c.MIM_HTCD, c.MIM_MMNO, c.MIM_SCD, c.MIM_TEKIYOYMD, DATEADD(second, -1, MIN(c.MIM_TEKIYOYMD_END)) AS MIM_TEKIYOYMD_END
	FROM (
		SELECT a.MIM_HTCD, a.MIM_MMNO, a.MIM_SCD, a.MIM_TEKIYOYMD, b.MIM_TEKIYOYMD AS MIM_TEKIYOYMD_END
		FROM (
			SELECT *
			FROM MIXMATCH_M_now
			WHERE MIM_DELFG <> 1) a
		INNER JOIN (
			SELECT *
			FROM MIXMATCH_M_now
			WHERE MIM_DELFG <> 1) b
		ON a.MIM_HTCD = b.MIM_HTCD
			AND a.MIM_MMNO = b.MIM_MMNO
			AND a.MIM_SCD = b.MIM_SCD
			AND a.MIM_TEKIYOYMD < b.MIM_TEKIYOYMD) c
	GROUP BY c.MIM_HTCD, c.MIM_MMNO, c.MIM_SCD, c.MIM_TEKIYOYMD) e
ON d.MIM_HTCD = e.MIM_HTCD
	AND d.MIM_MMNO = e.MIM_MMNO
	AND d.MIM_SCD = e.MIM_SCD
	AND d.MIM_TEKIYOYMD = e.MIM_TEKIYOYMD

GO