USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[vi_TYUMON_KNR_F]') AND type in (N'V'))
DROP VIEW [dbo].[vi_TYUMON_KNR_F]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vi_TYUMON_KNR_F]
AS
SELECT d.*, ISNULL(e.TKF_TEKIYOYMD_END, CAST('9999/12/31 23:59:59' AS datetime)) AS TKF_TEKIYOYMD_END
FROM (
	SELECT *
	FROM TYUMON_KNR_F_now
	WHERE TKF_DELFG = 0) d
LEFT OUTER JOIN (
	SELECT c.TKF_HTCD, c.TKF_SCD, c.TKF_KIKAKUCD, c.TKF_TEKIYOYMD, DATEADD(second, -1, MIN(c.TKF_TEKIYOYMD_END)) AS TKF_TEKIYOYMD_END
	FROM (
		SELECT a.TKF_HTCD, a.TKF_SCD, a.TKF_KIKAKUCD, a.TKF_TEKIYOYMD, b.TKF_TEKIYOYMD AS TKF_TEKIYOYMD_END
		FROM (
			SELECT *
			FROM TYUMON_KNR_F_now
			WHERE TKF_DELFG <> 1) a
		INNER JOIN (
			SELECT *
			FROM TYUMON_KNR_F_now
			WHERE TKF_DELFG <> 1) b
		ON a.TKF_HTCD = b.TKF_HTCD
			AND a.TKF_SCD = b.TKF_SCD
			AND a.TKF_KIKAKUCD = b.TKF_KIKAKUCD
			AND a.TKF_TEKIYOYMD < b.TKF_TEKIYOYMD) c
	GROUP BY c.TKF_HTCD, c.TKF_SCD, c.TKF_KIKAKUCD, c.TKF_TEKIYOYMD) e
ON d.TKF_HTCD = e.TKF_HTCD
	AND d.TKF_SCD = e.TKF_SCD
	AND d.TKF_KIKAKUCD = e.TKF_KIKAKUCD
	AND d.TKF_TEKIYOYMD = e.TKF_TEKIYOYMD

GO
