USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[vi_MIKEISAI_SCD_MST]') AND type in (N'V'))
DROP VIEW [dbo].[vi_MIKEISAI_SCD_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vi_MIKEISAI_SCD_MST]
AS
SELECT d.*, ISNULL(e.MKS_TEKIYOYMD_END, CAST('9999/12/31 23:59:59' AS datetime)) AS MKS_TEKIYOYMD_END
FROM (
	SELECT *
	FROM MIKEISAI_SCD_MST_now
	WHERE MKS_DELFG = 0) d
LEFT OUTER JOIN (
	SELECT c.MKS_KCD, c.MKS_HTCD, c.MKS_SCD, c.MKS_TEKIYOYMD, DATEADD(second, -1, MIN(c.MKS_TEKIYOYMD_END)) AS MKS_TEKIYOYMD_END
	FROM (
		SELECT a.MKS_KCD, a.MKS_HTCD, a.MKS_SCD, a.MKS_TEKIYOYMD, b.MKS_TEKIYOYMD AS MKS_TEKIYOYMD_END
		FROM (
			SELECT *
			FROM MIKEISAI_SCD_MST_now
			WHERE MKS_DELFG <> 1) a
		INNER JOIN (
			SELECT *
			FROM MIKEISAI_SCD_MST_now
			WHERE MKS_DELFG <> 1) b
		ON a.MKS_KCD = b.MKS_KCD
			AND a.MKS_HTCD = b.MKS_HTCD
			AND a.MKS_SCD = b.MKS_SCD
			AND a.MKS_TEKIYOYMD < b.MKS_TEKIYOYMD) c
	GROUP BY c.MKS_KCD, c.MKS_HTCD, c.MKS_SCD, c.MKS_TEKIYOYMD) e
ON d.MKS_KCD = e.MKS_KCD
	AND d.MKS_HTCD = e.MKS_HTCD
	AND d.MKS_SCD = e.MKS_SCD
	AND d.MKS_TEKIYOYMD = e.MKS_TEKIYOYMD

GO