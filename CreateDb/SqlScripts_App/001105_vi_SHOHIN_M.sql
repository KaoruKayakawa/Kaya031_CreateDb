USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[vi_SHOHIN_M]') AND type in (N'V'))
DROP VIEW [dbo].[vi_SHOHIN_M]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vi_SHOHIN_M]
AS
SELECT d.*, ISNULL(e.SHM_TEKIYOYMD_END, CAST('9999/12/31 23:59:59' AS datetime)) AS SHM_TEKIYOYMD_END
FROM (
	SELECT *
	FROM SHOHIN_M_now
	WHERE SHM_DELFG = 0) d
LEFT OUTER JOIN (
	SELECT c.SHM_HTCD, c.SHM_SCD, c.SHM_TEKIYOYMD, DATEADD(second, -1, MIN(c.SHM_TEKIYOYMD_END)) AS SHM_TEKIYOYMD_END
	FROM (
		SELECT a.SHM_HTCD, a.SHM_SCD, a.SHM_TEKIYOYMD, b.SHM_TEKIYOYMD AS SHM_TEKIYOYMD_END
		FROM (
			SELECT *
			FROM SHOHIN_M_now
			WHERE SHM_DELFG <> 1) a
		INNER JOIN (
			SELECT *
			FROM SHOHIN_M_now
			WHERE SHM_DELFG <> 1) b
		ON a.SHM_HTCD = b.SHM_HTCD
			AND a.SHM_SCD = b.SHM_SCD
			AND a.SHM_TEKIYOYMD < b.SHM_TEKIYOYMD) c
	GROUP BY c.SHM_HTCD, c.SHM_SCD, c.SHM_TEKIYOYMD) e
ON d.SHM_HTCD = e.SHM_HTCD
	AND d.SHM_SCD = e.SHM_SCD
	AND d.SHM_TEKIYOYMD = e.SHM_TEKIYOYMD

GO
