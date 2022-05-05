USE [#{-APP_DB-}#]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[vi_MIXMATCH_MST]') AND type in (N'V'))
DROP VIEW [dbo].[vi_MIXMATCH_MST]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[vi_MIXMATCH_MST]
AS
	SELECT a.*
	FROM #{-BASE_DB-}#.dbo.vi_MIXMATCH_MST a
	INNER JOIN #{-BASE_DB-}#.dbo.MIXMATCH_MMNO b
	ON a.SMIM_MMNOBIG = b.CSVMMNO
GO