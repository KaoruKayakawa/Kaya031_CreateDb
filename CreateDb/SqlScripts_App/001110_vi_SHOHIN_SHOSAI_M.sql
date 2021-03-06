USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[vi_SHOHIN_SHOSAI_M]') AND type in (N'V'))
DROP VIEW [dbo].[vi_SHOHIN_SHOSAI_M]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vi_SHOHIN_SHOSAI_M]
AS
SELECT d.*, ISNULL(e.SSM_TEKIYOYMD_END, CAST('9999/12/31 23:59:59' AS datetime)) AS SSM_TEKIYOYMD_END
FROM (
	SELECT *
	FROM SHOHIN_SHOSAI_M_now
	WHERE SSM_DELFG = 0) d
LEFT OUTER JOIN (
	SELECT c.SSM_HTCD, c.SSM_SCD, c.SSM_TEKIYOYMD, DATEADD(second, -1, MIN(c.SSM_TEKIYOYMD_END)) AS SSM_TEKIYOYMD_END
	FROM (
		SELECT a.SSM_HTCD, a.SSM_SCD, a.SSM_TEKIYOYMD, b.SSM_TEKIYOYMD AS SSM_TEKIYOYMD_END
		FROM (
			SELECT *
			FROM SHOHIN_SHOSAI_M_now
			WHERE SSM_DELFG <> 1) a
		INNER JOIN (
			SELECT *
			FROM SHOHIN_SHOSAI_M_now
			WHERE SSM_DELFG <> 1) b
		ON a.SSM_HTCD = b.SSM_HTCD
			AND a.SSM_SCD = b.SSM_SCD
			AND a.SSM_TEKIYOYMD < b.SSM_TEKIYOYMD) c
	GROUP BY c.SSM_HTCD, c.SSM_SCD, c.SSM_TEKIYOYMD) e
ON d.SSM_HTCD = e.SSM_HTCD
	AND d.SSM_SCD = e.SSM_SCD
	AND d.SSM_TEKIYOYMD = e.SSM_TEKIYOYMD

GO
