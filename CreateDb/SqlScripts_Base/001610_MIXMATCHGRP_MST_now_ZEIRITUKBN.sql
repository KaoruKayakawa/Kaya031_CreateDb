USE [#{-BASE_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MIXMATCHGRP_MST_now_ZEIRITUKBN]') AND type in (N'V'))
DROP VIEW [dbo].[MIXMATCHGRP_MST_now_ZEIRITUKBN]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[MIXMATCHGRP_MST_now_ZEIRITUKBN]
AS
WITH
	t2 AS (
		SELECT a.SMGM_KCD, a.SMGM_HTCD, a.SMGM_MMNO, a.SMGM_TEKIYOYMD, MAX(c.SSHM_ZEIRITUKBN) AS SSHM_ZEIRITUKBN
		FROM vi_MIXMATCHGRP_MST a
		INNER JOIN vi_MIXMATCH_MST b
		ON a.SMGM_KCD = b.SMIM_KCD
			AND a.SMGM_HTCD = b.SMIM_HTCD
			AND a.SMGM_MMNO = b.SMIM_MMNO
			AND (b.SMIM_TEKIYOYMD BETWEEN a.SMGM_TEKIYOYMD AND a.SMGM_TEKIYOYMD_END)
		INNER JOIN vi_SHOHIN_MST c
		ON b.SMIM_KCD = c.SSHM_KCD
			AND b.SMIM_HTCD = c.SSHM_HTCD
			AND b.SMIM_SCD = c.SSHM_SCD
			AND (b.SMIM_TEKIYOYMD BETWEEN c.SSHM_TEKIYOYMD AND c.SSHM_TEKIYOYMD_END)
		GROUP BY a.SMGM_KCD, a.SMGM_HTCD, a.SMGM_MMNO, a.SMGM_TEKIYOYMD
	)
SELECT t1.*, t2.SSHM_ZEIRITUKBN
FROM MIXMATCHGRP_MST_now t1
LEFT OUTER JOIN t2
ON t1.SMGM_KCD = t2.SMGM_KCD
	AND t1.SMGM_HTCD = t2.SMGM_HTCD
	AND t1.SMGM_MMNO = t2.SMGM_MMNO
	AND t1.SMGM_TEKIYOYMD = t2.SMGM_TEKIYOYMD

GO
