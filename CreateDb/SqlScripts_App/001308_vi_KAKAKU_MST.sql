USE [#{-APP_DB-}#]
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
	SELECT *
	FROM #{-BASE_DB-}#.dbo.vi_KAKAKU_MST
GO
