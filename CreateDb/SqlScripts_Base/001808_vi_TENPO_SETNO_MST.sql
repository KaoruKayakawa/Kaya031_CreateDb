USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[vi_TENPO_SETNO_MST]') AND type in (N'V'))
DROP VIEW [dbo].[vi_TENPO_SETNO_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vi_TENPO_SETNO_MST]
AS
SELECT d.*, ISNULL(e.TSM_TEKIYOYMD_END, CAST('9999/12/31 23:59:59' AS datetime)) AS TSM_TEKIYOYMD_END
FROM (
	SELECT *
	FROM TENPO_SETNO_MST_now
	WHERE TSM_DELFG = 0) d
LEFT OUTER JOIN (
	SELECT c.TSM_KCD_1, c.TSM_TENSETNO, c.TSM_KCD_2, c.TSM_TENCD, c.TSM_TEKIYOYMD, DATEADD(second, -1, MIN(c.TSM_TEKIYOYMD_END)) AS TSM_TEKIYOYMD_END
	FROM (
		SELECT a.TSM_KCD_1, a.TSM_TENSETNO, a.TSM_KCD_2, a.TSM_TENCD, a.TSM_TEKIYOYMD, b.TSM_TEKIYOYMD AS TSM_TEKIYOYMD_END
		FROM (
			SELECT *
			FROM TENPO_SETNO_MST_now
			WHERE TSM_DELFG <> 1) a
		INNER JOIN (
			SELECT *
			FROM TENPO_SETNO_MST_now
			WHERE TSM_DELFG <> 1) b
		ON a.TSM_KCD_1 = b.TSM_KCD_1
			AND a.TSM_TENSETNO = b.TSM_TENSETNO
			AND a.TSM_KCD_2 = b.TSM_KCD_2
			AND a.TSM_TENCD = b.TSM_TENCD
			AND a.TSM_TEKIYOYMD < b.TSM_TEKIYOYMD) c
	GROUP BY c.TSM_KCD_1, c.TSM_TENSETNO, c.TSM_KCD_2, c.TSM_TENCD, c.TSM_TEKIYOYMD) e
ON d.TSM_KCD_1 = e.TSM_KCD_1
	AND d.TSM_TENSETNO = e.TSM_TENSETNO
	AND d.TSM_KCD_2 = e.TSM_KCD_2
	AND d.TSM_TENCD = e.TSM_TENCD
	AND d.TSM_TEKIYOYMD = e.TSM_TEKIYOYMD

GO