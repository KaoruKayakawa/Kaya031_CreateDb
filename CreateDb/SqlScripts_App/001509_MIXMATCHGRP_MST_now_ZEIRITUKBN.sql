USE [#{-APP_DB-}#]
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
	SELECT a.*
	FROM #{-BASE_DB-}#.dbo.MIXMATCHGRP_MST_now_ZEIRITUKBN a
	INNER JOIN #{-BASE_DB-}#.dbo.MIXMATCH_MMNO b
	ON a.SMGM_MMNOBIG = b.CSVMMNO
GO
